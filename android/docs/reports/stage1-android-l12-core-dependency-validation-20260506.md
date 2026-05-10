# Stage 1 Android L12 Core Dependency Validation - 2026-05-06

## Scope

Android live-lane bounded implementation batch for the earliest remaining Android-owned validation surface.

This batch stayed under `android/**` and did not edit `ios/**`, shared `Docs/**`, or `.cron/**`.

## Implementation Change

The `:core` module imports Compose runtime value types only:

- `androidx.compose.runtime.staticCompositionLocalOf`
- `androidx.compose.runtime.Immutable`
- `androidx.compose.ui.graphics.Color`

It does not declare `@Composable` functions and does not need the Compose compiler. This batch removed `:core`'s Compose compiler configuration and replaced its broad Compose UI/Material dependency surface with the exact runtime and UI graphics aliases it imports.

Changed Android files:

- `android/core/build.gradle.kts`
- `android/gradle/libs.versions.toml`
- `android/docs/reports/stage1-android-l12-core-dependency-validation-20260506.md`

## Validation Results

All commands were run from `/Users/wangweiyang/GitHub/fastmd/android` unless noted. Gradle commands used:

```text
JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17
```

| Command | Result | Evidence |
| --- | --- | --- |
| `./gradlew projects --no-daemon` | PASS | Wrapper evaluated root project `fastmd-android` and modules `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`. |
| `./gradlew :core:compileDebugKotlin --no-daemon` | PASS | `:core` compiled after removing the unnecessary Compose compiler configuration and narrowing Compose dependencies. |
| `./gradlew :core:testDebugUnitTest --no-daemon` | BLOCKED | `:core:compileDebugKotlin` was up-to-date and the task advanced to `:core:generateDebugUnitTestStubRFile`, then failed resolving `junit:junit:4.13.2` and `org.jetbrains.kotlinx:kotlinx-coroutines-test:1.8.1` from `dl.google.com` because the connection timed out. |
| `./gradlew lint --no-daemon` before the dependency cleanup | BLOCKED | Failed at `:core:compileDebugKotlin` resolving `androidx.compose.compiler:compiler:1.5.14` from `dl.google.com`. |
| `./gradlew lint --no-daemon` after removing the Compose compiler from `:core` | BLOCKED | Advanced past `:core:compileDebugKotlin`; then failed at `:core:checkDebugAarMetadata` resolving `androidx.emoji2:emoji2:1.2.0`, which was pulled by the broad `compose-ui` dependency. |
| `./gradlew lint --no-daemon` after narrowing `:core` Compose dependencies | BLOCKED | Advanced through `:core:checkDebugAarMetadata`, `:core:compileDebugKotlin`, and `:core:extractDebugAnnotations`; then failed resolving `com.android.tools.lint:lint-gradle:31.13.2` from `dl.google.com` because the connection timed out. |
| `git diff --check -- android/core/build.gradle.kts android/gradle/libs.versions.toml` from repo root | PASS | No whitespace errors were reported. |
| `bash tools/audit_renderer_assets.sh` | PASS | No Android WebView/android.webkit implementation, no React Native/Flutter/Cordova runtime dependency, and no vendored JS/CSS/font renderer asset tree were found. |
| `bash tools/audit_stage1_manifest.sh` | PASS | No permissions; no broad storage, media, notification, or default `INTERNET`; `allowBackup=false`; cleartext disabled; only document-entry `MainActivity` exported; release hardening enabled. |

## Blocker Details

`./gradlew lint` is still not complete. The command now reaches the Android lint artifact resolution step:

```text
Execution failed for task ':core:extractDebugAnnotations'.
Could not resolve com.android.tools.lint:lint-gradle:31.13.2.
Could not GET 'https://dl.google.com/dl/android/maven2/com/android/tools/lint/lint-gradle/31.13.2/lint-gradle-31.13.2.pom'.
Connect to dl.google.com:443 failed: Connect timed out.
```

`./gradlew :core:testDebugUnitTest` is also still not complete. The command now reaches unit-test runtime dependency resolution:

```text
Execution failed for task ':core:generateDebugUnitTestStubRFile'.
Could not resolve junit:junit:4.13.2.
Could not resolve org.jetbrains.kotlinx:kotlinx-coroutines-test:1.8.1.
Connect to dl.google.com:443 failed: Connect timed out.
```

## Supervisor Checklist Recommendation

The supervisor can use this report as Android-lane evidence that the Gradle wrapper and `:core` debug Kotlin compilation are healthy with explicit JDK 17 after the dependency cleanup.

Keep these L12 checklist items open:

- Run Android `./gradlew lint`.
- Run Android `./gradlew :core:testDebugUnitTest`.
- Run Android `./gradlew build`.
- Run Android `./gradlew :feature:reader:testDebugUnitTest`.
- Run Android `./gradlew :app:assembleDebug`.
- Run Android `./gradlew :app:connectedDebugAndroidTest`.
- Run Android API 27 validation.
- Run Android low-memory/small-screen profile validation.
- Run Android modern device validation.

The supervisor can consider this report additional evidence for:

- L13: Record validation reports under `android/docs/reports/`.

