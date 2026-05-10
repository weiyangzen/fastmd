# Stage 1 Android L12 JDK 17 Validation - 2026-05-05

## Scope

This bounded Android-owned batch advanced the earliest still-open Android L12 validation cluster without editing iOS, `Docs/Stage1_Mobile_Blueprint.md`, or `Docs/todos_20260505.md`.

The daily snapshot still lists Android Gradle validation gates open. Earlier Android reports recorded three blockers: the normal shell had no Java runtime, the Android SDK path was missing, and network/DNS prevented Gradle dependency resolution. This batch rechecked those blockers and found partial progress:

- A local JDK 17 is installed at `/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home`.
- `android/local.properties` is present with `sdk.dir=/Users/wangweiyang/Library/Android/sdk`.
- System Gradle `9.3.0` can evaluate the Android project when `JAVA_HOME` is set to the local JDK 17 path.
- The checked-in wrapper still cannot run because it must download Gradle `9.3.0` from `services.gradle.org`, which fails DNS resolution.
- Compile/lint-backed Gradle tasks still cannot resolve Android/Kotlin dependencies because `dl.google.com` fails DNS resolution.

No app implementation code, renderer code, WebView code, JS renderer asset, iOS file, or authoritative `Docs/` checklist file was changed in this batch.

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `java -version` | BLOCKED | Normal shell still reports `Unable to locate a Java Runtime.` |
| `./gradlew projects --no-daemon` | BLOCKED | Normal shell cannot start the wrapper because no Java runtime is on `PATH` or `JAVA_HOME`. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew projects --no-daemon` | BLOCKED | Wrapper starts with JDK 17, then fails downloading `https://services.gradle.org/distributions/gradle-9.3.0-bin.zip` with `java.net.UnknownHostException: services.gradle.org`. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew lint --no-daemon` | BLOCKED | Same wrapper distribution DNS blocker: `java.net.UnknownHostException: services.gradle.org`. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home gradle projects --no-daemon` | PASS | System Gradle evaluated `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`; `BUILD SUCCESSFUL in 33s`. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home gradle lint --no-daemon` | BLOCKED | Project evaluation starts, then `:core:checkDebugAarMetadata` fails resolving Android/Kotlin artifacts from `dl.google.com`; examples include `androidx.datastore:datastore-preferences:1.1.1`, `org.jetbrains.kotlin:kotlin-stdlib:1.9.24`, and `androidx.compose:compose-bom:2024.06.00`. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home gradle :core:testDebugUnitTest --no-daemon` | BLOCKED | `:core:compileDebugKotlin` fails on the same `dl.google.com` DNS dependency-resolution blocker. |
| `bash tools/audit_stage1_manifest.sh` | PASS | No `uses-permission`; no broad storage, notification, or default `INTERNET`; `allowBackup=false`; cleartext disabled; only `MainActivity` exported; no WebView implementation; release hardening posture present. |
| `bash tools/audit_renderer_assets.sh` | PASS | No Android `WebView`/`android.webkit`, no React Native/Flutter/Cordova runtime dependency, and no vendored JS/CSS/font renderer asset tree. |
| `bash tools/audit_rich_fixture_render.sh` | PASS | Rich fixture category, parser/render coverage, inline style, local horizontal scroll, safe fallback, remote-image privacy, and no-web-runtime checks all passed. |
| `bash tools/audit_font_scale_tiers.sh && bash tools/audit_accessibility_semantics.sh` | PASS | Four font tiers compose with font scale; accessibility semantics audit passed. |
| `bash tools/audit_parser_source_ranges.sh && bash tools/audit_save_integrity.sh && bash tools/audit_diagnostics_redaction.sh` | PASS | Parser/source-range, save-integrity, and diagnostics-redaction audits passed. |

## Current Blockers

- Wrapper-based L12 commands remain open until `services.gradle.org` is reachable or the Gradle wrapper distribution is already available in the local Gradle cache.
- Compile, lint, assemble, unit-test, and device validation gates remain open until Android/Kotlin dependency resolution from `dl.google.com` works or the required artifacts are fully cached.
- The normal shell still needs JDK 17 exposed through `JAVA_HOME` or `PATH`; setting `JAVA_HOME` explicitly works for system Gradle in this batch, but wrapper commands still need the distribution download.
- No emulator or physical device validation was attempted in this batch because the build cannot yet reach compile/assemble outputs.

## Supervisor Reconciliation Notes

The supervisor can mark Android evidence for L13 `Record validation reports under android/docs/reports/` from this report.

The supervisor can also record partial L12 progress:

- Android project evaluation with a JDK 17-backed system Gradle fallback now passes.
- Android security audit report evidence is current from `tools/audit_stage1_manifest.sh` and `tools/audit_renderer_assets.sh`.
- Android rich fixture render report evidence remains current from `tools/audit_rich_fixture_render.sh`.

Keep these L12 checklist items open from this batch:

- Run Android `./gradlew lint`.
- Run Android `./gradlew build`.
- Run Android `./gradlew :core:testDebugUnitTest`.
- Run Android `./gradlew :feature:reader:testDebugUnitTest`.
- Run Android `./gradlew :app:assembleDebug`.
- Run Android `./gradlew :app:connectedDebugAndroidTest`.
- Run Android API 27 validation.
- Run Android low-memory/small-screen profile validation.
- Run Android modern device validation.

