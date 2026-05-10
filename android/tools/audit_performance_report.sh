#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MAIN_ACTIVITY="$ROOT_DIR/app/src/main/java/com/fastmd/mobile/MainActivity.kt"
DOCUMENT_ENTRY="$ROOT_DIR/app/src/main/java/com/fastmd/mobile/document/AndroidDocumentEntry.kt"
RECOVERY_STORE="$ROOT_DIR/app/src/main/java/com/fastmd/mobile/recovery/AndroidRecoveryDraftStore.kt"
READER_SCREEN="$ROOT_DIR/feature/reader/src/main/java/com/fastmd/mobile/feature/reader/ReaderScreen.kt"
PERFORMANCE_PROFILE="$ROOT_DIR/core/src/main/java/com/fastmd/mobile/core/performance/AndroidPerformanceProfile.kt"
DIAGNOSTICS_REPORT="$ROOT_DIR/core/src/main/java/com/fastmd/mobile/core/diagnostics/LocalDiagnosticsReport.kt"
FIXTURE_DIR="$ROOT_DIR/test-fixtures/markdown"

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

require_slurp_match() {
  local file="$1"
  local pattern="$2"
  local description="$3"
  if ! perl -0ne "exit 0 if /$pattern/s; exit 1" "$file"; then
    fail "$description"
  fi
}

require_file_contains "$DOCUMENT_ENTRY" "withContext(Dispatchers.IO)" \
  "Document load/save IO must be dispatched away from the main thread."
require_file_contains "$RECOVERY_STORE" "withContext(Dispatchers.IO)" \
  "Recovery draft reads and writes must be dispatched away from the main thread."
require_slurp_match "$MAIN_ACTIVITY" "withContext\\(Dispatchers\\.Default\\)\\s*\\{\\s*StructuredMarkdownParser\\.parse" \
  "Markdown parsing must run on Dispatchers.Default from Android entry flows."
require_file_contains "$MAIN_ACTIVITY" "private var searchJob: Job? = null" \
  "Reader search must use a cancellable background job for large documents."
require_file_contains "$MAIN_ACTIVITY" "private var searchGeneration = 0L" \
  "Reader search must guard against stale background results."
require_slurp_match "$MAIN_ACTIVITY" "withContext\\(Dispatchers\\.Default\\)\\s*\\{\\s*ReaderSearchEngine\\.summarize" \
  "Reader search summarization must run on Dispatchers.Default."
require_file_contains "$MAIN_ACTIVITY" "currentReady.renderModel.sourceRevision != renderModel.sourceRevision" \
  "Reader search must drop results after document changes."

require_file_contains "$READER_SCREEN" "LazyColumn(" \
  "Reader rendering must be virtualized by Markdown block."
require_file_contains "$READER_SCREEN" "key = { block -> block.id.value }" \
  "Virtualized reader items must use stable Markdown block ids."
require_file_contains "$READER_SCREEN" "snapshotFlow { lazyListState.firstVisibleItemIndex }" \
  "Scroll tracking must observe the virtualized list instead of reparsing Markdown."
require_file_contains "$READER_SCREEN" "produceState<Bitmap?>" \
  "Local image decoding must be asynchronous instead of running during composition."
require_slurp_match "$READER_SCREEN" "withContext\\(Dispatchers\\.IO\\)\\s*\\{\\s*decodeBoundedBitmap\\(context, source\\)" \
  "Local image stream reads and bitmap decode must run on Dispatchers.IO."
require_file_contains "$READER_SCREEN" ".horizontalScroll(rememberScrollState())" \
  "Wide code, table, and control rows must scroll inside local surfaces."

if rg -n 'StructuredMarkdownParser|ReaderSearchEngine\.summarize' "$ROOT_DIR/feature/reader/src/main/java"; then
  fail "Compose reader surfaces must not parse or search Markdown directly."
fi

if rg -n 'androidx\.compose\.animation|Animated|rememberInfiniteTransition|animate[A-Z]' \
  "$ROOT_DIR/app/src/main/java" "$ROOT_DIR/core/src/main/java" "$ROOT_DIR/feature"; then
  fail "Stage 1 Android must not introduce expensive animation surfaces before profile gating."
fi

remote_media_disabled_count="$(
  rg -o 'remoteMediaEnabledByDefault = false' "$PERFORMANCE_PROFILE" | wc -l | tr -d ' '
)"
if [ "$remote_media_disabled_count" != "4" ]; then
  fail "All Android performance profiles must keep remote media disabled by default."
fi
require_file_contains "$PERFORMANCE_PROFILE" "preferPlainFallbackForHeavyRichBlocks = true" \
  "Compact and legacy profiles must prefer plain fallback for heavy rich blocks."
require_file_contains "$DIAGNOSTICS_REPORT" "parse.toRedactedLine(\"parse\")" \
  "Diagnostics must expose parse timing without document content."
require_file_contains "$DIAGNOSTICS_REPORT" "render.toRedactedLine(\"render\")" \
  "Diagnostics must expose render timing without document content."
require_file_contains "$DIAGNOSTICS_REPORT" "search.toRedactedLine(\"search\")" \
  "Diagnostics must expose search timing without document content."
require_file_contains "$DIAGNOSTICS_REPORT" "save.toRedactedLine(\"save\")" \
  "Diagnostics must expose save timing without document content."

printf 'Android performance profile limits:\n'
perl -ne '
  if (/^\s*(WatchCompact|LegacyEfficient|ModernStandard|LargeScreen)\(/) {
    $profile = $1;
  }
  if (defined $profile && /fileSizeSoftLimitBytes = (.+),/) {
    $expr = $1;
    $bytes = $expr;
    $bytes =~ s/L//g;
    $bytes =~ s/\s+//g;
    $bytes =~ s/\*/ * /g;
    $value = eval $bytes;
    printf "  %s softLimitBytes=%d\n", $profile, $value;
    undef $profile;
  }
' "$PERFORMANCE_PROFILE"

printf 'Android fixture size matrix:\n'
for fixture in basic.md rich-preview.md long-1mb.md large-5mb.md huge-table.md huge-code-block.md remote-image.md local-image.md; do
  path="$FIXTURE_DIR/$fixture"
  if [ ! -f "$path" ]; then
    fail "Missing performance fixture: $fixture"
  fi
  size="$(wc -c < "$path" | tr -d ' ')"
  lines="$(wc -l < "$path" | tr -d ' ')"
  printf '  %s bytes=%s lines=%s\n' "$fixture" "$size" "$lines"
done

pass "Android performance report audit completed."
