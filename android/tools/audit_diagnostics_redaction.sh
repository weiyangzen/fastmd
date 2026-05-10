#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIAGNOSTICS_FILE="$ROOT_DIR/core/src/main/java/com/fastmd/mobile/core/diagnostics/LocalDiagnosticsReport.kt"
POLICY_FILE="$ROOT_DIR/core/src/main/java/com/fastmd/mobile/core/diagnostics/DiagnosticsRedactionPolicy.kt"
CONTRACT_TEST="$ROOT_DIR/core/src/test/java/com/fastmd/mobile/core/contracts/CoreContractsTest.kt"
MAIN_ACTIVITY="$ROOT_DIR/app/src/main/java/com/fastmd/mobile/MainActivity.kt"
SETTINGS_SCREEN="$ROOT_DIR/feature/settings/src/main/java/com/fastmd/mobile/feature/settings/SettingsScreen.kt"

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

require_file_contains() {
  local file="$1"
  local pattern="$2"
  local description="$3"
  if ! grep -Fq "$pattern" "$file"; then
    fail "$description"
  fi
}

require_file_contains "$DIAGNOSTICS_FILE" "DiagnosticsRedactionPolicy.requireRedacted" \
  "LocalDiagnosticsReport.toRedactedText must pass through the redaction policy."
require_file_contains "$POLICY_FILE" "\"://\"" \
  "Diagnostics redaction policy must reject URI-like fragments."
require_file_contains "$POLICY_FILE" "\"/Users/\"" \
  "Diagnostics redaction policy must reject local absolute user paths."
require_file_contains "$POLICY_FILE" "\"query=\"" \
  "Diagnostics redaction policy must reject search query fields."
require_file_contains "$POLICY_FILE" "\"clipboard=\"" \
  "Diagnostics redaction policy must reject clipboard fields."
require_file_contains "$POLICY_FILE" "\"source=\"" \
  "Diagnostics redaction policy must reject document source fields."
require_file_contains "$CONTRACT_TEST" "diagnosticsRedactionPolicyRejectsSensitiveFragments" \
  "Core contract tests must cover diagnostics redaction failure cases."
require_file_contains "$MAIN_ACTIVITY" "diagnosticsReport.toRedactedText()" \
  "Android UI must only pass redacted diagnostics text to settings."
require_file_contains "$SETTINGS_SCREEN" "diagnosticsReport: String" \
  "Settings diagnostics surface must receive pre-redacted text."

redacted_block="$(
  awk '
    /fun toRedactedText\(\)/ { inBlock = 1 }
    inBlock { print }
    inBlock && /companion object/ { exit }
  ' "$DIAGNOSTICS_FILE"
)"

if printf '%s\n' "$redacted_block" | rg -n 'displayName|rawReference|query|clipboard|source|uri|path'; then
  fail "LocalDiagnosticsReport.toRedactedText must not emit sensitive field names."
fi

printf 'PASS: Android diagnostics redaction audit completed.\n'
