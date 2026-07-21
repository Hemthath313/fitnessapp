import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness_app/services/iap_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'dart:async';

/// Manages premium subscription status.
/// Reads/writes isPremium in Firestore users/{uid}.
/// InAppPurchase success should call setPremiumStatus(true).
class SubscriptionProvider with ChangeNotifier {
  bool _isPremium = false;
  bool _isLifetime = false;
  bool _isLoading = true;
  String? _error;
  
  final IAPService _iapService = IAPService();
  List<ProductDetails> _products = [];
  List<SubscriptionPlan> _plans = [];
  StreamSubscription<PurchaseDetails>? _purchaseSubscription;
  StreamSubscription<User?>? _authSubscription;
  bool _didAttemptAutoRestore = false;

  bool get isPremium => _isPremium;
  bool get isLifetime => _isLifetime;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<ProductDetails> get products => _products;
  List<SubscriptionPlan> get plans => _plans;

  SubscriptionProvider() {
    _init();
  }

  Future<void> _init() async {
    await loadPremiumStatus();
    await _iapService.initialize();
    _products = _iapService.products;
    _updatePlans();
    
    _purchaseSubscription = _iapService.purchaseStream.listen(_handlePurchaseUpdate);

    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((User? user) async {
      if (user == null) {
        _isPremium = false;
        _isLifetime = false;
        notifyListeners();
      } else {
        await loadPremiumStatus();
      }
    });

    // Firebase-only production-friendly behavior:
    // If user logs in with a *new* Firebase account but the Store account already owns
    // the subscription, purchasing again will show "already owned".
    // Auto-restore lets us re-attach the entitlement to the new uid by writing isPremium=true.
    await verifySubscriptionStatus();
    
    _isLoading = false;
    notifyListeners();
  }

