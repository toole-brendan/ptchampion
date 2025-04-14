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

// Uncomment Kapt config block since plugin is re-enabled
kapt {
    correctErrorTypes = true
    keepJavacAnnotationProcessors = true
    includeCompileClasspath = false
    javacOptions {
        option("-source", "1.8")
        option("-target", "1.8")
        option("-J-Xmx2g")
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
                // Add the generated API source directory
                srcDirs("src/main/generatedapi/kotlin")
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

    buildTypes {
        release {
            isMinifyEnabled = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }
    kotlinOptions {
        jvmTarget = "1.8"
        // Add exclusions to ignore problematic files
        freeCompilerArgs += listOf(
            "-Xsuppress-version-warnings",
            "-Xno-source-root-directory"
        )
    }
    // Add Java toolchain configuration
    java {
        toolchain {
            languageVersion.set(JavaLanguageVersion.of(17))
        }
    }
    buildFeatures {
        compose = true
    }
    composeOptions {
        kotlinCompilerExtensionVersion = "1.5.1"
    }
    packaging {
        resources {
            excludes.add("/META-INF/{AL2.0,LGPL2.1}")
        }
    }
}

dependencies {
    // Core Android
    implementation("androidx.core:core-ktx:1.12.0")
    implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.7.0")
    implementation("androidx.activity:activity-compose:1.8.2")
    
    // Multidex support
    implementation("androidx.multidex:multidex:2.0.1")
    
    // Compose
    implementation(platform("androidx.compose:compose-bom:2023.08.00"))
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.ui:ui-graphics")
    implementation("androidx.compose.ui:ui-tooling-preview")
    implementation("androidx.compose.material3:material3")
    implementation("androidx.compose.material:material-icons-extended")
    implementation("androidx.navigation:navigation-compose:2.7.5")
    
    // Dependency Injection
    implementation("com.google.dagger:hilt-android:2.48.1")
    implementation("androidx.hilt:hilt-navigation-compose:1.0.0")
    kapt("com.google.dagger:hilt-compiler:2.48.1")
    
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
    kapt("com.squareup.moshi:moshi-kotlin-codegen:1.15.0")
    
    // Datastore
    implementation("androidx.datastore:datastore-preferences:1.0.0")
    
    // Camera
    implementation("androidx.camera:camera-camera2:1.3.1")
    implementation("androidx.camera:camera-lifecycle:1.3.1")
    implementation("androidx.camera:camera-view:1.3.1")
    
    // Accompanist - TEMPORARILY COMMENTED OUT
    // implementation("com.google.accompanist:accompanist-permissions:0.32.0")
    
    // MediaPipe - Disabled GPU version due to repository issues - TEMPORARILY COMMENTED OUT
    implementation("com.google.mediapipe:tasks-vision:0.10.1")
    // Keep this commented out until repository issues are resolved
    // implementation("com.google.mediapipe:tasks-vision-gpu:0.10.1")
    
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
    implementation("com.google.accompanist:accompanist-permissions:0.31.5-beta") // Use latest stable/suitable version
}
