# MASHWAR Qatar — Android R8 / ProGuard Rules
# Preserves Flutter engine bridges, Firebase SDK reflection models, and Crash/stacktrace line numbers.

# Keep source file names and line numbers for readable stack traces
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile
-keepattributes Signature,InnerClasses,EnclosingMethod,RuntimeVisibleAnnotations

# Flutter Wrapper & Engine Bridges
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Firebase & Google Play Services (Core, Auth, Firestore, Storage)
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-keepnames class com.google.firebase.** { *; }
-dontwarn com.google.appengine.**
-dontwarn com.google.apphosting.**
-dontwarn io.grpc.**
-dontwarn okio.**
