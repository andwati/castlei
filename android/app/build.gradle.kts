import java.util.Properties

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
    id("com.google.firebase.firebase-perf")
    // END: FlutterFire Configuration
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keyProps = Properties().apply {
    val f = rootProject.file("key.properties")
    if (f.exists()) f.inputStream().use { load(it) }
}

android {
    // Libraries ship 32-bit helper libs, but the app itself has no 32-bit build.
    packaging { jniLibs { excludes += "**/armeabi-v7a/**" } }
    namespace = "com.andwati.castlei"
    compileSdk = 37
    ndkVersion = "28.2.13676358"

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.andwati.castlei"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 29
        // 64-bit only: Flutter's engine and app code are built for arm64 and x86_64, so
        // 32-bit-only phones must not be offered the app (they would crash on launch).
        ndk { abiFilters += listOf("arm64-v8a", "x86_64") }
        externalNativeBuild { cmake { cppFlags += "-std=c++17"; arguments += "-DANDROID_SUPPORT_FLEXIBLE_PAGE_SIZES=ON"; if (System.getenv("CASTLEI_CCACHE") != null) arguments += listOf("-DCMAKE_C_COMPILER_LAUNCHER=ccache", "-DCMAKE_CXX_COMPILER_LAUNCHER=ccache") } }
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    externalNativeBuild { cmake { path = file("../../native/CMakeLists.txt"); version = "3.22.1" } }

    signingConfigs {
        if (keyProps.getProperty("storeFile") != null) {
            create("release") {
                storeFile = rootProject.file(keyProps.getProperty("storeFile"))
                storePassword = keyProps.getProperty("storePassword")
                keyAlias = keyProps.getProperty("keyAlias")
                keyPassword = keyProps.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            // Release key when android/key.properties exists (gitignored), debug key otherwise (CI without secrets).
            signingConfig = signingConfigs.findByName("release") ?: signingConfigs.getByName("debug")
            // Native (Stockfish adapter) crash symbolication. Off by default because
            // the unstripped libraries are large; enable for real releases with
            //   ORG_GRADLE_PROJECT_uploadNativeSymbols=true flutter build apk --release
            if (project.hasProperty("uploadNativeSymbols")) {
                extensions.configure<com.google.firebase.crashlytics.buildtools.gradle.CrashlyticsExtension>("firebaseCrashlytics") {
                    nativeSymbolUploadEnabled = true
                }
            }
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

dependencies {
    // Same BoM as firebase_core (FirebaseSDKVersion); the in-app messaging plugin exposes
    // Firebase libraries to the app without a version, so supply it here.
    implementation(platform("com.google.firebase:firebase-bom:35.1.0"))
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}
