import Foundation

public enum IOSSourceEditorSurface: String, CaseIterable, Equatable, Sendable {
    case swiftUITextEditor
    case uiKitTextKitTextView
}

public struct IOSSourceEditorRuntimeProfile: Equatable, Sendable {
    public let sourceUTF8ByteCount: Int
    public let observedSwiftUIInputLatencyMilliseconds: Double?
    public let observedDroppedInputFrameCount: Int
    public let isUserForcedTextKitFallback: Bool

    public init(
        sourceUTF8ByteCount: Int,
        observedSwiftUIInputLatencyMilliseconds: Double? = nil,
        observedDroppedInputFrameCount: Int = 0,
        isUserForcedTextKitFallback: Bool = false
    ) {
        self.sourceUTF8ByteCount = max(0, sourceUTF8ByteCount)
        self.observedSwiftUIInputLatencyMilliseconds = observedSwiftUIInputLatencyMilliseconds
        self.observedDroppedInputFrameCount = max(0, observedDroppedInputFrameCount)
        self.isUserForcedTextKitFallback = isUserForcedTextKitFallback
    }
}

public struct IOSSourceEditorRuntimePolicy: Equatable, Sendable {
    public let largeSourceByteThreshold: Int
    public let unstableInputLatencyMilliseconds: Double
    public let unstableDroppedInputFrameThreshold: Int

    public init(
        largeSourceByteThreshold: Int = 1_048_576,
        unstableInputLatencyMilliseconds: Double = 80,
        unstableDroppedInputFrameThreshold: Int = 3
    ) {
        self.largeSourceByteThreshold = max(1, largeSourceByteThreshold)
        self.unstableInputLatencyMilliseconds = max(16, unstableInputLatencyMilliseconds)
        self.unstableDroppedInputFrameThreshold = max(1, unstableDroppedInputFrameThreshold)
    }

    public func surface(for profile: IOSSourceEditorRuntimeProfile) -> IOSSourceEditorSurface {
        if profile.isUserForcedTextKitFallback {
            return .uiKitTextKitTextView
        }

        if profile.sourceUTF8ByteCount >= largeSourceByteThreshold {
            return .uiKitTextKitTextView
        }

        if let latency = profile.observedSwiftUIInputLatencyMilliseconds,
           latency >= unstableInputLatencyMilliseconds {
            return .uiKitTextKitTextView
        }

        if profile.observedDroppedInputFrameCount >= unstableDroppedInputFrameThreshold {
            return .uiKitTextKitTextView
        }

        return .swiftUITextEditor
    }
}

public struct IOSSourceEditorState: Equatable, Sendable {
    public let title: String
    public let currentSource: String
    public let isDirty: Bool
    public let canSave: Bool
    public let canCancel: Bool
    public let isReadOnly: Bool
    public let lastSaveError: FastMDErrorCode?
    public let editorSurface: IOSSourceEditorSurface

    public init(
        title: String,
        currentSource: String,
        isDirty: Bool,
        canSave: Bool,
        canCancel: Bool,
        isReadOnly: Bool,
        lastSaveError: FastMDErrorCode? = nil,
        editorSurface: IOSSourceEditorSurface? = nil
    ) {
        self.title = IOSDisplayNamePolicy().displayName(for: title)
        self.currentSource = currentSource
        self.isDirty = isDirty
        self.canSave = canSave
        self.canCancel = canCancel
        self.isReadOnly = isReadOnly
        self.lastSaveError = lastSaveError
        self.editorSurface = editorSurface ?? IOSSourceEditorRuntimePolicy().surface(
            for: IOSSourceEditorRuntimeProfile(sourceUTF8ByteCount: currentSource.utf8.count)
        )
    }
}

public struct IOSBlockSourceEditorState: Equatable, Sendable {
    public let title: String
    public let currentSource: String
    public let isDirty: Bool
    public let canApply: Bool
    public let canCancel: Bool
    public let isReadOnly: Bool
    public let blockID: MarkdownBlockID
    public let sourceRange: MarkdownSourceRange
    public let sourceRangeDescription: String
    public let editorSurface: IOSSourceEditorSurface

