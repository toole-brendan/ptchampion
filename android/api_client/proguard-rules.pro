# Proguard rules for the api_client JVM library module.
# These rules might be applied by the app module's R8 process.

# Prevent R8 warnings about java.lang.invoke used by newer JDKs for string concatenation
-dontwarn java.lang.invoke.**
# Keep the StringConcatFactory if code relies on it (safer for newer JDKs)
-keep class java.lang.invoke.StringConcatFactory { *; }
-keep class java.lang.invoke.MethodHandles$Lookup { *; }

# Keep the generated model classes (adjust package if generator output changes)
-keep class org.openapitools.client.models.** { *; }

# Keep the generated API interfaces and their methods used by Retrofit
-keep interface org.openapitools.client.apis.** { *; }
-keep interface * { @retrofit2.http.* <methods>; }

# Keep classes used for serialization (Moshi/Kotlinx Serialization) if needed
-keep @com.squareup.moshi.JsonQualifier @interface *
-keepclasseswithmembers class * { @com.squareup.moshi.FromJson *; }
-keepclasseswithmembers class * { @com.squareup.moshi.ToJson *; }
-keep class **JsonAdapter { *; } # Keep Moshi generated adapters

-keep class kotlinx.serialization.** { *; }
-keepclassmembers class ** { @kotlinx.serialization.Serializable *; }
-keepclassmembers class * { @kotlinx.serialization.* *; }

# Keep Retrofit/OkHttp classes used by the generated code
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn retrofit2.**
-keep class retrofit2.Callback
-keep class * implements retrofit2.Callback { *; }

# Keep Coroutine related classes if suspend functions are used in the API
-keepnames class kotlinx.coroutines.internal.MainDispatcherFactory {}
-keepnames class kotlinx.coroutines.CoroutineExceptionHandler {}
-keepnames class kotlinx.coroutines.flow.** { *; }

# Add other -keep rules if your generated code uses reflection or specific features
# that might be removed by R8 in the app module. 