# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Google Play Core (Flutter deferred components — kullanılmasa bile referans var)
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# Socket.IO — reflection kullaniyor
-keep class io.socket.** { *; }
-keep class com.neovisionaries.** { *; }
-keep class okhttp3.** { *; }
-keep class okio.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Gson / JSON
-keep class com.google.gson.** { *; }
-keepattributes Signature
-keepattributes *Annotation*

# Kotlin coroutines
-keep class kotlinx.coroutines.** { *; }

# image_picker / file_picker
-keep class androidx.** { *; }

# Genel — reflection ile erisilen siniflar
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}
