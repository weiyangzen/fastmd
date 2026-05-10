import Foundation

public enum IOSReaderAccessibilityControl: String, CaseIterable, Equatable, Sendable {
    case openMarkdown
    case searchDocument
    case editSource
    case fontSize
    case previousSearchResult
    case nextSearchResult
    case clearSearch
    case copyCode
    case cancelSourceEdit
    case saveSourceEdit
    case cancelBlockEdit
    case saveBlockEdit

    public var label: String {
        switch self {
        case .openMarkdown:
            return "Open Markdown"
        case .searchDocument:
            return "Search Document"
        case .editSource:
            return "Edit Source"
        case .fontSize:
            return "Font Size"
        case .previousSearchResult:
            return "Previous Search Result"
        case .nextSearchResult:
            return "Next Search Result"
        case .clearSearch:
            return "Clear Search"
        case .copyCode:
            return "Copy Code"
        case .cancelSourceEdit:
            return "Cancel Source Edit"
        case .saveSourceEdit:
            return "Save Source Edit"
        case .cancelBlockEdit:
            return "Cancel Block Edit"
        case .saveBlockEdit:
            return "Save Block Edit"
        }
    }
}

public enum IOSReaderAccessibilityElementKind: String, CaseIterable, Equatable, Sendable {
    case toolbar
    case searchBar
    case readerBlock
    case editorWarning
    case editor
    case recentDocument
    case progress
    case error
}

public struct IOSReaderAccessibilityElement: Equatable, Sendable {
    public let kind: IOSReaderAccessibilityElementKind
    public let label: String
    public let visualOrder: Int
    public let voiceOverOrder: Int
    public let isAlert: Bool

    public init(
        kind: IOSReaderAccessibilityElementKind,
        label: String,
        visualOrder: Int,
        voiceOverOrder: Int,
        isAlert: Bool = false
    ) {
        self.kind = kind
        self.label = label
        self.visualOrder = visualOrder
        self.voiceOverOrder = voiceOverOrder
        self.isAlert = isAlert
    }
}

public struct IOSReaderAccessibilityAudit: Equatable, Sendable {
    public let iconOnlyControlLabels: [IOSReaderAccessibilityControl: String]
    public let elements: [IOSReaderAccessibilityElement]
    public let searchAnnouncement: String?
    public let dirtyEditAlert: IOSReaderAccessibilityElement?

    public init(
        iconOnlyControlLabels: [IOSReaderAccessibilityControl: String],
        elements: [IOSReaderAccessibilityElement],
        searchAnnouncement: String?,
        dirtyEditAlert: IOSReaderAccessibilityElement?
    ) {
        self.iconOnlyControlLabels = iconOnlyControlLabels
        self.elements = elements
        self.searchAnnouncement = searchAnnouncement
        self.dirtyEditAlert = dirtyEditAlert
    }

    public var hasLabelsForAllIconOnlyControls: Bool {
        IOSReaderAccessibilityControl.allCases.allSatisfy { control in
            iconOnlyControlLabels[control]?.isEmpty == false
        }
    }

    public var voiceOverOrderMatchesVisualOrder: Bool {
        elements.map(\.visualOrder) == elements.map(\.voiceOverOrder)
    }

    public var hasAccessibleDirtyEditAlert: Bool {
        dirtyEditAlert?.isAlert == true
    }
}

public struct IOSDynamicTypeFontTierAudit: Equatable, Sendable {
    public let metricsByTier: [MobileFontTier: [NativeMarkdownTextSurface: NativeMarkdownTextMetrics]]

    public init(metricsByTier: [MobileFontTier: [NativeMarkdownTextSurface: NativeMarkdownTextMetrics]]) {
        self.metricsByTier = metricsByTier
    }

    public var validatesAllFourTiers: Bool {
        Set(metricsByTier.keys) == Set(MobileFontTier.allCases)
    }

    public var allMetricsComposeWithDynamicType: Bool {
        metricsByTier.values
            .flatMap { $0.values }
            .allSatisfy { $0.usesDynamicTypeTextStyle && !$0.dynamicTypeTextStyle.isEmpty }
    }
}

public struct IOSReaderAccessibilityPolicy: Equatable, Sendable {
    public init() {}

    public var iconOnlyControlLabels: [IOSReaderAccessibilityControl: String] {
        Dictionary(uniqueKeysWithValues: IOSReaderAccessibilityControl.allCases.map { ($0, $0.label) })
    }

    public func searchAnnouncement(for state: IOSReaderSearchState?) -> String? {
        guard let state else {
            return nil
        }

        if state.matches.isEmpty {
            return "No search results"
        }

        return "Search result \(state.resultSummary)"
    }

    public func audit(for state: IOSReaderScreenState) -> IOSReaderAccessibilityAudit {
        var order = 0
        var elements: [IOSReaderAccessibilityElement] = [
            element(.toolbar, label: "Reader Toolbar", order: &order)
        ]

        if state.isSearchVisible {
            elements.append(element(.searchBar, label: "Search Results", order: &order))
        }

        switch state.readerState {
        case .empty:
            elements.append(contentsOf: state.recentDocuments.map { recent in
                element(.recentDocument, label: recent.displayName, order: &order)
            })
        case .loading, .rendering, .saving:
            elements.append(element(.progress, label: state.progress?.title ?? "Working", order: &order))
        case .ready, .readOnly, .searching:
            elements.append(contentsOf: state.renderedBlocks.map { block in
                element(.readerBlock, label: block.plainText, order: &order)
            })
        case .editingSource, .editingBlock:
            if state.isDirtyEditing {
                elements.append(
                    element(.editorWarning, label: "Unsaved changes", order: &order, isAlert: true)
                )
            }
            elements.append(element(.editor, label: "Markdown Source Editor", order: &order))
        case .permissionLost, .error:
            elements.append(element(.error, label: state.errorCode?.rawValue ?? "Error", order: &order))
        }

        return IOSReaderAccessibilityAudit(
            iconOnlyControlLabels: iconOnlyControlLabels,
            elements: elements,
            searchAnnouncement: searchAnnouncement(for: state.searchState),
            dirtyEditAlert: elements.first { $0.kind == .editorWarning }
        )
    }

