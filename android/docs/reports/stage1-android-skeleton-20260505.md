# Stage 1 Android Skeleton Report - 2026-05-05

## Scope

Implemented the Android L1 repository skeleton under `android/**` only.

## Changed Files

Gradle and project metadata:

- `android/.gitignore`
- `android/README.md`
- `android/settings.gradle.kts`
- `android/build.gradle.kts`
- `android/gradle.properties`
- `android/gradle/libs.versions.toml`
- `android/app/build.gradle.kts`
- `android/core/build.gradle.kts`
- `android/feature/reader/build.gradle.kts`
- `android/feature/library/build.gradle.kts`
- `android/feature/settings/build.gradle.kts`

Android app shell:

- `android/app/src/main/AndroidManifest.xml`
- `android/app/src/main/java/com/fastmd/mobile/MainActivity.kt`
- `android/app/src/main/res/drawable/ic_launcher.xml`
- `android/app/src/main/res/drawable/ic_launcher_round.xml`
- `android/app/src/main/res/values/colors.xml`
- `android/app/src/main/res/values/strings.xml`
- `android/app/src/main/res/values/styles.xml`

Core module:

- `android/core/consumer-rules.pro`
- `android/core/src/main/AndroidManifest.xml`
- `android/core/src/main/java/com/fastmd/mobile/core/document/MarkdownDocument.kt`
- `android/core/src/test/java/com/fastmd/mobile/core/document/MarkdownDocumentTest.kt`

Feature modules:

- `android/feature/reader/consumer-rules.pro`
- `android/feature/reader/src/main/AndroidManifest.xml`
- `android/feature/reader/src/main/java/com/fastmd/mobile/feature/reader/ReaderScreen.kt`
- `android/feature/library/consumer-rules.pro`
- `android/feature/library/src/main/AndroidManifest.xml`
- `android/feature/library/src/main/java/com/fastmd/mobile/feature/library/LibraryScreen.kt`
- `android/feature/settings/consumer-rules.pro`
- `android/feature/settings/src/main/AndroidManifest.xml`
- `android/feature/settings/src/main/java/com/fastmd/mobile/feature/settings/SettingsScreen.kt`

Android docs placeholders:

- `android/docs/reports/README.md`
- `android/docs/screenshots/README.md`
- `android/docs/reports/stage1-android-skeleton-20260505.md`

Markdown fixtures:

- `android/test-fixtures/markdown/basic.md`
- `android/test-fixtures/markdown/cjk.md`
- `android/test-fixtures/markdown/rich-preview.md`
- `android/test-fixtures/markdown/long-1mb.md`
- `android/test-fixtures/markdown/large-5mb.md`
- `android/test-fixtures/markdown/huge-table.md`
- `android/test-fixtures/markdown/huge-code-block.md`
- `android/test-fixtures/markdown/malformed-markdown.md`
- `android/test-fixtures/markdown/malicious-html.md`
- `android/test-fixtures/markdown/malicious-links.md`
- `android/test-fixtures/markdown/remote-image.md`
- `android/test-fixtures/markdown/local-image.md`
- `android/test-fixtures/markdown/encoding-utf8-bom.md`
- `android/test-fixtures/markdown/line-endings-crlf.md`
- `android/test-fixtures/markdown/external-change-before-save.md`
- `android/test-fixtures/markdown/readonly-document.md`
- `android/test-fixtures/markdown/long-filename.md`
- `android/test-fixtures/markdown/rtl-and-emoji.md`

## Implementation Notes

- Created Gradle Kotlin DSL modules `:app`, `:core`, `:feature:reader`, `:feature:library`, and `:feature:settings`.
- Configured `compileSdk = 35`, `minSdk = 27`, `targetSdk = 35`, Java 17 compile options, Kotlin JVM target 17, Compose, Material 3, coroutines, DataStore, JUnit, AndroidX JUnit, and Espresso through `android/gradle/libs.versions.toml`.
- Added a minimal launcher Activity and Compose shell that references all feature modules.
- Added Android manifest entry points for launcher, Markdown-like `ACTION_VIEW`, and text/Markdown `ACTION_SEND`.
- Added a small `MarkdownDocument` core model and unit test.
- Seeded all required fixture matrix filenames. `basic.md`, `cjk.md`, and `rich-preview.md` were copied from the canonical shared fixtures. Large/pathological fixtures are small representative seeds for the skeleton and should be expanded by later performance validation harnesses.

## Validation

| Command | Result | Evidence |
| --- | --- | --- |
| `java -version` | FAIL | `/usr/bin/java` reported: `Unable to locate a Java Runtime.` |
| `./gradlew projects` | FAIL | No Gradle wrapper exists under `android/`: `/bin/bash: ./gradlew: No such file or directory`. |
| `gradle --version` | PASS | Global Gradle `9.3.0` is available. It launched with Homebrew JDK `25.0.1`, not the requested project baseline JDK 17. |
| `gradle projects` | PASS | Build succeeded in `1m 32s` and listed `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`. |
| `gradle :core:testDebugUnitTest` | FAIL | Android SDK was not configured: `SDK location not found. Define a valid SDK location with an ANDROID_HOME environment variable or by setting the sdk.dir path in your project's local properties file at '/Users/wangweiyang/GitHub/fastmd/android/local.properties'.` |

## Blockers

- No checked-in Android Gradle wrapper is present in `android/`, so required `./gradlew ...` commands cannot run yet.
- The shell `java -version` cannot find a Java runtime, while global Gradle uses Homebrew JDK 25. JDK 17 should be installed/configured for Android baseline validation.
- Android SDK location is not configured via `ANDROID_HOME` or `android/local.properties`, so Android compile/test tasks such as `:core:testDebugUnitTest` cannot execute.

## Current PASS/FAIL Summary

- PASS: Android module graph resolves with global Gradle.
- PASS: Required Android fixture filenames exist under `android/test-fixtures/markdown/`.
- PASS: Android docs report and screenshot directories have placeholder READMEs.
- FAIL/BLOCKED: Android unit test execution is blocked by missing SDK configuration.
- FAIL/BLOCKED: Wrapper-based validation is blocked by missing `android/gradlew`.
