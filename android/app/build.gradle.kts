plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
}

android {
    namespace = "com.hgengine.android"
    compileSdk = 35
    ndkVersion = "27.2.12479018"

    defaultConfig {
        applicationId = "com.hgengine.android"
        minSdk = 26
        targetSdk = 35
        versionCode = 1
        versionName = "0.1.0"

        ndk {
            // arm64 for phones (with the melonDS JIT), x86_64 for the emulator / Chromebooks.
            abiFilters += listOf("arm64-v8a", "x86_64")
        }
        externalNativeBuild {
            cmake {
                arguments += listOf("-DANDROID_STL=c++_static")
                // Use a local melonDS checkout instead of downloading: -PmelonDSDir=/path/to/melonDS
                (project.findProperty("melonDSDir") as String?)?.let {
                    arguments += "-DFETCHCONTENT_SOURCE_DIR_MELONDS=$it"
                }
            }
        }
    }

    externalNativeBuild {
        cmake {
            path = file("src/main/cpp/CMakeLists.txt")
            version = "3.22.1"
        }
    }

    signingConfigs {
        // Release builds are signed with the debug key unless a keystore is provided via
        // HGE_KEYSTORE / HGE_KEYSTORE_PASSWORD / HGE_KEY_ALIAS / HGE_KEY_PASSWORD.
        System.getenv("HGE_KEYSTORE")?.let { store ->
            create("release") {
                storeFile = file(store)
                storePassword = System.getenv("HGE_KEYSTORE_PASSWORD")
                keyAlias = System.getenv("HGE_KEY_ALIAS")
                keyPassword = System.getenv("HGE_KEY_PASSWORD")
            }
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            signingConfig = signingConfigs.findByName("release") ?: signingConfigs.getByName("debug")
        }
        debug {
            // The emulator core is unplayably slow without optimisation.
            externalNativeBuild { cmake { arguments += "-DCMAKE_BUILD_TYPE=Release" } }
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = "17"
    }

    androidResources {
        // The BPS patch is already dense; don't waste time compressing it.
        noCompress += "bps"
    }
}
