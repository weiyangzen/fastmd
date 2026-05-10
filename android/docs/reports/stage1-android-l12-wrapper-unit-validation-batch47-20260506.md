# Stage 1 Android L12 Wrapper Unit Validation Batch 47

Date: 2026-05-06

## Scope

- Android-owned validation evidence only.
- Blueprint area: L12 platform validation.
- No iOS files, shared `Docs/**` checklists, or `.cron/**` files were edited.

## Environment

- Working directory: `android/`
- Gradle entry point: checked-in wrapper `./gradlew`
- `JAVA_HOME`: `/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home`
- `ANDROID_HOME`: `/Users/wangweiyang/Library/Android/sdk`
- `local.properties`: contains `sdk.dir=/Users/wangweiyang/Library/Android/sdk`
- Installed Android SDK platforms observed locally: `android-31`, `android-32`, `android-33`, `android-34`, `android-35`, `android-36`
- Attached device check: `adb devices` returned only the header line, with no attached devices or running emulators.

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `JAVA_HOME="/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home" ANDROID_HOME="/Users/wangweiyang/Library/Android/sdk" ./gradlew projects --no-daemon` | PASS | Gradle resolved root project `fastmd-android` and modules `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`; `BUILD SUCCESSFUL in 13s`. |
| `JAVA_HOME="/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home" ANDROID_HOME="/Users/wangweiyang/Library/Android/sdk" ./gradlew :core:testDebugUnitTest --no-daemon` | BLOCKED | Kotlin first attempted a stale daemon running Java `25.0.1`, failed with `IllegalArgumentException: 25.0.1`, then fell back to non-daemon compilation. The task then failed resolving `:core:debugUnitTestRuntimeClasspath` because downloads from Google Maven timed out for `androidx.collection:collection-ktx:1.4.0` and `androidx.concurrent:concurrent-futures:1.1.0` from `https://dl.google.com/dl/android/maven2/...`. |
| `JAVA_HOME="/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home" ANDROID_HOME="/Users/wangweiyang/Library/Android/sdk" ./gradlew :feature:reader:testDebugUnitTest --no-daemon` | BLOCKED | The task reached `:feature:reader:compileDebugKotlin`, then failed resolving `:feature:reader:kotlin-extension` because Google Maven timed out fetching `androidx.compose.compiler:compiler:1.5.14` from `https://dl.google.com/dl/android/maven2/...`. |
| `ANDROID_HOME="/Users/wangweiyang/Library/Android/sdk" /Users/wangweiyang/Library/Android/sdk/platform-tools/adb devices` | BLOCKED | No attached Android device or running emulator was listed, so `:app:connectedDebugAndroidTest`, API 27 device validation, low-memory/small-screen validation, and modern-device validation remain open. |
| `find "/Users/wangweiyang/Library/Android/sdk/platforms" -maxdepth 1 -type d -name 'android-*'` | BLOCKED for API 27 | Installed platforms include API 31-36 only; no `android-27` platform was present for Android 8.1/API 27 local validation. |

## Checklist Evidence For Supervisor

- L12: Run Android `./gradlew :core:testDebugUnitTest`.
  - Do not mark complete from this batch. The task remains blocked by Google Maven dependency download timeouts, not by a source assertion failure.
- L12: Run Android `./gradlew :feature:reader:testDebugUnitTest`.
  - Do not mark complete from this batch. The task remains blocked by Google Maven dependency download timeouts during Compose compiler resolution.
- L12: Run Android `./gradlew :app:connectedDebugAndroidTest`.
  - Do not mark complete from this batch. No attached device or emulator was available.
- L12: Run Android API 27 validation.
  - Do not mark complete from this batch. The local SDK has no `android-27` platform installed and no API 27 device/emulator attached.
- L12: Run Android low-memory/small-screen profile validation.
  - Do not mark complete from this batch. Device/emulator validation is unavailable locally.
- L12: Run Android modern device validation.
  - Do not mark complete from this batch. Device/emulator validation is unavailable locally.
- L12: Record validation reports under `android/docs/reports/`.
  - Evidence: this report records current wrapper, unit-test, SDK, and device validation status.

## Remaining Open Validation

- `./gradlew lint`, `./gradlew build`, `./gradlew :app:assembleDebug`, and deeper unit-test/device gates remain open until Google Maven dependency resolution succeeds and device/emulator targets are available.
- The stale Kotlin daemon using Java `25.0.1` should be cleared with `./gradlew --stop` or by ensuring future worker shells do not launch Kotlin daemons from OpenJDK 25. In this batch, Gradle's non-daemon fallback allowed compilation to proceed until network dependency resolution blocked the unit-test tasks.
