## Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

## Android Alarm Manager Plus
-keep public class dev.fluttercommunity.plus.androidalarmmanager.AlarmService { *; }
-keep public class dev.fluttercommunity.plus.androidalarmmanager.AlarmBroadcastReceiver { *; }
-keep public class dev.fluttercommunity.plus.androidalarmmanager.RebootBroadcastReceiver { *; }

## Flutter Local Notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep class com.dexterous.flutterlocalnotifications.models.** { *; }

## AndroidX / Support Library
-keep class androidx.core.app.NotificationCompat** { *; }
-keep class android.support.v4.app.NotificationCompat** { *; }

## Keep the entry point for the alarm callback
-keep class com.smartnaamjap.smrt_counter.MainActivity { *; }

## Ignore missing Play Store classes (used by Flutter for deferred components which we don't use)
-dontwarn io.flutter.embedding.engine.deferredcomponents.**
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**