    public func dynamicTypeAudit() -> IOSDynamicTypeFontTierAudit {
        let metricsByTier = Dictionary(
            uniqueKeysWithValues: MobileFontTier.allCases.map { tier in
                let typography = NativeMarkdownTypography(fontTier: tier)
                let metrics = Dictionary(
                    uniqueKeysWithValues: NativeMarkdownTextSurface.allCases.map { surface in
                        (surface, typography.metrics(for: surface))
                    }
                )
                return (tier, metrics)
            }
        )
        return IOSDynamicTypeFontTierAudit(metricsByTier: metricsByTier)
    }

    private func element(
        _ kind: IOSReaderAccessibilityElementKind,
        label: String,
        order: inout Int,
        isAlert: Bool = false
    ) -> IOSReaderAccessibilityElement {
        let currentOrder = order
        order += 1
        return IOSReaderAccessibilityElement(
            kind: kind,
            label: IOSDisplayNamePolicy(maximumCharacterCount: 140).displayName(for: label),
            visualOrder: currentOrder,
            voiceOverOrder: currentOrder,
            isAlert: isAlert
        )
    }
}

public enum IOSDiagnosticsFileSizeBucket: String, CaseIterable, Equatable, Sendable {
    case empty
    case small
    case medium
    case large
    case huge
}

public struct IOSDiagnosticsSnapshot: Equatable, Sendable {
    public let parseMilliseconds: Double?
    public let renderMilliseconds: Double?
    public let searchMilliseconds: Double?
    public let saveMilliseconds: Double?
    public let deviceClass: MobilePerformanceProfileKind
    public let rendererProfile: String
    public let fileSizeBucket: IOSDiagnosticsFileSizeBucket
    public let lastErrorCategory: FastMDErrorCategory?
    public let includesDocumentContent: Bool
    public let includesFullPath: Bool
    public let includesFullURI: Bool
    public let includesQueryStrings: Bool
    public let includesClipboard: Bool

    public init(
        parseMilliseconds: Double?,
        renderMilliseconds: Double?,
        searchMilliseconds: Double?,
        saveMilliseconds: Double?,
        deviceClass: MobilePerformanceProfileKind,
        rendererProfile: String,
        fileSizeBucket: IOSDiagnosticsFileSizeBucket,
        lastErrorCategory: FastMDErrorCategory?,
        includesDocumentContent: Bool = false,
        includesFullPath: Bool = false,
        includesFullURI: Bool = false,
        includesQueryStrings: Bool = false,
        includesClipboard: Bool = false
    ) {
        self.parseMilliseconds = parseMilliseconds
        self.renderMilliseconds = renderMilliseconds
        self.searchMilliseconds = searchMilliseconds
        self.saveMilliseconds = saveMilliseconds
        self.deviceClass = deviceClass
        self.rendererProfile = rendererProfile
        self.fileSizeBucket = fileSizeBucket
        self.lastErrorCategory = lastErrorCategory
        self.includesDocumentContent = includesDocumentContent
        self.includesFullPath = includesFullPath
        self.includesFullURI = includesFullURI
        self.includesQueryStrings = includesQueryStrings
        self.includesClipboard = includesClipboard
    }

    public var isRedactedForLocalExport: Bool {
        !includesDocumentContent
            && !includesFullPath
            && !includesFullURI
            && !includesQueryStrings
            && !includesClipboard
    }
}

public struct IOSDiagnosticsBuilder: Equatable, Sendable {
    public init() {}

    public func fileSizeBucket(byteCount: Int?) -> IOSDiagnosticsFileSizeBucket {
        guard let byteCount, byteCount > 0 else {
            return .empty
        }

        switch byteCount {
        case 1..<100_000:
            return .small
        case 100_000..<1_000_000:
            return .medium
        case 1_000_000..<5_000_000:
            return .large
        default:
            return .huge
        }
    }

    public func snapshot(
        parseMilliseconds: Double?,
        renderMilliseconds: Double?,
        searchMilliseconds: Double?,
        saveMilliseconds: Double?,
        deviceClass: MobilePerformanceProfileKind = .iOSPhone12Standard,
        rendererProfile: String = "native-swiftui-uikit",
        byteCount: Int?,
        lastErrorCode: FastMDErrorCode?
    ) -> IOSDiagnosticsSnapshot {
        IOSDiagnosticsSnapshot(
            parseMilliseconds: parseMilliseconds,
            renderMilliseconds: renderMilliseconds,
            searchMilliseconds: searchMilliseconds,
            saveMilliseconds: saveMilliseconds,
            deviceClass: deviceClass,
            rendererProfile: rendererProfile,
            fileSizeBucket: fileSizeBucket(byteCount: byteCount),
            lastErrorCategory: lastErrorCode?.category
        )
    }
}
