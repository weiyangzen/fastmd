use fastmd_contracts::{
    shared_hint_chip_contract, BackgroundMode, EditingState, FencedCodeRenderingReference,
    HeadingRenderingReference, HintChipContract, InlineMarkupRenderingReference,
    MacOsPreviewFeature, ParagraphRenderingReference, PreviewFeatureCoverageLane,
    PreviewFeatureCoverageRecord, RenderingReference, RuntimeDiagnostic,
    SyntaxHighlightingRenderingReference, TaskListRenderingReference, MACOS_REFERENCE_BEHAVIOR,
};
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub enum MarkdownFeature {
    Heading,
    Paragraph,
    Emphasis,
    Strong,
    FencedCode,
    SyntaxHighlightedCode,
    Blockquote,
    TaskList,
    Table,
    Mermaid,
    Math,
    Image,
    Footnote,
    HtmlBlock,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub enum BlockKind {
    Heading,
    Paragraph,
    Blockquote,
    BulletList,
    OrderedList,
    Table,
    FencedCode,
    CodeBlock,
    HtmlBlock,
    HorizontalRule,
    Unknown,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct BlockMapping {
    pub block_id: usize,
    pub kind: BlockKind,
    pub start_line: u32,
    pub end_line: u32,
}

impl BlockMapping {
    pub fn contains_line(&self, line: u32) -> bool {
        self.start_line <= line && line < self.end_line
    }

    pub fn span_len(&self) -> u32 {
        self.end_line.saturating_sub(self.start_line)
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct ThemeVariables {
    pub page_bg: String,
    pub surface: String,
    pub surface_strong: String,
    pub border: String,
    pub text: String,
    pub muted: String,
    pub accent: String,
    pub accent_soft: String,
    pub quote: String,
    pub code_bg: String,
    pub editor_bg: String,
    pub editor_border: String,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct MarkdownRenderingContract {
    pub supported_features: Vec<MarkdownFeature>,
    pub width_tiers_px: Vec<u32>,
    pub aspect_ratio: f64,
    pub hint_chip: HintChipContract,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct PreviewDocumentModel {
    pub title: String,
    pub markdown: String,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct PreviewChromeModel {
    pub toolbar_eyebrow: String,
    pub hint_chip: HintChipContract,
    pub background_mode: BackgroundMode,
    pub selected_width_tier_index: usize,
    pub width_tiers_px: Vec<u32>,
    pub width_label_tooltip: String,
    pub width_label_aria_label: String,
    pub theme: ThemeVariables,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct InlineEditorCopy {
    pub source_line_label: String,
    pub return_hint: String,
    pub status_text: String,
    pub save_label: String,
    pub cancel_label: String,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct InlineEditorModel {
    pub block: BlockMapping,
    pub original_source: String,
    pub editable_source: String,
    pub source_line_label: String,
    pub return_hint: String,
    pub status_text: String,
    pub save_label: String,
    pub cancel_label: String,
}

#[derive(Debug, Clone, Default, PartialEq, Eq, Serialize, Deserialize)]
pub struct PreviewDiagnosticsModel {
    pub diagnostics: Vec<RuntimeDiagnostic>,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct PreviewModel {
    pub document: PreviewDocumentModel,
    pub chrome: PreviewChromeModel,
    pub block_mappings: Vec<BlockMapping>,
    pub inline_editor: Option<InlineEditorModel>,
    #[serde(default)]
    pub diagnostics: PreviewDiagnosticsModel,
}

pub fn preview_aspect_ratio() -> f64 {
    MACOS_REFERENCE_BEHAVIOR
        .preview_geometry
        .aspect_ratio_value()
}

pub fn clamped_width_tier_index(index: isize) -> usize {
    MACOS_REFERENCE_BEHAVIOR
        .preview_geometry
        .clamped_width_tier_index(index)
}

pub fn width_px_for_index(index: usize) -> u32 {
    MACOS_REFERENCE_BEHAVIOR
        .preview_geometry
        .width_px_for_index(index)
}

pub fn width_label(selected_width_tier_index: usize) -> String {
    shared_hint_chip_contract(selected_width_tier_index).width_label
}

pub fn hint_chip_contract(selected_width_tier_index: usize) -> HintChipContract {
    shared_hint_chip_contract(selected_width_tier_index)
}

pub fn macos_rendering_reference() -> &'static RenderingReference {
    &MACOS_REFERENCE_BEHAVIOR.rendering
}

pub fn heading_rendering_reference() -> &'static HeadingRenderingReference {
    &MACOS_REFERENCE_BEHAVIOR.rendering.text.heading
}

pub fn paragraph_rendering_reference() -> &'static ParagraphRenderingReference {
    &MACOS_REFERENCE_BEHAVIOR.rendering.text.paragraph
}

pub fn task_list_rendering_reference() -> &'static TaskListRenderingReference {
    &MACOS_REFERENCE_BEHAVIOR.rendering.text.task_list
}

pub fn inline_markup_rendering_reference() -> &'static InlineMarkupRenderingReference {
    &MACOS_REFERENCE_BEHAVIOR.rendering.text.inline_markup
}

pub fn fenced_code_rendering_reference() -> &'static FencedCodeRenderingReference {
    &MACOS_REFERENCE_BEHAVIOR.rendering.code.fenced_block
}

pub fn syntax_highlighting_rendering_reference() -> &'static SyntaxHighlightingRenderingReference {
    &MACOS_REFERENCE_BEHAVIOR.rendering.code.syntax_highlighting
}

pub fn width_label_tooltip(selected_width_tier_index: usize) -> String {
    let clamped = clamped_width_tier_index(selected_width_tier_index as isize);
    let width_px = width_px_for_index(clamped);
    MACOS_REFERENCE_BEHAVIOR.rendering.chrome.width_tooltip(
        clamped,
        MACOS_REFERENCE_BEHAVIOR
            .preview_geometry
            .width_tiers_px
            .len(),
        width_px,
    )
}

pub fn width_label_aria_label(selected_width_tier_index: usize) -> String {
    let clamped = clamped_width_tier_index(selected_width_tier_index as isize);
    let width_px = width_px_for_index(clamped);
    MACOS_REFERENCE_BEHAVIOR.rendering.chrome.width_aria_label(
        clamped,
        MACOS_REFERENCE_BEHAVIOR
            .preview_geometry
            .width_tiers_px
            .len(),
        width_px,
    )
}

pub fn inline_editor_copy(start_line: u32, end_line: u32) -> InlineEditorCopy {
    InlineEditorCopy {
        source_line_label: MACOS_REFERENCE_BEHAVIOR
            .rendering
            .chrome
            .inline_editor_source_line_label(start_line, end_line),
        return_hint: MACOS_REFERENCE_BEHAVIOR
            .rendering
            .chrome
            .inline_editor_return_text
            .to_string(),
        status_text: MACOS_REFERENCE_BEHAVIOR
            .rendering
            .chrome
            .edit_locked_status_text
            .to_string(),
        save_label: MACOS_REFERENCE_BEHAVIOR
            .rendering
            .chrome
            .save_label
            .to_string(),
        cancel_label: MACOS_REFERENCE_BEHAVIOR
            .rendering
            .chrome
            .cancel_label
            .to_string(),
    }
}

pub fn find_block_by_line_range(
    blocks: &[BlockMapping],
    start_line: u32,
    end_line: u32,
) -> Option<BlockMapping> {
    blocks
        .iter()
        .find(|block| block.start_line == start_line && block.end_line == end_line)
        .cloned()
}

pub fn find_block_for_editing_state(
    blocks: &[BlockMapping],
    editing: &EditingState,
) -> Option<BlockMapping> {
    let range = editing.target_line_range()?;
    find_block_by_line_range(blocks, range.start, range.end)
}

pub fn block_source_for_mapping(markdown: &str, block: &BlockMapping) -> Option<String> {
    let lines: Vec<&str> = markdown.split('\n').collect();
    let start = block.start_line as usize;
    let end = block.end_line as usize;

    if end <= start || end > lines.len() {
        return None;
    }

    Some(lines[start..end].join("\n"))
}

pub fn apply_inline_edit_to_markdown(
    markdown: &str,
    block: &BlockMapping,
    replacement_source: &str,
) -> Option<String> {
    let lines: Vec<&str> = markdown.split('\n').collect();
    let start = block.start_line as usize;
    let end = block.end_line as usize;
    if end <= start || end > lines.len() {
        return None;
    }

    let normalized_replacement = replacement_source.replace("\r\n", "\n");
    let replacement_lines: Vec<&str> = normalized_replacement.split('\n').collect();

    Some(
        lines[..start]
            .iter()
            .copied()
            .chain(replacement_lines.iter().copied())
            .chain(lines[end..].iter().copied())
            .collect::<Vec<_>>()
            .join("\n"),
    )
}

pub fn build_inline_editor_model(
    markdown: &str,
    block: &BlockMapping,
    editing: &EditingState,
) -> Option<InlineEditorModel> {
    let original_source = block_source_for_mapping(markdown, block)?;
    let copy = inline_editor_copy(block.start_line, block.end_line);
    let editable_source = editing
        .draft_source
        .clone()
        .unwrap_or_else(|| original_source.clone());

    Some(InlineEditorModel {
        block: block.clone(),
        original_source,
        editable_source,
        source_line_label: copy.source_line_label,
        return_hint: copy.return_hint,
        status_text: copy.status_text,
        save_label: copy.save_label,
        cancel_label: copy.cancel_label,
    })
}

pub fn build_inline_editor_model_for_editing_state(
    markdown: &str,
    blocks: &[BlockMapping],
    editing: &EditingState,
) -> Option<InlineEditorModel> {
    let block = find_block_for_editing_state(blocks, editing)?;
    build_inline_editor_model(markdown, &block, editing)
}

pub fn theme_variables(background_mode: BackgroundMode) -> ThemeVariables {
    match background_mode {
        BackgroundMode::White => ThemeVariables {
            page_bg: "#ffffff".to_string(),
            surface: "#ffffff".to_string(),
            surface_strong: "#ffffff".to_string(),
            border: "rgba(21, 33, 55, 0.12)".to_string(),
            text: "#111111".to_string(),
            muted: "#5f6b7c".to_string(),
            accent: "#1f6feb".to_string(),
            accent_soft: "rgba(31, 111, 235, 0.10)".to_string(),
            quote: "#d0dae8".to_string(),
            code_bg: "#f5f7fb".to_string(),
            editor_bg: "#fffdf8".to_string(),
            editor_border: "rgba(208, 150, 24, 0.28)".to_string(),
        },
        BackgroundMode::Black => ThemeVariables {
            page_bg: "#000000".to_string(),
            surface: "#000000".to_string(),
            surface_strong: "#000000".to_string(),
            border: "rgba(255, 255, 255, 0.14)".to_string(),
            text: "#f5f5f5".to_string(),
            muted: "#b3b3b3".to_string(),
            accent: "#7fb2ff".to_string(),
            accent_soft: "rgba(127, 178, 255, 0.12)".to_string(),
            quote: "rgba(255, 255, 255, 0.24)".to_string(),
            code_bg: "#0f0f10".to_string(),
            editor_bg: "#121212".to_string(),
            editor_border: "rgba(255, 196, 84, 0.36)".to_string(),
        },
    }
}

pub fn stage2_rendering_contract(selected_width_tier_index: usize) -> MarkdownRenderingContract {
    MarkdownRenderingContract {
        supported_features: vec![
            MarkdownFeature::Heading,
            MarkdownFeature::Paragraph,
            MarkdownFeature::Emphasis,
            MarkdownFeature::Strong,
            MarkdownFeature::FencedCode,
            MarkdownFeature::SyntaxHighlightedCode,
            MarkdownFeature::Blockquote,
            MarkdownFeature::TaskList,
            MarkdownFeature::Table,
            MarkdownFeature::Mermaid,
            MarkdownFeature::Math,
            MarkdownFeature::Image,
            MarkdownFeature::Footnote,
            MarkdownFeature::HtmlBlock,
        ],
        width_tiers_px: MACOS_REFERENCE_BEHAVIOR
            .preview_geometry
            .width_tiers_px
            .to_vec(),
        aspect_ratio: preview_aspect_ratio(),
        hint_chip: hint_chip_contract(selected_width_tier_index),
    }
}

pub fn shared_render_preview_feature_coverage() -> &'static [MacOsPreviewFeature] {
    &[
        MacOsPreviewFeature::CompactHintChipChrome,
        MacOsPreviewFeature::InlineBlockEditEntryAndSourceMapping,
        MacOsPreviewFeature::MarkdownRenderingSurface,
    ]
}

pub fn shared_render_preview_feature_coverage_records() -> &'static [PreviewFeatureCoverageRecord] {
    &[
        PreviewFeatureCoverageRecord::new(
            MacOsPreviewFeature::CompactHintChipChrome,
            PreviewFeatureCoverageLane::SharedRender,
        ),
        PreviewFeatureCoverageRecord::new(
            MacOsPreviewFeature::InlineBlockEditEntryAndSourceMapping,
            PreviewFeatureCoverageLane::SharedRender,
        ),
        PreviewFeatureCoverageRecord::new(
            MacOsPreviewFeature::MarkdownRenderingSurface,
            PreviewFeatureCoverageLane::SharedRender,
        ),
    ]
}

pub fn preview_chrome_model(
    selected_width_tier_index: usize,
    background_mode: BackgroundMode,
) -> PreviewChromeModel {
    let clamped = clamped_width_tier_index(selected_width_tier_index as isize);
    PreviewChromeModel {
        toolbar_eyebrow: MACOS_REFERENCE_BEHAVIOR
            .rendering
            .chrome
            .toolbar_eyebrow
            .to_string(),
        hint_chip: hint_chip_contract(clamped),
        background_mode,
        selected_width_tier_index: clamped,
        width_tiers_px: MACOS_REFERENCE_BEHAVIOR
            .preview_geometry
            .width_tiers_px
            .to_vec(),
        width_label_tooltip: width_label_tooltip(clamped),
        width_label_aria_label: width_label_aria_label(clamped),
        theme: theme_variables(background_mode),
    }
}

pub fn preview_model(
    title: impl Into<String>,
    markdown: impl Into<String>,
    selected_width_tier_index: usize,
    background_mode: BackgroundMode,
    block_mappings: Vec<BlockMapping>,
    inline_editor: Option<InlineEditorModel>,
) -> PreviewModel {
    PreviewModel {
        document: PreviewDocumentModel {
            title: title.into(),
            markdown: markdown.into(),
        },
        chrome: preview_chrome_model(selected_width_tier_index, background_mode),
        block_mappings,
        inline_editor,
        diagnostics: PreviewDiagnosticsModel::default(),
    }
}

pub fn find_smallest_matching_block(blocks: &[BlockMapping], line: u32) -> Option<BlockMapping> {
    blocks
        .iter()
        .filter(|block| block.contains_line(line))
        .min_by_key(|block| (block.span_len(), block.start_line, block.block_id))
        .cloned()
}

#[cfg(test)]
mod tests {
    use super::*;
    use fastmd_contracts::{
        preview_feature_gaps_against_reference, EditingPhase, EditingState, MacOsPreviewFeature,
        PreviewFeatureCoverageLane,
    };
    use std::collections::BTreeSet;
    use std::fs;
    use std::path::PathBuf;

    fn sample_blocks() -> Vec<BlockMapping> {
        vec![
            BlockMapping {
                block_id: 0,
                kind: BlockKind::Paragraph,
                start_line: 0,
                end_line: 10,
            },
            BlockMapping {
                block_id: 1,
                kind: BlockKind::Blockquote,
                start_line: 2,
                end_line: 8,
            },
            BlockMapping {
                block_id: 2,
                kind: BlockKind::Paragraph,
                start_line: 3,
                end_line: 5,
            },
        ]
    }

    fn sample_markdown() -> &'static str {
        "line 1\nline 2\nline 3\nline 4\nline 5\nline 6\nline 7\nline 8\nline 9\nline 10"
    }

    #[test]
    fn width_tiers_and_aspect_ratio_match_macos_reference() {
        assert_eq!(
            MACOS_REFERENCE_BEHAVIOR.preview_geometry.width_tiers_px,
            [560, 960, 1_440, 1_920]
        );
        assert!((preview_aspect_ratio() - (4.0 / 3.0)).abs() < f64::EPSILON);
        assert_eq!(clamped_width_tier_index(-10), 0);
        assert_eq!(clamped_width_tier_index(99), 3);
        assert_eq!(width_px_for_index(1), 960);
    }

    #[test]
    fn hint_chip_contract_matches_current_macos_copy() {
        let chip = hint_chip_contract(0);

        assert_eq!(chip.width_label, "← 1/4 →");
        assert_eq!(chip.background_label, "Tab");
        assert_eq!(chip.paging_label, "(⇧+) Space");
        assert_eq!(chip.background_icon, "◐");
        assert_eq!(chip.paging_icon, "⇵");
    }

    #[test]
    fn theme_variables_lock_white_and_black_background_modes() {
        let white = theme_variables(BackgroundMode::White);
        let black = theme_variables(BackgroundMode::Black);

        assert_eq!(white.page_bg, "#ffffff");
        assert_eq!(black.page_bg, "#000000");
        assert_eq!(white.surface, "#ffffff");
        assert_eq!(black.surface, "#000000");
    }

    #[test]
    fn smallest_block_selection_prefers_the_narrowest_matching_span() {
        let selected = find_smallest_matching_block(&sample_blocks(), 4).expect("block");

        assert_eq!(selected.block_id, 2);
        assert_eq!(selected.start_line, 3);
        assert_eq!(selected.end_line, 5);
    }

    #[test]
    fn preview_models_are_serializable_frontend_dtos() {
        let editing = EditingState {
            phase: EditingPhase::Active,
            target_start_line: Some(3),
            target_end_line: Some(5),
            draft_markdown: None,
            draft_source: None,
        };
        let model = preview_model(
            "spec.md",
            "# Title",
            8,
            BackgroundMode::Black,
            sample_blocks(),
            Some(
                build_inline_editor_model(
                    sample_markdown(),
                    &BlockMapping {
                        block_id: 2,
                        kind: BlockKind::Paragraph,
                        start_line: 3,
                        end_line: 5,
                    },
                    &editing,
                )
                .expect("inline editor model"),
            ),
        );

        assert_eq!(model.chrome.toolbar_eyebrow, "FastMD Preview");
        assert_eq!(model.chrome.selected_width_tier_index, 3);
        assert_eq!(model.chrome.hint_chip.width_label, "← 4/4 →");
        assert_eq!(model.chrome.width_label_tooltip, "4/4 · 1920px");
        assert_eq!(
            model.chrome.width_label_aria_label,
            "宽度档位 4/4，目标宽度 1920px"
        );
        assert_eq!(model.chrome.background_mode, BackgroundMode::Black);
        assert_eq!(
            model.inline_editor.as_ref().map(|editor| (
                editor.source_line_label.as_str(),
                editor.editable_source.as_str()
            )),
            Some(("Editing source lines 4-5", "line 4\nline 5"))
        );

        let encoded = serde_json::to_string(&model).expect("serialize");
        let decoded: PreviewModel = serde_json::from_str(&encoded).expect("deserialize");
        assert_eq!(model, decoded);
        assert!(decoded.diagnostics.diagnostics.is_empty());
    }

    #[test]
    fn preview_diagnostics_model_round_trips_structured_runtime_diagnostics() {
        let model = PreviewDiagnosticsModel {
            diagnostics: vec![RuntimeDiagnostic::new(
                fastmd_contracts::PlatformId::WindowsExplorer,
                fastmd_contracts::RuntimeDiagnosticLevel::Info,
                fastmd_contracts::RuntimeDiagnosticCategory::MonitorSelection,
                "Windows monitor selection classified the pointer into shared desktop space",
            )
            .at_ms(1_500)
            .with_detail("selected_monitor_id", "primary")],
        };

        let encoded = serde_json::to_string(&model).expect("serialize");
        let decoded: PreviewDiagnosticsModel = serde_json::from_str(&encoded).expect("deserialize");
        assert_eq!(model, decoded);
    }

    #[test]
    fn stage2_rendering_contract_names_all_current_shared_features() {
        let contract = stage2_rendering_contract(1);

        assert_eq!(
            contract.width_tiers_px,
            MACOS_REFERENCE_BEHAVIOR
                .preview_geometry
                .width_tiers_px
                .to_vec()
        );
        assert_eq!(contract.hint_chip.width_label, "← 2/4 →");
        assert!(contract
            .supported_features
            .contains(&MarkdownFeature::Heading));
        assert!(contract
            .supported_features
            .contains(&MarkdownFeature::Paragraph));
        assert!(contract
            .supported_features
            .contains(&MarkdownFeature::Emphasis));
        assert!(contract
            .supported_features
            .contains(&MarkdownFeature::Strong));
        assert!(contract
            .supported_features
            .contains(&MarkdownFeature::FencedCode));
        assert!(contract
            .supported_features
            .contains(&MarkdownFeature::SyntaxHighlightedCode));
        assert!(contract
            .supported_features
            .contains(&MarkdownFeature::TaskList));
        assert!(contract
            .supported_features
            .contains(&MarkdownFeature::Mermaid));
        assert!(contract.supported_features.contains(&MarkdownFeature::Math));
        assert!(contract
            .supported_features
            .contains(&MarkdownFeature::HtmlBlock));
    }

    #[test]
    fn shared_render_preview_feature_coverage_stays_explicit() {
        let features: BTreeSet<_> = shared_render_preview_feature_coverage()
            .iter()
            .copied()
            .collect();

        assert_eq!(features.len(), 3);
        assert!(features.contains(&MacOsPreviewFeature::CompactHintChipChrome));
        assert!(features.contains(&MacOsPreviewFeature::InlineBlockEditEntryAndSourceMapping));
        assert!(features.contains(&MacOsPreviewFeature::MarkdownRenderingSurface));
    }

    #[test]
    fn shared_render_preview_feature_coverage_stays_inside_render_owned_boundary() {
        let gaps =
            preview_feature_gaps_against_reference(&[shared_render_preview_feature_coverage()]);

        assert!(gaps.contains(&MacOsPreviewFeature::FrontmostFileManagerGating));
        assert!(gaps.contains(&MacOsPreviewFeature::HoverOpensAfterOneSecond));
        assert!(gaps.contains(&MacOsPreviewFeature::RuntimeDiagnosticsCoverage));
        assert!(!gaps.contains(&MacOsPreviewFeature::CompactHintChipChrome));
        assert!(!gaps.contains(&MacOsPreviewFeature::InlineBlockEditEntryAndSourceMapping));
        assert!(!gaps.contains(&MacOsPreviewFeature::MarkdownRenderingSurface));
    }

    #[test]
    fn shared_render_preview_feature_coverage_records_stay_tagged_to_the_render_lane() {
        let records = shared_render_preview_feature_coverage_records();
        let recorded_features: BTreeSet<_> = records.iter().map(|record| record.feature).collect();
        let plain_features: BTreeSet<_> = shared_render_preview_feature_coverage()
            .iter()
            .copied()
            .collect();

        assert_eq!(records.len(), 3);
        assert_eq!(recorded_features, plain_features);
        assert!(records
            .iter()
            .all(|record| { record.lane == PreviewFeatureCoverageLane::SharedRender }));
        assert!(records
            .iter()
            .any(|record| { record.feature == MacOsPreviewFeature::MarkdownRenderingSurface }));
    }

    #[test]
    fn shared_render_reference_matches_current_macos_markdown_renderer_copy_and_runtime() {
        let source = fs::read_to_string(markdown_renderer_swift_path())
            .expect("MarkdownRenderer.swift should be readable");
        let rendering = macos_rendering_reference();

        assert!(source.contains(rendering.chrome.toolbar_eyebrow));
        assert!(source.contains(rendering.typography.ui_font_family));
        assert!(source.contains(rendering.typography.body_font_family));
        assert!(source.contains(rendering.typography.code_font_family));
        assert!(source.contains(rendering.theme.white_page_bg));
        assert!(source.contains(rendering.theme.black_page_bg));
        assert!(source.contains(rendering.chrome.edit_locked_status_text));
        assert!(source.contains(rendering.chrome.saving_status_text));
        assert!(source.contains(rendering.chrome.save_failed_fallback_text));
        assert!(source.contains(rendering.chrome.inline_editor_return_text));
        assert!(source.contains(rendering.chrome.save_label));
        assert!(source.contains(rendering.chrome.cancel_label));
        assert!(source.contains("window.markdownit"));
        assert!(source.contains("window.markdownitFootnote"));
        assert!(source.contains("window.markdownitTaskLists"));
        assert!(source.contains("window.renderMathInElement"));
        assert!(source.contains("window.mermaid.initialize"));
        assert!(source.contains("hljs.highlightAuto"));
        assert!(source.contains("html: true"));
        assert!(source.contains("linkify: true"));
        assert!(source.contains("typographer: true"));
        assert!(source.contains(rendering.runtime.mermaid_fence_info_string));
        assert!(source.contains(rendering.runtime.mermaid_security_level));
        assert!(source.contains("class=\"md-block\""));
        assert!(source.contains("data-start-line"));
        assert!(source.contains("data-end-line"));
        for size in rendering.typography.heading_sizes_px {
            assert!(source.contains(&format!("font-size: {size}px;")));
        }
    }

    #[test]
    fn shared_render_reference_exposes_current_width_and_editor_copy() {
        assert_eq!(width_label_tooltip(0), "1/4 · 560px");
        assert_eq!(width_label_tooltip(2), "3/4 · 1440px");
        assert_eq!(width_label_aria_label(1), "宽度档位 2/4，目标宽度 960px");

        let editor = inline_editor_copy(3, 5);
        assert_eq!(editor.source_line_label, "Editing source lines 4-5");
        assert_eq!(
            editor.return_hint,
            "Double-clicked block returns to raw Markdown."
        );
        assert_eq!(
            editor.status_text,
            "Edit mode is locked until you save or cancel."
        );
        assert_eq!(editor.save_label, "Save");
        assert_eq!(editor.cancel_label, "Cancel");
    }

    #[test]
    fn shared_frontend_shell_keeps_macos_hint_chip_copy_without_windows_specific_text() {
        let source =
            fs::read_to_string(shared_frontend_app_path()).expect("ui app.ts should be readable");
        let chip = hint_chip_contract(0);

        assert!(source.contains(MACOS_REFERENCE_BEHAVIOR.rendering.chrome.toolbar_eyebrow));
        assert!(source.contains("class=\"hint-chip\""));
        assert!(source.contains("class=\"hint-separator\""));
        assert!(source.contains(&chip.width_label));
        assert!(source.contains(&chip.background_label));
        assert!(source.contains(&chip.paging_label));
        assert!(!source.contains("Windows"));
        assert!(!source.contains("Explorer"));
        assert!(!source.contains("Finder"));
    }

    #[test]
    fn shared_frontend_markdown_runtime_matches_macos_rendering_reference() {
        let source = fs::read_to_string(shared_frontend_markdown_path())
            .expect("ui markdown.ts should be readable");
        let rendering = macos_rendering_reference();

        assert!(source.contains("new MarkdownIt({"));
        if rendering.runtime.html_enabled {
            assert!(source.contains("html: true"));
        }
        if rendering.runtime.linkify {
            assert!(source.contains("linkify: true"));
        }
        if rendering.runtime.typographer {
            assert!(source.contains("typographer: true"));
        }
        if rendering.runtime.syntax_highlight_uses_highlight_js {
            assert!(source.contains("hljs.highlight(source, { language }).value;"));
        }
        if rendering.runtime.syntax_highlight_falls_back_to_auto_detect {
            assert!(source.contains("hljs.highlightAuto(source).value;"));
        }
        if rendering.runtime.supports_footnotes {
            assert!(source.contains("instance.use(markdownItFootnote);"));
        }
        if rendering.runtime.supports_task_lists {
            assert!(source.contains("instance.use(markdownItTaskLists"));
            assert!(source.contains("enabled: true"));
            assert!(source.contains("label: true"));
            assert!(source.contains("labelAfter: true"));
        }
        if rendering.runtime.supports_mermaid {
            assert!(source.contains(&format!(
                "if (info === \"{}\")",
                rendering.runtime.mermaid_fence_info_string
            )));
            assert!(source.contains("class=\"mermaid\""));
            assert!(source.contains("mermaid.initialize({"));
            assert!(source.contains(&format!(
                "securityLevel: \"{}\"",
                rendering.runtime.mermaid_security_level
            )));
        }
        if rendering.runtime.supports_math {
            assert!(source.contains("renderMathInElement(root, {"));
            for delimiter in rendering.runtime.math_delimiters {
                let left = typescript_string_literal(delimiter.left);
                let right = typescript_string_literal(delimiter.right);
                assert!(source.contains(&format!(
                    "{{ left: \"{left}\", right: \"{right}\", display: {} }}",
                    delimiter.display
                )));
            }
        }
        if rendering.runtime.html_blocks_passthrough {
            assert!(source.contains("wrapSelfClosingBlocks(instance, \"html_block\""));
        }
        if rendering.runtime.wraps_top_level_blocks_with_source_mapping {
            assert!(source.contains("assignBlockMetadata(tokens as any[]);"));
            assert!(source.contains("class=\"md-block\""));
            assert!(source.contains("data-block-id"));
            assert!(source.contains("data-start-line"));
            assert!(source.contains("data-end-line"));
        }
        assert!(source.contains("syncContentBase(root.ownerDocument, contentBaseUrl);"));
    }

    #[test]
    fn shared_frontend_styles_match_macos_rendering_surface_reference() {
        let source = fs::read_to_string(shared_frontend_styles_path())
            .expect("ui styles.css should be readable");
        let rendering = macos_rendering_reference();

        assert!(source.contains(rendering.typography.ui_font_family));
        assert!(source.contains(rendering.typography.body_font_family));
        assert!(source.contains(rendering.typography.code_font_family));
        assert!(source.contains(&format!(
            "font-size: {}px;",
            rendering.typography.base_font_size_px
        )));
        assert!(source.contains(rendering.theme.white_page_bg));
        assert!(source.contains(rendering.theme.black_page_bg));
        assert!(source.contains(rendering.theme.white_text));
        assert!(source.contains(rendering.theme.black_text));
        assert!(source.contains(rendering.theme.white_code_bg));
        assert!(source.contains(rendering.theme.black_code_bg));
        assert!(source.contains(rendering.theme.white_editor_bg));
        assert!(source.contains(rendering.theme.black_editor_bg));
        assert!(source.contains(&format!(
            "padding: {}px;",
            rendering.layout.render_root_padding_px
        )));
        assert!(source.contains(&format!(
            "padding: {}px {}px {}px;",
            rendering.layout.toolbar_padding_top_px,
            rendering.layout.toolbar_padding_horizontal_px,
            rendering.layout.toolbar_padding_bottom_px
        )));
        assert!(source.contains(&format!(
            "width: {}%;",
            rendering.layout.inline_editor_width_percent
        )));
        assert!(source.contains(".mermaid"));
        assert!(source.contains(".footnotes"));
        assert!(source.contains(".inline-editor"));
        assert!(source.contains("li.task-list-item"));
        assert!(source.contains("blockquote {"));
        assert!(source.contains("table {"));
        assert!(source.contains("img,"));
        assert!(source.contains("video {"));
        for size in rendering.typography.heading_sizes_px {
            assert!(source.contains(&format!("font-size: {size}px;")));
        }
    }

    #[test]
    fn shared_frontend_shell_routes_shell_state_through_shared_markdown_renderer() {
        let source =
            fs::read_to_string(shared_frontend_app_path()).expect("ui app.ts should be readable");

        assert!(source.contains("await renderMarkdownDocument("));
        assert!(source.contains("this.renderRoot,"));
        assert!(source.contains("this.shellState.markdown,"));
        assert!(source.contains("this.shellState.backgroundMode,"));
        assert!(source.contains("this.shellState.contentBaseUrl ?? null,"));
        assert!(source.contains("target.closest(\".md-block\")"));
        assert!(source.contains("replacePreviewMarkdown(this.pendingMarkdown)"));
    }

    #[test]
    fn heading_rendering_parity_is_explicit_in_shared_contract_and_reference_sources() {
        let swift_source = fs::read_to_string(markdown_renderer_swift_path())
            .expect("MarkdownRenderer.swift should be readable");
        let markdown_source = fs::read_to_string(shared_frontend_markdown_path())
            .expect("ui markdown.ts should be readable");
        let styles_source = fs::read_to_string(shared_frontend_styles_path())
            .expect("ui styles.css should be readable");
        let fixture = fs::read_to_string(rich_preview_fixture_path())
            .expect("rich-preview fixture should be readable");
        let heading = heading_rendering_reference();

        assert!(stage2_rendering_contract(0)
            .supported_features
            .contains(&MarkdownFeature::Heading));
        assert!(swift_source.contains("headingHTML(for: line)"));
        assert!(swift_source.contains("\"heading_open\","));
        assert!(markdown_source.contains("\"heading_open\","));
        assert!(styles_source.contains(&format!("margin: {};", heading.margin_css)));
        assert!(styles_source.contains(&format!("line-height: {};", heading.line_height_css)));
        assert!(styles_source.contains(&format!("letter-spacing: {};", heading.letter_spacing_css)));
        assert!(styles_source.contains(&format!("text-transform: {};", heading.h6_text_transform)));
        assert!(styles_source.contains(&format!(
            "letter-spacing: {};",
            heading.h6_letter_spacing_css
        )));
        for size in macos_rendering_reference().typography.heading_sizes_px {
            let fragment = format!("font-size: {size}px;");
            assert!(swift_source.contains(&fragment));
            assert!(styles_source.contains(&fragment));
        }
        assert!(fixture.contains("# H1 一级标题"));
        assert!(fixture.contains("###### H6 六级标题"));
    }

    #[test]
    fn paragraph_rendering_parity_is_explicit_in_shared_contract_and_reference_sources() {
        let swift_source = fs::read_to_string(markdown_renderer_swift_path())
            .expect("MarkdownRenderer.swift should be readable");
        let markdown_source = fs::read_to_string(shared_frontend_markdown_path())
            .expect("ui markdown.ts should be readable");
        let styles_source = fs::read_to_string(shared_frontend_styles_path())
            .expect("ui styles.css should be readable");
        let fixture = fs::read_to_string(rich_preview_fixture_path())
            .expect("rich-preview fixture should be readable");
        let paragraph = paragraph_rendering_reference();

        assert!(stage2_rendering_contract(0)
            .supported_features
            .contains(&MarkdownFeature::Paragraph));
        assert!(swift_source.contains("\"paragraph_open\","));
        assert!(markdown_source.contains("\"paragraph_open\","));
        assert!(styles_source.contains(&format!("margin: {};", paragraph.margin_css)));
        assert!(fixture.contains("普通段落可以混合"));
        assert!(fixture.contains("中文 English 日本語 한국어 mixed paragraph"));
    }

    #[test]
    fn task_list_rendering_parity_is_explicit_in_shared_contract_and_reference_sources() {
        let swift_source = fs::read_to_string(markdown_renderer_swift_path())
            .expect("MarkdownRenderer.swift should be readable");
        let markdown_source = fs::read_to_string(shared_frontend_markdown_path())
            .expect("ui markdown.ts should be readable");
        let styles_source = fs::read_to_string(shared_frontend_styles_path())
            .expect("ui styles.css should be readable");
        let fixture = fs::read_to_string(rich_preview_fixture_path())
            .expect("rich-preview fixture should be readable");
        let task_list = task_list_rendering_reference();
        let rendering = macos_rendering_reference();

        assert!(stage2_rendering_contract(0)
            .supported_features
            .contains(&MarkdownFeature::TaskList));
        assert!(rendering.runtime.supports_task_lists);
        assert!(rendering.runtime.task_list_wraps_label);
        assert!(rendering.runtime.task_list_wraps_label_after_checkbox);
        assert!(swift_source.contains("window.markdownitTaskLists"));
        assert!(swift_source.contains("enabled: true, label: true, labelAfter: true"));
        assert!(markdown_source.contains("instance.use(markdownItTaskLists, {"));
        assert!(markdown_source.contains("enabled: true"));
        assert!(markdown_source.contains("label: true"));
        assert!(markdown_source.contains("labelAfter: true"));
        assert!(styles_source.contains("li.task-list-item {"));
        assert!(styles_source.contains(&format!("list-style: {};", task_list.item_list_style_css)));
        assert!(
            styles_source.contains(&format!("margin-left: {};", task_list.item_margin_left_css))
        );
        assert!(styles_source.contains("li.task-list-item input {"));
        assert!(styles_source.contains(&format!(
            "margin-right: {};",
            task_list.checkbox_margin_right_css
        )));
        assert!(fixture.contains("- [x] 已完成任务"));
        assert!(fixture.contains("- [ ] 待完成任务"));
    }

    #[test]
    fn emphasis_and_strong_parity_are_explicit_in_shared_contract_and_reference_sources() {
        let swift_source = fs::read_to_string(markdown_renderer_swift_path())
            .expect("MarkdownRenderer.swift should be readable");
        let styles_source = fs::read_to_string(shared_frontend_styles_path())
            .expect("ui styles.css should be readable");
        let frontend_fixture_source = fs::read_to_string(shared_frontend_fixtures_path())
            .expect("ui fixtures.ts should be readable");
        let rich_fixture = fs::read_to_string(rich_preview_fixture_path())
            .expect("rich-preview fixture should be readable");
        let inline_markup = inline_markup_rendering_reference();

        assert!(stage2_rendering_contract(0)
            .supported_features
            .contains(&MarkdownFeature::Emphasis));
        assert!(stage2_rendering_contract(0)
            .supported_features
            .contains(&MarkdownFeature::Strong));
        assert!(swift_source.contains(inline_markup.strong_emphasis_html_snippet));
        assert!(swift_source.contains(&format!(
            "<{}>$1</{}>",
            inline_markup.strong_html_tag, inline_markup.strong_html_tag
        )));
        assert!(swift_source.contains(&format!(
            "<{}>$1</{}>",
            inline_markup.emphasis_html_tag, inline_markup.emphasis_html_tag
        )));
        assert!(styles_source.contains("strong {"));
        assert!(styles_source.contains(&format!(
            "font-weight: {};",
            inline_markup.strong_font_weight
        )));
        if inline_markup.strong_uses_ui_font_family {
            assert!(styles_source.contains("font-family: var(--font-ui);"));
        }
        assert!(frontend_fixture_source.contains("\"emphasis\""));
        assert!(frontend_fixture_source.contains("\"strong\""));
        assert!(rich_fixture.contains("*斜体*"));
        assert!(rich_fixture.contains("**粗体**"));
        assert!(rich_fixture.contains("***粗斜体***"));
    }

    #[test]
    fn fenced_code_rendering_parity_is_explicit_in_shared_contract_and_reference_sources() {
        let swift_source = fs::read_to_string(markdown_renderer_swift_path())
            .expect("MarkdownRenderer.swift should be readable");
        let markdown_source = fs::read_to_string(shared_frontend_markdown_path())
            .expect("ui markdown.ts should be readable");
        let styles_source = fs::read_to_string(shared_frontend_styles_path())
            .expect("ui styles.css should be readable");
        let fixture = fs::read_to_string(rich_preview_fixture_path())
            .expect("rich-preview fixture should be readable");
        let fenced = fenced_code_rendering_reference();

        assert!(stage2_rendering_contract(0)
            .supported_features
            .contains(&MarkdownFeature::FencedCode));
        assert!(swift_source.contains("const defaultFenceRule = md.renderer.rules.fence"));
        assert!(swift_source.contains("const defaultCodeBlockRule = md.renderer.rules.code_block"));
        assert!(swift_source.contains("wrapSelfClosingBlocks(md, \"fence\""));
        assert!(swift_source.contains("wrapSelfClosingBlocks(md, \"code_block\""));
        assert!(swift_source
            .contains("return `<pre><code>${md.utils.escapeHtml(token.content)}</code></pre>`;"));
        assert!(markdown_source.contains("const defaultFenceRule = instance.renderer.rules.fence"));
        assert!(markdown_source
            .contains("const defaultCodeBlockRule = instance.renderer.rules.code_block"));
        assert!(markdown_source.contains("wrapSelfClosingBlocks(instance, \"fence\""));
        assert!(markdown_source.contains("wrapSelfClosingBlocks(instance, \"code_block\""));
        assert!(markdown_source.contains(
            "return `<pre><code>${instance.utils.escapeHtml(token.content)}</code></pre>`;"
        ));
        assert!(styles_source.contains(&format!("margin: {};", fenced.pre_margin_css)));
        assert!(styles_source.contains(&format!("padding: {};", fenced.pre_padding_css)));
        assert!(
            styles_source.contains(&format!("border-radius: {};", fenced.pre_border_radius_css))
        );
        assert!(styles_source.contains(&format!("overflow-x: {};", fenced.pre_overflow_x_css)));
        assert!(styles_source.contains(&format!("font-size: {};", fenced.code_font_size_css)));
        assert!(fixture.contains("```swift"));
        assert!(fixture.contains("```javascript"));
        assert!(fixture.contains("```bash"));
        assert!(fixture.contains("```json"));
        assert!(fixture.contains("```diff"));
    }

    #[test]
    fn syntax_highlighting_parity_is_explicit_in_shared_contract_and_reference_sources() {
        let swift_source = fs::read_to_string(markdown_renderer_swift_path())
            .expect("MarkdownRenderer.swift should be readable");
        let markdown_source = fs::read_to_string(shared_frontend_markdown_path())
            .expect("ui markdown.ts should be readable");
        let styles_source = fs::read_to_string(shared_frontend_styles_path())
            .expect("ui styles.css should be readable");
        let fixture = fs::read_to_string(rich_preview_fixture_path())
            .expect("rich-preview fixture should be readable");
        let syntax = syntax_highlighting_rendering_reference();

        assert!(stage2_rendering_contract(0)
            .supported_features
            .contains(&MarkdownFeature::SyntaxHighlightedCode));
        assert!(styles_source.contains(&format!("@import \"{}\";", syntax.highlight_theme_asset)));
        assert!(markdown_source.contains("import hljs from \"highlight.js\";"));
        assert!(markdown_source.contains("hljs.getLanguage(language)"));
        assert!(markdown_source.contains("return hljs.highlight(source, { language }).value;"));
        assert!(markdown_source.contains("return hljs.highlightAuto(source).value;"));
        assert!(markdown_source.contains("return instance.utils.escapeHtml(source);"));
        assert!(swift_source.contains("window.hljs && lang && window.hljs.getLanguage(lang)"));
        assert!(
            swift_source.contains("return window.hljs.highlight(str, { language: lang }).value;")
        );
        assert!(swift_source.contains("return window.hljs.highlightAuto(str).value;"));
        assert!(swift_source.contains("return md.utils.escapeHtml(str);"));
        assert!(swift_source.contains("vendorScript(named: \"highlight.common.min.js\")"));
        assert_eq!(syntax.highlighter_symbol, "hljs");
        assert_eq!(syntax.language_guard_api, "getLanguage");
        assert_eq!(syntax.highlight_api, "highlight");
        assert_eq!(syntax.auto_detect_api, "highlightAuto");
        assert_eq!(syntax.escape_fallback_api, "escapeHtml");
        assert!(fixture.contains("```swift"));
        assert!(fixture.contains("```javascript"));
        assert!(fixture.contains("```bash"));
        assert!(fixture.contains("```json"));
        assert!(fixture.contains("```diff"));
    }

    #[test]
    fn rich_preview_fixture_covers_the_runtime_features_claimed_by_shared_render_contract() {
        let fixture = fs::read_to_string(rich_preview_fixture_path())
            .expect("rich-preview fixture should be readable");
        let rendering = macos_rendering_reference();

        assert!(fixture.contains("# H1"));
        assert!(fixture.contains("普通段落可以混合"));
        assert!(fixture.contains("**粗体**"));
        assert!(fixture.contains("```swift"));
        assert!(fixture.contains("> 这是一级引用。"));
        assert!(fixture.contains("- [x] 已完成任务"));
        assert!(fixture.contains("| Name | Type | Status | Notes |"));
        if rendering.runtime.supports_mermaid {
            assert!(fixture.contains("```mermaid"));
            assert!(fixture.contains("sequenceDiagram"));
        }
        if rendering.runtime.supports_math {
            assert!(fixture.contains("$$"));
            assert!(fixture.contains("\\nabla"));
        }
        assert!(fixture.contains("![Placeholder Diagram]"));
        if rendering.runtime.supports_footnotes {
            assert!(fixture.contains("[^note1]"));
        }
        if rendering.runtime.html_blocks_passthrough {
            assert!(fixture.contains("<details open>"));
            assert!(fixture.contains("<div style="));
        }
    }

    #[test]
    fn edit_source_helpers_follow_macos_line_mapping_and_splice_rules() {
        let blocks = sample_blocks();
        let editing = EditingState {
            phase: EditingPhase::Active,
            target_start_line: Some(3),
            target_end_line: Some(5),
            draft_markdown: Some(
                "line 1\nline 2\nline 3\nupdated\nblock\nline 6\nline 7\nline 8\nline 9\nline 10"
                    .to_string(),
            ),
            draft_source: Some("updated\nblock".to_string()),
        };

        let block = find_block_by_line_range(&blocks, 3, 5).expect("block");
        assert_eq!(block.block_id, 2);
        assert_eq!(
            block_source_for_mapping(sample_markdown(), &block).as_deref(),
            Some("line 4\nline 5")
        );
        assert_eq!(
            apply_inline_edit_to_markdown(sample_markdown(), &block, "updated\r\nblock").as_deref(),
            Some("line 1\nline 2\nline 3\nupdated\nblock\nline 6\nline 7\nline 8\nline 9\nline 10")
        );

        let model =
            build_inline_editor_model_for_editing_state(sample_markdown(), &blocks, &editing)
                .expect("inline editor model");
        assert_eq!(model.original_source, "line 4\nline 5");
        assert_eq!(model.editable_source, "updated\nblock");
        assert_eq!(model.source_line_label, "Editing source lines 4-5");
    }

    fn markdown_renderer_swift_path() -> PathBuf {
        PathBuf::from(env!("CARGO_MANIFEST_DIR"))
            .join("../../apps/macos/Sources/FastMD/MarkdownRenderer.swift")
    }

    fn shared_frontend_app_path() -> PathBuf {
        PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("../../ui/src/app.ts")
    }

    fn shared_frontend_markdown_path() -> PathBuf {
        PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("../../ui/src/markdown.ts")
    }

    fn shared_frontend_styles_path() -> PathBuf {
        PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("../../ui/src/styles.css")
    }

    fn shared_frontend_fixtures_path() -> PathBuf {
        PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("../../ui/src/fixtures.ts")
    }

    fn rich_preview_fixture_path() -> PathBuf {
        PathBuf::from(env!("CARGO_MANIFEST_DIR"))
            .join("../../Tests/Fixtures/Markdown/rich-preview.md")
    }

    fn typescript_string_literal(value: &str) -> String {
        value.replace('\\', "\\\\").replace('"', "\\\"")
    }
}