    public init(
        title: String,
        currentSource: String,
        isDirty: Bool,
        canApply: Bool,
        canCancel: Bool,
        isReadOnly: Bool,
        blockID: MarkdownBlockID,
        sourceRange: MarkdownSourceRange,
        editorSurface: IOSSourceEditorSurface? = nil
    ) {
        self.title = IOSDisplayNamePolicy().displayName(for: title)
        self.currentSource = currentSource
        self.isDirty = isDirty
        self.canApply = canApply
        self.canCancel = canCancel
        self.isReadOnly = isReadOnly
        self.blockID = blockID
        self.sourceRange = sourceRange
        self.sourceRangeDescription = "Lines \(sourceRange.startLine)-\(sourceRange.endLine)"
        self.editorSurface = editorSurface ?? IOSSourceEditorRuntimePolicy().surface(
            for: IOSSourceEditorRuntimeProfile(sourceUTF8ByteCount: currentSource.utf8.count)
        )
    }
}

public enum IOSBlockSourceEditError: Equatable, Error, Sendable {
    case wrongEditorMode
    case missingBlockSourceRange
    case invalidSourceRange
    case sourceRangeMismatch
}

public struct IOSBlockSourceEditApplyResult: Equatable, Sendable {
    public let source: String
    public let lineEnding: MarkdownLineEnding
    public let didChange: Bool

    public init(source: String, lineEnding: MarkdownLineEnding, didChange: Bool) {
        self.source = source
        self.lineEnding = lineEnding
        self.didChange = didChange
    }
}

public struct IOSSourceEditSaveResult: Equatable, Sendable {
    public let context: IOSReaderNavigationContext
    public let saveResult: IOSDocumentSaveResult?
    public let error: IOSDocumentSaveError?

    public init(
        context: IOSReaderNavigationContext,
        saveResult: IOSDocumentSaveResult?,
        error: IOSDocumentSaveError?
    ) {
        self.context = context
        self.saveResult = saveResult
        self.error = error
    }
}

public struct IOSSourceEditorEngine: Equatable, Sendable {
    public init() {}

    public func beginFullSourceEditing(
        loadResult: MarkdownLoadResult,
        from state: IOSReaderScreenState
    ) -> IOSReaderNavigationContext {
        let returnState: ReaderState = loadResult.handle.canWrite ? .ready : .readOnly
        let editSession = IOSReaderEditSession(
            mode: .source,
            originalSource: loadResult.source,
            currentSource: loadResult.source,
            returnReaderState: returnState
        )

        return IOSReaderNavigationContext(
            state: state.editingSourceState(editSession: editSession),
            editSession: editSession
        )
    }

    public func beginBlockSourceEditing(
        loadResult: MarkdownLoadResult,
        block: NativeMarkdownBlockPresentation,
        from state: IOSReaderScreenState
    ) throws -> IOSReaderNavigationContext {
        let blockSource = try sourceSlice(
            in: loadResult.source,
            range: block.sourceRange
        )
        let returnState: ReaderState = loadResult.handle.canWrite ? .ready : .readOnly
        let editSession = IOSReaderEditSession(
            mode: .block,
            originalSource: blockSource,
            currentSource: blockSource,
            returnReaderState: returnState,
            blockID: block.id,
            sourceRange: block.sourceRange
        )

        return IOSReaderNavigationContext(
            state: state.editingBlockState(editSession: editSession),
            editSession: editSession
        )
    }

    public func updateSource(
        in context: IOSReaderNavigationContext,
        currentSource: String
    ) -> IOSReaderNavigationContext {
        guard let editSession = context.editSession,
              editSession.mode == .source else {
            return context
        }

        let updatedSession = editSession.replacingCurrentSource(currentSource)
        return IOSReaderNavigationContext(
            state: context.state.editingSourceState(editSession: updatedSession),
            editSession: updatedSession
        )
    }

    public func updateBlockSource(
        in context: IOSReaderNavigationContext,
        currentSource: String
    ) -> IOSReaderNavigationContext {
        guard let editSession = context.editSession,
              editSession.mode == .block else {
            return context
        }

        let updatedSession = editSession.replacingCurrentSource(currentSource)
        return IOSReaderNavigationContext(
            state: context.state.editingBlockState(editSession: updatedSession),
            editSession: updatedSession
        )
    }

