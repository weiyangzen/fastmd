# Stage 1 Android L12 Live Validation Batch 15 - 2026-05-06

## Scope

Android live-lane bounded batch for the earliest still-open Android-owned Stage 1
validation surface. This batch only wrote Android-local evidence under
`android/docs/reports/`.

No changes were made to `Docs/Stage1_Mobile_Blueprint.md`,
`Docs/todos_20260505.md`, `ios/**`, or `.cron/**`.

## Changed Android Files

- `android/docs/reports/stage1-android-l12-live-validation-batch15-20260506.md`

## Environment

- Working directory: `android/`
- Default shell `java -version`: blocked because macOS could not locate a Java runtime.
- Explicit validation JVM:
  `/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home`
- Explicit JVM version: OpenJDK `17.0.17` Homebrew build.
- Android SDK: `local.properties` points at
  `/Users/wangweiyang/Library/Android/sdk`.
- Device state: `adb devices` ran successfully, but no Android emulator or physical
  device was attached.

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `java -version` | BLOCKED | Default shell environment reported `Unable to locate a Java Runtime.` |
| `/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home/bin/java -version` | PASS | Reported OpenJDK `17.0.17`. |
| `adb devices` | BLOCKED for device validation | Command was available, but returned an empty device list. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew projects --no-daemon` | PASS | Gradle evaluated the project graph and listed `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew lint --no-daemon` | BLOCKED | Reached `:core:extractDebugAnnotations`, then timed out resolving `com.android.tools.lint:lint-gradle:31.13.2` from Google Maven. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew :core:testDebugUnitTest --no-daemon` | BLOCKED | Reached `:core:testDebugUnitTest`, then timed out downloading AndroidX runtime JARs from Google Maven. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew stage1AndroidRendererAssetGates stage1AndroidPerformanceReport stage1AndroidSecurityAuditReport stage1AndroidRichFixtureRenderReport --no-daemon` | PASS | Script-backed Gradle gates completed successfully for renderer asset packaging/offline checks, performance posture, security posture, and rich fixture render coverage. |

## Gradle Projects Evidence

`./gradlew projects` produced this Android module graph with JDK 17 supplied:

```text
Root project 'fastmd-android'
+--- Project ':app'
+--- Project ':core'
\--- Project ':feature'
     +--- Project ':feature:library'
     +--- Project ':feature:reader'
     \--- Project ':feature:settings'
```

## Blocker Details

The default shell still cannot locate a Java runtime:

```text
The operation couldn't be completed. Unable to locate a Java Runtime.
```

The explicit JDK 17 path works, so compile-backed Gradle gates were attempted with
`JAVA_HOME` set. The `lint` gate remains open because Android lint's Gradle
artifact could not be fetched:

```text
Execution failed for task ':core:extractDebugAnnotations'.
Could not resolve com.android.tools.lint:lint-gradle:31.13.2.
Could not GET 'https://dl.google.com/dl/android/maven2/com/android/tools/lint/lint-gradle/31.13.2/lint-gradle-31.13.2.pom'.
Connect to dl.google.com:443 failed: Connect timed out
```

The `:core:testDebugUnitTest` gate remains open because AndroidX runtime test
classpath artifacts could not be fetched:

```text
Execution failed for task ':core:testDebugUnitTest'.
Could not download collection-ktx-1.4.0.jar.
Could not download concurrent-futures-1.1.0.jar.
Connect to dl.google.com:443 failed: Connect timed out
```

Device-backed gates remain open because `adb devices` returned no attached target:

```text
List of devices attached
```

## Script-Backed Gradle Report Evidence

The combined script-backed Gradle report command passed:

- Renderer asset gates:
  - No Android `WebView` or `android.webkit` implementation is present.
  - No React Native, Flutter, Cordova, or equivalent web runtime dependency is present.
  - No vendored JS/CSS/font renderer asset tree is present; rich blocks use native fallback paths.
  - Regression cases pass for app-local SHA-256 assets and fail closed for missing manifests,
    misplaced assets, remote subresources, content URIs, protocol-relative URLs,
    uppercase dangerous URLs, external navigation APIs, stale manifests, unlisted assets,
    escaping manifest paths, WebView implementation markers, and React Native runtime markers.
- Performance report:
  - Watch Compact, Legacy Efficient, Modern Standard, and Large Screen profile limits were listed.
  - Fixture size matrix was printed for core Stage 1 Markdown fixtures.
  - Source-level performance posture audit completed.
- Security report:
  - No `uses-permission` declarations are present.
  - No broad storage, notification, or default `INTERNET` permission is present.
  - `allowBackup=false` and cleartext-disabled posture are documented in the manifest.
  - Only the document-entry `MainActivity` is exported.
  - Release build type enables minify, resource shrinking, non-debuggable output, and app ProGuard rules.
- Rich fixture render report:
  - Rich fixture coverage passed for headings, inline styles, links/autolinks, blockquote,
    lists, task lists, tables, fenced code, Mermaid fallback, math fallback, images,
    media placeholders, footnotes, details/summary fallback, generic HTML fallback,
    CJK/mixed-language content, escaped markers, parser/render model block kinds,
    native Compose reader paths, wide-surface containment, remote-image privacy placeholders,
    and absence of WebView/web-runtime rendering.

## Supervisor Checklist Candidates

The supervisor can consider this Android-owned item complete with this report as
evidence:

- L12: Capture Android performance report.
  - Evidence: this report records a passing
    `stage1AndroidPerformanceReport` run via the combined script-backed Gradle report command.
- L12: Capture Android security audit report.
  - Evidence: this report records a passing
    `stage1AndroidSecurityAuditReport` run via the combined script-backed Gradle report command.
- L12: Capture rich fixture render report.
  - Evidence: this report records a passing
    `stage1AndroidRichFixtureRenderReport` run via the combined script-backed Gradle report command.
- L13: Record validation reports under `android/docs/reports/`.
  - Evidence: this Android-local report.

Keep these Android-owned validation items open:

- L12: Run Android `./gradlew lint`.
  - Blocker: Google Maven timeout resolving `com.android.tools.lint:lint-gradle:31.13.2`.
- L12: Run Android `./gradlew build`.
  - Not attempted in this batch after compile/test classpath resolution timed out.
- L12: Run Android `./gradlew :core:testDebugUnitTest`.
  - Blocker: Google Maven timeout downloading AndroidX runtime JARs.
- L12: Run Android `./gradlew :feature:reader:testDebugUnitTest`.
  - Not attempted in this batch after `:core:testDebugUnitTest` dependency resolution timed out.
- L12: Run Android `./gradlew :app:assembleDebug`.
  - Not attempted in this batch after compile/test classpath resolution timed out.
- L12: Run Android `./gradlew :app:connectedDebugAndroidTest`.
  - Blocker: no attached emulator or physical Android device.
- L12: Run Android API 27 validation.
  - Blocker: no attached/running API 27 target.
- L12: Run Android low-memory/small-screen profile validation.
  - Blocker: no attached/running small-screen or constrained-memory Android target.
- L12: Run Android modern device validation.
  - Blocker: no attached/running modern Android target.
