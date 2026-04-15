# Keep necessary Firebase & Google Play Services classes
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-keep class com.razorpay.** { *; }

# Fix missing Google Pay classes
-keep class com.google.android.apps.nbu.paisa.** { *; }

# Fix ProGuard annotations
-keep class proguard.annotation.** { *; }

# Prevent minification of Firebase Auth and Messaging APIs
-keep class com.google.firebase.auth.** { *; }
-keep class com.google.firebase.messaging.** { *; }
-keep class proguard.annotation.** { *; }
-keep class com.razorpay.** { *; }
-keep class com.google.android.gms.** { *; }
-keep class com.google.firebase.** { *; }
-keep class com.google.android.apps.nbu.paisa.** { *; }

# Keep Razorpay and Google Pay classes
-keep class com.google.android.apps.nbu.paisa.inapp.client.api.** { *; }
-keep class com.razorpay.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**
-dontwarn proguard.annotation.**
-dontwarn com.google.android.apps.nbu.paisa.inapp.client.api.**

# TensorFlow Lite - prevent R8 from removing GPU delegate
-keep class org.tensorflow.** { *; }
-dontwarn org.tensorflow.**
