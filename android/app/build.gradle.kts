// Add this plugin with others
plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin is applied here.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.zaza_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.zaza_app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // ADD THESE FIREBASE DEPENDENCIES
    implementation(platform("com.google.firebase:firebase-bom:33.0.0"))
    implementation("com.google.firebase:firebase-auth")
    implementation("com.google.firebase:firebase-analytics")
    
    // Keep any existing dependencies here
}

// ADD THIS LINE AT THE VERY BOTTOM
apply(plugin = "com.google.gms.google-services")