import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness_app/services/iap_service.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages premium subscription status.
/// Reads/writes isPremium in Firestore users/{uid}.
/// InAppPurchase success should call setPremiumStatus(true).
class SubscriptionProvider with ChangeNotifier {
  bool _isPremium = false;
  bool _isLifetime = false;
  bool _isLoading = true;
  String? _error;
  bool _isOfflineFallback = false;
  bool _isServerConfirmed = false;
  int _loadRequestId = 0;

  @visibleForTesting
  String? userIdOverrideForTesting;

  @visibleForTesting
  Future<Map<String, dynamic>?> Function(String uid)?
      remoteUserDocFetcherForTesting;

  IAPService? _iapService;
  IAPService get iapService => _iapService ??= IAPService();

  List<ProductDetails> _products = [];
  List<SubscriptionPlan> _plans = [];
  StreamSubscription<PurchaseDetails>? _purchaseSubscription;
  StreamSubscription<User?>? _authSubscription;

  bool get isPremium => _isPremium;
  bool get isLifetime => _isLifetime;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isOfflineFallback => _isOfflineFallback;
  bool get isServerConfirmed => _isServerConfirmed;
  List<ProductDetails> get products => _products;
  List<SubscriptionPlan> get plans => _plans;

  User? get _currentUser {
    try {
      return FirebaseAuth.instance.currentUser;
    } catch (_) {
      return null;
    }
  }

  String? get currentUserId {
    if (userIdOverrideForTesting != null) {
      return userIdOverrideForTesting;
    }
    return _currentUser?.uid;
  }

  SubscriptionProvider({
    bool autoInitialize = true,
    IAPService? iapService,
  }) : _iapService = iapService {
    if (autoInitialize) {
      _init();
    }
  }

  static const String _cachedSubscriptionPrefix = 'cached_subscription_state_';

  static String getCacheKey(String uid) => '$_cachedSubscriptionPrefix$uid';

  /// Persists the last confirmed subscription state to SharedPreferences
  Future<void> saveEntitlementsToCache(
    String uid, {
    required bool isPremium,
    required bool isLifetime,
    DateTime? expirationDate,
  }) async {
    if (uid.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final map = <String, dynamic>{
        'isPremium': isPremium,
        'isLifetime': isLifetime,
        'cachedAt': DateTime.now().toIso8601String(),
        if (expirationDate != null)
          'expirationDate': expirationDate.toIso8601String(),
      };
      await prefs.setString(getCacheKey(uid), jsonEncode(map));
    } catch (e) {
      debugPrint('SubscriptionProvider: Failed to cache entitlements: $e');
    }
  }

