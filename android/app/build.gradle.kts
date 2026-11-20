import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // Flutter Gradle plugin harus setelah plugin Android/Kotlin.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties().apply {
    val file = rootProject.file("key.properties")
    if (file.exists()) FileInputStream(file).use { load(it) }
}

// Signing: key.properties untuk lokal, environment variable untuk CI.
val envStoreFile = System.getenv("KEYSTORE_FILE") ?: keystoreProperties.getProperty("storeFile")
val envStorePassword = System.getenv("KEYSTORE_PASSWORD") ?: keystoreProperties.getProperty("storePassword")
val envKeyAlias = System.getenv("KEY_ALIAS") ?: keystoreProperties.getProperty("keyAlias")
val envKeyPassword = System.getenv("KEY_PASSWORD") ?: keystoreProperties.getProperty("keyPassword")

// Google Sign-In serverClientId (fallback native bila --dart-define tidak dipakai).
val googleServerClientId = System.getenv("GOOGLE_SERVER_CLIENT_ID")
    ?: "YOUR_SERVER_CLIENT_ID.apps.googleusercontent.com"

android {
    namespace = "com.yusup28.note_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    buildFeatures {
        buildConfig = true
    }

    defaultConfig {
        applicationId = "com.yusup28.note_app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true

        buildConfigField(
            "String",
            "GOOGLE_SERVER_CLIENT_ID",
            "\"${googleServerClientId}\"",
        )
    }

    signingConfigs {
        create("release") {
            val storePath = envStoreFile
            if (!storePath.isNullOrEmpty()) {
                val store = file(storePath)
                if (store.exists()) {
                    storeFile = store
                    storePassword = envStorePassword
                    keyAlias = envKeyAlias
                    keyPassword = envKeyPassword
                }
            }
        }
    }

    buildTypes {
        getByName("release") {
            val releaseConfig = signingConfigs.findByName("release")
            if (releaseConfig?.storeFile != null) {
                signingConfig = releaseConfig
            } else {
                signingConfig = signingConfigs.getByName("debug")
                println("[!] Release keystore tidak ditemukan — pakai DEBUG key")
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

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}

flutter {
    source = "../.."
}
