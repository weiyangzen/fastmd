import Foundation
import Darwin

@inline(__always)
func iosIsMainThreadForDiagnostics() -> Bool {
    pthread_main_np() != 0
}

public struct IOSOffMainActorExecutionMetadata: Equatable, Sendable {
    public let scheduledWithDetachedTask: Bool
    public let startedOnMainThread: Bool
    public let completedOnMainThread: Bool

    public init(
        scheduledWithDetachedTask: Bool,
        startedOnMainThread: Bool,
        completedOnMainThread: Bool
    ) {
        self.scheduledWithDetachedTask = scheduledWithDetachedTask
        self.startedOnMainThread = startedOnMainThread
        self.completedOnMainThread = completedOnMainThread
    }

    public var stayedOffMainThread: Bool {
        scheduledWithDetachedTask && !startedOnMainThread && !completedOnMainThread
    }
}

public struct IOSOffMainActorWorkResult<Value: Sendable>: Sendable {
    public let value: Value
    public let execution: IOSOffMainActorExecutionMetadata

    public init(value: Value, execution: IOSOffMainActorExecutionMetadata) {
        self.value = value
        self.execution = execution
    }
}

public struct IOSDisplayNamePolicy: Equatable, Sendable {
    public let fallbackName: String
    public let maximumCharacterCount: Int

    public init(
        fallbackName: String = "Untitled Markdown",
        maximumCharacterCount: Int = 96
    ) {
        self.fallbackName = fallbackName
        self.maximumCharacterCount = max(16, maximumCharacterCount)
    }

    public func displayName(for rawName: String?) -> String {
        guard let rawName else {
            return fallbackName
        }

        let flattened = rawName
            .replacingOccurrences(of: "\r", with: " ")
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\t", with: " ")
        let collapsed = flattened
            .split(whereSeparator: { $0.isWhitespace })
            .joined(separator: " ")
        let leaf = collapsed
            .split(whereSeparator: { $0 == "/" || $0 == "\\" })
            .last
            .map(String.init) ?? collapsed
        let trimmed = leaf.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {
            return fallbackName
        }

        return truncate(trimmed)
    }

    private func truncate(_ name: String) -> String {
        guard name.count > maximumCharacterCount else {
            return name
        }

        let marker = "..."
        let extensionText = extensionToPreserve(in: name)
        let prefixCount = maximumCharacterCount - marker.count - extensionText.count

        guard prefixCount >= 8 else {
            return String(name.prefix(maximumCharacterCount - marker.count)) + marker
        }

        return String(name.prefix(prefixCount)) + marker + extensionText
    }

    private func extensionToPreserve(in name: String) -> String {
        guard let dotIndex = name.lastIndex(of: "."),
              dotIndex != name.startIndex else {
            return ""
        }

        let extensionText = String(name[dotIndex...])
        guard extensionText.count <= 12,
              extensionText.count < name.count else {
            return ""
        }

        return extensionText
    }
}

public struct IOSRecentDocumentSummary: Equatable, Sendable {
    public let identifier: String
    public let displayName: String
    public let contentTypeIdentifier: String?
    public let byteCount: Int?
    public let lastOpenedAt: Date?

    public init(
        identifier: String,
        displayName: String,
        contentTypeIdentifier: String? = nil,
        byteCount: Int? = nil,
        lastOpenedAt: Date? = nil
    ) {
        self.identifier = identifier
        self.displayName = IOSDisplayNamePolicy().displayName(for: displayName)
        self.contentTypeIdentifier = contentTypeIdentifier
        self.byteCount = byteCount
        self.lastOpenedAt = lastOpenedAt
    }

    public init(record: IOSRecentDocumentRecord) {
        self.init(
            identifier: record.identifier,
            displayName: record.displayName,
            contentTypeIdentifier: record.contentTypeIdentifier,
            byteCount: record.byteCount,
            lastOpenedAt: record.lastOpenedAt
        )
    }
}

public struct IOSReaderProgress: Equatable, Sendable {
    public let title: String
    public let message: String

    public init(title: String, message: String) {
        self.title = title
        self.message = message
    }
}

public struct IOSReaderSearchTextRange: Equatable, Sendable {
    public let startUTF16Offset: Int
    public let lengthUTF16: Int

    public init(startUTF16Offset: Int, lengthUTF16: Int) {
        self.startUTF16Offset = startUTF16Offset
        self.lengthUTF16 = lengthUTF16
    }

    public var endUTF16Offset: Int {
        startUTF16Offset + lengthUTF16
    }
}

public struct IOSReaderSearchMatch: Equatable, Sendable {
    public let blockID: MarkdownBlockID
    public let blockOrdinal: Int
    public let range: IOSReaderSearchTextRange
    public let preview: String

    public init(
        blockID: MarkdownBlockID,
        blockOrdinal: Int,
        range: IOSReaderSearchTextRange,
        preview: String
    ) {
        self.blockID = blockID
        self.blockOrdinal = blockOrdinal
        self.range = range
        self.preview = preview
    }
}

public struct IOSReaderSearchState: Equatable, Sendable {
    public let query: String
    public let matches: [IOSReaderSearchMatch]
    public let selectedMatchIndex: Int?

    public init(
        query: String,
        matches: [IOSReaderSearchMatch],
        selectedMatchIndex: Int?
    ) {
        self.query = query
        self.matches = matches
        self.selectedMatchIndex = selectedMatchIndex
    }

    public var resultCount: Int {
        matches.count
    }

    public var selectedMatch: IOSReaderSearchMatch? {
        guard let selectedMatchIndex,
              matches.indices.contains(selectedMatchIndex) else {
            return nil
        }
        return matches[selectedMatchIndex]
    }

