plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("kotlin-kapt")
    kotlin("plugin.serialization")
    id("dagger.hilt.android.plugin")
}

import org.jetbrains.kotlin.gradle.tasks.KotlinCompile

// Exclude generated tests from Kotlin compilation
tasks.withType<KotlinCompile>().configureEach {
    exclude("**/generatedapi/src/test/**")
}

// Enable Kapt configuration
kapt {
    correctErrorTypes = true
    includeCompileClasspath = false
    javacOptions {
        option("-J-Xmx2g")
    }
}

// Add the configurations block here
configurations.all {
    resolutionStrategy {
        force("com.google.guava:guava:32.1.3-android")
        // Force consistent Moshi versions to avoid conflicts with generatedapi
        force("com.squareup.moshi:moshi:1.15.0") 
        force("com.squareup.moshi:moshi-kotlin:1.15.0")
        force("com.squareup.moshi:moshi-adapters:1.15.0")
        // Force consistent Retrofit versions
        force("com.squareup.retrofit2:retrofit:2.9.0")
        force("com.squareup.retrofit2:converter-moshi:2.9.0")
        force("com.squareup.retrofit2:converter-scalars:2.9.0")
        // Force consistent OkHttp versions
        force("com.squareup.okhttp3:logging-interceptor:5.0.0-alpha.11")
        force("com.squareup.okhttp3:okhttp:5.0.0-alpha.11")
    }
}

android {
    namespace = "com.example.ptchampion"
    compileSdk = 34

    sourceSets {
        getByName("main") {
            java.srcDirs("src/main/java")
            kotlin {
                // Explicitly set the standard Kotlin source directory
                srcDirs("src/main/kotlin")
                // Don't include generatedapi sources directly anymore, we have a module dependency
            }
        }
        // Explicitly set test source dirs, excluding generated tests
        getByName("test") {
            kotlin.setSrcDirs(listOf("src/test/kotlin")) // Only include standard test dir
            resources.setSrcDirs(listOf("src/test/resources")) // Include resources if needed
        }
        // Explicitly set androidTest source dirs, excluding generated tests
        getByName("androidTest") {
            kotlin.setSrcDirs(listOf("src/androidTest/kotlin")) // Only include standard androidTest dir
            resources.setSrcDirs(listOf("src/androidTest/resources")) // Include resources if needed
        }
    }

    defaultConfig {
        applicationId = "com.example.ptchampion"
        minSdk = 26
        targetSdk = 34
        versionCode = 1
        versionName = "1.0"
        
        // Enable multidex support
        multiDexEnabled = true

        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
        vectorDrawables {
            useSupportLibrary = true
        }
    }
    
    // App signing configuration for release builds
    signingConfigs {
        create("release") {
            // These values should be provided by environment variables or CI/CD secrets
            // For local development, you can use placeholder values
            storeFile = file(System.getenv("KEYSTORE_FILE") ?: "${rootProject.projectDir}/keystore/ptchampion.keystore")
            storePassword = System.getenv("KEYSTORE_PASSWORD") ?: "placeholder_pwd"
            keyAlias = System.getenv("KEY_ALIAS") ?: "ptchampion"
            keyPassword = System.getenv("KEY_PASSWORD") ?: "placeholder_pwd"
            // Enable v1 and v2 signing
            enableV1Signing = true
            enableV2Signing = true
        }
    }

    buildTypes {
        release {
            // Enable minification
            isMinifyEnabled = true
            // Enable resource shrinking
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            // Apply release signing config
            signingConfig = signingConfigs.getByName("release")
            buildConfigField("String", "BASE_URL", "\"https://your-production-api.com/api/v1/\"")
        }
        debug {
            buildConfigField("String", "BASE_URL", "\"http://10.0.2.2:8080/api/v1/\"")
        }
    }
    compileOptions {
        // Remove source/targetCompatibility when using toolchain
        // sourceCompatibility = JavaVersion.VERSION_1_8 
        // targetCompatibility = JavaVersion.VERSION_1_8
    }
    // Rely on Java toolchain for Kotlin JVM target
    kotlinOptions {
        // Keep other options like freeCompilerArgs if needed
        freeCompilerArgs += listOf(
            "-Xsuppress-version-warnings",
        )
    }
    // Add Java toolchain configuration
    java {
        toolchain {
            languageVersion.set(JavaLanguageVersion.of(17))
        }
    }
    // Explicitly set Kotlin toolchain as well for Kapt
    kotlin {
        jvmToolchain(17)
    }
    buildFeatures {
        compose = true
        // Enable BuildConfig generation
        buildConfig = true 
    }
    composeOptions {
        kotlinCompilerExtensionVersion = "1.5.8"
    }
    // Add Kotlin compiler options to suppress version check
    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
        kotlinOptions {
            freeCompilerArgs += listOf(
                "-Xsuppress-version-warnings",
                "-P",
                "plugin:androidx.compose.compiler.plugins.kotlin:suppressKotlinVersionCompatibilityCheck=true"
            )
        }
    }
    packaging {
        resources {
            excludes.add("/META-INF/{AL2.0,LGPL2.1}")
            // Add exclusions for conflicting files from dependencies
            excludes.add("META-INF/LICENSE.md")
            excludes.add("META-INF/LICENSE-notice.md")
        }
    }
    // Add lint configuration to disable aborting on errors temporarily
    lint {
        abortOnError = false
    }
    
    // Add explicit TensorFlow Lite related config
    packaging {
        resources {
            excludes += setOf("/META-INF/{AL2.0,LGPL2.1}")
            
            // Handle TensorFlow Lite conflicts
            jniLibs.pickFirsts.add("**/libtensorflowlite_gpu_jni.so")
            jniLibs.pickFirsts.add("**/libtensorflowlite.so")
        }
    }
}

