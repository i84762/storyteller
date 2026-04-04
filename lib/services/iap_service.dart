import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../utils/constants.dart';

class IAPService {
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  List<ProductDetails> _products = [];
  List<ProductDetails> get products => _products;

  Function(PurchaseDetails)? onPurchaseSuccess;
  Function(String)? onPurchaseError;

  Future<bool> init() async {
    final available = await _iap.isAvailable();
    if (!available) return false;

    final productIds = {
      AppConstants.iapMonthlySubId,
      AppConstants.iapTokenPack500Id,
      AppConstants.iapTokenPack2000Id,
      AppConstants.iapByokPlatformFeeId,
      AppConstants.iapOnDeviceProId,
    };

    final response = await _iap.queryProductDetails(productIds);
    _products = response.productDetails;

    _subscription = _iap.purchaseStream.listen(_handlePurchases);
    return true;
  }

  void _handlePurchases(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        _iap.completePurchase(purchase);
        onPurchaseSuccess?.call(purchase);
      } else if (purchase.status == PurchaseStatus.error) {
        onPurchaseError?.call(purchase.error?.message ?? 'Unknown error');
      }
    }
  }

  Future<void> buyProduct(String productId) async {
    final product = _products.firstWhere(
      (p) => p.id == productId,
      orElse: () => throw Exception('Product $productId not found'),
    );
    final param = PurchaseParam(productDetails: product);
    await _iap.buyNonConsumable(purchaseParam: param);
  }

  Future<void> restorePurchases() async {
    await _iap.restorePurchases();
  }

  void dispose() {
    _subscription?.cancel();
  }
}
