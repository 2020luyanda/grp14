# Keep ML Kit and TensorFlow Lite
-keep class org.tensorflow.** { *; }
-keep class com.google.mlkit.** { *; }
-dontwarn org.tensorflow.**
-dontwarn com.google.mlkit.**

# Prevent class obfuscation
-keepnames class com.google.mlkit.**
-keepnames class org.tensorflow.**
