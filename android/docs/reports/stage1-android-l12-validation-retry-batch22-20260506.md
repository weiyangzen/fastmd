# Stage 1 Android L12 Validation Retry Batch 22 - 2026-05-06

## Scope

Android live-lane bounded batch for the earliest still-open Android-owned
platform validation items:

- Run Android `./gradlew lint`.
- Run Android `./gradlew build`.
- Run Android `./gradlew :core:testDebugUnitTest`.
- Run Android `./gradlew :feature:reader:testDebugUnitTest`.
- Run Android `./gradlew :app:assembleDebug`.
- Preserve current device/API blockers for connected, API 27,
  low-memory/small-screen, and modern-device validation.

No `ios/**`, shared `Docs/**`, or `.cron/**` files were edited.

## Environment

All commands were run from `/Users/wangweiyang/GitHub/fastmd/android`.

Gradle commands used:

```text
JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home
```

Environment probes:

| Probe | Result | Evidence |
| --- | --- | --- |
| `/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home/bin/java -version` | PASS | OpenJDK `17.0.17` Homebrew runtime is installed. |
| `cat local.properties` | PASS | `sdk.dir=/Users/wangweiyang/Library/Android/sdk`. |
| `ls -ld /Users/wangweiyang/Library/Android/sdk/platforms/android-35` | PASS | Android API 35 platform is installed. |
| `ls -ld /Users/wangweiyang/Library/Android/sdk/platforms/android-27` | BLOCKED | No API 27 platform directory was found. |
| `adb devices` | BLOCKED | `adb` is installed, but no attached devices or running emulators are listed. |

## Gradle Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `./gradlew projects --no-daemon` | PASS | Wrapper-backed Gradle evaluated root project `fastmd-android` and listed `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`. |
| `./gradlew :core:testDebugUnitTest --no-daemon` | BLOCKED | Gradle reached `:core:testDebugUnitTest`, then failed resolving Google Maven AndroidX runtime jars: `androidx.collection:collection-ktx:1.4.0` and `androidx.concurrent:concurrent-futures:1.1.0`; both `https://dl.google.com/...` requests timed out. |
| `./gradlew lint --no-daemon` | BLOCKED | Gradle reached `:core:extractDebugAnnotations`, then failed resolving `com.android.tools.lint:lint-gradle:31.13.2` from `https://dl.google.com/...` with a connection timeout. |
| `./gradlew build --no-daemon` | BLOCKED | Gradle reached `:feature:library:compileDebugKotlin`, then failed resolving `androidx.compose.compiler:compiler:1.5.14` from `https://dl.google.com/...` with a connection timeout. |
| `./gradlew :app:assembleDebug --no-daemon` | BLOCKED | Gradle reached `:feature:library:compileDebugKotlin`, then failed resolving `androidx.compose.compiler:compiler:1.5.14` from `https://dl.google.com/...` with a connection timeout. |
| `./gradlew :feature:reader:testDebugUnitTest --no-daemon` | BLOCKED | Gradle reached `:feature:reader:compileDebugKotlin`, then failed resolving `androidx.compose.compiler:compiler:1.5.14` from `https://dl.google.com/...` with a connection timeout. |

## Blockers Preserved

- L12 Android `./gradlew lint` remains open because Google Maven timed out
  resolving `com.android.tools.lint:lint-gradle:31.13.2`.
- L12 Android `./gradlew build`, `./gradlew :app:assembleDebug`, and
  `./gradlew :feature:reader:testDebugUnitTest` remain open because Google Maven
  timed out resolving `androidx.compose.compiler:compiler:1.5.14`.
- L12 Android `./gradlew :core:testDebugUnitTest` remains open because Google
  Maven timed out resolving AndroidX runtime jars.
- L12 Android `./gradlew :app:connectedDebugAndroidTest` remains open because no
  attached device or running emulator is listed by `adb devices`.
- L12 Android API 27 validation remains open because no API 27 platform directory
  was found in `/Users/wangweiyang/Library/Android/sdk/platforms/`.
- L12 Android low-memory/small-screen and modern-device validation remain open
  because `adb devices` lists no attached target.

## Supervisor Checklist Recommendation

The supervising session can use this report as Android-lane evidence for:

- L13: Record validation reports under `android/docs/reports/`.

Do not mark Android lint, build, unit-test, assemble, connected-device, API 27,
low-memory/small-screen, or modern-device validation complete from this batch.
