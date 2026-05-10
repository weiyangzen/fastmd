# Stage 1 Android L12 Gradle Mirror Validation Batch 88 - 2026-05-06

## Scope

Android live-lane bounded implementation and validation batch for the earliest
still-open Android-owned L12 platform validation gates.

This batch stayed inside Android ownership. It did not edit `ios/**`, shared
`Docs/**`, or `.cron/**`.

## Changed Android Files

- `android/settings.gradle.kts`
- `android/README.md`
- `android/core/src/main/java/com/fastmd/mobile/core/markdown/MarkdownInlineParser.kt`
- `android/core/src/main/java/com/fastmd/mobile/core/markdown/StructuredMarkdownParser.kt`
- `android/feature/reader/src/main/java/com/fastmd/mobile/feature/reader/ReaderScreen.kt`
- `android/app/src/main/java/com/fastmd/mobile/recovery/AndroidRecoveryDraftStore.kt`
- `android/docs/reports/stage1-android-l12-gradle-mirror-validation-batch88-20260506.md`

## Environment

- Working directory: `/Users/wangweiyang/GitHub/fastmd/android`
- Batch timestamp: `2026-05-06 21:07:32 CST`
- Gradle entry point: checked-in wrapper `./gradlew`
- Explicit validation JDK:
  `/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home`
- Default shell Java discovery: blocked; `java -version` printed
  `Unable to locate a Java Runtime`.
- Android SDK path from `android/local.properties`:
  `/Users/wangweiyang/Library/Android/sdk`
- Android API 27 system image directory: absent at
  `/Users/wangweiyang/Library/Android/sdk/system-images/android-27`.
- Connected Android devices before and after connected test command: none;
  `adb devices` printed only `List of devices attached`.
- `android/app/src/androidTest`: no checked-in instrumentation test source
  files found.

## Implementation Notes

- Added an opt-in Android Gradle repository escape hatch:
  `-Pfastmd.useChinaMavenMirror=true`.
- The default repository posture is unchanged. Without the property, Gradle
  still uses `google()`, `mavenCentral()`, and Gradle Plugin Portal.
- The mirror flag prepends Aliyun Google/Central/Gradle-plugin mirrors only when
  explicitly requested. This resolved the lane-local `dl.google.com` timeout for
  exact missing Google Maven artifacts.
- Fixed Android Kotlin compile errors surfaced once dependency resolution
  progressed:
  - Avoided unsafe Compose `Bitmap?` smart cast from delegated state.
  - Avoided cross-module smart casts for inline link target/decision.
  - Replaced an invalid expression-bodied recovery summary parser with a block
    body and explicit enum type.
