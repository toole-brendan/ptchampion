dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
        maven { url = uri("https://jitpack.io") }
        maven { url = uri("https://maven.google.com") }
        // Comment out MediaPipe repo since it's causing DNS issues
        // maven { url = uri("https://packages.mediapipe.dev/maven") }
    }
}

rootProject.name = "PTChampion"
include(":app")