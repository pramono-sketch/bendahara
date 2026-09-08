// android/app/build.gradle.kts

plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("kotlin-android")

    // Flutter Gradle Plugin harus diterapkan setelah
    // Android dan Kotlin Gradle Plugin.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.bendahara"

    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    defaultConfig {
        applicationId = "com.example.bendahara"

        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion

        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Masih menggunakan debug signing untuk sementara.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

// 📍 Konfigurasi Kotlin
kotlin {
    compilerOptions {
        jvmTarget.set(
            org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_11
        )
    }
}

flutter {
    source = "../.."
}