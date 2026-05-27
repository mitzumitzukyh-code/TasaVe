/// IDs de productos en Google Play Console (Suscripciones).
class SubscriptionConstants {
  SubscriptionConstants._();

  /// Crear en Play Console → Monetización → Suscripciones
  static const String proMonthlyId = 'calculaya_pro_monthly';

  static const Set<String> productIds = {proMonthlyId};

  static const String privacyPolicyUrl =
      'https://tasave-app.pages.dev/privacy.html';

  static const String fallbackPriceLabel = r'$1.99 / mes';

  static const int freeScannerDailyLimit = 5;
  static const int freeProfileLimit = 1;
  static const int freeHistoryMaxDays = 30;
}
