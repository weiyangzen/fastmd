use crate::target::DisplayServerKind;

/// Authoritative host-facing inputs for hovered Nautilus item resolution.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum NautilusHoveredItemApi {
    /// `org.a11y.atspi.Component.GetAccessibleAtPoint` in screen coordinates.
    AtspiComponentGetAccessibleAtPoint,
    /// `org.a11y.atspi.Accessible.GetChildren` /
    /// `org.a11y.atspi.Accessible.GetChildAtIndex` on the hovered lineage.
    AtspiAccessibleGetChildren,
    /// `org.a11y.atspi.Accessible.GetRole` / `GetRoleName` for list and row
    /// classification.
    AtspiAccessibleGetRole,
    /// `org.a11y.atspi.Accessible.GetAttributes` for URI or path-style
    /// metadata exposed by Nautilus widgets.
    AtspiAccessibleGetAttributes,
    /// `org.a11y.atspi.Text.GetText` for the visible file-name label when no
    /// direct URI-like attribute is available.
    AtspiTextGetText,
    /// GTK accessibility roles used by Nautilus rows and list descendants.
    GtkAccessibleListRoles,
}

impl NautilusHoveredItemApi {
    /// Stable human-readable diagnostic label.
    pub const fn label(self) -> &'static str {
        match self {
            Self::AtspiComponentGetAccessibleAtPoint => {
                "AT-SPI Component.GetAccessibleAtPoint(screen)"
            }
            Self::AtspiAccessibleGetChildren => "AT-SPI Accessible.GetChildren/GetChildAtIndex",
            Self::AtspiAccessibleGetRole => "AT-SPI Accessible.GetRole/GetRoleName",
            Self::AtspiAccessibleGetAttributes => "AT-SPI Accessible.GetAttributes",
            Self::AtspiTextGetText => "AT-SPI Text.GetText",
            Self::GtkAccessibleListRoles => "GTK accessible roles LIST/LIST_ITEM/ROW",
        }
    }
}

/// Explicit hovered-item detection stack for one Linux display-server backend.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct NautilusHoveredItemApiStack {
    pub display_server: DisplayServerKind,
    pub pointer_hit_test: NautilusHoveredItemApi,
    pub lineage_walk: NautilusHoveredItemApi,
    pub role_filter: NautilusHoveredItemApi,
    pub metadata_attributes: NautilusHoveredItemApi,
    pub visible_label_text: NautilusHoveredItemApi,
    pub gtk_role_reference: NautilusHoveredItemApi,
}

impl NautilusHoveredItemApiStack {
    /// Stable summary for diagnostics and documentation.
    pub fn diagnostic_summary(self) -> String {
        format!(
            "pointer={} + lineage={} + role={} + metadata={} + label={} + gtk_roles={}",
            self.pointer_hit_test.label(),
            self.lineage_walk.label(),
            self.role_filter.label(),
            self.metadata_attributes.label(),
            self.visible_label_text.label(),
            self.gtk_role_reference.label(),
        )
    }
}

pub static WAYLAND_HOVERED_ITEM_API_STACK: NautilusHoveredItemApiStack =
    NautilusHoveredItemApiStack {
        display_server: DisplayServerKind::Wayland,
        pointer_hit_test: NautilusHoveredItemApi::AtspiComponentGetAccessibleAtPoint,
        lineage_walk: NautilusHoveredItemApi::AtspiAccessibleGetChildren,
        role_filter: NautilusHoveredItemApi::AtspiAccessibleGetRole,
        metadata_attributes: NautilusHoveredItemApi::AtspiAccessibleGetAttributes,
        visible_label_text: NautilusHoveredItemApi::AtspiTextGetText,
        gtk_role_reference: NautilusHoveredItemApi::GtkAccessibleListRoles,
    };

pub static X11_HOVERED_ITEM_API_STACK: NautilusHoveredItemApiStack = NautilusHoveredItemApiStack {
    display_server: DisplayServerKind::X11,
    pointer_hit_test: NautilusHoveredItemApi::AtspiComponentGetAccessibleAtPoint,
    lineage_walk: NautilusHoveredItemApi::AtspiAccessibleGetChildren,
    role_filter: NautilusHoveredItemApi::AtspiAccessibleGetRole,
    metadata_attributes: NautilusHoveredItemApi::AtspiAccessibleGetAttributes,
    visible_label_text: NautilusHoveredItemApi::AtspiTextGetText,
    gtk_role_reference: NautilusHoveredItemApi::GtkAccessibleListRoles,
};

pub fn hovered_item_api_stack_for_display_server(
    display_server: DisplayServerKind,
) -> &'static NautilusHoveredItemApiStack {
    match display_server {
        DisplayServerKind::Wayland => &WAYLAND_HOVERED_ITEM_API_STACK,
        DisplayServerKind::X11 => &X11_HOVERED_ITEM_API_STACK,
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn authoritative_hovered_item_api_stacks_are_explicit() {
        assert_eq!(
            WAYLAND_HOVERED_ITEM_API_STACK.pointer_hit_test,
            NautilusHoveredItemApi::AtspiComponentGetAccessibleAtPoint
        );
        assert_eq!(
            WAYLAND_HOVERED_ITEM_API_STACK.lineage_walk,
            NautilusHoveredItemApi::AtspiAccessibleGetChildren
        );
        assert_eq!(
            WAYLAND_HOVERED_ITEM_API_STACK.role_filter,
            NautilusHoveredItemApi::AtspiAccessibleGetRole
        );
        assert_eq!(
            WAYLAND_HOVERED_ITEM_API_STACK.metadata_attributes,
            NautilusHoveredItemApi::AtspiAccessibleGetAttributes
        );
        assert_eq!(
            WAYLAND_HOVERED_ITEM_API_STACK.visible_label_text,
            NautilusHoveredItemApi::AtspiTextGetText
        );
        assert_eq!(
            WAYLAND_HOVERED_ITEM_API_STACK.gtk_role_reference,
            NautilusHoveredItemApi::GtkAccessibleListRoles
        );
    }

    #[test]
    fn hovered_item_stack_lookup_matches_the_display_server() {
        assert_eq!(
            hovered_item_api_stack_for_display_server(DisplayServerKind::Wayland),
            &WAYLAND_HOVERED_ITEM_API_STACK
        );
        assert_eq!(
            hovered_item_api_stack_for_display_server(DisplayServerKind::X11),
            &X11_HOVERED_ITEM_API_STACK
        );
    }

    #[test]
    fn hovered_item_stack_summary_stays_diagnostic_friendly() {
        let summary = WAYLAND_HOVERED_ITEM_API_STACK.diagnostic_summary();

        assert!(summary.contains("AT-SPI Component.GetAccessibleAtPoint(screen)"));
        assert!(summary.contains("AT-SPI Accessible.GetAttributes"));
        assert!(summary.contains("GTK accessible roles LIST/LIST_ITEM/ROW"));
    }
}
