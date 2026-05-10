#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
audit_script="${script_dir}/audit_renderer_request_blocking.sh"

make_project() {
  local root="$1"

  mkdir -p \
    "${root}/app/src/main/java/com/fastmd/mobile" \
    "${root}/core/src/main/java/com/fastmd/mobile/core/render" \
    "${root}/core/src/test/java/com/fastmd/mobile/core/render" \
    "${root}/feature/reader/src/main/java" \
    "${root}/feature/library/src/main/java" \
    "${root}/feature/settings/src/main/java"

  write_policy_contract "$root"
  write_policy_test_contract "$root"
}

write_policy_contract() {
  local root="$1"
  local policy_file="${root}/core/src/main/java/com/fastmd/mobile/core/render/RichRendererAssetPolicy.kt"

  cat > "$policy_file" <<'KOTLIN'
package com.fastmd.mobile.core.render

object RichRendererRequestPolicy {
    val iframeKind = RichRendererRequestKind.Iframe
    fun decide() = Unit
}

enum class RichRendererRequestKind {
    Iframe,
}

enum class RichRendererRequestBlockReason {
    NetworkRequest,
    ExternalNavigation,
    JavascriptUrl,
    DataUrl,
    ContentUri,
    NonRendererFile,
}
KOTLIN
}

write_policy_test_contract() {
  local root="$1"
  local policy_test_file="${root}/core/src/test/java/com/fastmd/mobile/core/render/RichRendererAssetPolicyTest.kt"

  cat > "$policy_test_file" <<'KOTLIN'
package com.fastmd.mobile.core.render

class RichRendererAssetPolicyTest {
    fun requestPolicyAllowsOnlyBundledRendererAssets() {
        val metadataLock = "renderer-assets.lock"
    }

    fun requestPolicyBlocksRemoteAndDangerousRendererRequests() = Unit
    fun requestPolicyClassifiesPercentEncodedDangerousRendererRequests() = Unit
    fun requestPolicyBlocksExternalNavigationAndIframes() = Unit
}
KOTLIN
}

run_audit() {
  local root="$1"
  FASTMD_ANDROID_AUDIT_ROOT="$root" bash "$audit_script"
}

expect_pass() {
  local label="$1"
  local root="$2"

  if run_audit "$root" >/tmp/fastmd-renderer-request-audit-test.out 2>&1; then
    printf 'PASS: %s\n' "$label"
  else
    cat /tmp/fastmd-renderer-request-audit-test.out >&2
    printf 'FAIL: expected pass for %s\n' "$label" >&2
    exit 1
  fi
}

expect_fail() {
  local label="$1"
  local root="$2"

  if run_audit "$root" >/tmp/fastmd-renderer-request-audit-test.out 2>&1; then
    cat /tmp/fastmd-renderer-request-audit-test.out >&2
    printf 'FAIL: expected failure for %s\n' "$label" >&2
    exit 1
  else
    printf 'PASS: %s\n' "$label"
  fi
}

tmp_root="$(mktemp -d)"
trap 'rm -rf "$tmp_root" /tmp/fastmd-renderer-request-audit-test.out' EXIT

native_root="${tmp_root}/native-fallback"
make_project "$native_root"
expect_pass 'native fallback request policy and tests satisfy the gate' "$native_root"

missing_policy_root="${tmp_root}/missing-request-policy"
make_project "$missing_policy_root"
rm "${missing_policy_root}/core/src/main/java/com/fastmd/mobile/core/render/RichRendererAssetPolicy.kt"
expect_fail 'missing request policy contract fails the gate' "$missing_policy_root"

missing_test_root="${tmp_root}/missing-request-policy-tests"
make_project "$missing_test_root"
cat > "${missing_test_root}/core/src/test/java/com/fastmd/mobile/core/render/RichRendererAssetPolicyTest.kt" <<'KOTLIN'
package com.fastmd.mobile.core.render

class RichRendererAssetPolicyTest
KOTLIN
expect_fail 'missing request policy unit-test markers fail the gate' "$missing_test_root"

unrouted_webview_root="${tmp_root}/unrouted-webview"
make_project "$unrouted_webview_root"
cat > "${unrouted_webview_root}/app/src/main/java/com/fastmd/mobile/RichBlockWebView.kt" <<'KOTLIN'
package com.fastmd.mobile

class RichBlockWebView {
    val marker = "android.webkit.WebView"
}
KOTLIN
expect_fail 'WebView renderer without request interception fails the gate' "$unrouted_webview_root"

intercept_only_webview_root="${tmp_root}/intercept-only-webview"
make_project "$intercept_only_webview_root"
cat > "${intercept_only_webview_root}/app/src/main/java/com/fastmd/mobile/RichBlockWebView.kt" <<'KOTLIN'
package com.fastmd.mobile

class RichBlockWebView {
    val marker = "android.webkit.WebView"
    fun route() = RichRendererRequestPolicy.decide()
    fun shouldInterceptRequest() = Unit
}
KOTLIN
expect_fail 'WebView renderer without navigation override fails the gate' "$intercept_only_webview_root"

routed_webview_root="${tmp_root}/routed-webview"
make_project "$routed_webview_root"
cat > "${routed_webview_root}/app/src/main/java/com/fastmd/mobile/RichBlockWebView.kt" <<'KOTLIN'
package com.fastmd.mobile

import com.fastmd.mobile.core.render.RichRendererRequestKind
import com.fastmd.mobile.core.render.RichRendererRequestPolicy

class RichBlockWebView {
    val marker = "android.webkit.WebView"
    fun route() = RichRendererRequestPolicy.decide()
    fun shouldInterceptRequest() = RichRendererRequestPolicy.decide()
    fun shouldOverrideUrlLoading() = RichRendererRequestPolicy.decide()
    fun classifyIframe() = RichRendererRequestKind.Iframe
}
KOTLIN
expect_pass 'WebView renderer with policy routing and interception satisfies the gate' "$routed_webview_root"
