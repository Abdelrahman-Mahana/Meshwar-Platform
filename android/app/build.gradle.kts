import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    FileInputStream(keystorePropertiesFile).use { keystoreProperties.load(it) }
}

fun resolveKeystoreFile(rawPath: String): File {
    val candidate = File(rawPath)
    if (candidate.isAbsolute) return candidate
    val fromRoot = rootProject.file(rawPath)
    if (fromRoot.exists()) return fromRoot
    return file(rawPath)
}

val configuredStoreFilePath = keystoreProperties.getProperty("storeFile")?.trim()
val hasReleaseSigningConfig = keystorePropertiesFile.exists() &&
    !configuredStoreFilePath.isNullOrEmpty() &&
    resolveKeystoreFile(configuredStoreFilePath).exists()

android {
    namespace = "com.mashwar.app.mashwar"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.mashwar.app.mashwar"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs.create("release") {
        if (keystorePropertiesFile.exists()) {
            keyAlias = keystoreProperties.getProperty("keyAlias")
            keyPassword = keystoreProperties.getProperty("keyPassword")
            storeFile = configuredStoreFilePath
                ?.takeIf { it.isNotEmpty() }
                ?.let { resolveKeystoreFile(it) }
            storePassword = keystoreProperties.getProperty("storePassword")
        }
    }

    buildTypes {
        release {
            // Uses android/key.properties when present; falls back to debug signing ONLY for local dev builds.
            signingConfig = if (hasReleaseSigningConfig) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

if (file("google-services.json").exists()) {
    apply(plugin = "com.google.gms.google-services")
}
