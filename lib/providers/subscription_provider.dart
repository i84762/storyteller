import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../services/iap_service.dart';
import '../services/usage_tracker.dart';
import '../utils/constants.dart';

class SubscriptionProvider extends ChangeNotifier {
  final IAPService _iapService = IAPService();
  final UsageTracker _usageTracker = UsageTracker();

  bool _isPremium = false;
  bool _isByokActive = false;
  bool _isOnDeviceUnlocked = false;
  bool _isLoading = false;
  String? _error;

  bool get isPremium => _isPremium;
  bool get isByokActive => _isByokActive;
  bool get isOnDeviceUnlocked => _isOnDeviceUnlocked;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<ProductDetails> get products => _iapService.products;

  Future<void> init() async {
    await _iapService.init();
    _iapService.onPurchaseSuccess = _handlePurchaseSuccess;
    _iapService.onPurchaseError = (msg) {
      _error = msg;
      notifyListeners();
    };
  }

  void _handlePurchaseSuccess(PurchaseDetails purchase) async {
    switch (purchase.productID) {
      case AppConstants.iapMonthlySubId:
        _isPremium = true;
        await _usageTracker.addPurchasedTokens(5000);
        break;
      case AppConstants.iapTokenPack500Id:
        await _usageTracker.addPurchasedTokens(500);
        break;
      case AppConstants.iapTokenPack2000Id:
        await _usageTracker.addPurchasedTokens(2000);
        break;
      case AppConstants.iapByokPlatformFeeId:
        _isByokActive = true;
        break;
      case AppConstants.iapOnDeviceProId:
        _isOnDeviceUnlocked = true;
        break;
    }
    notifyListeners();
  }

  Future<void> purchaseProduct(String productId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _iapService.buyProduct(productId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> restorePurchases() async {
    _isLoading = true;
    notifyListeners();
    await _iapService.restorePurchases();
    _isLoading = false;
    notifyListeners();
  }
}
