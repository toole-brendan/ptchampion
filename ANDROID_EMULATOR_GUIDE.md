# Running the PT Champion Android App on an Emulator

This guide explains how to build, install, and run the Android `app` module on an Android Virtual Device (AVD) / Emulator.

## Prerequisites

1.  **Android Studio:** Make sure you have Android Studio installed and configured.
2.  **Android SDK:** Ensure the necessary Android SDK Platform(s) are installed via Android Studio's SDK Manager.
3.  **Emulator (AVD):** Set up at least one Android Virtual Device using Android Studio's AVD Manager.

## Steps

1.  **Start the Emulator:**
    *   Launch your desired emulator from the Android Studio AVD Manager (`Tools -> AVD Manager`).
    *   Alternatively, if you have the emulator directory added to your system `PATH`, you can list and launch emulators from the command line:
        ```bash
        emulator -list-avds
        emulator @<avd_name>
        ```
    *   Ensure only **one** emulator is running, or the `adb` and `gradlew` commands might target the wrong device.

2.  **Navigate to the Android Project:**
    Open your terminal and change the directory to the Android project root:
    ```bash
    cd /Users/brendantoole/projects/ptchampion/android
    ```
    *(Replace the path if your project root is different)*

3.  **Build and Install the Debug App:**
    Run the following Gradle command to compile the debug version of the `app` module and install it on the running emulator:
    ```bash
    ./gradlew :app:installDebug
    ```
    Wait for the build to complete successfully.

4.  **Launch the App:**
    You can usually find the "PT Champion" app icon in the emulator's app drawer and launch it manually.

    Alternatively, you can launch the main activity directly using the Android Debug Bridge (`adb`):
    ```bash
    adb shell am start -n com.example.ptchampion/com.example.ptchampion.ui.MainActivity
    ```

## Troubleshooting

*   **`emulator: command not found`**: The Android SDK `emulator` directory (`~/Library/Android/sdk/emulator` on macOS by default) is not in your system's `PATH`. You can either add it to your `PATH` or always launch the emulator via Android Studio.
*   **`CLEARTEXT communication to 10.0.2.2 not permitted`**: This occurs because the debug build tries to connect to your local machine's server (`http://10.0.2.2:8080`) using unencrypted HTTP. The project includes a Network Security Configuration (`android/app/src/main/res/xml/network_security_config.xml`) that allows this specific connection for debug builds. If you encounter this, ensure the configuration is present and referenced in the `AndroidManifest.xml`.
*   **App crashes on start (`Cannot create an instance of class ...ViewModel`)**: This often indicates a problem with Hilt (Dependency Injection). Ensure:
    *   The `Activity` hosting the screen (e.g., `MainActivity`) is annotated with `@AndroidEntryPoint`.
    *   The `Application` class (`PTChampionApp`) is annotated with `@HiltAndroidApp`.
    *   The `ViewModel` (e.g., `SplashViewModel`) is annotated with `@HiltViewModel` and uses `@Inject constructor`.
    *   The Composable screen (e.g., `SplashScreen`) is using `hiltViewModel()` to get the ViewModel instance, not the standard `viewModel()`. 