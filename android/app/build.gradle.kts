plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Import Java classes for signing configuration
import java.util.Properties
import java.io.FileInputStream

android {
    namespace = "dk.cykel.cykel"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlin {
        compilerOptions {
            jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
        }
    }

    // ─── Signing Configuration ────────────────────────────────────────────────
    // To generate release keystore:
    // keytool -genkey -v -keystore ~/release.keystore -alias cykel -keyalg RSA -keysize 2048 -validity 10000
    // 
    // Then create android/key.properties with:
    // storePassword=<password>
    // keyPassword=<password>
    // keyAlias=cykel
    // storeFile=/path/to/release.keystore
    
    signingConfigs {
        create("release") {
            val keystorePropertiesFile = rootProject.file("key.properties")
            if (keystorePropertiesFile.exists()) {
                val keystoreProperties = Properties()
                FileInputStream(keystorePropertiesFile).use { stream ->
                    keystoreProperties.load(stream)
                }
                
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            } else {
                // Fallback to debug signing if key.properties not found
                println("⚠️  WARNING: key.properties not found. Using debug signing for release.")
                println("    Generate release keystore and create key.properties for production builds.")
            }
        }
    }

    defaultConfig {
        applicationId = "dk.cykel.cykel"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        debug {
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false
            isShrinkResources = false
        }
        
        release {
            // Use release signing if key.properties exists, otherwise debug
            val keystorePropertiesFile = rootProject.file("key.properties")
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                println("⚠️  Using debug signing for release build")
                signingConfigs.getByName("debug")
            }
            
            // Enable code shrinking, obfuscation, and optimization
            isMinifyEnabled = true
            isShrinkResources = true
            
            // ProGuard/R8 configuration
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            
            // Keep crash report line numbers readable
            ndk {
                debugSymbolLevel = "FULL"
            }
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}

flutter {
    source = "../.."
}

// Suppress obsolete Java version warnings from dependencies
tasks.withType<JavaCompile> {
    options.compilerArgs.add("-Xlint:-options")
}