    public var resultSummary: String {
        guard let selectedMatchIndex, !matches.isEmpty else {
            return "0 of 0"
        }
        return "\(selectedMatchIndex + 1) of \(matches.count)"
    }
}

public struct IOSReaderSearchEngine: Equatable, Sendable {
    public init() {}

    public func searchOffMainActor(
        query: String,
        in blocks: [NativeMarkdownBlockPresentation],
        selectedMatchIndex: Int = 0
    ) async -> IOSOffMainActorWorkResult<IOSReaderSearchState> {
        await Task.detached(priority: .userInitiated) {
            let startedOnMainThread = iosIsMainThreadForDiagnostics()
            let value = search(
                query: query,
                in: blocks,
                selectedMatchIndex: selectedMatchIndex
            )
            return IOSOffMainActorWorkResult(
                value: value,
                execution: IOSOffMainActorExecutionMetadata(
                    scheduledWithDetachedTask: true,
                    startedOnMainThread: startedOnMainThread,
                    completedOnMainThread: iosIsMainThreadForDiagnostics()
                )
            )
        }.value
    }

    public func search(
        query: String,
        in blocks: [NativeMarkdownBlockPresentation],
        selectedMatchIndex: Int = 0
    ) -> IOSReaderSearchState {
        let normalizedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedQuery.isEmpty else {
            return IOSReaderSearchState(query: "", matches: [], selectedMatchIndex: nil)
        }

        let matches = blocks.flatMap { blockMatches(in: $0, query: normalizedQuery) }
        let selectedIndex: Int?
        if matches.isEmpty {
            selectedIndex = nil
        } else {
            selectedIndex = min(max(0, selectedMatchIndex), matches.count - 1)
        }

        return IOSReaderSearchState(
            query: normalizedQuery,
            matches: matches,
            selectedMatchIndex: selectedIndex
        )
    }

    public func next(in state: IOSReaderSearchState) -> IOSReaderSearchState {
        guard !state.matches.isEmpty else {
            return state
        }

        let current = state.selectedMatchIndex ?? -1
        let nextIndex = (current + 1) % state.matches.count
        return IOSReaderSearchState(
            query: state.query,
            matches: state.matches,
            selectedMatchIndex: nextIndex
        )
    }

    public func previous(in state: IOSReaderSearchState) -> IOSReaderSearchState {
        guard !state.matches.isEmpty else {
            return state
        }

        let current = state.selectedMatchIndex ?? 0
        let previousIndex = (current - 1 + state.matches.count) % state.matches.count
        return IOSReaderSearchState(
            query: state.query,
            matches: state.matches,
            selectedMatchIndex: previousIndex
        )
    }

    private func blockMatches(
        in block: NativeMarkdownBlockPresentation,
        query: String
    ) -> [IOSReaderSearchMatch] {
        let searchableText = block.plainText
        let text = searchableText as NSString
        let queryLength = (query as NSString).length
        guard text.length > 0, queryLength > 0 else {
            return []
        }

        var results: [IOSReaderSearchMatch] = []
        var searchRange = NSRange(location: 0, length: text.length)

        while searchRange.location < text.length {
            let foundRange = text.range(
                of: query,
                options: [.caseInsensitive, .diacriticInsensitive],
                range: searchRange
            )

            if foundRange.location == NSNotFound {
                break
            }

            let preview = text.substring(with: foundRange)
            results.append(
                    IOSReaderSearchMatch(
                        blockID: block.id,
                        blockOrdinal: stableBlockOrdinal(for: block.id),
                        range: IOSReaderSearchTextRange(
                            startUTF16Offset: foundRange.location,
                            lengthUTF16: foundRange.length
                    ),
                    preview: preview
                )
            )

            let nextLocation = foundRange.location + max(foundRange.length, 1)
            guard nextLocation <= text.length else {
                break
            }
            searchRange = NSRange(location: nextLocation, length: text.length - nextLocation)
        }

        return results
    }

    private func stableBlockOrdinal(for id: MarkdownBlockID) -> Int {
        Int(id.rawValue.split(separator: ":").last ?? "") ?? 0
    }
}

public struct IOSReaderScreenState: Equatable, Sendable {
    public let readerState: ReaderState
    public let title: String
    public let subtitle: String?
    public let selectedFontTier: MobileFontTier
    public let themeScheme: IOSReaderThemeScheme
    public let recentDocuments: [IOSRecentDocumentSummary]
    public let renderedBlocks: [NativeMarkdownBlockPresentation]
    public let progress: IOSReaderProgress?
    public let errorCode: FastMDErrorCode?
    public let searchState: IOSReaderSearchState?
    public let isOpenActionAvailable: Bool
    public let isSearchAvailable: Bool
    public let editSession: IOSReaderEditSession?

    public init(
        readerState: ReaderState,
        title: String,
        subtitle: String? = nil,
        selectedFontTier: MobileFontTier = .default,
        themeScheme: IOSReaderThemeScheme = .light,
        recentDocuments: [IOSRecentDocumentSummary] = [],
        renderedBlocks: [NativeMarkdownBlockPresentation] = [],
        progress: IOSReaderProgress? = nil,
        errorCode: FastMDErrorCode? = nil,
        searchState: IOSReaderSearchState? = nil,
        isOpenActionAvailable: Bool = true,
        isSearchAvailable: Bool = false,
        editSession: IOSReaderEditSession? = nil
    ) {
        self.readerState = readerState
        self.title = IOSDisplayNamePolicy().displayName(for: title)
        self.subtitle = subtitle
        self.selectedFontTier = selectedFontTier
        self.themeScheme = themeScheme
        self.recentDocuments = recentDocuments
        self.renderedBlocks = renderedBlocks
        self.progress = progress
        self.errorCode = errorCode
        self.searchState = searchState
        self.isOpenActionAvailable = isOpenActionAvailable
        self.isSearchAvailable = isSearchAvailable
        self.editSession = editSession
    }

