# Google Play Core & Deferred Components (Suppress warnings for optional dynamic split components)
-dontwarn com.google.android.play.core.**
-dontwarn io.flutter.embedding.engine.deferredcomponents.**

# Flutter Wrapper Rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# SQLite (sqflite)
-keep class com.tekartik.sqflite.** { *; }

# Biometric & Local Auth
-keep class io.flutter.plugins.localauth.** { *; }
-keep class androidx.biometric.** { *; }

# Flutter Secure Storage (Android KeyStore)
-keep class com.it_nomads.fluttersecurestorage.** { *; }