  /// Load premium status from Firestore
  Future<void> loadPremiumStatus() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _isPremium = false;
        _isLoading = false;
        notifyListeners();
        return;
      }

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      _isPremium = doc.data()?['isPremium'] == true;
      _isLifetime = doc.data()?['isLifetime'] == true;
      _isLoading = false;
      _error = null;
    } catch (e) {
      _error = e.toString();
    }
    notifyListeners();
  }

  void _handlePurchaseUpdate(PurchaseDetails purchase) async {
    if (purchase.status == PurchaseStatus.purchased || purchase.status == PurchaseStatus.restored) {
      if (purchase.productID == 'premium_monthly' || purchase.productID == 'premium_yearly') {
        await setPremiumStatus(true, isLifetime: true);
      } else if (purchase.productID == 'gymbuddy_premium_monthly') {
        await setPremiumStatus(true);
      }
    } else if (purchase.status == PurchaseStatus.error) {
      _error = purchase.error?.message;
      notifyListeners();
    }
  }

  Future<void> buyProduct(ProductDetails product) async {
    try {
      await _iapService.buyProduct(product);
    } catch (e) {
      // If the store says the item is already owned, we should restore instead.
      final msg = e.toString().toLowerCase();
      if (msg.contains('already') && msg.contains('own')) {
        await restorePurchases();
      }
      rethrow;
    }
  }

  Future<void> restorePurchases() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _iapService.restorePurchases();
      // purchase stream handler will set premium if entitlement exists
      await loadPremiumStatus();
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  /// Strictly verify subscription status on startup.
  /// On Android, this checks for expiration by querying past purchases.
  /// On iOS, it relies on the store's stream updates (or manual restore).
  Future<void> verifySubscriptionStatus() async {
    // If the user already has lifetime access written to their Firestore doc,
    // we bypass all active check updates and keep them premium forever.
    if (_isLifetime) {
      _isPremium = true;
      notifyListeners();
      return;
    }

    // 1. Android Strict Check
    if (defaultTargetPlatform == TargetPlatform.android) {
      final pastPurchases = await _iapService.getAndroidPastPurchases();
      if (pastPurchases != null) {
        // If they own legacy or lifetime one-time products, upgrade them to lifetime in Firestore.
        bool ownsLegacyOrLifetime = pastPurchases.any((purchase) =>
            (purchase.status == PurchaseStatus.purchased || purchase.status == PurchaseStatus.restored) &&
            (purchase.productID == 'premium_monthly' || purchase.productID == 'premium_yearly'));

        if (ownsLegacyOrLifetime) {
          await setPremiumStatus(true, isLifetime: true);
          return;
        }

        // Check if any purchase is active (purchased/restored) AND matches our IDs
        bool hasActiveSubscription = pastPurchases.any((purchase) =>
            (purchase.status == PurchaseStatus.purchased || purchase.status == PurchaseStatus.restored) &&
            (purchase.productID == 'gymbuddy_premium_monthly'));

        if (!hasActiveSubscription && _isPremium) {
          debugPrint('SubscriptionProvider: Expired subscription detected on Android. Downgrading.');
          await setPremiumStatus(false);
        } else if (hasActiveSubscription && !_isPremium) {
           debugPrint('SubscriptionProvider: Active subscription found on Android. Upgrading.');
           // We found a valid subscription!
           await setPremiumStatus(true);
        }
        return;
      }
    }

    // 2. iOS / Generic Fallback
    // We can't strict-check expiration easily on iOS without a backend or annoying the user with login prompts.
    // However, we call restorePurchases() if the user CLAIMS to be premium, to try and validate it.
    // If they are NOT premium, we don't bother (to avoid prompts).
    if (_isPremium) {
       try {
         await _iapService.restorePurchases();
       } catch (e) {
         // Ignore errors here
       }
    }
  }

  /// Set premium status in Firestore (called after successful purchase)
  Future<void> setPremiumStatus(bool value, {bool isLifetime = false}) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final data = {
        'isPremium': value,
      };
      if (isLifetime) {
        data['isLifetime'] = true;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(data, SetOptions(merge: true));

      _isPremium = value;
      if (isLifetime) {
        _isLifetime = true;
      }
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Refresh premium status (e.g. after login or restore)
  Future<void> refresh() => loadPremiumStatus();

  void _updatePlans() {
    final List<SubscriptionPlan> newPlans = [];
    
    for (var product in _products) {
      if (defaultTargetPlatform == TargetPlatform.android && product is GooglePlayProductDetails) {
        final index = product.subscriptionIndex;
        final offers = product.productDetails.subscriptionOfferDetails;
        if (index != null && offers != null && index < offers.length) {
          final offer = offers[index];
          final isYearly = offer.basePlanId == 'yearly';
          final isMonthly = offer.basePlanId == 'monthly';
          
          if (isMonthly || isYearly) {
            final pricingPhase = offer.pricingPhases.last;
            final price = pricingPhase.formattedPrice;
            
            newPlans.add(SubscriptionPlan(
              id: '${product.id}:${offer.basePlanId}',
              title: isYearly ? 'Gym Buddy AI Premium Yearly' : 'Gym Buddy AI Premium Monthly',
              description: isYearly 
                  ? 'Best value! Auto-renews every year.' 
                  : 'Auto-renews every month.',
              price: price,
              isYearly: isYearly,
              productDetails: product,
            ));
          }
        } else {
          // Fallback if no offer details (e.g. one-time product or legacy billing)
          final isLifetime = product.id == 'premium_yearly';
          newPlans.add(SubscriptionPlan(
            id: product.id,
            title: isLifetime ? 'Gym Buddy AI Premium Lifetime' : product.title.split('(')[0].trim(),
            description: isLifetime 
                ? 'One-time payment. Full lifetime access.' 
                : product.description,
            price: product.price,
            isYearly: false,
            isLifetime: isLifetime,
            productDetails: product,
          ));
        }
      } else {
        // iOS or non-Android fallback
        final isYearly = product.id.contains('yearly') && !product.id.contains('lifetime') && product.id != 'premium_yearly';
        final isLifetime = product.id.contains('lifetime') || product.id == 'premium_yearly';
        newPlans.add(SubscriptionPlan(
          id: product.id,
          title: isLifetime 
              ? 'Gym Buddy AI Premium Lifetime' 
              : (isYearly ? 'Gym Buddy AI Premium Yearly' : 'Gym Buddy AI Premium Monthly'),
          description: isLifetime 
              ? 'One-time payment. Full lifetime access.' 
              : (isYearly ? 'Best value! Auto-renews every year.' : 'Auto-renews every month.'),
          price: product.price,
          isYearly: isYearly,
          isLifetime: isLifetime,
          productDetails: product,
        ));
      }
    }
    
    _plans = newPlans;
  }

  Future<void> buyPlan(SubscriptionPlan plan) async {
    try {
      await _iapService.buyProduct(plan.productDetails);
    } catch (e) {
      // If the store says the item is already owned, we should restore instead.
      final msg = e.toString().toLowerCase();
      if (msg.contains('already') && msg.contains('own')) {
        await restorePurchases();
      }
      rethrow;
    }
  }

  @override
  void dispose() {
    _purchaseSubscription?.cancel();
    _authSubscription?.cancel();
    _iapService.dispose();
    super.dispose();
  }
}

class SubscriptionPlan {
  final String id;
  final String title;
  final String description;
  final String price;
  final bool isYearly;
  final bool isLifetime;
  final ProductDetails productDetails;
  final String? offerToken;

  SubscriptionPlan({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.isYearly,
    this.isLifetime = false,
    required this.productDetails,
    this.offerToken,
  });
}
