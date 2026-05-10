#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PARSER_FILE="$ROOT_DIR/core/src/main/java/com/fastmd/mobile/core/markdown/StructuredMarkdownParser.kt"
RENDER_MODEL_FILE="$ROOT_DIR/core/src/main/java/com/fastmd/mobile/core/render/MarkdownRenderModel.kt"
PARSER_TEST="$ROOT_DIR/core/src/test/java/com/fastmd/mobile/core/markdown/StructuredMarkdownParserTest.kt"
BLOCK_EDIT_FILE="$ROOT_DIR/core/src/main/java/com/fastmd/mobile/core/reader/BlockSourceEdit.kt"

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

require_file_contains "$PARSER_FILE" "sourceRange = SourceRange(" \
  "Parser must create a SourceRange for every rendered block."
require_file_contains "$PARSER_FILE" "startOffset = start.startOffset" \
  "Parser source ranges must start at the original source offset."
require_file_contains "$PARSER_FILE" "endOffsetExclusive = end.endOffsetExclusive" \
  "Parser source ranges must end at the original source offset."
require_file_contains "$PARSER_FILE" "startLine = start.lineNumber" \
  "Parser source ranges must preserve one-based start lines."
require_file_contains "$PARSER_FILE" "endLineInclusive = end.lineNumber" \
  "Parser source ranges must preserve inclusive end lines."
require_file_contains "$PARSER_FILE" "blocks += parsed.block.copy(ordinal = blocks.size)" \
  "Parser must assign contiguous render block ordinals."
require_file_contains "$PARSER_FILE" "sourceSlice = substring(start, offset)" \
  "Parser source line splitting must retain original line endings for source mapping."
require_file_contains "$PARSER_FILE" "MarkdownBlockId(\"\${kind.name.lowercase(Locale.ROOT)}-\${start.lineNumber}-\${sourceSlice.crc32Hex()}\")" \
  "Parser must create stable source-derived block ids."

require_file_contains "$RENDER_MODEL_FILE" "Render block ids must be stable and unique within a render model." \
  "Render model must enforce unique block ids."
require_file_contains "$RENDER_MODEL_FILE" "Render block ordinals must be contiguous and match list order." \
  "Render model must enforce contiguous ordinals."

require_file_contains "$BLOCK_EDIT_FILE" "currentSource.substring(range.startOffset, range.endOffsetExclusive)" \
  "Block editor must apply parser source ranges to exact source slices."
require_file_contains "$BLOCK_EDIT_FILE" "currentBlockSource != snapshot.originalSource" \
  "Block editor must fail closed when source ranges no longer match."

require_file_contains "$PARSER_TEST" "parserContractKeepsStableOrderedRangesForRichBlockSurface" \
  "Parser tests must cover stable ordered ranges across the rich block surface."
require_file_contains "$PARSER_TEST" "sourceRangesMapBackToExactEditableSourceSlices" \
  "Parser tests must cover exact source slice mapping for editable blocks."
require_file_contains "$PARSER_TEST" "preservesCrLfOffsetsInSourceRanges" \
  "Parser tests must cover CRLF source offsets."
require_file_contains "$PARSER_TEST" "parsesNativeBlockKindsNeededByEarlyRichMarkdownRenderer" \
  "Parser tests must cover native rich Markdown block kinds."

pass "Android parser/source-range audit completed."
