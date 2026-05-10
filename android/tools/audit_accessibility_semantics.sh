#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
READER_SCREEN="$ROOT_DIR/feature/reader/src/main/java/com/fastmd/mobile/feature/reader/ReaderScreen.kt"
MAIN_ACTIVITY="$ROOT_DIR/app/src/main/java/com/fastmd/mobile/MainActivity.kt"

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

icon_button_errors="$(
  find "$ROOT_DIR/app/src/main/java" "$ROOT_DIR/feature" -type f -name '*.kt' -print0 |
    xargs -0 awk '
      /IconButton[[:space:]]*\(/ {
        inIconButton = 1
        startLine = FNR
        foundDescription = ($0 ~ /contentDescription/)
        opens = gsub(/\(/, "(")
        closes = gsub(/\)/, ")")
        depth = opens - closes
        next
      }
      inIconButton {
        if ($0 ~ /contentDescription/) {
          foundDescription = 1
        }
        opens = gsub(/\(/, "(")
        closes = gsub(/\)/, ")")
        depth += opens - closes
        if (depth <= 0) {
          if (!foundDescription) {
            printf "%s:%d: IconButton missing contentDescription evidence\n", FILENAME, startLine
          }
          inIconButton = 0
        }
      }
    '
)"

if [ -n "$icon_button_errors" ]; then
  printf '%s\n' "$icon_button_errors" >&2
  fail "Every Android icon-only control must expose a contentDescription."
fi

require_file_contains "$READER_SCREEN" "heading()" \
  "Reader screen must mark major titles as accessibility headings."
require_file_contains "$READER_SCREEN" "LiveRegionMode.Polite" \
  "Reader search result count must use a polite live region."
require_file_contains "$READER_SCREEN" "Search results:" \
  "Reader search result count must expose an explicit TalkBack summary."
require_file_contains "$READER_SCREEN" "LiveRegionMode.Assertive" \
  "Dirty edit and save warnings must use assertive live regions."
require_file_contains "$READER_SCREEN" "paneTitle = \"Full source editor\"" \
  "Full source editor must expose an accessibility pane title."
require_file_contains "$READER_SCREEN" "paneTitle = \"Block source editor\"" \
  "Block source editor must expose an accessibility pane title."
require_file_contains "$MAIN_ACTIVITY" "paneTitle = \"Discard unsaved changes\"" \
  "Dirty discard dialog must expose an accessibility pane title."

printf 'PASS: Android accessibility semantics audit completed.\n'
