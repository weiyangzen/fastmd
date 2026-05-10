# FastMD Stage 1 Android L12 Validation Batch 61

Date: 2026-05-06
Worker: Android live lane
Scope: Android-owned validation evidence only.

## Batch Selection

The daily snapshot shows L0-L10 complete and the earliest remaining Android-owned work in L11/L12.
This batch targeted the earliest concrete Android platform validation gates that can be advanced without touching iOS or the shared Docs checklist.

No app implementation files were changed in this batch. Evidence is recorded here for the supervising session to reconcile.

## Gradle/JDK Validation

Command:

```text
./gradlew projects
```

Result: Blocked.

Observed output:

```text
The operation couldn't be completed. Unable to locate a Java Runtime.
Please visit http://www.java.com for information on installing Java.
```

Environment probe:

```text
java -version
```

Result: Blocked with the same missing Java Runtime message.

Local Android SDK configuration is present:

```text
sdk.dir=/Users/wangweiyang/Library/Android/sdk
```

Gradle wrapper configuration is present:

```text
distributionUrl=https\://services.gradle.org/distributions/gradle-9.3.0-bin.zip
```

Conclusion: Android wrapper tasks remain open until a Java 17 runtime is available to the shell environment.
This blocks `./gradlew lint`, `./gradlew build`, `:core:testDebugUnitTest`, `:feature:reader:testDebugUnitTest`, `:app:assembleDebug`, and connected Android tests.

## Shell Audits

Command:

```text
bash ./tools/audit_stage1_manifest.sh
```

Result: Pass.

Evidence summary:

```text
PASS: No uses-permission declarations are present.
PASS: No broad storage, notification, or default INTERNET permission is present.
PASS: App manifest documents Stage 1 backup posture with allowBackup=false.
PASS: App manifest disables cleartext network traffic.
PASS: Only the document-entry MainActivity is exported.
PASS: No Android WebView implementation is present in Stage 1 main code.
PASS: Release build type enables R8 minify, resource shrinking, non-debuggable output, and app ProGuard rules.
```

Command:

```text
./tools/audit_renderer_assets.sh
```

Result: Pass.

Evidence summary:

```text
PASS: No Android WebView or android.webkit implementation is present.
PASS: No React Native, Flutter, Cordova, or equivalent web runtime dependency is present.
PASS: No vendored JS/CSS/font renderer asset tree is present; Android rich blocks use native fallback paths.
```

Command:

```text
./tools/audit_renderer_request_blocking.sh
```

Result: Pass.

Evidence summary:

```text
PASS: Renderer request policy is a first-class Android core contract.
PASS: Renderer request policy has an explicit iframe request class.
PASS: Renderer request policy has an explicit network-request block reason.
PASS: Renderer request policy has an explicit external-navigation block reason.
PASS: Renderer request policy has an explicit javascript: URL block reason.
PASS: Renderer request policy has an explicit data: URL block reason.
PASS: Renderer request policy has an explicit content URI block reason.
PASS: Renderer request policy has an explicit non-renderer-file block reason.
PASS: Unit tests cover allowlisting of bundled Android renderer assets.
PASS: Unit tests cover blocking renderer metadata lock file requests.
PASS: Unit tests cover remote and dangerous renderer request blocking.
PASS: Unit tests cover percent-encoded dangerous renderer requests.
PASS: Unit tests cover external navigation and iframe blocking.
PASS: No Android WebView or android.webkit implementation is present; rich Markdown uses native fallback surfaces.
```

Command:

```text
bash ./tools/audit_rich_fixture_render.sh
```

Result: Pass.

Evidence summary:

```text
PASS: Rich fixture includes H1-H6 heading coverage.
PASS: Rich fixture includes bold inline coverage.
PASS: Rich fixture includes italic inline coverage.
PASS: Rich fixture includes bold-italic inline coverage.
PASS: Rich fixture includes strikethrough inline coverage.
PASS: Rich fixture includes inline code coverage.
PASS: Rich fixture includes mark/highlight inline HTML coverage.
PASS: Rich fixture includes subscript inline HTML coverage.
PASS: Rich fixture includes superscript inline HTML coverage.
PASS: Rich fixture includes Markdown link coverage.
PASS: Rich fixture includes autolink coverage.
PASS: Rich fixture includes email autolink coverage.
PASS: Rich fixture includes blockquote coverage.
PASS: Rich fixture includes unordered list coverage.
PASS: Rich fixture includes ordered list coverage.
PASS: Rich fixture includes task list coverage.
PASS: Rich fixture includes table coverage.
PASS: Rich fixture includes fenced code coverage.
PASS: Rich fixture includes Mermaid fallback coverage.
PASS: Rich fixture includes inline math coverage.
PASS: Rich fixture includes block math coverage.
PASS: Rich fixture includes image coverage.
PASS: Rich fixture includes safe video HTML coverage.
PASS: Rich fixture includes footnote definition coverage.
PASS: Rich fixture includes details/summary coverage.
PASS: Rich fixture includes generic HTML fallback coverage.
PASS: Rich fixture includes mixed CJK/English/Japanese/Korean coverage.
PASS: Rich fixture includes escaped marker coverage.
PASS: Reader constrains wide code/table/media surfaces with local horizontal scroll.
PASS: Reader preserves remote image privacy with a placeholder.
PASS: Reader renders Mermaid as a native readable source card.
PASS: Reader renders block math as a native readable source card.
PASS: Android rich rendering remains native Kotlin/Compose without a web app runtime.
Android rich fixture render audit completed.
```

Command:

```text
bash ./tools/audit_performance_report.sh
```

Result: Pass.

Evidence summary:

```text
Android performance profile limits:
  WatchCompact softLimitBytes=262144
  LegacyEfficient softLimitBytes=1048576
  ModernStandard softLimitBytes=5242880
  LargeScreen softLimitBytes=5242880
Android fixture size matrix:
  basic.md bytes=124 lines=7
  rich-preview.md bytes=5050 lines=246
  long-1mb.md bytes=328 lines=10
  large-5mb.md bytes=296 lines=8
  huge-table.md bytes=333 lines=9
  huge-code-block.md bytes=176 lines=11
  remote-image.md bytes=148 lines=5
  local-image.md bytes=142 lines=5
PASS: Android performance report audit completed.
```

Command:

```text
bash ./tools/audit_save_integrity.sh
```

Result: Pass.

Evidence summary:

```text
PASS: Android save integrity audit completed.
```

## Notes

The direct invocations below are blocked by file mode, not by audit logic:

```text
./tools/audit_stage1_manifest.sh
./tools/audit_rich_fixture_render.sh
```

Both pass when invoked through `bash`. This batch did not change executable bits.

## Blueprint Reconciliation Candidates

The supervising session can use this report as evidence for:

- L12: Capture Android security audit report.
- L12: Capture Android performance report.
- L12: Capture rich fixture render report.
- L13: Record validation reports under `android/docs/reports/`.

The following must remain open:

- L12: Run Android `./gradlew lint`.
- L12: Run Android `./gradlew build`.
- L12: Run Android `./gradlew :core:testDebugUnitTest`.
- L12: Run Android `./gradlew :feature:reader:testDebugUnitTest`.
- L12: Run Android `./gradlew :app:assembleDebug`.
- L12: Run Android `./gradlew :app:connectedDebugAndroidTest`.
- L12: Android API 27 validation.
- L12: Android low-memory/small-screen profile validation.
- L12: Android modern device validation.

Blocker: shell-visible Java 17 runtime is missing, so Gradle cannot start.
