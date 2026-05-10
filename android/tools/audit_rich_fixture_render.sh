#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FIXTURE="$ROOT_DIR/test-fixtures/markdown/rich-preview.md"
PARSER="$ROOT_DIR/core/src/main/java/com/fastmd/mobile/core/markdown/StructuredMarkdownParser.kt"
INLINE_PARSER="$ROOT_DIR/core/src/main/java/com/fastmd/mobile/core/markdown/MarkdownInlineParser.kt"
RENDER_MODEL="$ROOT_DIR/core/src/main/java/com/fastmd/mobile/core/render/MarkdownRenderModel.kt"
READER="$ROOT_DIR/feature/reader/src/main/java/com/fastmd/mobile/feature/reader/ReaderScreen.kt"
PARSER_TEST="$ROOT_DIR/core/src/test/java/com/fastmd/mobile/core/markdown/StructuredMarkdownParserTest.kt"

failures=0

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  failures=$((failures + 1))
}

pass() {
  printf 'PASS: %s\n' "$1"
}

require_file_contains() {
  local file="$1"
  local pattern="$2"
  local description="$3"
  if grep -Fq -- "$pattern" "$file"; then
    pass "$description"
  else
    fail "$description"
  fi
}

require_absent() {
  local pattern="$1"
  local description="$2"
  shift 2
  if rg -n "$pattern" "$@"; then
    fail "$description"
  else
    pass "$description"
  fi
}

require_file_contains "$FIXTURE" "# H1" "Rich fixture includes H1-H6 heading coverage."
require_file_contains "$FIXTURE" "**粗体**" "Rich fixture includes bold inline coverage."
require_file_contains "$FIXTURE" "*斜体*" "Rich fixture includes italic inline coverage."
require_file_contains "$FIXTURE" "***粗斜体***" "Rich fixture includes bold-italic inline coverage."
require_file_contains "$FIXTURE" "~~删除线~~" "Rich fixture includes strikethrough inline coverage."
require_file_contains "$FIXTURE" "\`inline code\`" "Rich fixture includes inline code coverage."
require_file_contains "$FIXTURE" "<mark>高亮</mark>" "Rich fixture includes mark/highlight inline HTML coverage."
require_file_contains "$FIXTURE" "<sub>下标</sub>" "Rich fixture includes subscript inline HTML coverage."
require_file_contains "$FIXTURE" "<sup>上标</sup>" "Rich fixture includes superscript inline HTML coverage."
require_file_contains "$FIXTURE" "[OpenAI](https://openai.com)" "Rich fixture includes Markdown link coverage."
require_file_contains "$FIXTURE" "<https://github.com>" "Rich fixture includes autolink coverage."
require_file_contains "$FIXTURE" "<hello@example.com>" "Rich fixture includes email autolink coverage."
require_file_contains "$FIXTURE" "> 这是一级引用。" "Rich fixture includes blockquote coverage."
require_file_contains "$FIXTURE" "- 苹果" "Rich fixture includes unordered list coverage."
require_file_contains "$FIXTURE" "1. 第一项" "Rich fixture includes ordered list coverage."
require_file_contains "$FIXTURE" "- [x] 已完成任务" "Rich fixture includes task list coverage."
require_file_contains "$FIXTURE" "| Name | Type | Status | Notes |" "Rich fixture includes table coverage."
require_file_contains "$FIXTURE" "\`\`\`javascript" "Rich fixture includes fenced code coverage."
require_file_contains "$FIXTURE" "\`\`\`mermaid" "Rich fixture includes Mermaid fallback coverage."
require_file_contains "$FIXTURE" '行内公式：$E = mc^2$' "Rich fixture includes inline math coverage."
require_file_contains "$FIXTURE" '$$' "Rich fixture includes block math coverage."
require_file_contains "$FIXTURE" "![Placeholder Diagram]" "Rich fixture includes image coverage."
require_file_contains "$FIXTURE" "<video controls" "Rich fixture includes safe video HTML coverage."
require_file_contains "$FIXTURE" "[^note1]:" "Rich fixture includes footnote definition coverage."
require_file_contains "$FIXTURE" "<details open>" "Rich fixture includes details/summary coverage."
require_file_contains "$FIXTURE" "<div style=" "Rich fixture includes generic HTML fallback coverage."
require_file_contains "$FIXTURE" "中文 English 日本語 한국어" "Rich fixture includes mixed CJK/English/Japanese/Korean coverage."
require_file_contains "$FIXTURE" "\\*这行前后的星号应该被转义" "Rich fixture includes escaped marker coverage."

