-keep class com.write4me.llama_flutter_android.** { *; }
-keepclassmembers class com.write4me.llama_flutter_android.** { *; }
-keep class kotlin.jvm.functions.** { *; }
-keepclassmembers class * implements kotlin.jvm.functions.Function1 {
    public java.lang.Object invoke(java.lang.Object);
}
-keepclassmembers class * implements kotlin.jvm.functions.Function0 {
    public java.lang.Object invoke();
}
-keepattributes Signature,InnerClasses,EnclosingMethod