    public func editorState(for context: IOSReaderNavigationContext) -> IOSSourceEditorState? {
        guard context.state.readerState == .editingSource,
              let editSession = context.editSession,
              editSession.mode == .source else {
            return nil
        }

        let isReadOnly = editSession.returnReaderState == .readOnly
        return IOSSourceEditorState(
            title: context.state.title,
            currentSource: editSession.currentSource,
            isDirty: editSession.isDirty,
            canSave: editSession.isDirty && !isReadOnly,
            canCancel: true,
            isReadOnly: isReadOnly,
            lastSaveError: context.state.errorCode
        )
    }

    public func saveFullSourceEdit(
        from context: IOSReaderNavigationContext,
        activeDocument: MarkdownLoadResult,
        destinationURL: URL,
        fileIO: IOSDocumentFileIO = IOSDocumentFileIO()
    ) -> IOSSourceEditSaveResult {
        guard let editSession = context.editSession,
              editSession.mode == .source else {
            return IOSSourceEditSaveResult(
                context: context,
                saveResult: nil,
                error: .unsupportedEncoding
            )
        }

        do {
            let result = try fileIO.saveDocument(
                editedSource: editSession.currentSource,
                for: activeDocument,
                to: destinationURL
            )
            let cleanSession = IOSReaderEditSession(
                mode: .source,
                originalSource: result.savedSource,
                currentSource: result.savedSource,
                returnReaderState: editSession.returnReaderState
            )
            return IOSSourceEditSaveResult(
                context: IOSReaderNavigationContext(
                    state: context.state.editingSourceState(editSession: cleanSession),
                    editSession: cleanSession
                ),
                saveResult: result,
                error: nil
            )
        } catch let error as IOSDocumentSaveError {
            return IOSSourceEditSaveResult(
                context: IOSReaderNavigationContext(
                    state: context.state.failedSourceSaveState(
                        editSession: editSession,
                        errorCode: error.readerErrorCode
                    ),
                    editSession: editSession
                ),
                saveResult: nil,
                error: error
            )
        } catch {
            let saveError = IOSDocumentSaveError.writeFailed(
                retainedDirtyBuffer: editSession.currentSource
            )
            return IOSSourceEditSaveResult(
                context: IOSReaderNavigationContext(
                    state: context.state.failedSourceSaveState(
                        editSession: editSession,
                        errorCode: saveError.readerErrorCode
                    ),
                    editSession: editSession
                ),
                saveResult: nil,
                error: saveError
            )
        }
    }

    public func blockEditorState(for context: IOSReaderNavigationContext) -> IOSBlockSourceEditorState? {
        guard context.state.readerState == .editingBlock,
              let editSession = context.editSession,
              editSession.mode == .block,
              let blockID = editSession.blockID,
              let sourceRange = editSession.sourceRange else {
            return nil
        }

        let isReadOnly = editSession.returnReaderState == .readOnly
        return IOSBlockSourceEditorState(
            title: context.state.title,
            currentSource: editSession.currentSource,
            isDirty: editSession.isDirty,
            canApply: editSession.isDirty && !isReadOnly,
            canCancel: true,
            isReadOnly: isReadOnly,
            blockID: blockID,
            sourceRange: sourceRange
        )
    }

    public func applyBlockEdit(
        from context: IOSReaderNavigationContext,
        to loadResult: MarkdownLoadResult
    ) throws -> IOSBlockSourceEditApplyResult {
        guard let editSession = context.editSession,
              editSession.mode == .block else {
            throw IOSBlockSourceEditError.wrongEditorMode
        }

        guard let sourceRange = editSession.sourceRange else {
            throw IOSBlockSourceEditError.missingBlockSourceRange
        }

        let currentBlockSource = try sourceSlice(
            in: loadResult.source,
            range: sourceRange
        )
        guard currentBlockSource == editSession.originalSource else {
            throw IOSBlockSourceEditError.sourceRangeMismatch
        }

        guard editSession.isDirty else {
            return IOSBlockSourceEditApplyResult(
                source: loadResult.source,
                lineEnding: loadResult.lineEnding,
                didChange: false
            )
        }

        let updatedSource = try replacingSourceSlice(
            in: loadResult.source,
            range: sourceRange,
            with: editSession.currentSource
        )
        return IOSBlockSourceEditApplyResult(
            source: updatedSource,
            lineEnding: MarkdownLineEnding.detect(in: updatedSource),
            didChange: true
        )
    }