dependencies {
    // Core Android
    implementation("androidx.core:core-ktx:1.12.0")
    implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.7.0")
    implementation("androidx.lifecycle:lifecycle-runtime-compose:2.7.0")
    implementation("androidx.activity:activity-compose:1.8.2")
    implementation("com.google.guava:guava:32.1.3-android")
    
    // Add the api_client module dependency
    implementation(project(":api_client"))
    
    // Multidex support
    implementation("androidx.multidex:multidex:2.0.1")
    
    // Paging
    implementation("androidx.paging:paging-runtime-ktx:3.2.1")
    implementation("androidx.paging:paging-compose:3.2.1")
    
    // Compose
    implementation(platform("androidx.compose:compose-bom:2023.08.00"))
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.ui:ui-graphics")
    implementation("androidx.compose.ui:ui-tooling-preview")
    implementation("androidx.compose.material3:material3")
    implementation("androidx.compose.material:material-icons-extended")
    implementation("androidx.navigation:navigation-compose:2.7.5")
    
    // Dependency Injection - Re-enable
    implementation("com.google.dagger:hilt-android:2.48.1")
    implementation("androidx.hilt:hilt-navigation-compose:1.0.0")
    kapt("com.google.dagger:hilt-compiler:2.48.1") // Re-enable Hilt compiler
    
    // Network
    implementation("com.squareup.retrofit2:retrofit:2.9.0")
    implementation("com.squareup.retrofit2:converter-gson:2.9.0")
    // Add missing converters used by generated code
    implementation("com.squareup.retrofit2:converter-scalars:2.9.0")
    implementation("com.squareup.retrofit2:converter-moshi:2.9.0")
    implementation("com.squareup.okhttp3:logging-interceptor:5.0.0-alpha.11")
    implementation("org.jetbrains.kotlinx:kotlinx-serialization-json:1.6.0")
    implementation("com.jakewharton.retrofit:retrofit2-kotlinx-serialization-converter:1.0.0")
    
    // Moshi for generated code serialization (based on errors)
    implementation("com.squareup.moshi:moshi-kotlin:1.15.0")
    kapt("com.squareup.moshi:moshi-kotlin-codegen:1.15.0") // Re-enable Moshi codegen
    
    // Datastore
    implementation("androidx.datastore:datastore-preferences:1.0.0")
    
    // Security - For EncryptedSharedPreferences
    implementation("androidx.security:security-crypto:1.1.0-alpha06") // Or use latest stable
    
    // CameraX dependencies - use stable versions
    implementation("androidx.camera:camera-core:1.3.0")
    implementation("androidx.camera:camera-camera2:1.3.0")
    implementation("androidx.camera:camera-lifecycle:1.3.0")
    implementation("androidx.camera:camera-view:1.3.0")
    
    // Accompanist - Re-enable
    implementation("com.google.accompanist:accompanist-permissions:0.31.5-beta")
    
    // MediaPipe dependencies - Use specific version instead of latest.release
    implementation("com.google.mediapipe:tasks-vision:0.10.5") // Updated to specific version for PoseLandmarker
    // Optional GPU acceleration - Keep specific version or update if needed
    implementation("org.tensorflow:tensorflow-lite-gpu:2.12.0")
    
    // Bluetooth - Comment out problematic library
    // implementation("com.github.NordicSemiconductor:Android-BLE-Library:v2.6.1")
    
    // Use Google's Bluetooth APIs instead (already added)
    // implementation("com.google.android.gms:play-services-location:21.0.1")
    
    // Coroutines
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-core:1.7.3")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-play-services:1.7.3")
    // Datetime
    implementation("org.jetbrains.kotlinx:kotlinx-datetime:0.5.0")
    
    // Testing
    testImplementation("junit:junit:4.13.2")
    // Kotest for generated tests (based on errors)
    testImplementation("io.kotest:kotest-runner-junit5:5.8.0")
    testImplementation("io.kotest:kotest-assertions-core:5.8.0")

    androidTestImplementation("androidx.test.ext:junit:1.1.5")
    androidTestImplementation("androidx.test.espresso:espresso-core:3.5.1")
    androidTestImplementation(platform("androidx.compose:compose-bom:2023.08.00"))
    androidTestImplementation("androidx.compose.ui:ui-test-junit4")
    debugImplementation("androidx.compose.ui:ui-tooling")
    debugImplementation("androidx.compose.ui:ui-test-manifest")

    // Location Services
    implementation("com.google.android.gms:play-services-location:21.0.1") // Use latest stable version

    // Accompanist Permissions
    // implementation("com.google.accompanist:accompanist-permissions:0.31.5-beta") // Use latest stable/suitable version

    // Coil image caching dependency
    implementation("io.coil-kt:coil-compose:2.4.0")

    // Google Play Core for in-app updates
    implementation("com.google.android.play:app-update:2.1.0")
    implementation("com.google.android.play:app-update-ktx:2.1.0")
}
