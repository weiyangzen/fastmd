# Stage 1 Android L12 Lint Validation Batch 13 - 2026-05-06

## Scope

Android live lane bounded batch for the earliest still-open Android-owned L12 validation gate:

- Run Android `./gradlew lint`.

This batch did not change product source. It rechecked wrapper health, attempted the checklist-named
lint command, and captured Android-local security, renderer, and rich-fixture validation evidence that
does not require new remote dependency downloads or an attached device.

## Validation Results

All commands were run from `/Users/wangweiyang/GitHub/fastmd/android`.

| Command | Result | Evidence |
| --- | --- | --- |
| `java -version` | BLOCKED | The shell default Java runtime is unavailable through `/usr/bin/java`: `Unable to locate a Java Runtime.` |
| `which java && which gradle && gradle --version` | PASS | `gradle` is available at `/usr/local/bin/gradle` and runs as Gradle 9.3.0 on Homebrew JDK 25.0.1. Android validation commands below explicitly set JDK 17. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17 gradle projects --no-daemon` | PASS | System Gradle evaluated root project `fastmd-android` and listed `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17 ./gradlew projects --no-daemon` | PASS | Checked-in wrapper evaluated the same Android project graph successfully. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17 gradle lint --no-daemon` | BLOCKED | Gradle reached `:core:compileDebugKotlin`, then failed resolving `androidx.compose.compiler:compiler:1.5.14` from `https://dl.google.com/dl/android/maven2/...` because the connection to `dl.google.com:443` timed out. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17 ./gradlew lint --no-daemon` | BLOCKED | Wrapper reached `:core:compileDebugKotlin`, then failed on the same remote artifact: `androidx.compose.compiler:compiler:1.5.14`; `dl.google.com:443` connection timed out. |
| `bash tools/audit_stage1_manifest.sh` | PASS | No manifest permissions; no broad storage/media/notification/default `INTERNET`; `allowBackup=false`; cleartext disabled; only `MainActivity` exported; no WebView implementation; release hardening enabled. |
| `bash tools/audit_renderer_assets.sh` | PASS | No Android WebView/android.webkit implementation, no React Native/Flutter/Cordova runtime dependency, and no vendored JS/CSS/font renderer asset tree. |
| `bash tools/test_renderer_asset_audit.sh` | PASS | Native fallback, app-local hashed assets, missing/stale/misplaced/unlisted assets, remote/dangerous references, WebView marker, and React Native dependency cases behaved as expected. |
| `bash tools/audit_rich_fixture_render.sh` | PASS | Rich fixture coverage, native parser/render model kinds, native Compose renderer paths, safe Mermaid/math fallback, local horizontal scrolling constraints, and no web runtime were verified. |

## Current Blocker

`./gradlew lint` is not complete. The environment can run the wrapper and can find the Android SDK
from `local.properties`, but lint cannot pass until the Compose compiler artifact resolves from
Google Maven:

```text
Could not resolve androidx.compose.compiler:compiler:1.5.14.
Could not GET 'https://dl.google.com/dl/android/maven2/androidx/compose/compiler/compiler/1.5.14/compiler-1.5.14.pom'.
Connect to dl.google.com:443 failed: Connect timed out.
```

This is a remote dependency retrieval blocker. It is not evidence of an Android source compile error
in this batch.

## Supervisor Checklist Recommendation

Keep the Android `./gradlew lint` checklist item open. The command was attempted through the checked-in
wrapper and progressed to Kotlin compilation, but did not complete because Google Maven timed out while
resolving `androidx.compose.compiler:compiler:1.5.14`.

The supervisor can use this report as additional Android L12 evidence for:

- Wrapper health: `./gradlew projects --no-daemon` passes with JDK 17.
- Android project graph presence: `:app`, `:core`, `:feature:library`, `:feature:reader`, and
  `:feature:settings` are evaluated.
- Android security audit report: `bash tools/audit_stage1_manifest.sh` and
  `bash tools/audit_renderer_assets.sh` pass.
- Rich fixture render report: `bash tools/audit_rich_fixture_render.sh` passes.

Do not mark `./gradlew lint`, `./gradlew build`, module unit tests, `:app:assembleDebug`,
connected device tests, API 27 validation, low-memory/small-screen validation, or modern-device
validation complete from this batch.