    public var isEmpty: Bool {
        readerState == .empty
    }

    public var isProgressVisible: Bool {
        progress != nil && (readerState == .loading || readerState == .rendering)
    }

    public var isReadyForReading: Bool {
        readerState == .ready || readerState == .readOnly
    }

    public var isSearchVisible: Bool {
        readerState == .searching || searchState != nil
    }
}

public struct IOSReaderLazyRenderingPolicy: Equatable, Sendable {
    public let containerName: String
    public let rendersOnlyVisibleBlocksInitially: Bool
    public let stableIdentityKey: String
    public let maxContentWidth: Double
    public let horizontalOverflowContainedRoles: Set<NativeMarkdownBlockRole>

    public init(
        containerName: String = "LazyVStack",
        rendersOnlyVisibleBlocksInitially: Bool = true,
        stableIdentityKey: String = "MarkdownBlockID",
        maxContentWidth: Double = 760,
        horizontalOverflowContainedRoles: Set<NativeMarkdownBlockRole> = [.table, .codeFence]
    ) {
        self.containerName = containerName
        self.rendersOnlyVisibleBlocksInitially = rendersOnlyVisibleBlocksInitially
        self.stableIdentityKey = stableIdentityKey
        self.maxContentWidth = maxContentWidth
        self.horizontalOverflowContainedRoles = horizontalOverflowContainedRoles
    }

    public var satisfiesStageOneLazyBlockRendering: Bool {
        containerName == "LazyVStack"
            && rendersOnlyVisibleBlocksInitially
            && stableIdentityKey == "MarkdownBlockID"
            && maxContentWidth > 0
            && horizontalOverflowContainedRoles.isSuperset(of: [.table, .codeFence])
    }
}

public struct IOSRenderPipelineResult: Sendable {
    public let document: MarkdownRenderDocument
    public let renderedBlocks: [NativeMarkdownBlockPresentation]
    public let execution: IOSOffMainActorExecutionMetadata

    public init(
        document: MarkdownRenderDocument,
        renderedBlocks: [NativeMarkdownBlockPresentation],
        execution: IOSOffMainActorExecutionMetadata
    ) {
        self.document = document
        self.renderedBlocks = renderedBlocks
        self.execution = execution
    }
}

public struct IOSReaderScreenEngine: Equatable, Sendable {
    public let parser: MarkdownParserAdapter
    public let renderer: MarkdownNativeRenderer
    public let searchEngine: IOSReaderSearchEngine
    public let lazyRenderingPolicy: IOSReaderLazyRenderingPolicy

    public init(
        parser: MarkdownParserAdapter = MarkdownParserAdapter(),
        renderer: MarkdownNativeRenderer = MarkdownNativeRenderer(),
        searchEngine: IOSReaderSearchEngine = IOSReaderSearchEngine(),
        lazyRenderingPolicy: IOSReaderLazyRenderingPolicy = IOSReaderLazyRenderingPolicy()
    ) {
        self.parser = parser
        self.renderer = renderer
        self.searchEngine = searchEngine
        self.lazyRenderingPolicy = lazyRenderingPolicy
    }

