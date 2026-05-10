# Stage 1 Android L11/L12 Validation Refresh Batch 65 - 2026-05-06

Worker: FastMD Stage 1 Mobile Android live lane

Timestamp: 2026-05-06 12:23:57 CST

## Scope

This bounded Android-owned batch refreshed the earliest remaining Android checklist
cluster from the daily snapshot:

- L11 conditional renderer asset packaging/offline gates when JS/CSS/font rich
  renderer assets are used.
- L11 conditional WebView request-blocking gates when a local rich renderer
  WebView surface is used.
- L11 conditional renderer asset manifest/hash verification gates when
  JS/CSS/font assets are vendored.
- L12 Android Gradle validation evidence for `projects`, `lint`,
  `:core:testDebugUnitTest`, `:app:assembleDebug`, and Android-local source
  reports.

No iOS files, shared Docs checklists, or `.cron` files were edited.

## Environment

- Repository root: `/Users/wangweiyang/GitHub/fastmd`
- Android root: `/Users/wangweiyang/GitHub/fastmd/android`
- Android SDK: `sdk.dir=/Users/wangweiyang/Library/Android/sdk`
- Default `java`: blocked with `Unable to locate a Java Runtime`
- Explicit validation JDK: `/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home`
- Android Studio JBR observed: OpenJDK `21.0.6`

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `java -version` | BLOCKED | Default shell Java remains unavailable: `Unable to locate a Java Runtime`. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew projects --no-daemon` | PASS | Gradle lists root project `fastmd-android` with `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`; `BUILD SUCCESSFUL in 13s`. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew lint --no-daemon` | BLOCKED | Gradle reached `:core:extractDebugAnnotations`, then timed out resolving `com.android.tools.lint:lint-gradle:31.13.2` from `https://dl.google.com/dl/android/maven2/...`; `BUILD FAILED in 3m 19s`. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew :core:testDebugUnitTest --no-daemon` | BLOCKED | Gradle reached `:core:testDebugUnitTest`, then timed out downloading `androidx.collection:collection-ktx:1.4.0` and `androidx.concurrent:concurrent-futures:1.1.0` from Google Maven; `BUILD FAILED in 3m 19s`. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew :app:assembleDebug --no-daemon` | BLOCKED | Gradle reached `:feature:library:compileDebugKotlin`, then timed out resolving `androidx.compose.compiler:compiler:1.5.14` from Google Maven; `BUILD FAILED in 3m 20s`. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew stage1AndroidRendererAssetGates stage1AndroidPerformanceReport stage1AndroidSecurityAuditReport stage1AndroidRichFixtureRenderReport --no-daemon` | PASS | Android-local source gates passed; `BUILD SUCCESSFUL in 1m 16s`, 7 executed tasks. |

## Android-Local Gate Evidence

The passing Android-local Gradle command executed:

- `auditRendererAssets`
- `auditRendererRequestBlocking`
- `testRendererAssetAudit`
- `testRendererRequestBlockingAudit`
- `auditPerformanceReport`
- `auditSecurityReport`
- `auditRichFixtureRenderReport`

Renderer asset/request evidence:

- No Android `WebView` or `android.webkit` implementation is present.
- No React Native, Flutter, Cordova, or equivalent web runtime dependency is present.
- No vendored JS/CSS/font renderer asset tree is present; rich Mermaid/math
  blocks remain native fallback surfaces.
- Synthetic app-local JS/CSS/font renderer assets pass only with local
  SHA-256 manifest and metadata lock coverage.
- Missing, misplaced, stale, unlisted, malformed, escaping, remote,
  dangerous-scheme, WebView, and web-runtime cases fail closed.
- Request-blocking audit requires explicit policy coverage for bundled asset
  allowlisting, metadata-lock request blocking, remote/dangerous URL blocking,
  percent-encoded dangerous requests, external navigation blocking, and iframe
  blocking.

Security evidence:

- No manifest `uses-permission` declarations are present.
- No broad storage, notification, or default `INTERNET` permission is present.
- `allowBackup=false` and disabled cleartext traffic are present.
- Only the document-entry `MainActivity` is exported.
- Release build posture enables R8 minify, resource shrinking, non-debuggable
  output, and app ProGuard rules.

Rich render evidence:

- Rich fixture coverage passed for headings, inline styles, links/autolinks,
  blockquotes, unordered/ordered/task lists, tables, code fences, Mermaid/math
  native fallback cards, images, safe video HTML placeholders, footnotes,
  details/summary, generic HTML fallback, mixed CJK/English/Japanese/Korean,
  and escaped markers.
- Parser/render model coverage passed for native block kinds and inline styles.
- Reader source audit passed for native Compose render paths, local horizontal
  scroll containment for wide code/table/media surfaces, remote-image privacy
  placeholders, and no web app runtime.

## Current Blockers

The default shell Java remains unavailable, so Android validation commands need
explicit `JAVA_HOME` until the host PATH/JDK setup is fixed.

With explicit JDK 17, Gradle can start and local source gates pass, but the
Maven-backed Android validation gates still depend on `dl.google.com` artifacts
that timed out in this environment:

- `com.android.tools.lint:lint-gradle:31.13.2`
- `androidx.collection:collection-ktx:1.4.0`
- `androidx.concurrent:concurrent-futures:1.1.0`
- `androidx.compose.compiler:compiler:1.5.14`

Because these artifacts remain unresolved, the platform validation checklist
items for `lint`, `build`, unit-test gates, assemble, connected device, API 27,
small-screen/low-memory, and modern-device validation should remain open unless
the supervisor accepts previously cached or external device evidence.

## Supervisor Completion Candidates

Android evidence supports marking the Android side of these L11 conditional
items complete:

- Add local renderer packaging/offline tests if JS renderer assets are used.
  Evidence: `stage1AndroidRendererAssetGates` passed and includes
  `testRendererAssetAudit`.
- Add WebView/WKWebView request-blocking tests if local JS renderer surfaces
  are used, Android portion.
  Evidence: no Android WebView surface is present; `auditRendererRequestBlocking`
  and `testRendererRequestBlockingAudit` passed.
- Add renderer asset manifest/hash verification tests if JS/CSS/font assets are
  vendored.
  Evidence: `testRendererAssetAudit` passed manifest/hash positive and negative
  cases.
- Capture Android performance report.
  Evidence: `stage1AndroidPerformanceReport` passed.
- Capture Android security audit report.
  Evidence: `stage1AndroidSecurityAuditReport` passed.
- Capture rich fixture render report, Android portion.
  Evidence: `stage1AndroidRichFixtureRenderReport` passed.

## Changed Android Files

- `android/docs/reports/stage1-android-l11-l12-validation-refresh-batch65-20260506.md`
