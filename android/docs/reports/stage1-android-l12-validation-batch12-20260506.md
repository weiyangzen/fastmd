# Stage 1 Android L12 Validation Batch 12 - 2026-05-06

## Scope

Android live-lane bounded validation batch for the remaining Android-owned L12/L13 evidence surface.

This batch did not edit `Docs/Stage1_Mobile_Blueprint.md`, `Docs/todos_20260505.md`, `ios/**`, or `.cron/**`.

## Changed Android Files

- `android/docs/reports/stage1-android-l12-validation-batch12-20260506.md`

## Environment

- Working directory: `android/`
- Default shell `java -version`: blocked with `Unable to locate a Java Runtime`.
- Homebrew Gradle runtime: Gradle `9.3.0`, launcher JVM `25.0.1` from `/usr/local/Cellar/openjdk/25.0.1/libexec/openjdk.jdk/Contents/Home`.
- Android SDK path: `local.properties` points at `/Users/wangweiyang/Library/Android/sdk`.
- `adb devices`: command is available, but no device or emulator is attached.
- Google Maven reachability: direct `curl` to both `https://dl.google.com/.../compiler-1.5.14.pom` and `https://maven.google.com/.../compiler-1.5.14.pom` timed out after 20 seconds.
- Local Gradle cache: no cached `androidx.compose.compiler:compiler:1.5.14` artifact found.

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `gradle projects --no-daemon` | PASS | Project graph resolved for `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`. |
| `JAVA_HOME=/usr/local/Cellar/openjdk/25.0.1/libexec/openjdk.jdk/Contents/Home ./gradlew projects --no-daemon` | PASS | Wrapper project graph resolved for the same Android module set. |
| `JAVA_HOME=/usr/local/Cellar/openjdk/25.0.1/libexec/openjdk.jdk/Contents/Home ./gradlew lint --no-daemon` | BLOCKED | Fails at `:core:compileDebugKotlin` because Gradle cannot resolve `androidx.compose.compiler:compiler:1.5.14` from Google Maven. |
| `JAVA_HOME=/usr/local/Cellar/openjdk/25.0.1/libexec/openjdk.jdk/Contents/Home ./gradlew :core:testDebugUnitTest --offline --no-daemon` | BLOCKED | Confirms no cached `androidx.compose.compiler:compiler:1.5.14` is available for offline mode. |
| `bash tools/audit_stage1_manifest.sh` | PASS | Manifest audit reports no broad storage/media/notification/default `INTERNET` permissions, `allowBackup=false`, cleartext disabled, constrained exported component scope, no WebView implementation, and release hardening enabled. |
| `bash tools/audit_renderer_assets.sh` | PASS | No Android WebView or web-runtime dependency is present; no vendored JS/CSS/font renderer asset tree is present; native fallback paths are used. |
| `bash tools/audit_performance_report.sh` | PASS | Performance profile limits and fixture size matrix emitted; audit completed. |
| `bash tools/audit_rich_fixture_render.sh` | PASS | Rich fixture coverage, parser/render model coverage, native Compose paths, wide-surface containment, remote image privacy, Mermaid/math fallback cards, and no web-runtime posture all passed. |
| `JAVA_HOME=/usr/local/Cellar/openjdk/25.0.1/libexec/openjdk.jdk/Contents/Home ./gradlew stage1AndroidPerformanceReport stage1AndroidSecurityAuditReport stage1AndroidRichFixtureRenderReport --no-daemon` | PASS | Gradle-exposed Android performance, security, and rich fixture report tasks completed successfully. |
| `adb devices` | BLOCKED for device validation | `adb` runs, but the device list is empty. |

## Blocker Details

Wrapper-based Gradle commands can now run when `JAVA_HOME` is explicitly set to the Homebrew JDK. The remaining compile-backed gate blocker is Google Maven artifact resolution:

```text
Execution failed for task ':core:compileDebugKotlin'.
Could not resolve androidx.compose.compiler:compiler:1.5.14.
Could not GET 'https://dl.google.com/dl/android/maven2/androidx/compose/compiler/compiler/1.5.14/compiler-1.5.14.pom'.
Connect to dl.google.com:443 failed: Connect timed out
```

Offline mode confirms the required Compose compiler artifact is not cached locally:

```text
No cached version of androidx.compose.compiler:compiler:1.5.14 available for offline mode.
```

Device-backed Android validation remains blocked because no emulator or physical Android device is attached:

```text
List of devices attached
```

## Supervisor Checklist Candidates

The supervisor can consider these Android-owned items complete, with this report as additional evidence:

- L12: Capture Android performance report.
  - Evidence: `bash tools/audit_performance_report.sh` passed; `./gradlew stage1AndroidPerformanceReport` passed with explicit `JAVA_HOME`.
- L12: Capture Android security audit report.
  - Evidence: `bash tools/audit_stage1_manifest.sh` passed; `bash tools/audit_renderer_assets.sh` passed; `./gradlew stage1AndroidSecurityAuditReport` passed with explicit `JAVA_HOME`.
- L12: Capture rich fixture render report.
  - Evidence: `bash tools/audit_rich_fixture_render.sh` passed; `./gradlew stage1AndroidRichFixtureRenderReport` passed with explicit `JAVA_HOME`.
- L13: Record validation reports under `android/docs/reports/`.
  - Evidence: this report.

Keep these Android L12 gates open:

- Run Android `./gradlew lint`.
- Run Android `./gradlew build`.
- Run Android `./gradlew :core:testDebugUnitTest`.
- Run Android `./gradlew :feature:reader:testDebugUnitTest`.
- Run Android `./gradlew :app:assembleDebug`.
- Run Android `./gradlew :app:connectedDebugAndroidTest`.
- Run Android API 27 validation.
- Run Android low-memory/small-screen profile validation.
- Run Android modern device validation.

Compile-backed gates remain open until Google Maven is reachable or `androidx.compose.compiler:compiler:1.5.14` is otherwise present in the local Gradle cache. Device-backed gates remain open until API 27 and modern Android targets are attached or running.
