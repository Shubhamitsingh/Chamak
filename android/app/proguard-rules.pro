# ProGuard rules for Android release builds

# ✅ CRITICAL FIX: Keep Flutter native libraries and JNI classes
# This prevents libflutter.so from being stripped or causing issues
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.embedding.engine.** { *; }
-keep class io.flutter.embedding.engine.loader.** { *; }

# Keep Flutter JNI classes
-keep class io.flutter.embedding.engine.FlutterJNI { *; }
-keep class io.flutter.embedding.engine.loader.FlutterLoader { *; }
-keep class io.flutter.embedding.engine.FlutterEngineGroup { *; }

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep serialization classes
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# ✅ FIX: Keep Google Play Core classes (required for Flutter deferred components)
# These classes are referenced by Flutter but may not be directly used
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**
-keep class com.google.android.play.core.** { *; }

# ✅ FIX: Keep Google Play Services annotation classes
-dontwarn com.google.android.gms.common.annotation.NoNullnessRewrite
-keep class com.google.android.gms.common.annotation.** { *; }
