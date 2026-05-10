# Stage 1 Android L11/L12 Source Validation - 2026-05-06

## Scope

This bounded Android live-lane batch advanced Android-owned validation evidence without editing
`Docs/**`, `ios/**`, or `.cron/**`.

The batch focused on the earliest still-open Android-owned checklist area that could be advanced
in the current environment:

- L11 conditional renderer asset gates, using the Android-local Gradle task and script audit.
- L12 source-level Android performance, security, and rich fixture render report capture.
- L12 Gradle and device validation attempts, preserving exact blockers for gates that cannot pass
  in this environment.

The Android implementation remains native Kotlin with Jetpack Compose. No Android `WebView`,
`android.webkit`, React Native, Flutter, Cordova, Capacitor, remote WebView shell, or vendored
JS/CSS/font renderer asset tree is present.

## Validation Commands

All commands were run from `/Users/wangweiyang/GitHub/fastmd/android`.

| Command | Result | Notes |
| --- | --- | --- |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ./gradlew projects --no-daemon` | BLOCKED | The wrapper attempted to download `https://services.gradle.org/distributions/gradle-9.3.0-bin.zip` and failed before project evaluation with `java.net.UnknownHostException: services.gradle.org`. |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" gradle projects --no-daemon` | PASS | System Gradle resolved root project `fastmd-android` with modules `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`; `BUILD SUCCESSFUL in 3s`. |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" gradle :core:testDebugUnitTest --no-daemon` | BLOCKED | Project evaluation and Android resource setup started, then `:core:compileDebugKotlin` failed resolving Android/Kotlin artifacts from `https://dl.google.com`, including `androidx.datastore:datastore-preferences:1.1.1`; DNS reported `dl.google.com: nodename nor servname provided, or not known`. |
| `bash tools/audit_stage1_manifest.sh` | PASS | No permissions, no broad storage/notification/default `INTERNET`, `allowBackup=false`, cleartext disabled, only document-entry `MainActivity` exported, no WebView implementation, and release hardening posture is present. |
| `bash tools/audit_performance_report.sh` | PASS | Reported Android performance profiles and fixture matrix; verified source-level performance posture for IO, parser/search dispatching, stable reader blocks, remote media policy, and redacted diagnostics timing fields. |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" gradle stage1AndroidPerformanceReport --no-daemon` | PASS | Executed `auditPerformanceReport`; `BUILD SUCCESSFUL in 4s`. |
| `bash tools/audit_rich_fixture_render.sh` | PASS | Verified rich fixture coverage, parser block/inline support, native Compose render paths, local horizontal scrolling constraints, safe Mermaid/math source cards, remote image privacy placeholders, and no web app runtime. |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" gradle stage1AndroidRendererAssetGates --no-daemon` | PASS | Executed `auditRendererAssets` and `testRendererAssetAudit`; no WebView/web-runtime/assets are present, native fallback passes, and future renderer assets must be app-local, offline, hashed, and free of remote/navigation subresource forms. |
| `adb devices` | BLOCKED | `adb` is available, but no device or emulator target is attached. Output contained only `List of devices attached`. |
| `ls /Users/wangweiyang/Library/Android/sdk/system-images/android-27` | BLOCKED | No API 27 system image directory is installed at the local SDK path. |

## Android Source-Level Evidence

### Security Audit

`bash tools/audit_stage1_manifest.sh` passed with these checks:

- No `uses-permission` declarations are present.
- No broad storage, notification, or default `INTERNET` permission is present.
- Stage 1 backup posture is documented with `allowBackup=false`.
- Cleartext network traffic is disabled.
- Only the document-entry `MainActivity` is exported.
- No Android WebView implementation is present in Stage 1 main code.
- Release build type enables R8 minify, resource shrinking, non-debuggable output, and app
  ProGuard rules.

### Performance Report

`bash tools/audit_performance_report.sh` and `gradle stage1AndroidPerformanceReport --no-daemon`
passed. The audit printed these profile limits:

| Profile | Soft limit bytes |
| --- | ---: |
| WatchCompact | 262144 |
| LegacyEfficient | 1048576 |
| ModernStandard | 5242880 |
| LargeScreen | 5242880 |

The audit also printed the fixture matrix for `basic.md`, `rich-preview.md`, `long-1mb.md`,
`large-5mb.md`, `huge-table.md`, `huge-code-block.md`, `remote-image.md`, and `local-image.md`.

### Rich Fixture Render Report

`bash tools/audit_rich_fixture_render.sh` passed. The audit verified:

- Rich fixture content includes headings H1-H6, paragraphs, inline emphasis, strikethrough,
  inline code, mark/highlight, subscript, superscript, links, autolinks, email autolinks,
  blockquotes, unordered/ordered/task lists, tables, fenced code, Mermaid fallback, inline and
  block math fallback, images, safe video HTML, footnotes, details/summary, generic HTML fallback,
  mixed CJK/English/Japanese/Korean content, and escaped markers.
- Android render model and parser declare and emit the required block kinds.
- Android inline parser declares the required native inline styles and safe inline HTML mappings.
- Reader code contains native Compose render paths for Markdown blocks, local horizontal scroll for
  code/table/media surfaces, remote image privacy placeholders, and native readable source cards for
  Mermaid and block math.
- Android rich rendering remains native Kotlin/Compose without a web app runtime.

### Renderer Asset Gates

`gradle stage1AndroidRendererAssetGates --no-daemon` passed using system Gradle. The gate executed:

- `auditRendererAssets`
- `testRendererAssetAudit`

The gate confirmed the current native fallback implementation has no WebView or vendored
JS/CSS/font renderer assets. The regression audit also confirmed future renderer additions fail
unless they are app-local under `app/src/main/assets/fastmd-renderers`, include a valid SHA-256
manifest, avoid remote/protocol-relative/content URI/dangerous URL references, and do not introduce
WebView without request-blocking coverage or React Native-style runtimes.

## Blockers Preserved

- Wrapper-based Android validation remains blocked by DNS failure for `services.gradle.org`.
- Compile-backed Android validation remains blocked by dependency resolution failure for
  `dl.google.com`.
- `./gradlew lint`, `./gradlew build`, `./gradlew :core:testDebugUnitTest`,
  `./gradlew :feature:reader:testDebugUnitTest`, `./gradlew :app:assembleDebug`, and
  `./gradlew :app:connectedDebugAndroidTest` should remain open until wrapper/dependency
  resolution is available.
- Connected Android validation remains blocked because `adb devices` lists no device or emulator.
- Android API 27 validation remains blocked because no local API 27 system image is installed.
- Android low-memory/small-screen and modern-device validation remain open until suitable
  emulator/device targets are available.

## Supervisor Checklist Recommendation

The supervising session can use this Android-local report as evidence for:

- L11: Add local renderer packaging/offline tests if JS renderer assets are used.
- L11: Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.
- L11: Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.
- L12: Capture Android performance report.
- L12: Capture Android security audit report.
- L12: Capture rich fixture render report.
- L13: Record validation reports under `android/docs/reports/`.

The supervising session should keep all wrapper-backed compile, lint, build, assemble, connected
test, API 27, low-memory/small-screen, and modern-device gates open from this batch because they are
blocked by the environment constraints recorded above.
