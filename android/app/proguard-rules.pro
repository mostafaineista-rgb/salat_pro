# Gson (used by flutter_local_notifications for scheduled notification cache).
# Without these, R8 can strip type metadata and Gson throws "Missing type parameter" in release.
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses

-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken

-keep class com.dexterous.flutterlocalnotifications.** { *; }
