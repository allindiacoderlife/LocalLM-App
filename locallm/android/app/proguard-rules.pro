# Keep llama_flutter_android JNI & Pigeon classes
-keep class com.write4me.llama_flutter_android.** { *; }
-keepclassmembers class com.write4me.llama_flutter_android.** { *; }

# Keep Kotlin Function1/Function0 invoke() called directly from C++ JNI (GetMethodID)
-keep class kotlin.jvm.functions.** { *; }
-keepclassmembers class * implements kotlin.jvm.functions.Function1 {
    public java.lang.Object invoke(java.lang.Object);
}
-keepclassmembers class * implements kotlin.jvm.functions.Function0 {
    public java.lang.Object invoke();
}

# Preserve generic signatures and annotations for Pigeon / Flutter / JNI
-keepattributes Signature,InnerClasses,EnclosingMethod,*Annotation*
-keep class com.allindiacoderlife.locallm.** { *; }

# Suppress warnings for optional Play Core deferred components in Flutter engine
-dontwarn com.google.android.play.core.**
