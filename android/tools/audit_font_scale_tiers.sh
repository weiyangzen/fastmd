#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FONT_TIER_FILE="$ROOT_DIR/core/src/main/java/com/fastmd/mobile/core/reader/FontTier.kt"
READER_SCREEN="$ROOT_DIR/feature/reader/src/main/java/com/fastmd/mobile/feature/reader/ReaderScreen.kt"
CONTRACT_TEST="$ROOT_DIR/core/src/test/java/com/fastmd/mobile/core/contracts/CoreContractsTest.kt"

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

pass() {
  printf 'PASS: %s\n' "$1"
}

require_file_contains() {
  local file="$1"
  local pattern="$2"
  local description="$3"
  if ! grep -Fq "$pattern" "$file"; then
    fail "$description"
  fi
}

require_file_contains "$FONT_TIER_FILE" "Compact(bodySp = 14, codeSp = 13, lineHeightMultiplier = 1.48f)" \
  "Compact font tier must match the Stage 1 Android 14sp body contract."
require_file_contains "$FONT_TIER_FILE" "Default(bodySp = 16, codeSp = 15, lineHeightMultiplier = 1.52f)" \
  "Default font tier must match the Stage 1 Android 16sp body contract."
require_file_contains "$FONT_TIER_FILE" "Large(bodySp = 18, codeSp = 17, lineHeightMultiplier = 1.56f)" \
  "Large font tier must match the Stage 1 Android 18sp body contract."
require_file_contains "$FONT_TIER_FILE" "Reader(bodySp = 21, codeSp = 19, lineHeightMultiplier = 1.60f)" \
  "Reader font tier must match the Stage 1 Android 21sp body contract."

require_file_contains "$READER_SCREEN" "private fun TextStyle.withFontTier" \
  "Reader text must use the central Android font-tier helper."
require_file_contains "$READER_SCREEN" "fontSize = scaledSp.sp" \
  "Android font tiers must emit scalable sp text units instead of dp or px."
require_file_contains "$READER_SCREEN" "lineHeight = (scaledSp * fontTier.lineHeightMultiplier).sp" \
  "Android font-tier line heights must remain scalable sp text units."
require_file_contains "$CONTRACT_TEST" "fontTierContractKeepsSystemFontScaleComposable" \
  "Core contracts must document sampled Android fontScale behavior for all four tiers."

if rg -n 'LocalDensity|fontScale[[:space:]]*=|TextUnit|fontSize[[:space:]]*=[^,)]*\.dp|lineHeight[[:space:]]*=[^,)]*\.dp' \
  "$ROOT_DIR/app/src/main/java" \
  "$ROOT_DIR/core/src/main/java" \
  "$ROOT_DIR/feature" \
  "$ROOT_DIR/core/src/test/java"; then
  fail "Android source must not neutralize system font scale or express text size/line height in dp."
fi

matrix="$(
  perl -ne '
    if (/^\s*(Compact|Default|Large|Reader)\(bodySp = ([0-9]+), codeSp = ([0-9]+), lineHeightMultiplier = ([0-9.]+)f\)/) {
      for my $scale (0.85, 1.0, 1.3, 2.0) {
        my $body = $2 * $scale;
        my $code = $3 * $scale;
        my $line = $body * $4;
        printf "%s fontScale %.2f body %.2fsp code %.2fsp lineHeight %.2fsp\n", $1, $scale, $body, $code, $line;
      }
    }
  ' "$FONT_TIER_FILE"
)"

if [ "$(printf '%s\n' "$matrix" | sed '/^$/d' | wc -l | tr -d ' ')" != "16" ]; then
  fail "Expected a 4-tier by 4-fontScale validation matrix."
fi

printf '%s\n' "$matrix"
pass "Android fontScale tier audit completed."
