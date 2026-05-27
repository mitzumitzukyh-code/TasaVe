import 'dart:js_interop';

@JS('window.tasavePush.subscribe')
external JSPromise<JSString?> _jsSubscribe();

@JS('window.tasavePush.unsubscribe')
external JSPromise<JSString?> _jsUnsubscribe();

@JS('window.tasavePush.isSubscribed')
external JSPromise<JSBoolean> _jsIsSubscribed();

Future<String?> subscribeToPush() async {
  try {
    final result = await _jsSubscribe().toDart;
    return result?.toDart;
  } catch (e) {
    return null;
  }
}

Future<String?> unsubscribeFromPush() async {
  try {
    final result = await _jsUnsubscribe().toDart;
    return result?.toDart;
  } catch (e) {
    return null;
  }
}

Future<bool> isPushSubscribed() async {
  try {
    final result = await _jsIsSubscribed().toDart;
    return result.toDart;
  } catch (e) {
    return false;
  }
}
