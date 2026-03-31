# WoofTalk ProGuard Rules

# Keep model classes
-keep class com.wooftalk.data.remote.model.** { *; }
-keep class com.wooftalk.data.local.entity.** { *; }
-keep class com.wooftalk.domain.model.** { *; }

# Keep Room
-keep class * extends androidx.room.RoomDatabase
-keep @androidx.room.Entity class *
-dontwarn androidx.room.paging.**

# Keep Supabase
-keep class io.github.jan_tennert.supabase.** { *; }
-keep class io.ktor.** { *; }

# Keep Kotlin Coroutines
-keepnames class kotlinx.coroutines.internal.MainDispatcherFactory {}
-keepnames class kotlinx.coroutines.CoroutineExceptionHandler {}

# Keep Gson
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# Keep Speech Recognition
-keep class android.speech.** { *; }
-keep class android.speech.tts.** { *; }

# Keep Glance widgets
-keep class com.wooftalk.ui.widget.** { *; }

# Remove logging in release
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
}
