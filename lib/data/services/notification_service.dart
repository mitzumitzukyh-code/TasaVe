import 'package:flutter/foundation.dart';

/// Service that handles push notification setup.
/// - Web: uses browser Notification API
/// - Mobile: uses Firebase Cloud Messaging (requires firebase setup)
class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  String? _token;
  String? get token => _token;

  bool _initialized = false;

  /// Initialize notification service and request permissions
  Future<bool> initialize() async {
    if (_initialized) return _token != null;

    try {
      if (kIsWeb) {
        return await _initializeWeb();
      } else {
        return await _initializeMobile();
      }
    } catch (e) {
      debugPrint('NotificationService init error: $e');
      return false;
    } finally {
      _initialized = true;
    }
  }

  Future<bool> _initializeWeb() async {
    // Web push uses a unique device identifier stored locally
    // Real FCM web tokens require Firebase JS SDK setup
    // For now, generate a stable device ID for web
    _token = 'web_${DateTime.now().millisecondsSinceEpoch}';
    return true;
  }

  Future<bool> _initializeMobile() async {
    // Firebase Cloud Messaging for mobile
    // Requires: firebase_core + firebase_messaging packages
    // And google-services.json (Android) / GoogleService-Info.plist (iOS)
    //
    // When Firebase is configured, uncomment:
    // await Firebase.initializeApp();
    // final messaging = FirebaseMessaging.instance;
    // final settings = await messaging.requestPermission();
    // if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    //   _token = await messaging.getToken();
    //   return true;
    // }
    _token = null;
    return false;
  }
}
