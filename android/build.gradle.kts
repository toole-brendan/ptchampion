buildscript {
    repositories {
        google()
        mavenCentral()
        maven { url = uri("https://jitpack.io") }
        maven { url = uri("https://maven.google.com") }
    }
    dependencies {
        classpath("com.android.tools.build:gradle:8.9.1")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.23")
        classpath("com.google.dagger:hilt-android-gradle-plugin:2.48.1")
        classpath("org.jetbrains.kotlin:kotlin-serialization:1.9.23")
        classpath("org.openapitools:openapi-generator-gradle-plugin:7.12.0")
    }
}

tasks.register("clean", Delete::class) {
    delete(rootProject.buildDir)
}