  /// Restores confirmed subscription state from local SharedPreferences
  Future<bool> restoreCachedEntitlements(String? uid) async {
    if (uid == null || uid.isEmpty) {
      _isPremium = false;
      _isLifetime = false;
      _isOfflineFallback = false;
      _isServerConfirmed = false;
      return false;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(getCacheKey(uid));
      if (cachedJson == null || cachedJson.trim().isEmpty) {
        return false;
      }

      final dynamic decoded = jsonDecode(cachedJson);
      if (decoded is Map<String, dynamic> || decoded is Map) {
        final map = Map<String, dynamic>.from(decoded);
        final cachedPremium = map['isPremium'] == true;
        final cachedLifetime = map['isLifetime'] == true;

        // Verify expiration if not a lifetime license
        if (cachedPremium && !cachedLifetime && map['expirationDate'] != null) {
          final exp = DateTime.tryParse(map['expirationDate'].toString());
          if (exp != null && DateTime.now().isAfter(exp)) {
            _isPremium = false;
            _isLifetime = false;
            _isOfflineFallback = false;
            return false;
          }
        }

        _isPremium = cachedPremium;
        _isLifetime = cachedLifetime;
        _isOfflineFallback = true;
        _isServerConfirmed = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint(
          'SubscriptionProvider: Failed to restore cached entitlements: $e');
    }
    return false;
  }

  /// Clears cached subscription state for the specified user
  Future<void> clearCachedEntitlements(String? uid) async {
    if (uid == null || uid.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(getCacheKey(uid));
    } catch (e) {
      debugPrint(
          'SubscriptionProvider: Failed to clear cached entitlements: $e');
    }
  }

  Future<void> _init() async {
    final uid = currentUserId;
    if (uid != null && uid.isNotEmpty) {
      await restoreCachedEntitlements(uid);
    }
    await loadPremiumStatus();

    try {
      final iap = iapService;
      await iap.initialize();
      _products = iap.products;
      _updatePlans();
      _purchaseSubscription =
          iap.purchaseStream.listen(_handlePurchaseUpdate);
    } catch (e) {
      debugPrint('SubscriptionProvider: IAP init error: $e');
    }

    try {
      _authSubscription =
          FirebaseAuth.instance.authStateChanges().listen((User? user) async {
        if (user == null) {
          _isPremium = false;
          _isLifetime = false;
          _isServerConfirmed = false;
          _isOfflineFallback = false;
          notifyListeners();
        } else {
          await loadPremiumStatus();
        }
      });
    } catch (_) {
      // Firebase not initialized in test environments
    }

    try {
      await verifySubscriptionStatus();
    } catch (e) {
      debugPrint('SubscriptionProvider: verifySubscriptionStatus error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Load premium status from Firestore or fallback to cache on network failure
  Future<void> loadPremiumStatus() async {
    final requestId = ++_loadRequestId;
    _isLoading = true;
    _error = null;
    notifyListeners();

    final uid = currentUserId;

    if (uid == null || uid.isEmpty) {
      _isPremium = false;
      _isLifetime = false;
      _isServerConfirmed = false;
      _isOfflineFallback = false;
      _isLoading = false;
      _error = null;
      notifyListeners();
      return;
    }

    // Fast-path / offline availability: load from cache first
    await restoreCachedEntitlements(uid);

    try {
      Map<String, dynamic>? data;

      if (remoteUserDocFetcherForTesting != null) {
        data = await remoteUserDocFetcherForTesting!(uid);
      } else {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();
        data = doc.data();
      }

      // If user switched or request is stale, abandon updating
      if (requestId != _loadRequestId || currentUserId != uid) {
        return;
      }

      final serverPremium = data?['isPremium'] == true;
      final serverLifetime = data?['isLifetime'] == true;
      DateTime? expirationDate;
      final expVal = data?['premiumExpiresAt'] ?? data?['expiresAt'];
      if (expVal != null) {
        if (expVal is Timestamp) {
          expirationDate = expVal.toDate();
        } else if (expVal is String) {
          expirationDate = DateTime.tryParse(expVal);
        }
      }

      // Check if authoritative expiration is past
      if (serverPremium && !serverLifetime && expirationDate != null) {
        if (DateTime.now().isAfter(expirationDate)) {
          _isPremium = false;
          _isLifetime = false;
          _isServerConfirmed = true;
          _isOfflineFallback = false;
          _error = null;
          await saveEntitlementsToCache(
            uid,
            isPremium: false,
            isLifetime: false,
            expirationDate: expirationDate,
          );
          return;
        }
      }

      _isPremium = serverPremium;
      _isLifetime = serverLifetime;
      _isServerConfirmed = true;
      _isOfflineFallback = false;
      _error = null;

      // Update cache with authoritative response
      await saveEntitlementsToCache(
        uid,
        isPremium: serverPremium,
        isLifetime: serverLifetime,
        expirationDate: expirationDate,
      );
    } catch (e) {
      // If user switched or request is stale
      if (requestId != _loadRequestId || currentUserId != uid) {
        return;
      }

      _error = e.toString();

      // If remote failed (offline / network error):
      // Do not treat failed network request as authoritative proof that subscription expired!
      // If we restored cached entitlements earlier, they are retained as offline fallback.
      if (!_isLifetime && !_isPremium) {
        await restoreCachedEntitlements(uid);
      }
    } finally {
      if (requestId == _loadRequestId) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  void _handlePurchaseUpdate(PurchaseDetails purchase) async {
    if (purchase.status == PurchaseStatus.purchased ||
        purchase.status == PurchaseStatus.restored) {
      if (purchase.productID == 'premium_monthly' ||
          purchase.productID == 'premium_yearly') {
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
      await iapService.buyProduct(product);
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
      await iapService.restorePurchases();
      // purchase stream handler will set premium if entitlement exists
      await loadPremiumStatus();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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
      final pastPurchases = await iapService.getAndroidPastPurchases();
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
         await iapService.restorePurchases();
       } catch (e) {
         // Ignore errors here
       }
    }
  }

  /// Set premium status in Firestore (called after successful purchase)
  Future<void> setPremiumStatus(bool value, {bool isLifetime = false}) async {
    try {
      final user = _currentUser;
      final uid = currentUserId;
      if (uid == null || uid.isEmpty) return;

      final data = <String, dynamic>{
        'isPremium': value,
      };
      if (isLifetime) {
        data['isLifetime'] = true;
      }

      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .set(data, SetOptions(merge: true));
      }

      _isPremium = value;
      if (isLifetime) {
        _isLifetime = true;
      } else if (!value) {
        _isLifetime = false;
      }
      _isServerConfirmed = true;
      _isOfflineFallback = false;
      _error = null;

      await saveEntitlementsToCache(
        uid,
        isPremium: value,
        isLifetime: _isLifetime,
      );

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
      await iapService.buyProduct(plan.productDetails);
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
    _iapService?.dispose();
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
