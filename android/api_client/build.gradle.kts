// Apply the Kotlin JVM plugin and OpenAPI Generator plugin
plugins {
    kotlin("jvm")
    kotlin("plugin.serialization") // Apply serialization plugin without explicit version
    // kotlin("kapt") // Keep kapt for Moshi codegen if needed by generated code - REMOVED
    id("com.google.devtools.ksp") version "1.9.23-1.0.19" // ADD KSP plugin
    id("org.openapi.generator") // Apply the generator plugin
}

// Configure the OpenAPI Generator task
openApiGenerate {
    // See available generators: ./gradlew :api_client:openApiGenerators
    generatorName.set("kotlin")
    // IMPORTANT: Verify this path points to your actual OpenAPI spec file
    inputSpec.set("$rootDir/../openapi.yaml") 
    // Output to a temporary directory within the build folder
    // outputDir.set("$projectDir/src/main/kotlin") 
    // Correctly set outputDir using layout provider
    outputDir.set(layout.buildDirectory.map { it.dir("generated/openapi").asFile.absolutePath })
    apiPackage.set("org.openapitools.client.apis")
    modelPackage.set("org.openapitools.client.models")
    invokerPackage.set("org.openapitools.client.infrastructure") // For ApiClient base

    configOptions = mapOf(
        "library" to "jvm-retrofit2",
        "serializableModel" to "true",
        "serializationLibrary" to "moshi", // Use moshi based on existing dependencies
        "useCoroutines" to "true",
        "dateLibrary" to "java8", // Use Java 8 date/time types (requires core library desugaring OR minSdk 26 in app)
        "moshiCodeGen" to "true", // Enable Moshi codegen annotations (@JsonClass)
        "generateTests" to "false", // Disable test generation
        // "generateApiTests" to "false", // Explicitly disable API tests - REMOVED
        // "generateModelTests" to "false" // Explicitly disable model tests - REMOVED
        // Add other Kotlin generator options if needed:
        // https://openapi-generator.tech/docs/generators/kotlin
    )
}

// Configure source sets to include the generated code
sourceSets {
    main {
        java {
            // Include the generated Java code if any (though typically Kotlin generator produces .kt)
            // The generator might place java under src/main/java within its output structure
            srcDir(layout.buildDirectory.dir("generated/openapi/src/main/java"))
        }
        kotlin {
            // Include ONLY the generated MAIN Kotlin code
            // The generator places kotlin under src/main/kotlin within its output structure
            srcDir(layout.buildDirectory.dir("generated/openapi/src/main/kotlin"))
            // Explicitly EXCLUDE the test sources that the generator might have put inside the main path
            exclude("**/src/test/kotlin/**")
        }
    }
    // We explicitly DO NOT configure a test source set here, as we don't want
    // the generated tests included in the build.
}

// Add a task hook to clean the output directory before generation
// tasks.named("openApiGenerate") {
//     doFirst {
//         delete(file("$projectDir/src/main/kotlin"))
//     }
// }

dependencies {
    // Kotlin standard library
    implementation(kotlin("stdlib"))

    // Kotlinx Serialization (if used by generator alongside Moshi? Unlikely needed if using moshi)
    // api("org.jetbrains.kotlinx:kotlinx-serialization-json:1.6.0") 

    // Retrofit & Moshi (if used by generator)
    api("com.squareup.retrofit2:retrofit:2.9.0")
    api("com.squareup.retrofit2:converter-moshi:2.9.0")
    api("com.squareup.moshi:moshi:1.15.0") // Match app module version
    api("com.squareup.moshi:moshi-kotlin:1.15.0") // Match app module version
    // kapt("com.squareup.moshi:moshi-kotlin-codegen:1.15.0") // Keep if moshi codegen is used - CHANGED to ksp
    ksp("com.squareup.moshi:moshi-kotlin-codegen:1.15.0") // Use KSP for Moshi codegen
    // Provide Kotest to kapt to resolve ShouldSpec in generated stubs - REMOVED
    // kapt("io.kotest:kotest-runner-junit5-jvm:5.5.4") 

    // OkHttp dependencies (adjust api/implementation based on generator output)
    api("com.squareup.okhttp3:logging-interceptor:5.0.0-alpha.11") // Match app module version
    api("com.squareup.okhttp3:okhttp:5.0.0-alpha.11") // Match app module version

    // Other converters/dependencies needed by generated code
    api("com.squareup.retrofit2:converter-scalars:2.9.0")

    // Coroutines (if used by generator)
    api("org.jetbrains.kotlinx:kotlinx-coroutines-core:1.10.2") // Match app module version

    // --- Add any OTHER specific dependencies required by your generated code ---\
    // If using dateLibrary=java8 and minSdk < 26, app needs core library desugaring
    // testImplementation("io.kotest:kotest-runner-junit5-jvm:5.5.4") // Add Kotest for generated test stubs - Didn't work here
}

// Configure Kotlin JVM target
tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile> {
    kotlinOptions {
        jvmTarget = "17" // Match your app module's Java toolchain version
    }
}

// Add Kapt configuration if needed - REMOVED
// kapt {
//     correctErrorTypes = true
// }

// Ensure Kapt runs after OpenAPI generation to process generated code - REMOVED
// tasks.withType<org.jetbrains.kotlin.gradle.internal.KaptGenerateStubsTask> {
//     dependsOn(tasks.named("openApiGenerate"))
// } 

// Ensure KSP runs after OpenAPI generation if needed (Optional, usually handled by dependencies)
// tasks.withType<com.google.devtools.ksp.gradle.KspTask> {
//    dependsOn(tasks.named("openApiGenerate"))
// }
// The extra brace that was here should now be gone.