    public func emptyState(
        recentDocuments: [IOSRecentDocumentSummary] = [],
        selectedFontTier: MobileFontTier = .default,
        themeScheme: IOSReaderThemeScheme = .light
    ) -> IOSReaderScreenState {
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

    public func loadingState(
        displayName: String,
        selectedFontTier: MobileFontTier = .default,
        themeScheme: IOSReaderThemeScheme = .light
    ) -> IOSReaderScreenState {
        IOSReaderScreenState(
            readerState: .loading,
            title: displayName,
            selectedFontTier: selectedFontTier,
            themeScheme: themeScheme,
            progress: IOSReaderProgress(
                title: "Opening",
                message: "Reading Markdown source"
            ),
            isOpenActionAvailable: false,
            isSearchAvailable: false
        )
    }

    public func renderingState(
        displayName: String,
        selectedFontTier: MobileFontTier = .default,
        themeScheme: IOSReaderThemeScheme = .light
    ) -> IOSReaderScreenState {
        IOSReaderScreenState(
            readerState: .rendering,
            title: displayName,
            selectedFontTier: selectedFontTier,
            themeScheme: themeScheme,
            progress: IOSReaderProgress(
                title: "Rendering",
                message: "Preparing native Markdown blocks"
            ),
            isOpenActionAvailable: false,
            isSearchAvailable: false
        )
    }

    public func readyState(
        loadResult: MarkdownLoadResult,
        renderedBlocks: [NativeMarkdownBlockPresentation],
        selectedFontTier: MobileFontTier = .default,
        themeScheme: IOSReaderThemeScheme = .light
    ) -> IOSReaderScreenState {
        let readerState: ReaderState = loadResult.handle.canWrite ? .ready : .readOnly
        return IOSReaderScreenState(
            readerState: readerState,
            title: loadResult.metadata.displayName,
            subtitle: subtitle(for: loadResult),
            selectedFontTier: selectedFontTier,
            themeScheme: themeScheme,
            renderedBlocks: renderedBlocks,
            isOpenActionAvailable: true,
            isSearchAvailable: !renderedBlocks.isEmpty
        )
    }

    public func errorState(
        displayName: String = "FastMD",
        errorCode: FastMDErrorCode,
        selectedFontTier: MobileFontTier = .default,
        themeScheme: IOSReaderThemeScheme = .light
    ) -> IOSReaderScreenState {
        IOSReaderScreenState(
            readerState: errorCode == .permissionLost ? .permissionLost : .error,
            title: displayName,
            selectedFontTier: selectedFontTier,
            themeScheme: themeScheme,
            errorCode: errorCode,
            isOpenActionAvailable: true,
            isSearchAvailable: false
        )
    }

    public func searchingState(
        from state: IOSReaderScreenState,
        query: String,
        selectedMatchIndex: Int = 0
    ) -> IOSReaderScreenState {
        let searchState = searchEngine.search(
            query: query,
            in: state.renderedBlocks,
            selectedMatchIndex: selectedMatchIndex
        )

        return IOSReaderScreenState(
            readerState: .searching,
            title: state.title,
            subtitle: state.subtitle,
            selectedFontTier: state.selectedFontTier,
            themeScheme: state.themeScheme,
            recentDocuments: state.recentDocuments,
            renderedBlocks: state.renderedBlocks,
            searchState: searchState,
            isOpenActionAvailable: state.isOpenActionAvailable,
            isSearchAvailable: state.isSearchAvailable
        )
    }

    public func nextSearchMatch(from state: IOSReaderScreenState) -> IOSReaderScreenState {
        guard let searchState = state.searchState else {
            return state
        }

        return state.replacingSearchState(searchEngine.next(in: searchState))
    }

    public func previousSearchMatch(from state: IOSReaderScreenState) -> IOSReaderScreenState {
        guard let searchState = state.searchState else {
            return state
        }

        return state.replacingSearchState(searchEngine.previous(in: searchState))
    }

    public func clearSearch(from state: IOSReaderScreenState) -> IOSReaderScreenState {
        let readerState: ReaderState = state.readerState == .readOnly || state.subtitle?.hasPrefix("Read-only") == true
            ? .readOnly
            : .ready
        return IOSReaderScreenState(
            readerState: readerState,
            title: state.title,
            subtitle: state.subtitle,
            selectedFontTier: state.selectedFontTier,
            themeScheme: state.themeScheme,
            recentDocuments: state.recentDocuments,
            renderedBlocks: state.renderedBlocks,
            isOpenActionAvailable: state.isOpenActionAvailable,
            isSearchAvailable: state.isSearchAvailable
        )
    }

    public func renderLoadedDocumentStates(
        _ loadResult: MarkdownLoadResult,
        selectedFontTier: MobileFontTier = .default,
        themeScheme: IOSReaderThemeScheme = .light
    ) async -> [IOSReaderScreenState] {
        let loading = loadingState(
            displayName: loadResult.metadata.displayName,
            selectedFontTier: selectedFontTier,
            themeScheme: themeScheme
        )
        await Task.yield()

        let rendering = renderingState(
            displayName: loadResult.metadata.displayName,
            selectedFontTier: selectedFontTier,
            themeScheme: themeScheme
        )
        await Task.yield()

        let renderResult = await renderDocumentOffMainActor(loadResult)
        let ready = readyState(
            loadResult: loadResult,
            renderedBlocks: renderResult.renderedBlocks,
            selectedFontTier: selectedFontTier,
            themeScheme: themeScheme
        )

        return [loading, rendering, ready]
    }

    public func renderDocumentOffMainActor(
        _ loadResult: MarkdownLoadResult
    ) async -> IOSRenderPipelineResult {
        await Task.detached(priority: .userInitiated) {
            let startedOnMainThread = iosIsMainThreadForDiagnostics()
            let document = parser.parse(loadResult.source)
            let blocks = renderer.render(document: document, source: loadResult.source)
            return IOSRenderPipelineResult(
                document: document,
                renderedBlocks: blocks,
                execution: IOSOffMainActorExecutionMetadata(
                    scheduledWithDetachedTask: true,
                    startedOnMainThread: startedOnMainThread,
                    completedOnMainThread: iosIsMainThreadForDiagnostics()
                )
            )
        }.value
    }

    public func searchingStateOffMainActor(
        from state: IOSReaderScreenState,
        query: String,
        selectedMatchIndex: Int = 0
    ) async -> IOSOffMainActorWorkResult<IOSReaderScreenState> {
        let searchResult = await searchEngine.searchOffMainActor(
            query: query,
            in: state.renderedBlocks,
            selectedMatchIndex: selectedMatchIndex
        )

        return IOSOffMainActorWorkResult(
            value: IOSReaderScreenState(
                readerState: .searching,
                title: state.title,
                subtitle: state.subtitle,
                selectedFontTier: state.selectedFontTier,
                themeScheme: state.themeScheme,
                recentDocuments: state.recentDocuments,
                renderedBlocks: state.renderedBlocks,
                searchState: searchResult.value,
                isOpenActionAvailable: state.isOpenActionAvailable,
                isSearchAvailable: state.isSearchAvailable
            ),
            execution: searchResult.execution
        )
    }

    private func subtitle(for loadResult: MarkdownLoadResult) -> String {
        let access = loadResult.handle.canWrite ? "Writable" : "Read-only"
        return "\(access) · \(loadResult.metadata.byteCount) bytes"
    }
}

private extension IOSReaderScreenState {
    func replacingSearchState(_ searchState: IOSReaderSearchState) -> IOSReaderScreenState {
        IOSReaderScreenState(
            readerState: .searching,
            title: title,
            subtitle: subtitle,
            selectedFontTier: selectedFontTier,
            themeScheme: themeScheme,
            recentDocuments: recentDocuments,
            renderedBlocks: renderedBlocks,
            progress: progress,
            errorCode: errorCode,
            searchState: searchState,
            isOpenActionAvailable: isOpenActionAvailable,
            isSearchAvailable: isSearchAvailable
        )
    }
}

#if canImport(SwiftUI)
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

@available(iOS 14.0, macOS 11.0, *)
public struct IOSReaderScreenActions {
    public var openDocument: () -> Void
    public var search: () -> Void
    public var editSource: () -> Void
    public var editBlock: (NativeMarkdownBlockPresentation) -> Void
    public var searchQueryChanged: (String) -> Void
    public var previousSearchMatch: () -> Void
    public var nextSearchMatch: () -> Void
    public var clearSearch: () -> Void
    public var sourceTextChanged: (String) -> Void
    public var saveSourceEdit: () -> Void
    public var cancelSourceEdit: () -> Void
    public var blockTextChanged: (String) -> Void
    public var saveBlockEdit: () -> Void
    public var cancelBlockEdit: () -> Void
    public var changeFontTier: (MobileFontTier) -> Void
    public var selectRecentDocument: (IOSRecentDocumentSummary) -> Void
    public var copyCodeBlock: (NativeMarkdownCodeBlock) -> Void

