import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness_app/services/iap_service.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'dart:async';

/// Manages premium subscription status.
/// Reads/writes isPremium in Firestore users/{uid}.
/// InAppPurchase success should call setPremiumStatus(true).
class SubscriptionProvider with ChangeNotifier {
  bool _isPremium = false;
  bool _isLoading = true;
  String? _error;
  
  final IAPService _iapService = IAPService();
  List<ProductDetails> _products = [];
  StreamSubscription<PurchaseDetails>? _purchaseSubscription;

  bool get isPremium => _isPremium;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<ProductDetails> get products => _products;

  SubscriptionProvider() {
    _init();
  }

  Future<void> _init() async {
    await loadPremiumStatus();
    await _iapService.initialize();
    _products = _iapService.products;
    
    _purchaseSubscription = _iapService.purchaseStream.listen(_handlePurchaseUpdate);
    
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
        await setPremiumStatus(true);
      }
    } else if (purchase.status == PurchaseStatus.error) {
      _error = purchase.error?.message;
      notifyListeners();
    }
  }

  Future<void> buyProduct(ProductDetails product) async {
    await _iapService.buyProduct(product);
  }

  Future<void> restorePurchases() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _iapService.restorePurchases();
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  /// Set premium status in Firestore (called after successful purchase)
  Future<void> setPremiumStatus(bool value) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({'isPremium': value}, SetOptions(merge: true));

      _isPremium = value;
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

  @override
  void dispose() {
    _purchaseSubscription?.cancel();
    _iapService.dispose();
    super.dispose();
  }
}
