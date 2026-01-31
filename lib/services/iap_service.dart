import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class IAPService {
  final InAppPurchase _iap = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;
  
  final _purchaseController = StreamController<PurchaseDetails>.broadcast();
  Stream<PurchaseDetails> get purchaseStream => _purchaseController.stream;

  final List<String> _productIds = ['premium_monthly', 'premium_yearly'];
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
    if (product.id.contains('monthly') || product.id.contains('yearly')) {
      await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    } else {
      await _iap.buyConsumable(purchaseParam: purchaseParam);
    }
  }

  Future<void> restorePurchases() async {
    await _iap.restorePurchases();
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
