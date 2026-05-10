import Foundation

public enum IOSReaderEditMode: String, CaseIterable, Equatable, Sendable {
    case source
    case block
}

public struct IOSReaderEditSession: Equatable, Sendable {
    public let mode: IOSReaderEditMode
    public let originalSource: String
    public let currentSource: String
    public let returnReaderState: ReaderState
    public let blockID: MarkdownBlockID?
    public let sourceRange: MarkdownSourceRange?

    public init(
        mode: IOSReaderEditMode,
        originalSource: String,
        currentSource: String,
        returnReaderState: ReaderState = .ready,
        blockID: MarkdownBlockID? = nil,
        sourceRange: MarkdownSourceRange? = nil
    ) {
        self.mode = mode
        self.originalSource = originalSource
        self.currentSource = currentSource
        self.returnReaderState = returnReaderState
        self.blockID = blockID
        self.sourceRange = sourceRange
    }

    public var isDirty: Bool {
        currentSource != originalSource
    }
}

public struct IOSReaderScrollPosition: Equatable, Sendable {
    public let anchorBlockID: MarkdownBlockID?
    public let yOffsetWithinBlock: Double

    public init(
        anchorBlockID: MarkdownBlockID?,
        yOffsetWithinBlock: Double = 0
    ) {
        self.anchorBlockID = anchorBlockID
        self.yOffsetWithinBlock = yOffsetWithinBlock
    }
}

public struct IOSReaderNavigationContext: Equatable, Sendable {
    public let state: IOSReaderScreenState
    public let editSession: IOSReaderEditSession?

    public init(
        state: IOSReaderScreenState,
        editSession: IOSReaderEditSession? = nil
    ) {
        self.state = state
        self.editSession = editSession ?? state.editSession
    }
}

public enum IOSReaderNavigationAction: Equatable, Sendable {
    case none
    case closeSearch(IOSReaderScreenState)
    case closeEditor(IOSReaderScreenState)
    case requestDiscardConfirmation(IOSReaderEditMode)
    case showRecentDocuments(IOSReaderScreenState)
    case stayOnCurrentState
}

public struct IOSReaderNavigationEngine: Equatable, Sendable {
    public init() {}

    public func backAction(
        for context: IOSReaderNavigationContext
    ) -> IOSReaderNavigationAction {
        let state = context.state

        if state.isSearchVisible {
            return .closeSearch(state.withoutSearch())
        }

        switch state.readerState {
        case .editingBlock:
            return editorBackAction(for: context, expectedMode: .block)

        case .editingSource:
            return editorBackAction(for: context, expectedMode: .source)

        case .ready, .readOnly, .permissionLost, .error:
            return .showRecentDocuments(state.asRecentDocumentsState())

        case .loading, .rendering, .saving:
            return .stayOnCurrentState

        case .empty:
            return .none

        case .searching:
            return .closeSearch(state.withoutSearch())
        }
    }

    private func editorBackAction(
        for context: IOSReaderNavigationContext,
        expectedMode: IOSReaderEditMode
    ) -> IOSReaderNavigationAction {
        guard let editSession = context.editSession,
              editSession.mode == expectedMode else {
            return .closeEditor(context.state.asReaderState(.ready))
        }

        guard !editSession.isDirty else {
            return .requestDiscardConfirmation(editSession.mode)
        }

        return .closeEditor(context.state.asReaderState(editSession.returnReaderState))
    }
}

public struct IOSReaderRuntimeRestorationSnapshot: Equatable, Sendable {
    public let screenState: IOSReaderScreenState
    public let activeDocument: MarkdownLoadResult?
    public let scrollPosition: IOSReaderScrollPosition?
    public let editSession: IOSReaderEditSession?

    public init(
        screenState: IOSReaderScreenState,
        activeDocument: MarkdownLoadResult?,
        scrollPosition: IOSReaderScrollPosition?,
        editSession: IOSReaderEditSession?
    ) {
        self.screenState = screenState
        self.activeDocument = activeDocument
        self.scrollPosition = scrollPosition
        self.editSession = editSession
    }

    public var selectedFontTier: MobileFontTier {
        screenState.selectedFontTier
    }

    public var searchQuery: String? {
        screenState.searchState?.query
    }

    public var dirtyEditBuffer: String? {
        guard editSession?.isDirty == true else {
            return nil
        }
        return editSession?.currentSource
    }

    public var storesDocumentContentPersistently: Bool {
        false
    }
}

public struct IOSReaderRuntimeRestorationCoordinator: Equatable, Sendable {
    public init() {}

    public func capture(
        state: IOSReaderScreenState,
        activeDocument: MarkdownLoadResult?,
        scrollPosition: IOSReaderScrollPosition?,
        editSession: IOSReaderEditSession? = nil
    ) -> IOSReaderRuntimeRestorationSnapshot {
        IOSReaderRuntimeRestorationSnapshot(
            screenState: state,
            activeDocument: activeDocument,
            scrollPosition: scrollPosition,
            editSession: editSession
        )
    }

    public func restore(
        _ snapshot: IOSReaderRuntimeRestorationSnapshot
    ) -> IOSReaderNavigationContext {
        IOSReaderNavigationContext(
            state: snapshot.screenState,
            editSession: snapshot.editSession
        )
    }
}

private extension IOSReaderScreenState {
    func withoutSearch() -> IOSReaderScreenState {
        asReaderState(readerState == .readOnly || subtitle?.hasPrefix("Read-only") == true ? .readOnly : .ready)
    }

    func asRecentDocumentsState() -> IOSReaderScreenState {
        IOSReaderScreenState(
            readerState: .empty,
            title: "FastMD",
            subtitle: recentDocuments.isEmpty ? nil : "Recent documents",
            selectedFontTier: selectedFontTier,
            themeScheme: themeScheme,
            recentDocuments: recentDocuments,
            isOpenActionAvailable: true,
            isSearchAvailable: false
        )
    }

    func asReaderState(_ readerState: ReaderState) -> IOSReaderScreenState {
        IOSReaderScreenState(
            readerState: readerState,
            title: title,
            subtitle: subtitle,
            selectedFontTier: selectedFontTier,
            themeScheme: themeScheme,
            recentDocuments: recentDocuments,
            renderedBlocks: renderedBlocks,
            progress: nil,
            errorCode: nil,
            searchState: nil,
            isOpenActionAvailable: isOpenActionAvailable,
            isSearchAvailable: isSearchAvailable
        )
    }
}
