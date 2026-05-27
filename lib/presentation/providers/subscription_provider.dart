import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../core/constants/subscription_constants.dart';
import '../../data/models/tasa_model.dart';
import '../../services/widget_service.dart';
import 'accessibility_provider.dart';
import 'tasa_provider.dart';

final subscriptionServiceProvider = Provider<SubscriptionService>((ref) {
  final service = SubscriptionService(ref);
  ref.onDispose(service.dispose);
  return service;
});

final subscriptionProvider =
    StateNotifierProvider<SubscriptionNotifier, SubscriptionState>((ref) {
  return SubscriptionNotifier(ref);
});

class SubscriptionState {
  final bool isLoading;
  final bool isAvailable;
  final bool isPremium;
  final String? priceLabel;
  final String? errorMessage;
  final bool purchasePending;

  const SubscriptionState({
    this.isLoading = true,
    this.isAvailable = false,
    this.isPremium = false,
    this.priceLabel,
    this.errorMessage,
    this.purchasePending = false,
  });

  SubscriptionState copyWith({
    bool? isLoading,
    bool? isAvailable,
    bool? isPremium,
    String? priceLabel,
    String? errorMessage,
    bool? purchasePending,
    bool clearError = false,
  }) {
    return SubscriptionState(
      isLoading: isLoading ?? this.isLoading,
      isAvailable: isAvailable ?? this.isAvailable,
      isPremium: isPremium ?? this.isPremium,
      priceLabel: priceLabel ?? this.priceLabel,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      purchasePending: purchasePending ?? this.purchasePending,
    );
  }
}

class SubscriptionNotifier extends StateNotifier<SubscriptionState> {
  final Ref _ref;

  SubscriptionNotifier(this._ref)
      : super(SubscriptionState(
          isPremium: _ref.read(localStorageProvider).isPremium,
        )) {
    _syncUserPlan();
  }

  void _syncUserPlan() {
    _ref.read(userPlanProvider.notifier).state =
        state.isPremium ? 'premium' : 'free';
  }

  Future<void> setPremium(bool value) async {
    await _ref.read(localStorageProvider).setUserPlan(value ? 'premium' : 'free');
    state = state.copyWith(isPremium: value, isLoading: false);
    _ref.read(userPlanProvider.notifier).state = value ? 'premium' : 'free';

    final tasa = _ref.read(tasaProvider).valueOrNull;
    if (tasa != null && value) {
      await WidgetService.updateFromTasa(tasa, isPremium: true);
    }
  }
}

class SubscriptionService {
  final Ref _ref;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;
  ProductDetails? _monthlyProduct;

  SubscriptionService(this._ref);

  SubscriptionNotifier get _notifier => _ref.read(subscriptionProvider.notifier);

  Future<void> init() async {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) {
      _notifier.state = _notifier.state.copyWith(isLoading: false);
      return;
    }

    final available = await InAppPurchase.instance.isAvailable();
    final storage = _ref.read(localStorageProvider);
    _notifier.state = _notifier.state.copyWith(
      isAvailable: available,
      isPremium: storage.isPremium,
      isLoading: true,
    );
    _ref.read(userPlanProvider.notifier).state =
        storage.isPremium ? 'premium' : 'free';

    await _purchaseSub?.cancel();
    _purchaseSub = InAppPurchase.instance.purchaseStream.listen(
      _onPurchaseUpdate,
      onError: (_) {
        _notifier.state = _notifier.state.copyWith(
          errorMessage: 'Error al procesar la compra',
          purchasePending: false,
          isLoading: false,
        );
      },
    );

    if (available) {
      await _loadProducts();
      await restorePurchases();
    } else {
      _notifier.state = _notifier.state.copyWith(
        isLoading: false,
        priceLabel: SubscriptionConstants.fallbackPriceLabel,
      );
    }
  }

  Future<void> _loadProducts() async {
    final response = await InAppPurchase.instance
        .queryProductDetails(SubscriptionConstants.productIds);

    if (response.error != null) {
      _notifier.state = _notifier.state.copyWith(
        isLoading: false,
        priceLabel: SubscriptionConstants.fallbackPriceLabel,
        errorMessage: 'No se pudo cargar el precio desde Play Store',
      );
      return;
    }

    for (final p in response.productDetails) {
      if (p.id == SubscriptionConstants.proMonthlyId) {
        _monthlyProduct = p;
        break;
      }
    }
    _monthlyProduct ??=
        response.productDetails.isNotEmpty ? response.productDetails.first : null;

    _notifier.state = _notifier.state.copyWith(
      isLoading: false,
      priceLabel: _monthlyProduct?.price ?? SubscriptionConstants.fallbackPriceLabel,
    );
  }

  Future<void> buyPro() async {
    final product = _monthlyProduct;
    if (product == null) {
      _notifier.state = _notifier.state.copyWith(
        errorMessage:
            'Suscripción no disponible. Configura la suscripción en Play Console.',
      );
      return;
    }

    _notifier.state = _notifier.state.copyWith(
      purchasePending: true,
      clearError: true,
    );

    await InAppPurchase.instance.buyNonConsumable(
      purchaseParam: PurchaseParam(productDetails: product),
    );
  }

  Future<void> restorePurchases() async {
    await InAppPurchase.instance.restorePurchases();
  }

  Future<void> refreshWidgetIfPremium(TasaModel tasa) async {
    if (!_ref.read(subscriptionProvider).isPremium) return;
    await WidgetService.updateFromTasa(tasa, isPremium: true);
  }

  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (!SubscriptionConstants.productIds.contains(purchase.productID)) continue;

      switch (purchase.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _notifier.setPremium(true);
          _notifier.state = _notifier.state.copyWith(
            purchasePending: false,
            clearError: true,
          );
        case PurchaseStatus.error:
          _notifier.state = _notifier.state.copyWith(
            purchasePending: false,
            errorMessage: 'Compra cancelada o fallida',
          );
        case PurchaseStatus.canceled:
          _notifier.state = _notifier.state.copyWith(purchasePending: false);
        case PurchaseStatus.pending:
          _notifier.state = _notifier.state.copyWith(purchasePending: true);
      }

      if (purchase.pendingCompletePurchase) {
        await InAppPurchase.instance.completePurchase(purchase);
      }
    }
  }

  void dispose() {
    _purchaseSub?.cancel();
  }
}

/// Atajo para comprobar plan Pro en pantallas.
final isPremiumProvider = Provider<bool>((ref) {
  return ref.watch(subscriptionProvider).isPremium ||
      ref.watch(userPlanProvider) == 'premium';
});
