# Stage 1 Android L11/L12 Renderer And Validation Batch - 2026-05-06

## Scope

Android live-lane bounded batch for the earliest still-open Android-owned checklist
cluster:

- L11 renderer asset packaging/offline tests when JS renderer assets are used.
- L11 WebView request-blocking tests when local JS renderer surfaces are used.
- L11 renderer asset manifest/hash verification tests when JS/CSS/font assets are
  vendored.
- L12 Android Gradle validation retry with the current local environment.

No `ios/**`, shared `Docs/**`, or `.cron/**` files were edited.

## Implementation Change

Updated `settings.gradle.kts` so `mavenCentral()` is checked before `google()` for
regular dependency resolution. This keeps Android/Google-only artifacts available
through Google Maven while avoiding Google Maven timeouts for standard artifacts
such as JUnit and kotlinx-coroutines test libraries when Maven Central can serve
them directly.

Plugin resolution remains unchanged.

## Changed Android Files

- `android/settings.gradle.kts`
- `android/docs/reports/stage1-android-l11-l12-renderer-validation-batch-20260506.md`

## Validation Results

All commands were run from `/Users/wangweiyang/GitHub/fastmd/android` unless noted.
Gradle commands used:

```text
JAVA_HOME=/Applications/Android Studio.app/Contents/jbr/Contents/Home
```

| Command | Result | Evidence |
| --- | --- | --- |
| `java -version` | BLOCKED | Shell default Java runtime is unavailable: `Unable to locate a Java Runtime.` |
| `ls -l gradlew gradle/wrapper/gradle-wrapper.properties local.properties` | PASS | Android Gradle wrapper, wrapper properties, and `local.properties` are present. |
| `find /Applications/Android Studio.app/Contents/jbr/Contents/Home -maxdepth 2 -type f -name java` | PASS | Android Studio bundled JBR exists at `.../Contents/Home/bin/java`. |
| `adb devices` | BLOCKED | `adb` is installed, but no attached devices or running emulators are listed. |
| `./gradlew projects --no-daemon` | PASS | Wrapper-backed Gradle evaluated root project `fastmd-android` and listed `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`. |
| `./gradlew lint --no-daemon` | BLOCKED | Gradle reached `:core:extractDebugAnnotations`, then timed out fetching `com.android.tools.lint:lint-gradle:31.13.2` from `https://dl.google.com/dl/android/maven2/...`. |
| `./gradlew :core:testDebugUnitTest --no-daemon` before repository-order change | BLOCKED | Gradle reached `:core:generateDebugUnitTestStubRFile`, then timed out asking Google Maven for `junit:junit:4.13.2` and `org.jetbrains.kotlinx:kotlinx-coroutines-test:1.8.1`. |
| `./gradlew :core:testDebugUnitTest --no-daemon` after repository-order change | BLOCKED | JUnit and kotlinx test artifacts resolved, but the gate still timed out fetching AndroidX runtime jars `androidx.collection:collection-ktx:1.4.0` and `androidx.concurrent:concurrent-futures:1.1.0` from Google Maven. |
| `./gradlew stage1AndroidRendererAssetGates --no-daemon` | PASS | Ran `:auditRendererAssets` and `:testRendererAssetAudit`; no Android WebView/android.webkit implementation, no React Native/Flutter/Cordova runtime, no vendored renderer asset tree, and all synthetic renderer asset manifest/hash/offline/dangerous-reference regression cases passed. |
| `git diff --check -- android` from repo root | PASS | No whitespace errors were reported. |

## Renderer Gate Evidence

`stage1AndroidRendererAssetGates` confirmed:

- Native fallback passes when no vendored JS/CSS/font renderer asset tree exists.
- Any future renderer asset tree must be app-local under
  `app/src/main/assets/fastmd-renderers/`.
- Renderer assets require a SHA-256 manifest.
- Missing, stale, escaping, or incomplete manifests fail the audit.
- Remote subresources, protocol-relative URLs, `javascript:`, `data:`,
  `content:`, and external navigation API references fail the audit.
- A WebView marker fails the audit until a separate request-blocking gate exists.
- React Native/web-shell runtime dependencies fail the audit.

## Blockers Preserved

- L12 `./gradlew lint` remains open because Google Maven timed out resolving
  `com.android.tools.lint:lint-gradle:31.13.2`.
- L12 `./gradlew :core:testDebugUnitTest` remains open because Google Maven timed
  out resolving AndroidX runtime jars.
- L12 `./gradlew build`, `./gradlew :feature:reader:testDebugUnitTest`,
  `./gradlew :app:assembleDebug`, and `./gradlew :app:connectedDebugAndroidTest`
  remain open behind the same Google Maven/device availability blockers.
- Android API 27, low-memory/small-screen, and modern-device validation remain open
  because `adb devices` lists no attached target.

## Supervisor Checklist Recommendation

The supervising session can use this report as Android-lane evidence for:

- L11: Add local renderer packaging/offline tests if JS renderer assets are used.
- L11: Add WebView/WKWebView request-blocking tests if local JS renderer surfaces
  are used.
- L11: Add renderer asset manifest/hash verification tests if JS/CSS/font assets
  are vendored.
- L13: Record validation reports under `android/docs/reports/`.

Do not mark Android lint, build, unit-test, assemble, connected-device, API 27,
low-memory/small-screen, or modern-device validation complete from this batch.
