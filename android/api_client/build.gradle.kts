plugins {
    id("com.android.library")
    id("org.jetbrains.kotlin.android")
    kotlin("plugin.serialization")
    // Add kapt if Moshi codegen is used (it was enabled in generator)
    kotlin("kapt") // Re-enable kapt
}

android {
    namespace = "com.example.ptchampion.data.network.generated"
    compileSdk = 34

    defaultConfig {
        minSdk = 26
        
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
        consumerProguardFiles("consumer-rules.pro")
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
    
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    
    kotlinOptions {
        jvmTarget = "17"
    }
}

dependencies {
    implementation("androidx.core:core-ktx:1.12.0")
    
    // Kotlin standard library
    implementation(kotlin("stdlib"))
    
    // Kotlinx Serialization (since serializableModel=true was used)
    implementation("org.jetbrains.kotlinx:kotlinx-serialization-json:1.6.0") // Match app module version

    // Retrofit & Moshi (since library=jvm-retrofit2 and moshiCodeGen=true were used)
    api("com.squareup.retrofit2:retrofit:2.9.0") // api so app module can access Retrofit types if needed
    api("com.squareup.retrofit2:converter-moshi:2.9.0")
    api("com.squareup.moshi:moshi:1.15.0") // Match app module version
    api("com.squareup.moshi:moshi-kotlin:1.15.0") // Match app module version
    // Add Moshi codegen processor if needed (check generated code for @JsonClass)
    kapt("com.squareup.moshi:moshi-kotlin-codegen:1.15.0") // Re-enable Moshi codegen
    
    // Add missing dependencies for generated ApiClient
    api("com.squareup.okhttp3:logging-interceptor:5.0.0-alpha.11") // Match app module version
    api("com.squareup.retrofit2:converter-scalars:2.9.0") // Match app module version
    
    // Other potential dependencies based on generated code (e.g., okhttp, threetenbp)
    api("com.squareup.okhttp3:okhttp:5.0.0-alpha.11") // Match app module version
    // Add Threeten backport if JDK < 8 AND generated code uses java.time.* (check imports)
    // implementation("org.threeten:threetenbp:1.6.8")
    
    // Coroutines (since useCoroutines=true was used)
    api("org.jetbrains.kotlinx:kotlinx-coroutines-core:1.7.3") // Match app module version
}

// Add sourceSets block if needed to point to 'src/main/kotlin'
// (should be default, but can be explicit)
// sourceSets {
//     main {
//         java {
//             srcDirs("src/main/kotlin")
//         }
//     }
// } 