    public init(
        openDocument: @escaping () -> Void = {},
        search: @escaping () -> Void = {},
        editSource: @escaping () -> Void = {},
        editBlock: @escaping (NativeMarkdownBlockPresentation) -> Void = { _ in },
        searchQueryChanged: @escaping (String) -> Void = { _ in },
        previousSearchMatch: @escaping () -> Void = {},
        nextSearchMatch: @escaping () -> Void = {},
        clearSearch: @escaping () -> Void = {},
        sourceTextChanged: @escaping (String) -> Void = { _ in },
        saveSourceEdit: @escaping () -> Void = {},
        cancelSourceEdit: @escaping () -> Void = {},
        blockTextChanged: @escaping (String) -> Void = { _ in },
        saveBlockEdit: @escaping () -> Void = {},
        cancelBlockEdit: @escaping () -> Void = {},
        changeFontTier: @escaping (MobileFontTier) -> Void = { _ in },
        selectRecentDocument: @escaping (IOSRecentDocumentSummary) -> Void = { _ in },
        copyCodeBlock: @escaping (NativeMarkdownCodeBlock) -> Void = { _ in }
    ) {
        self.openDocument = openDocument
        self.search = search
        self.editSource = editSource
        self.editBlock = editBlock
        self.searchQueryChanged = searchQueryChanged
        self.previousSearchMatch = previousSearchMatch
        self.nextSearchMatch = nextSearchMatch
        self.clearSearch = clearSearch
        self.sourceTextChanged = sourceTextChanged
        self.saveSourceEdit = saveSourceEdit
        self.cancelSourceEdit = cancelSourceEdit
        self.blockTextChanged = blockTextChanged
        self.saveBlockEdit = saveBlockEdit
        self.cancelBlockEdit = cancelBlockEdit
        self.changeFontTier = changeFontTier
        self.selectRecentDocument = selectRecentDocument
        self.copyCodeBlock = copyCodeBlock
    }
}

@available(iOS 14.0, macOS 11.0, *)
public struct FastMDReaderScreen: View {
    public let state: IOSReaderScreenState
    public let actions: IOSReaderScreenActions
    private let accessibilityPolicy = IOSReaderAccessibilityPolicy()

    public init(
        state: IOSReaderScreenState,
        actions: IOSReaderScreenActions = IOSReaderScreenActions()
    ) {
        self.state = state
        self.actions = actions
    }

    public var body: some View {
        VStack(spacing: 0) {
            toolbar
            if state.isSearchVisible {
                searchBar
            }
            Divider()
            content
        }
        .foregroundColor(themePrimaryColor)
        .background(themeBackgroundColor)
    }

    private var toolbar: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(displayTitle)
                    .font(.headline)
                    .lineLimit(1)
                if let subtitle = state.subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(themeSecondaryColor)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 12)

            Button(action: actions.openDocument) {
                Image(systemName: "folder")
            }
            .disabled(!state.isOpenActionAvailable)
            .accessibilityLabel(accessibilityLabel(.openMarkdown))

            Button(action: actions.search) {
                Image(systemName: "magnifyingglass")
            }
            .disabled(!state.isSearchAvailable)
            .accessibilityLabel(accessibilityLabel(.searchDocument))

            Button(action: actions.editSource) {
                Image(systemName: "square.and.pencil")
            }
            .disabled(!state.isReadyForReading)
            .accessibilityLabel(accessibilityLabel(.editSource))

            Menu {
                ForEach(MobileFontTier.allCases, id: \.self) { tier in
                    Button(fontTierTitle(tier)) {
                        actions.changeFontTier(tier)
                    }
                }
            } label: {
                Image(systemName: "textformat.size")
            }
            .accessibilityLabel(accessibilityLabel(.fontSize))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .accessibilityElement(children: .contain)
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            TextField(
                "Search",
                text: Binding(
                    get: { state.searchState?.query ?? "" },
                    set: actions.searchQueryChanged
                )
            )
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .accessibilityLabel("Search Query")

            Text(state.searchState?.resultSummary ?? "0 of 0")
                .font(.caption)
                .foregroundColor(themeSecondaryColor)
                .frame(minWidth: 54, alignment: .trailing)
                .accessibilityLabel("Search Result Count")
                .accessibilityValue(accessibilityPolicy.searchAnnouncement(for: state.searchState) ?? "No active search")
                .accessibilityAddTraits(.updatesFrequently)

            Button(action: actions.previousSearchMatch) {
                Image(systemName: "chevron.up")
            }
            .disabled((state.searchState?.resultCount ?? 0) == 0)
            .accessibilityLabel(accessibilityLabel(.previousSearchResult))

