import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:flutter/services.dart';

class IAPService {
  final InAppPurchase _iap = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;
  
  final _purchaseController = StreamController<PurchaseDetails>.broadcast();
  Stream<PurchaseDetails> get purchaseStream => _purchaseController.stream;

  final List<String> _productIds = [
    'gymbuddy_premium_monthly',
    'premium_yearly',
  ];
  List<ProductDetails> _products = [];
  List<ProductDetails> get products => _products;

  bool _isAvailable = false;
  bool get isAvailable => _isAvailable;

  IAPService() {
    final purchaseUpdated = _iap.purchaseStream;
    _subscription = purchaseUpdated.listen(
      _onPurchaseUpdate,
      onDone: () => _subscription.cancel(),
      onError: (error) => debugPrint('IAP Error: $error'),
    );
  }

  Future<void> initialize() async {
    _isAvailable = await _iap.isAvailable();
    if (_isAvailable) {
      await _loadProducts();
    }
  }

  Future<void> _loadProducts() async {
    final response = await _iap.queryProductDetails(_productIds.toSet());
    if (response.error == null) {
      _products = response.productDetails;
    } else {
      debugPrint('Error loading products: ${response.error}');
    }
  }

  Future<void> buyProduct(ProductDetails product) async {
    final purchaseParam = PurchaseParam(productDetails: product);
    try {
      // Subscriptions + non-consumables use buyNonConsumable in this plugin.
      if (product.id.contains('monthly') || 
          product.id.contains('yearly') || 
          product.id.contains('gymbuddy')) {
        await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      } else {
        await _iap.buyConsumable(purchaseParam: purchaseParam);
      }
    } on PlatformException catch (e) {
      // Android commonly throws item_already_owned for already-owned purchases.
      // In that case, trigger a restore to re-attach entitlement to current Firebase uid.
      final code = e.code.toLowerCase();
      final msg = (e.message ?? '').toLowerCase();
      if (code.contains('already') || msg.contains('already') && msg.contains('own')) {
        await restorePurchases();
      }
      rethrow;
    }
  }

  Future<void> restorePurchases() async {
    await _iap.restorePurchases();
  }

  /// Android-specific: Check past purchases synchronously to detect expiration.
  Future<List<PurchaseDetails>?> getAndroidPastPurchases() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      // Accessing the Android-specific platform addition
      // Note: This requires the platform interface to match. 
      // If 'InAppPurchaseAndroidPlatformAddition' is not found, ensuring imports.
      try {
         final addition = _iap.getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
         final response = await addition.queryPastPurchases();
         return response.pastPurchases;
      } catch (e) {
        debugPrint('Error querying Android past purchases: $e');
        return null;
      }
    }
    return null;
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    debugPrint('IAPService: Received ${purchaseDetailsList.length} purchase updates.');
    for (var purchase in purchaseDetailsList) {
      debugPrint('IAPService: Processing purchase - ID: ${purchase.productID}, Status: ${purchase.status}, PendingComplete: ${purchase.pendingCompletePurchase}');
      _purchaseController.add(purchase);
      if (purchase.pendingCompletePurchase) {
        debugPrint('IAPService: Completing purchase for ID: ${purchase.productID}');
        _iap.completePurchase(purchase);
      }
    }
  }

  void dispose() {
    _subscription.cancel();
    _purchaseController.close();
  }
}