for kind in \
  Heading Paragraph Blockquote UnorderedList OrderedList TaskList Table CodeFence Mermaid MathBlock Image VideoHtml HorizontalRule Footnote Details HtmlFallback
do
  require_file_contains "$RENDER_MODEL" "$kind" "Render model declares $kind block kind."
  require_file_contains "$PARSER" "MarkdownBlockKind.$kind" "Parser emits $kind blocks."
done

for style in Bold Italic Strikethrough InlineCode Highlight Subscript Superscript Math
do
  require_file_contains "$RENDER_MODEL" "$style" "Render model declares $style inline style."
done

require_file_contains "$INLINE_PARSER" "InlineHtmlStyleTags" "Inline parser has safe inline HTML style tag handling."
require_file_contains "$INLINE_PARSER" '"mark" to MarkdownInlineStyle.Highlight' "Inline parser maps <mark> to native highlight spans."
require_file_contains "$INLINE_PARSER" '"sub" to MarkdownInlineStyle.Subscript' "Inline parser maps <sub> to native subscript spans."
require_file_contains "$INLINE_PARSER" '"sup" to MarkdownInlineStyle.Superscript' "Inline parser maps <sup> to native superscript spans."
require_file_contains "$INLINE_PARSER" "escapedCharacterAt" "Inline parser preserves escaped marker characters."
require_file_contains "$INLINE_PARSER" "LinkPolicy" "Inline parser routes links through the safe link policy."

for renderer in \
  MarkdownBlockPreview BlockquoteBlock ListBlock TableBlock CodeLikeBlock ImageBlock MediaPlaceholderBlock FootnoteBlock DetailsBlock SafeFallbackBlock toAnnotatedString
do
  require_file_contains "$READER" "$renderer" "Reader has native renderer path: $renderer."
done

require_file_contains "$READER" "horizontalScroll(rememberScrollState())" "Reader constrains wide code/table/media surfaces with local horizontal scroll."
require_file_contains "$READER" "Remote images are not fetched automatically." "Reader preserves remote image privacy with a placeholder."
require_file_contains "$READER" "Mermaid diagram source" "Reader renders Mermaid as a native readable source card."
require_file_contains "$READER" "Math source" "Reader renders block math as a native readable source card."

require_file_contains "$PARSER_TEST" "parsesInlineEmphasisCodeMarkSubscriptAndSuperscriptAsNativeSpans" \
  "Parser tests cover native inline emphasis/code/mark/subscript/superscript spans."
require_file_contains "$PARSER_TEST" "tag mark" "Parser tests cover <mark> inline HTML conversion."
require_file_contains "$PARSER_TEST" "<sub>2</sub>" "Parser tests cover <sub> inline HTML conversion."
require_file_contains "$PARSER_TEST" "<sup>3</sup>" "Parser tests cover <sup> inline HTML conversion."
require_file_contains "$PARSER_TEST" "parsesNativeBlockKindsNeededByEarlyRichMarkdownRenderer" \
  "Parser tests cover native rich block kinds."
require_file_contains "$PARSER_TEST" "parsesMathImagesFootnotesAndSafeHtmlFallbackAttributes" \
  "Parser tests cover math, image, footnote, and safe HTML fallback attributes."

require_absent 'WebView|android\.webkit|ReactNative|com\.facebook\.react|Flutter|io\.flutter|Cordova|org\.apache\.cordova' \
  "Android rich rendering remains native Kotlin/Compose without a web app runtime." \
  "$ROOT_DIR/app/src/main/java" "$ROOT_DIR/core/src/main/java" "$ROOT_DIR/feature"

if [ "$failures" -ne 0 ]; then
  printf 'Rich fixture render audit failed with %s issue(s).\n' "$failures" >&2
  exit 1
fi

printf 'Android rich fixture render audit completed.\n'
