## Play Core (Flutter deferred components)
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**

## Google ML Kit — keep classes needed by text recognition
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_text_recognition.** { *; }
-dontwarn com.google.mlkit.**

## Google Mobile Ads
-keep class com.google.android.gms.ads.** { *; }

## Google Play Billing / in_app_purchase
-keep class com.android.vending.billing.** { *; }
-keep class com.android.billingclient.api.** { *; }

## Home Widget
-keep class es.antonborri.home_widget.** { *; }

## Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

## Camera
-keep class io.flutter.plugins.camera.** { *; }