- Fixed two core parser defects surfaced by unit tests:
  - One-line `<video ...></video>` no longer consumes following blocks as an
    unterminated video block.
  - Escaped paired inline markers such as `\**` and `\`` remain literal and do
    not create inline spans.

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `java -version` | BLOCKED without explicit JDK | Shell Java discovery failed with `Unable to locate a Java Runtime`; all wrapper-backed commands below used explicit JDK 17. |
| `JAVA_HOME=... ./gradlew --offline --no-daemon projects` | PASS | Root project `fastmd-android` evaluated and listed `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`; `BUILD SUCCESSFUL in 13s`. |
| `JAVA_HOME=... ./gradlew --offline --no-daemon lint` | BLOCKED | Failed at `:core:extractDebugAnnotations` because `com.android.tools.lint:lint-gradle:31.13.2` was not cached for offline mode. |
| `curl -I --max-time 20 https://dl.google.com/dl/android/maven2/com/android/tools/lint/lint-gradle/31.13.2/lint-gradle-31.13.2.pom` | BLOCKED | Timed out after 20 seconds. |
| `curl -I --max-time 20 https://maven.aliyun.com/repository/google/com/android/tools/lint/lint-gradle/31.13.2/lint-gradle-31.13.2.pom` | PASS | HTTP 200 from the regional Google Maven mirror. |
| `curl -I --max-time 20 https://maven.aliyun.com/repository/google/androidx/compose/compiler/compiler/1.5.14/compiler-1.5.14.pom` | PASS | HTTP 200 from the regional Google Maven mirror. |
| `curl -I --max-time 20 https://maven.aliyun.com/repository/google/androidx/collection/collection-ktx/1.4.0/collection-ktx-1.4.0.pom` | PASS | HTTP 200 from the regional Google Maven mirror. |
| `JAVA_HOME=... ./gradlew -Pfastmd.useChinaMavenMirror=true --no-daemon projects` | PASS | Project graph evaluated successfully with mirror flag; `BUILD SUCCESSFUL in 44s`. |
| `JAVA_HOME=... ./gradlew -Pfastmd.useChinaMavenMirror=true --no-daemon lint` | PASS | All Android module lint tasks completed; `BUILD SUCCESSFUL in 2m 8s`. |
| `JAVA_HOME=... ./gradlew -Pfastmd.useChinaMavenMirror=true --no-daemon :core:testDebugUnitTest` | PASS | Core unit tests completed after parser fixes; `BUILD SUCCESSFUL in 53s`. |
| `JAVA_HOME=... ./gradlew -Pfastmd.useChinaMavenMirror=true --no-daemon build` | PASS | Full Android build completed, including app/core/feature builds, unit tests, lint, R8 release minification, and renderer asset/request gates; `BUILD SUCCESSFUL in 5m 51s`. |
| `JAVA_HOME=... ./gradlew -Pfastmd.useChinaMavenMirror=true --no-daemon :feature:reader:testDebugUnitTest` | PASS | Reader feature debug unit-test task completed; `BUILD SUCCESSFUL in 16s`. |
| `JAVA_HOME=... ./gradlew -Pfastmd.useChinaMavenMirror=true --no-daemon :app:assembleDebug` | PASS | Debug APK assembly completed; `BUILD SUCCESSFUL in 18s`. |
| `JAVA_HOME=... ./gradlew -Pfastmd.useChinaMavenMirror=true --no-daemon :app:connectedDebugAndroidTest` | PASS / no-device caveat | Gradle task completed and packaged the empty Android test APK; `BUILD SUCCESSFUL in 57s`. ADB listed no attached devices before and after, and no checked-in `androidTest` sources were present, so this is not device validation evidence. |
| `/Users/wangweiyang/Library/Android/sdk/platform-tools/adb devices` | BLOCKED for device validation | ADB ran successfully, but no attached Android device or running emulator was listed. |
| `ls /Users/wangweiyang/Library/Android/sdk/system-images/android-27` | BLOCKED for API 27 validation | API 27 system image directory is absent. |

## Build Findings Fixed

Before the fixes in this batch, mirror-enabled Gradle validation surfaced these
real Android source failures:

- `ReaderScreen.kt`: unsafe smart casts for `Bitmap?`, `linkDecision`, and
  `linkTarget`.
- `AndroidRecoveryDraftStore.kt`: invalid `return null` inside an
  expression-bodied function and missing enum type inference.
- `StructuredMarkdownParserTest`: one-line video HTML consumed following blocks.
- `StructuredMarkdownParserTest`: escaped paired inline markers were not
  preserved as literal text.

All four source issue groups are fixed and covered by the passing Gradle gates
above.

## Preserved Blockers

- Default Java discovery remains blocked until a JDK is visible on `PATH` or
  `JAVA_HOME` is exported before wrapper use.
- Android dependency resolution without the mirror flag remains unreliable from
  this lane because `dl.google.com` times out for Google Maven artifacts.
- Android API 27 validation remains open because no API 27 system image or
  attached API 27 device/emulator is present.
- Android low-memory/small-screen profile validation remains open because no
  matching Android device or emulator is attached.
- Android modern-device validation remains open because no attached Android
  device or emulator is present.
- Device-backed interpretation of `:app:connectedDebugAndroidTest` remains open:
  the Gradle task completed, but ADB listed no devices and there are no
  checked-in `androidTest` sources to execute.

## Supervisor Checklist Recommendation

The supervising session can use this report as Android-lane evidence to mark:

- L12: Run Android `./gradlew lint`, with explicit JDK 17 and
  `-Pfastmd.useChinaMavenMirror=true` in this network environment.
- L12: Run Android `./gradlew build`, with explicit JDK 17 and
  `-Pfastmd.useChinaMavenMirror=true`.
- L12: Run Android `./gradlew :core:testDebugUnitTest`, with explicit JDK 17
  and `-Pfastmd.useChinaMavenMirror=true`.
- L12: Run Android `./gradlew :feature:reader:testDebugUnitTest`, with explicit
  JDK 17 and `-Pfastmd.useChinaMavenMirror=true`.
- L12: Run Android `./gradlew :app:assembleDebug`, with explicit JDK 17 and
  `-Pfastmd.useChinaMavenMirror=true`.

Do not mark Android API 27 validation, low-memory/small-screen validation, or
modern-device validation complete from this batch. Treat
`:app:connectedDebugAndroidTest` as command-level packaging evidence only, not
device-backed validation, unless the supervisor accepts a no-device/no-test
Gradle pass for that checklist line.
