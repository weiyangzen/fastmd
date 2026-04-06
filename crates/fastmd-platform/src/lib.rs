use fastmd_contracts::{
    CloseReason, FrontSurface, HostCapabilities, HostError, HoveredItem, LoadedDocument,
    MonitorMetadata, PermissionState, PlatformId, PreviewWindowRequest, ResolvedDocument,
    ScreenPoint,
};

pub trait HostSurface {
    fn platform_id(&self) -> PlatformId;
    fn capabilities(&self) -> HostCapabilities;
    fn permission_state(&self) -> Result<PermissionState, HostError>;
    fn request_permissions(&self) -> Result<PermissionState, HostError>;
    fn current_front_surface(&self) -> Result<FrontSurface, HostError>;
    fn hovered_item(&self, cursor: ScreenPoint) -> Result<Option<HoveredItem>, HostError>;
    fn available_monitors(&self) -> Result<Vec<MonitorMetadata>, HostError>;
}

pub trait PreviewWindowHost {
    fn show_preview(&self, request: PreviewWindowRequest) -> Result<(), HostError>;
    fn move_preview(&self, request: PreviewWindowRequest) -> Result<(), HostError>;
    fn hide_preview(&self, reason: CloseReason) -> Result<(), HostError>;
}

pub trait DocumentHost {
    fn load_markdown(&self, document: &ResolvedDocument) -> Result<LoadedDocument, HostError>;
    fn save_markdown(&self, document: &ResolvedDocument, content: &str) -> Result<(), HostError>;
}

#[cfg(test)]
mod tests {
    use super::*;
    use fastmd_contracts::{
        BackgroundMode, DocumentKind, DocumentOrigin, DocumentPath, FrontSurfaceIdentity,
        FrontSurfaceKind, HostErrorCode, PreviewWindowRequest, ScreenRect,
    };

    #[derive(Debug, Clone)]
    struct StubHost;

    impl HostSurface for StubHost {
        fn platform_id(&self) -> PlatformId {
            PlatformId::MacosFinder
        }

        fn capabilities(&self) -> HostCapabilities {
            HostCapabilities {
                supports_front_surface_detection: true,
                supports_hover_resolution: true,
                supports_preview_window: true,
                supports_inline_editing: true,
                supports_multi_monitor_placement: true,
                supports_global_mouse_monitoring: true,
                supports_background_toggle: true,
                supports_paging: true,
            }
        }

        fn permission_state(&self) -> Result<PermissionState, HostError> {
            Ok(PermissionState::Granted)
        }

        fn request_permissions(&self) -> Result<PermissionState, HostError> {
            Ok(PermissionState::Granted)
        }

        fn current_front_surface(&self) -> Result<FrontSurface, HostError> {
            Ok(FrontSurface {
                platform_id: PlatformId::MacosFinder,
                surface_kind: FrontSurfaceKind::FinderListView,
                app_identifier: "com.apple.finder".to_string(),
                window_title: Some("Docs".to_string()),
                directory: Some(DocumentPath::from("/Users/example/Docs")),
                stable_identity: Some(
                    FrontSurfaceIdentity::new("finder-window-1").with_process_id(7_001),
                ),
                expected_host: true,
            })
        }

        fn hovered_item(&self, cursor: ScreenPoint) -> Result<Option<HoveredItem>, HostError> {
            Ok(Some(HoveredItem {
                document: ResolvedDocument::new(
                    "/Users/example/Docs/spec.md",
                    "spec.md",
                    DocumentOrigin::LocalFileSystem,
                    DocumentKind::File,
                ),
                screen_point: cursor,
                element_description: "Finder row subtree direct path".to_string(),
            }))
        }

        fn available_monitors(&self) -> Result<Vec<MonitorMetadata>, HostError> {
            Ok(vec![MonitorMetadata {
                id: "main".to_string(),
                name: Some("Studio Display".to_string()),
                frame: ScreenRect::new(0.0, 0.0, 3024.0, 1964.0),
                visible_frame: ScreenRect::new(0.0, 25.0, 3024.0, 1910.0),
                scale_factor: 2.0,
                is_primary: true,
            }])
        }
    }

    impl PreviewWindowHost for StubHost {
        fn show_preview(&self, _request: PreviewWindowRequest) -> Result<(), HostError> {
            Ok(())
        }

        fn move_preview(&self, _request: PreviewWindowRequest) -> Result<(), HostError> {
            Ok(())
        }

        fn hide_preview(&self, _reason: CloseReason) -> Result<(), HostError> {
            Ok(())
        }
    }

    impl DocumentHost for StubHost {
        fn load_markdown(&self, document: &ResolvedDocument) -> Result<LoadedDocument, HostError> {
            Ok(LoadedDocument {
                document: document.clone(),
                encoding: "utf-8".to_string(),
                markdown: "# Title".to_string(),
            })
        }

        fn save_markdown(
            &self,
            _document: &ResolvedDocument,
            _content: &str,
        ) -> Result<(), HostError> {
            Ok(())
        }
    }

    #[test]
    fn traits_match_the_shared_contract_surface() {
        let host = StubHost;
        let item = host
            .hovered_item(ScreenPoint::new(120.0, 220.0))
            .expect("hovered item")
            .expect("resolved item");
        let request = PreviewWindowRequest {
            document: item.document.clone(),
            title: "spec.md".to_string(),
            anchor: ScreenPoint::new(120.0, 220.0),
            frame: ScreenRect::new(100.0, 140.0, 960.0, 720.0),
            selected_width_tier_index: 1,
            requested_width_px: 960,
            background_mode: BackgroundMode::White,
            interaction_hot: true,
            monitor_id: Some("main".to_string()),
        };

        assert_eq!(host.platform_id(), PlatformId::MacosFinder);
        assert!(host.capabilities().supports_preview_window);
        assert_eq!(
            host.permission_state().expect("permission"),
            PermissionState::Granted
        );
        assert!(host
            .current_front_surface()
            .expect("surface")
            .is_expected_host());
        assert!(item.document.is_local_markdown_file());
        assert_eq!(host.available_monitors().expect("monitors").len(), 1);
        host.show_preview(request.clone()).expect("show");
        host.move_preview(request).expect("move");
        host.hide_preview(CloseReason::OutsideClick).expect("hide");
        host.load_markdown(&item.document).expect("load");
        host.save_markdown(&item.document, "# Updated")
            .expect("save");
    }

    #[test]
    fn host_errors_flow_through_trait_results() {
        let error = HostError::new(
            HostErrorCode::PermissionDenied,
            "Accessibility permission missing",
            PlatformId::MacosFinder,
            false,
        );

        assert!(error
            .to_string()
            .contains("Accessibility permission missing"));
    }
}
