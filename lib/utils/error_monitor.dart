import 'dart:collection';
import 'package:flutter/foundation.dart';

class ErrorEntry {
  final String message;
  final String? stackTrace;
  final DateTime timestamp;

  const ErrorEntry({
    required this.message,
    this.stackTrace,
    required this.timestamp,
  });

  @override
  String toString() => '[$timestamp] $message';
}

/// Singleton de monitoreo de errores en la app.
/// Captura errores de Flutter, Dart zones, y logs manuales.
/// Máximo 100 entradas en memoria (ring buffer).
class ErrorMonitor {
  ErrorMonitor._();
  static final instance = ErrorMonitor._();

  static const _maxEntries = 100;
  final _entries = Queue<ErrorEntry>();

  UnmodifiableListView<ErrorEntry> get entries =>
      UnmodifiableListView(_entries.toList().reversed);

  int get count => _entries.length;

  void log(String message, [String? stackTrace]) {
    _entries.addLast(ErrorEntry(
      message: message,
      stackTrace: stackTrace,
      timestamp: DateTime.now(),
    ));
    if (_entries.length > _maxEntries) _entries.removeFirst();
    debugPrint('[ERROR_MONITOR] $message');
  }

  void clear() => _entries.clear();

  /// Instala los handlers globales. Llamar una vez en main().
  static void install() {
    final monitor = ErrorMonitor.instance;

    // Flutter framework errors
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      monitor.log(
        'FlutterError: ${details.exceptionAsString()}',
        details.stack?.toString(),
      );
      originalOnError?.call(details);
    };

    // Dart async errors not caught by Flutter
    PlatformDispatcher.instance.onError = (error, stack) {
      monitor.log(
        'UncaughtError: $error',
        stack.toString(),
      );
      return true; // handled
    };
  }
}