            Button(action: actions.nextSearchMatch) {
                Image(systemName: "chevron.down")
            }
            .disabled((state.searchState?.resultCount ?? 0) == 0)
            .accessibilityLabel(accessibilityLabel(.nextSearchResult))

            Button(action: actions.clearSearch) {
                Image(systemName: "xmark.circle")
            }
            .accessibilityLabel(accessibilityLabel(.clearSearch))
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 10)
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private var content: some View {
        switch state.readerState {
        case .empty:
            emptyView
        case .loading, .rendering:
            progressView
        case .ready, .readOnly, .searching:
            readerView
        case .permissionLost, .error:
            errorView
        case .editingSource:
            sourceEditorView
        case .editingBlock:
            blockSourceEditorView
        case .saving:
            progressView
        }
    }

    private var emptyView: some View {
        VStack(alignment: .leading, spacing: 18) {
            Button(action: actions.openDocument) {
                Label("Open Markdown", systemImage: "folder")
                    .frame(maxWidth: .infinity)
            }
            .accessibilityLabel("Open Markdown")

            if !state.recentDocuments.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recent")
                        .font(.headline)
                    ForEach(state.recentDocuments, id: \.identifier) { document in
                        Button {
                            actions.selectRecentDocument(document)
                        } label: {
                            HStack {
                                Image(systemName: "doc.text")
                                Text(displayName(document.displayName))
                                    .lineLimit(1)
                                Spacer()
                            }
                        }
                        .accessibilityLabel("Open \(displayName(document.displayName))")
                    }
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var progressView: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text(state.progress?.title ?? "Working")
                .font(.headline)
            Text(state.progress?.message ?? "")
                .font(.subheadline)
                .foregroundColor(themeSecondaryColor)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
    }

    private var readerView: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 14) {
                ForEach(state.renderedBlocks, id: \.id) { block in
                    blockView(block)
                        .contextMenu {
                            Button {
                                actions.editBlock(block)
                            } label: {
                                Label("Edit Block", systemImage: "square.and.pencil")
                            }
                        }
                }
            }
            .padding(16)
            .frame(maxWidth: 760, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
    }

    private var blockSourceEditorView: some View {
        editorView(
            statusTitle: state.isDirtyEditing ? "Unsaved block changes" : blockRangeTitle,
            currentSource: state.editSession?.currentSource ?? "",
            isReadOnly: state.editSession?.returnReaderState == .readOnly,
            cancelAccessibilityLabel: accessibilityLabel(.cancelBlockEdit),
            saveAccessibilityLabel: accessibilityLabel(.saveBlockEdit),
            textAccessibilityLabel: "Markdown Block Source Editor",
            textChanged: actions.blockTextChanged,
            editorSurface: editorSurface(for: state.editSession?.currentSource ?? ""),
            save: actions.saveBlockEdit,
            cancel: actions.cancelBlockEdit
        )
    }

    private var sourceEditorView: some View {
        editorView(
            statusTitle: state.isDirtyEditing ? "Unsaved changes" : "Source",
            currentSource: state.editSession?.currentSource ?? "",
            isReadOnly: state.editSession?.returnReaderState == .readOnly,
            cancelAccessibilityLabel: accessibilityLabel(.cancelSourceEdit),
            saveAccessibilityLabel: accessibilityLabel(.saveSourceEdit),
            textAccessibilityLabel: "Markdown Source Editor",
            textChanged: actions.sourceTextChanged,
            editorSurface: editorSurface(for: state.editSession?.currentSource ?? ""),
            save: actions.saveSourceEdit,
            cancel: actions.cancelSourceEdit
        )
    }

    private func editorView(
        statusTitle: String,
        currentSource: String,
        isReadOnly: Bool,
        cancelAccessibilityLabel: String,
        saveAccessibilityLabel: String,
        textAccessibilityLabel: String,
        textChanged: @escaping (String) -> Void,
        editorSurface: IOSSourceEditorSurface,
        save: @escaping () -> Void,
        cancel: @escaping () -> Void
    ) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Text(statusTitle)
                    .font(.caption)
                    .foregroundColor(themeSecondaryColor)
                Spacer()
                Button(action: cancel) {
                    Text("Cancel")
                }
                .accessibilityLabel(cancelAccessibilityLabel)
                if !isReadOnly {
                    Button(action: save) {
                        Text("Save")
                    }
                    .disabled(!state.isDirtyEditing)
                    .accessibilityLabel(saveAccessibilityLabel)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            sourceEditingControl(
                currentSource: currentSource,
                accessibilityLabel: textAccessibilityLabel,
                editorSurface: editorSurface,
                textChanged: textChanged
            )
        }
        .accessibilityElement(children: .contain)
        .accessibilityHint(state.isDirtyEditing ? "Unsaved edit warning" : "")
    }

    @ViewBuilder
    private func sourceEditingControl(
        currentSource: String,
        accessibilityLabel: String,
        editorSurface: IOSSourceEditorSurface,
        textChanged: @escaping (String) -> Void
    ) -> some View {
        #if canImport(UIKit)
        if editorSurface == .uiKitTextKitTextView {
            FastMDTextKitSourceEditor(
                text: Binding(
                    get: { currentSource },
                    set: textChanged
                ),
                pointSize: CGFloat(typography.metrics(for: .code).pointSize)
            )
            .padding(12)
            .background(themeBackgroundColor)
            .accessibilityLabel(accessibilityLabel)
        } else {
            swiftUISourceEditingControl(
                currentSource: currentSource,
                accessibilityLabel: accessibilityLabel,
                textChanged: textChanged
            )
        }
        #else
        swiftUISourceEditingControl(
            currentSource: currentSource,
            accessibilityLabel: accessibilityLabel,
            textChanged: textChanged
        )
        #endif
    }

    private func swiftUISourceEditingControl(
        currentSource: String,
        accessibilityLabel: String,
        textChanged: @escaping (String) -> Void
    ) -> some View {
        TextEditor(
            text: Binding(
                get: { currentSource },
                set: textChanged
            )
        )
        .font(codeFont)
        .foregroundColor(themePrimaryColor)
        .padding(12)
        .background(themeBackgroundColor)
        .accessibilityLabel(accessibilityLabel)
    }

    private func editorSurface(for currentSource: String) -> IOSSourceEditorSurface {
        IOSSourceEditorRuntimePolicy().surface(
            for: IOSSourceEditorRuntimeProfile(sourceUTF8ByteCount: currentSource.utf8.count)
        )
    }

    private var errorView: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.title)
            Text(errorTitle)
                .font(.headline)
            Button(action: actions.openDocument) {
                Label("Open Markdown", systemImage: "folder")
            }
            .accessibilityLabel("Open Markdown")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private func blockView(_ block: NativeMarkdownBlockPresentation) -> some View {
        switch block.role {
        case .heading:
            highlightedText(for: block)
                .font(headingFont(level: block.headingLevel ?? 1))
                .accessibilityAddTraits(.isHeader)

        case .paragraph, .footnote:
            highlightedText(for: block)
                .font(bodyFont)
                .lineSpacing(lineSpacing)

        case .blockquote:
            VStack(alignment: .leading, spacing: 6) {
                ForEach(Array(block.blockquoteLines.enumerated()), id: \.offset) { _, line in
                    Text(line.plainText)
                        .font(bodyFont)
                        .foregroundColor(themePrimaryColor)
                        .padding(.leading, CGFloat(max(0, line.depth - 1) * 14))
                }
            }
            .padding(.leading, 10)
            .overlay(
                Rectangle()
                    .fill(themeQuoteBarColor)
                    .frame(width: 3),
                alignment: .leading
            )

        case .unorderedList, .orderedList, .taskList:
            VStack(alignment: .leading, spacing: 6) {
                ForEach(Array(block.listItems.enumerated()), id: \.offset) { _, item in
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(listMarker(for: item))
                            .font(bodyFont.monospacedDigit())
                        Text(item.plainText)
                            .font(bodyFont)
                    }
                    .padding(.leading, CGFloat(item.nestingLevel * 18))
                }
            }

        case .table:
            ScrollView(.horizontal, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(Array((block.table?.rows ?? []).enumerated()), id: \.offset) { _, row in
                        HStack(spacing: 12) {
                            ForEach(Array(row.enumerated()), id: \.offset) { _, cell in
                                Text(cell)
                                    .font(bodyFont)
                                    .foregroundColor(themePrimaryColor)
                                    .frame(minWidth: 90, alignment: .leading)
                            }
                        }
                    }
                }
                .padding(10)
            }
            .background(themeBlockSurfaceColor)
            .cornerRadius(8)

        case .codeFence:
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(block.codeBlock?.language ?? "code")
                        .font(.caption)
                        .foregroundColor(themeSecondaryColor)
                    Spacer()
                    if let codeBlock = block.codeBlock {
                        Button {
                            actions.copyCodeBlock(codeBlock)
                        } label: {
                            Image(systemName: "doc.on.doc")
                        }
                        .accessibilityLabel(accessibilityLabel(.copyCode))
                    }
                }
                ScrollView(.horizontal, showsIndicators: true) {
                    Text(block.codeBlock?.code ?? block.plainText)
                        .font(codeFont)
                        .padding(10)
                }
            }
            .background(themeBlockSurfaceColor)
            .cornerRadius(8)

        case .richFallback:
            fallbackCard(title: block.richFallback?.title ?? "Rich block", text: block.richFallback?.source ?? block.plainText)

        case .image:
            fallbackCard(
                title: block.image?.requiresManualOpenAction == true ? "Remote image" : "Local image",
                text: block.image?.altText ?? block.plainText
            )

        case .horizontalRule:
            Divider()

        case .htmlFallback:
            fallbackCard(title: htmlFallbackTitle(block.htmlFallback), text: block.htmlFallback?.sanitizedText ?? block.plainText)
        }
    }

    private func fallbackCard(title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundColor(themeSecondaryColor)
            Text(text)
                .font(bodyFont)
                .lineSpacing(lineSpacing)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(themeBlockSurfaceColor)
        .cornerRadius(8)
    }

    private var displayTitle: String {
        IOSDisplayNamePolicy().displayName(for: state.title)
    }

    private var errorTitle: String {
        state.errorCode == .permissionLost ? "Permission Lost" : "Unable to Open Document"
    }

    private var blockRangeTitle: String {
        guard let range = state.editSession?.sourceRange else {
            return "Block"
        }
        return "Block lines \(range.startLine)-\(range.endLine)"
    }

    private var bodyFont: Font {
        let metrics = typography.metrics(for: .paragraph)
        return .system(size: metrics.pointSize)
    }

    private var codeFont: Font {
        let metrics = typography.metrics(for: .code)
        return .system(size: metrics.pointSize, design: .monospaced)
    }

    private var lineSpacing: CGFloat {
        let metrics = typography.metrics(for: .paragraph)
        return CGFloat(metrics.pointSize * (metrics.lineHeightMultiple - 1))
    }

    private func headingFont(level: Int) -> Font {
        let surface: NativeMarkdownTextSurface
        switch level {
        case 1:
            surface = .heading1
        case 2:
            surface = .heading2
        case 3:
            surface = .heading3
        case 4:
            surface = .heading4
        case 5:
            surface = .heading5
        default:
            surface = .heading6
        }
        return .system(size: typography.metrics(for: surface).pointSize, weight: .semibold)
    }

    private func fontTierTitle(_ tier: MobileFontTier) -> String {
        switch tier {
        case .compact:
            return "Compact"
        case .default:
            return "Default"
        case .large:
            return "Large"
        case .reader:
            return "Reader"
        }
    }

    private func listMarker(for item: NativeMarkdownListItem) -> String {
        if let checked = item.checked {
            return checked ? "[x]" : "[ ]"
        }
        return item.marker
    }

    private func htmlFallbackTitle(_ fallback: NativeMarkdownHTMLFallback?) -> String {
        switch fallback?.kind {
        case .detailsDisclosure:
            return fallback?.summary ?? "Details"
        case .videoPlaceholder:
            return "Video"
        case .genericSanitizedText:
            return "HTML"
        case nil:
            return "HTML"
        }
    }

    private func displayName(_ name: String) -> String {
        IOSDisplayNamePolicy().displayName(for: name)
    }

    private func accessibilityLabel(_ control: IOSReaderAccessibilityControl) -> String {
        accessibilityPolicy.iconOnlyControlLabels[control] ?? control.label
    }

    private func highlightedText(for block: NativeMarkdownBlockPresentation) -> Text {
        let ranges = searchRanges(for: block)
        guard !ranges.isEmpty else {
            return Text(block.plainText)
        }

        let text = block.plainText as NSString
        var cursor = 0
        var output = Text("")

        for range in ranges {
            if range.startUTF16Offset > cursor {
                output = output + Text(
                    text.substring(
                        with: NSRange(
                            location: cursor,
                            length: range.startUTF16Offset - cursor
                        )
                    )
                )
            }

            output = output + Text(
                text.substring(
                    with: NSRange(
                        location: range.startUTF16Offset,
                        length: range.lengthUTF16
                    )
                )
            )
            .foregroundColor(themeSearchHighlightColor)
            .bold()

            cursor = range.endUTF16Offset
        }

        if cursor < text.length {
            output = output + Text(
                text.substring(
                    with: NSRange(location: cursor, length: text.length - cursor)
                )
            )
        }

        return output
    }

    private func searchRanges(for block: NativeMarkdownBlockPresentation) -> [IOSReaderSearchTextRange] {
        state.searchState?.matches
            .filter { $0.blockID == block.id }
            .map(\.range)
            .sorted { $0.startUTF16Offset < $1.startUTF16Offset } ?? []
    }

    private var typography: NativeMarkdownTypography {
        NativeMarkdownTypography(fontTier: state.selectedFontTier)
    }

    private var themeTokens: IOSReaderSemanticColorTokens {
        IOSReaderSemanticColorTokens.tokens(for: state.themeScheme)
    }

    private var themeBackgroundColor: Color {
        color(for: themeTokens.background)
    }

    private var themePrimaryColor: Color {
        color(for: themeTokens.primaryText)
    }

    private var themeSecondaryColor: Color {
        color(for: themeTokens.secondaryText)
    }

    private var themeBlockSurfaceColor: Color {
        color(for: themeTokens.blockSurface)
    }

    private var themeQuoteBarColor: Color {
        color(for: themeTokens.quoteBar)
    }

    private var themeSearchHighlightColor: Color {
        color(for: themeTokens.accent)
    }

    private func color(for token: String) -> Color {
        switch token {
        case "reader.background.dark":
            return Color(red: 0.06, green: 0.07, blue: 0.08)
        case "reader.text.primary.dark":
            return Color(red: 0.92, green: 0.93, blue: 0.94)
        case "reader.text.secondary.dark":
            return Color(red: 0.62, green: 0.66, blue: 0.70)
        case "reader.blockSurface.dark":
            return Color(red: 0.13, green: 0.15, blue: 0.17)
        case "reader.quoteBar.dark":
            return Color(red: 0.42, green: 0.62, blue: 0.78)
        case "reader.background.light":
            return Color(red: 0.98, green: 0.98, blue: 0.97)
        case "reader.text.primary.light":
            return Color(red: 0.10, green: 0.11, blue: 0.12)
        case "reader.text.secondary.light":
            return Color(red: 0.42, green: 0.44, blue: 0.46)
        case "reader.blockSurface.light":
            return Color(red: 0.93, green: 0.94, blue: 0.92)
        case "reader.quoteBar.light":
            return Color(red: 0.22, green: 0.46, blue: 0.62)
        default:
            return .accentColor
        }
    }
}

#if canImport(UIKit)
@available(iOS 14.0, *)
public struct FastMDTextKitSourceEditor: UIViewRepresentable {
    @Binding private var text: String
    private let pointSize: CGFloat

    public init(text: Binding<String>, pointSize: CGFloat) {
        self._text = text
        self.pointSize = pointSize
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    public func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.font = UIFont.monospacedSystemFont(ofSize: pointSize, weight: .regular)
        textView.autocorrectionType = .no
        textView.autocapitalizationType = .none
        textView.smartDashesType = .no
        textView.smartQuotesType = .no
        textView.alwaysBounceVertical = true
        textView.isScrollEnabled = true
        textView.backgroundColor = .clear
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 6, bottom: 8, right: 6)
        textView.text = text
        return textView
    }

    public func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }
        uiView.font = UIFont.monospacedSystemFont(ofSize: pointSize, weight: .regular)
    }

    public final class Coordinator: NSObject, UITextViewDelegate {
        private var text: Binding<String>

        init(text: Binding<String>) {
            self.text = text
        }

        public func textViewDidChange(_ textView: UITextView) {
            text.wrappedValue = textView.text
        }
    }
}
#endif
#endif
