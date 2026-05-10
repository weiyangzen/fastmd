#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOADER_FILE="$ROOT_DIR/app/src/main/java/com/fastmd/mobile/document/AndroidDocumentEntry.kt"
MAIN_ACTIVITY="$ROOT_DIR/app/src/main/java/com/fastmd/mobile/MainActivity.kt"
CODEC_FILE="$ROOT_DIR/core/src/main/java/com/fastmd/mobile/core/document/MarkdownSourceCodec.kt"
SAVE_TEST="$ROOT_DIR/core/src/test/java/com/fastmd/mobile/core/document/MarkdownSaveIntegrityTest.kt"

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

require_file_contains "$CODEC_FILE" "fun prepareForSave" \
  "Core codec must expose a pure save preparation contract."
require_file_contains "$CODEC_FILE" "trimLeadingUtf8Bom()" \
  "Save preparation must trim any accidental leading BOM before encoding."
require_file_contains "$CODEC_FILE" "MarkdownEncoding.Utf8Bom -> UTF8_BOM + body" \
  "UTF-8 BOM saves must add exactly one encoded BOM."
require_file_contains "$CODEC_FILE" "MarkdownLineEnding.Crlf" \
  "Save preparation must preserve loaded CRLF line-ending posture."
require_file_contains "$CODEC_FILE" "MarkdownLineEnding.Lf" \
  "Save preparation must preserve loaded LF line-ending posture."

require_file_contains "$SAVE_TEST" "utf8BomSaveDoesNotDuplicateLeadingBom" \
  "Save integrity tests must cover duplicate BOM prevention."
require_file_contains "$SAVE_TEST" "savePreservesLoadedCrlfLineEndings" \
  "Save integrity tests must cover CRLF preservation."
require_file_contains "$SAVE_TEST" "savePreservesLoadedLfLineEndings" \
  "Save integrity tests must cover LF preservation."
require_file_contains "$SAVE_TEST" "saveLeavesMixedLineEndingsUnchanged" \
  "Save integrity tests must cover mixed line-ending preservation."

require_file_contains "$LOADER_FILE" "MarkdownSourceCodec.prepareForSave" \
  "Android loader must use the shared save preparation contract."
require_file_contains "$LOADER_FILE" "val currentSource = readCurrentDocumentSource(handle)" \
  "Android save must reread the backing document before writing."
require_file_contains "$LOADER_FILE" "currentSource != originalSource" \
  "Android save must compare the backing source against the loaded source."
require_file_contains "$LOADER_FILE" "FastMdErrorCode.SaveExternalMutationConflict" \
  "Android save must fail with an external mutation conflict before overwriting."
require_file_contains "$LOADER_FILE" "openOutputStream(uri, \"wt\")" \
  "Android SAF save must use a writable truncate stream only after conflict checks."
require_file_contains "$LOADER_FILE" "output.write(preparedSave.bytes)" \
  "Android SAF save must write the fully prepared byte array."
require_file_contains "$LOADER_FILE" "file.writeBytes(preparedSave.bytes)" \
  "Android file save must write the fully prepared byte array."
require_file_contains "$LOADER_FILE" "FastMdErrorCode.SaveIoFailure" \
  "Android save must surface write failures as save IO failures."

mutation_line="$(grep -n 'currentSource != originalSource' "$LOADER_FILE" | head -1 | cut -d: -f1)"
open_line="$(grep -n 'openOutputStream(uri, "wt")' "$LOADER_FILE" | head -1 | cut -d: -f1)"
if [ -z "$mutation_line" ] || [ -z "$open_line" ] || [ "$mutation_line" -ge "$open_line" ]; then
  fail "External mutation check must happen before opening the output stream."
fi

require_file_contains "$MAIN_ACTIVITY" "restoreFailedSourceSave" \
  "Source save failure must restore the dirty draft instead of replacing it with an error screen."
require_file_contains "$MAIN_ACTIVITY" "restoreFailedBlockSave" \
  "Block save failure must restore the dirty draft instead of replacing it with an error screen."
require_file_contains "$MAIN_ACTIVITY" "persistRecoveryDraft()" \
  "Save failure paths must refresh app-private recovery drafts."

pass "Android save integrity audit completed."