    private func sourceSlice(
        in source: String,
        range: MarkdownSourceRange
    ) throws -> String {
        let bounds = try stringBounds(in: source, range: range)
        return String(source[bounds.start..<bounds.end])
    }

    private func replacingSourceSlice(
        in source: String,
        range: MarkdownSourceRange,
        with replacement: String
    ) throws -> String {
        let bounds = try stringBounds(in: source, range: range)
        var updated = source
        updated.replaceSubrange(bounds.start..<bounds.end, with: replacement)
        return updated
    }

    private func stringBounds(
        in source: String,
        range: MarkdownSourceRange
    ) throws -> (start: String.Index, end: String.Index) {
        guard range.isValid,
              range.startUTF8Offset >= 0,
              range.endUTF8Offset <= source.utf8.count else {
            throw IOSBlockSourceEditError.invalidSourceRange
        }

        let utf8Start = source.utf8.index(
            source.utf8.startIndex,
            offsetBy: range.startUTF8Offset
        )
        let utf8End = source.utf8.index(
            source.utf8.startIndex,
            offsetBy: range.endUTF8Offset
        )

        guard let start = String.Index(utf8Start, within: source),
              let end = String.Index(utf8End, within: source) else {
            throw IOSBlockSourceEditError.invalidSourceRange
        }

        return (start, end)
    }
}

public struct IOSDirtyEditRecoveryDraft: Equatable, Codable, Sendable {
    public let documentIdentifier: String
    public let displayName: String
    public let editorMode: IOSReaderEditMode
    public let originalSourceHash: Int
    public let currentSource: String
    public let capturedAt: Date
    public let expiresAt: Date

    public init(
        documentIdentifier: String,
        displayName: String,
        editorMode: IOSReaderEditMode,
        originalSourceHash: Int,
        currentSource: String,
        capturedAt: Date,
        expiresAt: Date
    ) {
        self.documentIdentifier = documentIdentifier
        self.displayName = IOSDisplayNamePolicy().displayName(for: displayName)
        self.editorMode = editorMode
        self.originalSourceHash = originalSourceHash
        self.currentSource = currentSource
        self.capturedAt = capturedAt
        self.expiresAt = expiresAt
    }

    public func isExpired(at date: Date) -> Bool {
        date >= expiresAt
    }
}

public enum IOSDirtyEditDraftStoreResult: Equatable, Sendable {
    case stored(IOSDirtyEditRecoveryDraft)
    case skippedCleanSession
    case skippedMissingDocument
}

public struct IOSDirtyEditDraftStore: Equatable, Sendable {
    public let storageKey: String
    public let timeToLive: TimeInterval

    public init(
        storageKey: String = "fastmd.ios.dirtyEditRecoveryDraft",
        timeToLive: TimeInterval = 6 * 60 * 60
    ) {
        self.storageKey = storageKey
        self.timeToLive = timeToLive
    }

    @discardableResult
    public func captureForBackground(
        activeDocument: MarkdownLoadResult?,
        editSession: IOSReaderEditSession?,
        now: Date = Date(),
        defaults: UserDefaults = .standard
    ) -> IOSDirtyEditDraftStoreResult {
        guard let activeDocument else {
            clear(defaults: defaults)
            return .skippedMissingDocument
        }

        guard let editSession, editSession.isDirty else {
            clear(defaults: defaults)
            return .skippedCleanSession
        }

        let draft = IOSDirtyEditRecoveryDraft(
            documentIdentifier: activeDocument.handle.identifier,
            displayName: activeDocument.metadata.displayName,
            editorMode: editSession.mode,
            originalSourceHash: editSession.originalSource.hashValue,
            currentSource: editSession.currentSource,
            capturedAt: now,
            expiresAt: now.addingTimeInterval(timeToLive)
        )

        if let data = try? JSONEncoder().encode(draft) {
            defaults.set(data, forKey: storageKey)
        }
        return .stored(draft)
    }

