import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.emergency_resource_dispatch_system"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlin {
        compilerOptions {
            jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_11)
        }
    }

    buildFeatures {
        buildConfig = true
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.emergency_resource_dispatch_system"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = Math.max(flutter.minSdkVersion, 21)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // Google Maps API Key from local.properties
        var mapsApiKey = ""
        val localPropertiesFile = file("local.properties")
        if (localPropertiesFile.exists()) {
            val localProperties = Properties()
            localPropertiesFile.inputStream().use { localProperties.load(it) }
            mapsApiKey = localProperties.getProperty("GOOGLE_MAPS_API_KEY") ?: ""
            
            // Validate API key only if property explicitly exists but is empty
            // Empty key (not set) allows build but Maps won't work
            if (localProperties.containsKey("GOOGLE_MAPS_API_KEY") && mapsApiKey.isEmpty()) {
                throw GradleException("GOOGLE_MAPS_API_KEY is empty! Add a valid key to local.properties or remove the property")
            }
        }
        buildConfigField("String", "GOOGLE_MAPS_API_KEY", "\"$mapsApiKey\"")
        manifestPlaceholders["GOOGLE_MAPS_API_KEY"] = mapsApiKey
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
