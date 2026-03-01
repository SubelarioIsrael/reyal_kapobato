import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    try {
        // Try the normal loader first (will throw IllegalArgumentException on malformed \uxxxx)
        keystoreProperties.load(FileInputStream(keystorePropertiesFile))
    } catch (e: IllegalArgumentException) {
        // Fallback: parse file manually to avoid Java properties' \uXXXX processing (preserve backslashes)
        keystoreProperties.clear()
        keystorePropertiesFile.readText(Charsets.UTF_8).lines().forEach { line ->
            val trimmed = line.trim()
            if (trimmed.isEmpty() || trimmed.startsWith("#") || trimmed.startsWith("!")) return@forEach
            val delimIndex = listOf('=', ':')
                .map { trimmed.indexOf(it) }
                .filter { it >= 0 }
                .minOrNull() ?: -1
            if (delimIndex <= 0) return@forEach
            val key = trimmed.substring(0, delimIndex).trim()
            var value = trimmed.substring(delimIndex + 1).trim()
            // Remove surrounding quotes if present
            if ((value.startsWith("\"") && value.endsWith("\"")) || (value.startsWith("'") && value.endsWith("'"))) {
                value = value.substring(1, value.length - 1)
            }
            keystoreProperties.setProperty(key, value)
        }
    }
}

// Add: determine whether the referenced keystore file actually exists
val releaseKeystoreExists: Boolean = run {
    val storeFileProp = keystoreProperties["storeFile"]?.toString()
    if (storeFileProp.isNullOrBlank()) {
        false
    } else {
        // resolve relative path against project root (same resolution used later by file())
        rootProject.file(storeFileProp).exists()
    }
}

android {
    namespace = "com.example.breathe_better"
    compileSdk = 36
    ndkVersion = "28.2.13676358"

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        // Match the package name used in your Firebase google-services.json
        applicationId = "com.example.breathe_better"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }
    signingConfigs {
        // Only create the release signing config when we actually have a keystore file
        if (releaseKeystoreExists) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = keystoreProperties["storeFile"]?.let { file(it) }
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }
    buildTypes {
        release {
            isShrinkResources = false
            isMinifyEnabled = false
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            proguardFiles( 
                getDefaultProguardFile("proguard-android.txt"),
                "proguard-rules.pro"
            )
            // If a real release keystore exists, use it; otherwise fall back to debug signing to allow build
            if (releaseKeystoreExists && signingConfigs.findByName("release") != null) {
                signingConfig = signingConfigs.getByName("release")
            } else {
                signingConfig = signingConfigs.getByName("debug")
            }
        }
    }
}

dependencies {
    // For AGP 7.4+
    coreLibraryDesugaring ("com.android.tools:desugar_jdk_libs:2.1.5")
    // For AGP 7.3
    // coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:1.2.3'
    // For AGP 4.0 to 7.2
    // coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:1.1.9'
}

flutter {
    source = "../.."
}