    public func load(
        now: Date = Date(),
        defaults: UserDefaults = .standard
    ) -> IOSDirtyEditRecoveryDraft? {
        guard let data = defaults.data(forKey: storageKey),
              let draft = try? JSONDecoder().decode(IOSDirtyEditRecoveryDraft.self, from: data) else {
            return nil
        }

        guard !draft.isExpired(at: now) else {
            clear(defaults: defaults)
            return nil
        }

        return draft
    }

    public func clear(defaults: UserDefaults = .standard) {
        defaults.removeObject(forKey: storageKey)
    }
}

public enum IOSDirtyEditRecoveryOffer: Equatable, Sendable {
    case restoreDraft(IOSDirtyEditRecoveryDraft)
    case noDraft
}

public struct IOSDirtyEditRecoveryCoordinator: Equatable, Sendable {
    public let store: IOSDirtyEditDraftStore

    public init(store: IOSDirtyEditDraftStore = IOSDirtyEditDraftStore()) {
        self.store = store
    }

    public func recoveryOffer(
        now: Date = Date(),
        defaults: UserDefaults = .standard
    ) -> IOSDirtyEditRecoveryOffer {
        guard let draft = store.load(now: now, defaults: defaults) else {
            return .noDraft
        }
        return .restoreDraft(draft)
    }

    public func makeRestoredEditSession(
        draft: IOSDirtyEditRecoveryDraft,
        activeDocument: MarkdownLoadResult
    ) -> IOSReaderEditSession {
        IOSReaderEditSession(
            mode: draft.editorMode,
            originalSource: activeDocument.source,
            currentSource: draft.currentSource,
            returnReaderState: activeDocument.handle.canWrite ? .ready : .readOnly
        )
    }
}

extension IOSReaderEditMode: Codable {}

public extension IOSDocumentSaveError {
    var readerErrorCode: FastMDErrorCode {
        switch self {
        case .externalMutation:
            return .externalMutation
        case .readOnlyDocument, .unsupportedEncoding, .writeFailed:
            return .saveFailed
        }
    }
}

public extension IOSReaderEditSession {
    func replacingCurrentSource(_ currentSource: String) -> IOSReaderEditSession {
        IOSReaderEditSession(
            mode: mode,
            originalSource: originalSource,
            currentSource: currentSource,
            returnReaderState: returnReaderState,
            blockID: blockID,
            sourceRange: sourceRange
        )
    }
}

public extension IOSReaderScreenState {
    var isDirtyEditing: Bool {
        editSession?.isDirty == true
    }

    func editingSourceState(editSession: IOSReaderEditSession) -> IOSReaderScreenState {
        IOSReaderScreenState(
            readerState: .editingSource,
            title: title,
            subtitle: editSession.isDirty ? "Editing source · Unsaved" : "Editing source",
            selectedFontTier: selectedFontTier,
            themeScheme: themeScheme,
            recentDocuments: recentDocuments,
            renderedBlocks: renderedBlocks,
            searchState: nil,
            isOpenActionAvailable: false,
            isSearchAvailable: false,
            editSession: editSession
        )
    }

    func failedSourceSaveState(
        editSession: IOSReaderEditSession,
        errorCode: FastMDErrorCode = .saveFailed
    ) -> IOSReaderScreenState {
        IOSReaderScreenState(
            readerState: .editingSource,
            title: title,
            subtitle: errorCode == .externalMutation
                ? "External change detected · Unsaved"
                : "Save failed · Unsaved",
            selectedFontTier: selectedFontTier,
            themeScheme: themeScheme,
            recentDocuments: recentDocuments,
            renderedBlocks: renderedBlocks,
            errorCode: errorCode,
            searchState: nil,
            isOpenActionAvailable: false,
            isSearchAvailable: false,
            editSession: editSession
        )
    }

    func editingBlockState(editSession: IOSReaderEditSession) -> IOSReaderScreenState {
        IOSReaderScreenState(
            readerState: .editingBlock,
            title: title,
            subtitle: editSession.isDirty ? "Editing block · Unsaved" : "Editing block",
            selectedFontTier: selectedFontTier,
            themeScheme: themeScheme,
            recentDocuments: recentDocuments,
            renderedBlocks: renderedBlocks,
            searchState: nil,
            isOpenActionAvailable: false,
            isSearchAvailable: false,
            editSession: editSession
        )
    }
}
