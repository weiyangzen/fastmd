use fastmd_contracts::{BackgroundMode, MACOS_REFERENCE_BEHAVIOR};
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
pub struct HintChipContract {
    pub width_label: String,
    pub background_label: String,
    pub paging_label: String,
    pub background_icon: String,
    pub paging_icon: String,
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
    pub hint_chip: HintChipContract,
    pub background_mode: BackgroundMode,
    pub selected_width_tier_index: usize,
    pub width_tiers_px: Vec<u32>,
    pub theme: ThemeVariables,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct InlineEditorModel {
    pub block: BlockMapping,
    pub original_source: String,
    pub status_text: String,
    pub save_label: String,
    pub cancel_label: String,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct PreviewModel {
    pub document: PreviewDocumentModel,
    pub chrome: PreviewChromeModel,
    pub block_mappings: Vec<BlockMapping>,
    pub inline_editor: Option<InlineEditorModel>,
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
    let clamped = clamped_width_tier_index(selected_width_tier_index as isize);
    MACOS_REFERENCE_BEHAVIOR.hint_chip.width_label(
        clamped,
        MACOS_REFERENCE_BEHAVIOR
            .preview_geometry
            .width_tiers_px
            .len(),
    )
}

pub fn hint_chip_contract(selected_width_tier_index: usize) -> HintChipContract {
    HintChipContract {
        width_label: width_label(selected_width_tier_index),
        background_label: MACOS_REFERENCE_BEHAVIOR
            .hint_chip
            .background_label
            .to_string(),
        paging_label: MACOS_REFERENCE_BEHAVIOR.hint_chip.paging_label.to_string(),
        background_icon: MACOS_REFERENCE_BEHAVIOR
            .hint_chip
            .background_icon
            .to_string(),
        paging_icon: MACOS_REFERENCE_BEHAVIOR.hint_chip.paging_icon.to_string(),
    }
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

pub fn preview_chrome_model(
    selected_width_tier_index: usize,
    background_mode: BackgroundMode,
) -> PreviewChromeModel {
    let clamped = clamped_width_tier_index(selected_width_tier_index as isize);
    PreviewChromeModel {
        hint_chip: hint_chip_contract(clamped),
        background_mode,
        selected_width_tier_index: clamped,
        width_tiers_px: MACOS_REFERENCE_BEHAVIOR
            .preview_geometry
            .width_tiers_px
            .to_vec(),
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
        let model = preview_model(
            "spec.md",
            "# Title",
            8,
            BackgroundMode::Black,
            sample_blocks(),
            Some(InlineEditorModel {
                block: BlockMapping {
                    block_id: 2,
                    kind: BlockKind::Paragraph,
                    start_line: 3,
                    end_line: 5,
                },
                original_source: "hello".to_string(),
                status_text: "Edit mode is locked until you save or cancel.".to_string(),
                save_label: "Save".to_string(),
                cancel_label: "Cancel".to_string(),
            }),
        );

        assert_eq!(model.chrome.selected_width_tier_index, 3);
        assert_eq!(model.chrome.hint_chip.width_label, "← 4/4 →");
        assert_eq!(model.chrome.background_mode, BackgroundMode::Black);

        let encoded = serde_json::to_string(&model).expect("serialize");
        let decoded: PreviewModel = serde_json::from_str(&encoded).expect("deserialize");
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
            .contains(&MarkdownFeature::Mermaid));
        assert!(contract.supported_features.contains(&MarkdownFeature::Math));
        assert!(contract
            .supported_features
            .contains(&MarkdownFeature::HtmlBlock));
    }
}
