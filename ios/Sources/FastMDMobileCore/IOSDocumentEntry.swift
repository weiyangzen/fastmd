import Foundation

public enum IOSDocumentEntryPoint: String, CaseIterable, Equatable, Sendable {
    case launcher
    case documentPicker
    case filesAppOpen
    case shareText
    case shareDocumentURL
}

public enum IOSDocumentEntryError: Equatable, Error, Sendable {
    case unsupportedDocumentType
    case unsupportedEncoding
    case emptySharedText
    case missingURL
    case readFailed
    case writeFailed
    case staleBookmark
    case bookmarkCreationFailed
}

public struct IOSMarkdownDocumentTypePolicy: Equatable, Sendable {
    public let allowedFilenameExtensions: Set<String>
    public let markdownContentTypeIdentifiers: Set<String>

    public init(
        allowedFilenameExtensions: Set<String> = ["md", "markdown", "mdown", "mkd"],
        markdownContentTypeIdentifiers: Set<String> = [
            "net.daringfireball.markdown",
            "public.markdown",
            "public.plain-text"
        ]
    ) {
        self.allowedFilenameExtensions = Set(allowedFilenameExtensions.map { $0.lowercased() })
        self.markdownContentTypeIdentifiers = markdownContentTypeIdentifiers
    }

    public func acceptsDocumentURL(_ url: URL) -> Bool {
        allowedFilenameExtensions.contains(url.pathExtension.lowercased())
    }
}

public struct IOSDocumentEntryRequest: Equatable, Sendable {
    public let entryPoint: IOSDocumentEntryPoint
    public let url: URL?
    public let sharedText: String?
    public let displayName: String?
    public let contentTypeIdentifier: String?
    public let isUserSelected: Bool

    public init(
        entryPoint: IOSDocumentEntryPoint,
        url: URL? = nil,
        sharedText: String? = nil,
        displayName: String? = nil,
        contentTypeIdentifier: String? = nil,
        isUserSelected: Bool = false
    ) {
        self.entryPoint = entryPoint
        self.url = url
        self.sharedText = sharedText
        self.displayName = displayName
        self.contentTypeIdentifier = contentTypeIdentifier
        self.isUserSelected = isUserSelected
    }
}

public enum IOSDocumentEntryAction: Equatable, Sendable {
    case showLauncher
    case openDocumentURL(URL, origin: MobileSourceOrigin, persistBookmark: Bool)
    case loadSharedText(String, displayName: String)
}

public struct IOSDocumentEntryCoordinator: Equatable, Sendable {
    public let typePolicy: IOSMarkdownDocumentTypePolicy

    public init(typePolicy: IOSMarkdownDocumentTypePolicy = IOSMarkdownDocumentTypePolicy()) {
        self.typePolicy = typePolicy
    }

    public func action(for request: IOSDocumentEntryRequest) throws -> IOSDocumentEntryAction {
        switch request.entryPoint {
        case .launcher:
            return .showLauncher

        case .documentPicker:
            let url = try validatedMarkdownURL(from: request)
            return .openDocumentURL(url, origin: .documentPicker, persistBookmark: request.isUserSelected)

        case .filesAppOpen:
            let url = try validatedMarkdownURL(from: request)
            return .openDocumentURL(url, origin: .filesAppOpen, persistBookmark: false)

        case .shareText:
            let text = request.sharedText?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard !text.isEmpty else {
                throw IOSDocumentEntryError.emptySharedText
            }
            return .loadSharedText(text, displayName: request.displayName ?? "Shared Markdown")

        case .shareDocumentURL:
            let url = try validatedMarkdownURL(from: request)
            return .openDocumentURL(url, origin: .shareDocumentURL, persistBookmark: false)
        }
    }

    public func makeTemporarySharedTextLoadResult(
        text: String,
        displayName: String = "Shared Markdown",
        loadedAt: Date = Date()
    ) throws -> MarkdownLoadResult {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else {
            throw IOSDocumentEntryError.emptySharedText
        }

        let handle = MobileDocumentHandle(
            identifier: "ios:share-text:\(trimmedText.hashValue)",
            displayName: displayName,
            origin: .shareText,
            access: .readOnly
        )
        let metadata = MobileFileMetadata(
            displayName: displayName,
            byteCount: trimmedText.utf8.count,
            contentTypeIdentifier: "net.daringfireball.markdown"
        )

        return MarkdownLoadResult(
            handle: handle,
            metadata: metadata,
            source: trimmedText,
            encoding: .utf8,
            lineEnding: MarkdownLineEnding.detect(in: trimmedText),
            loadedAt: loadedAt
        )
    }

    private func validatedMarkdownURL(from request: IOSDocumentEntryRequest) throws -> URL {
        guard let url = request.url else {
            throw IOSDocumentEntryError.missingURL
        }

        guard typePolicy.acceptsDocumentURL(url) else {
            throw IOSDocumentEntryError.unsupportedDocumentType
        }

        return url
    }
}

public struct IOSSecurityScopedAccess: Equatable, Sendable {
    public let url: URL
    public let didStartAccessing: Bool

    public init(url: URL, didStartAccessing: Bool) {
        self.url = url
        self.didStartAccessing = didStartAccessing
    }

    public static func withAccess<T>(
        to url: URL,
        _ operation: (IOSSecurityScopedAccess) throws -> T
    ) rethrows -> T {
        let didStartAccessing = url.startAccessingSecurityScopedResource()
        defer {
            if didStartAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }

        return try operation(
            IOSSecurityScopedAccess(url: url, didStartAccessing: didStartAccessing)
        )
    }
}

public struct IOSDocumentFileIO: Equatable, Sendable {
    public init() {}

    public func loadDocumentOffMainActor(
        at url: URL,
        origin: MobileSourceOrigin,
        access: MobileDocumentAccess = .readWrite,
        bookmarkData: Data? = nil,
        contentTypeIdentifier: String? = "net.daringfireball.markdown",
        loadedAt: Date = Date()
    ) async throws -> IOSOffMainActorWorkResult<MarkdownLoadResult> {
        try await Task.detached(priority: .userInitiated) {
            let startedOnMainThread = iosIsMainThreadForDiagnostics()
            let value = try loadDocument(
                at: url,
                origin: origin,
                access: access,
                bookmarkData: bookmarkData,
                contentTypeIdentifier: contentTypeIdentifier,
                loadedAt: loadedAt
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

    public func loadDocument(
        at url: URL,
        origin: MobileSourceOrigin,
        access: MobileDocumentAccess = .readWrite,
        bookmarkData: Data? = nil,
        contentTypeIdentifier: String? = "net.daringfireball.markdown",
        loadedAt: Date = Date()
    ) throws -> MarkdownLoadResult {
        try IOSSecurityScopedAccess.withAccess(to: url) { _ in
            let data: Data
            do {
                data = try Data(contentsOf: url)
            } catch {
                throw IOSDocumentEntryError.readFailed
            }

            let decoded = try decodeMarkdownData(data)
            let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
            let modifiedAt = attributes?[.modificationDate] as? Date
            let handle = MobileDocumentHandle(
                identifier: "ios:url:\(url.path)",
                displayName: url.lastPathComponent,
                origin: origin,
                access: access,
                bookmarkData: bookmarkData
            )
            let metadata = MobileFileMetadata(
                displayName: url.lastPathComponent,
                byteCount: data.count,
                contentTypeIdentifier: contentTypeIdentifier,
                modifiedAt: modifiedAt
            )

            return MarkdownLoadResult(
                handle: handle,
                metadata: metadata,
                source: decoded.source,
                encoding: decoded.encoding,
                lineEnding: MarkdownLineEnding.detect(in: decoded.source),
                loadedAt: loadedAt
            )
        }
    }

    public func saveDocument(source: String, to url: URL) throws {
        try IOSSecurityScopedAccess.withAccess(to: url) { _ in
            guard let data = source.data(using: .utf8) else {
                throw IOSDocumentEntryError.unsupportedEncoding
            }

            do {
                try data.write(to: url, options: .atomic)
            } catch {
                throw IOSDocumentEntryError.writeFailed
            }
        }
    }

    @discardableResult
    public func saveDocumentOffMainActor(
        editedSource: String,
        for loadedDocument: MarkdownLoadResult,
        to url: URL
    ) async throws -> IOSOffMainActorWorkResult<IOSDocumentSaveResult> {
        try await Task.detached(priority: .userInitiated) {
            let startedOnMainThread = iosIsMainThreadForDiagnostics()
            let value = try saveDocument(
                editedSource: editedSource,
                for: loadedDocument,
                to: url
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

    @discardableResult
    public func saveDocument(
        editedSource: String,
        for loadedDocument: MarkdownLoadResult,
        to url: URL
    ) throws -> IOSDocumentSaveResult {
        let plan = try IOSDocumentSavePlanner().makePlan(
            editedSource: editedSource,
            for: loadedDocument
        )

        do {
            try IOSSecurityScopedAccess.withAccess(to: url) { _ in
                try verifyDestinationUnchanged(
                    loadedDocument: loadedDocument,
                    destinationURL: url,
                    retainedDirtyBuffer: editedSource
                )
                try plan.completeOutput.write(to: url, options: .atomic)
            }
        } catch let error as IOSDocumentSaveError {
            throw error
        } catch {
            throw IOSDocumentSaveError.writeFailed(retainedDirtyBuffer: editedSource)
        }

        return IOSDocumentSaveResult(
            savedSource: plan.normalizedSource,
            encoding: plan.encoding,
            lineEnding: plan.lineEnding,
            byteCount: plan.completeOutput.count,
            retainedDirtyBufferAfterFailure: nil
        )
    }

    private func decodeMarkdownData(_ data: Data) throws -> (source: String, encoding: MarkdownTextEncoding) {
        if data.starts(with: [0xEF, 0xBB, 0xBF]) {
            let body = data.dropFirst(3)
            guard let source = String(data: body, encoding: .utf8) else {
                throw IOSDocumentEntryError.unsupportedEncoding
            }
            return (source, .utf8WithBOM)
        }

        guard let source = String(data: data, encoding: .utf8) else {
            throw IOSDocumentEntryError.unsupportedEncoding
        }

        return (source, .utf8)
    }

    private func verifyDestinationUnchanged(
        loadedDocument: MarkdownLoadResult,
        destinationURL: URL,
        retainedDirtyBuffer: String
    ) throws {
        let currentData: Data
        do {
            currentData = try Data(contentsOf: destinationURL)
        } catch {
            throw IOSDocumentSaveError.writeFailed(retainedDirtyBuffer: retainedDirtyBuffer)
        }

        let currentDecoded: (source: String, encoding: MarkdownTextEncoding)
        do {
            currentDecoded = try decodeMarkdownData(currentData)
        } catch {
            throw IOSDocumentSaveError.externalMutation(retainedDirtyBuffer: retainedDirtyBuffer)
        }

        guard currentDecoded.source == loadedDocument.source,
              currentDecoded.encoding == loadedDocument.encoding,
              currentData.count == loadedDocument.metadata.byteCount else {
            throw IOSDocumentSaveError.externalMutation(retainedDirtyBuffer: retainedDirtyBuffer)
        }
    }
}

public enum IOSDocumentSaveError: Equatable, Error, Sendable {
    case readOnlyDocument
    case unsupportedEncoding
    case externalMutation(retainedDirtyBuffer: String)
    case writeFailed(retainedDirtyBuffer: String)
}

public struct IOSDocumentSavePlan: Equatable, Sendable {
    public let normalizedSource: String
    public let completeOutput: Data
    public let encoding: MarkdownTextEncoding
    public let lineEnding: MarkdownLineEnding
    public let writesCompleteOutput: Bool

    public init(
        normalizedSource: String,
        completeOutput: Data,
        encoding: MarkdownTextEncoding,
        lineEnding: MarkdownLineEnding,
        writesCompleteOutput: Bool = true
    ) {
        self.normalizedSource = normalizedSource
        self.completeOutput = completeOutput
        self.encoding = encoding
        self.lineEnding = lineEnding
        self.writesCompleteOutput = writesCompleteOutput
    }
}

public struct IOSDocumentSaveResult: Equatable, Sendable {
    public let savedSource: String
    public let encoding: MarkdownTextEncoding
    public let lineEnding: MarkdownLineEnding
    public let byteCount: Int
    public let retainedDirtyBufferAfterFailure: String?

    public init(
        savedSource: String,
        encoding: MarkdownTextEncoding,
        lineEnding: MarkdownLineEnding,
        byteCount: Int,
        retainedDirtyBufferAfterFailure: String?
    ) {
        self.savedSource = savedSource
        self.encoding = encoding
        self.lineEnding = lineEnding
        self.byteCount = byteCount
        self.retainedDirtyBufferAfterFailure = retainedDirtyBufferAfterFailure
    }
}

public struct IOSDocumentSavePlanner: Equatable, Sendable {
    public init() {}

    public func makePlan(
        editedSource: String,
        for loadedDocument: MarkdownLoadResult
    ) throws -> IOSDocumentSavePlan {
        guard loadedDocument.handle.canWrite else {
            throw IOSDocumentSaveError.readOnlyDocument
        }

        guard loadedDocument.encoding != .unsupported else {
            throw IOSDocumentSaveError.unsupportedEncoding
        }

        let sourceWithoutLeadingBOM = editedSource.droppingLeadingUnicodeBOM()
        let normalizedSource = normalizeLineEndings(
            in: sourceWithoutLeadingBOM,
            preserving: loadedDocument.lineEnding
        )
        guard var data = normalizedSource.data(using: .utf8) else {
            throw IOSDocumentSaveError.unsupportedEncoding
        }

        if loadedDocument.encoding == .utf8WithBOM {
            data.insert(contentsOf: [0xEF, 0xBB, 0xBF], at: 0)
        }

        return IOSDocumentSavePlan(
            normalizedSource: normalizedSource,
            completeOutput: data,
            encoding: loadedDocument.encoding,
            lineEnding: MarkdownLineEnding.detect(in: normalizedSource),
            writesCompleteOutput: true
        )
    }

    private func normalizeLineEndings(
        in source: String,
        preserving loadedLineEnding: MarkdownLineEnding
    ) -> String {
        switch loadedLineEnding {
        case .crlf:
            return source.normalizedToLF().replacingOccurrences(of: "\n", with: "\r\n")
        case .lf:
            return source.normalizedToLF()
        case .mixed, .none:
            return source
        }
    }
}

public struct IOSRecentDocumentRecord: Equatable, Sendable {
    public let identifier: String
    public let displayName: String
    public let bookmarkData: Data
    public let contentTypeIdentifier: String?
    public let lastOpenedAt: Date
    public let byteCount: Int?

    public init(
        identifier: String,
        displayName: String,
        bookmarkData: Data,
        contentTypeIdentifier: String?,
        lastOpenedAt: Date,
        byteCount: Int? = nil
    ) {
        self.identifier = identifier
        self.displayName = displayName
        self.bookmarkData = bookmarkData
        self.contentTypeIdentifier = contentTypeIdentifier
        self.lastOpenedAt = lastOpenedAt
        self.byteCount = byteCount
    }

    public var handle: MobileDocumentHandle {
        MobileDocumentHandle(
            identifier: identifier,
            displayName: displayName,
            origin: .recentBookmark,
            access: .readWrite,
            bookmarkData: bookmarkData
        )
    }
}

public struct IOSRecentDocumentStore: Equatable, Sendable {
    public private(set) var records: [IOSRecentDocumentRecord]

    public init(records: [IOSRecentDocumentRecord] = []) {
        self.records = records
    }

    public mutating func upsertUserSelectedDocument(
        url: URL,
        bookmarkData: Data?,
        contentTypeIdentifier: String?,
        openedAt: Date = Date(),
        byteCount: Int? = nil
    ) throws {
        guard let bookmarkData, !bookmarkData.isEmpty else {
            throw IOSDocumentEntryError.bookmarkCreationFailed
        }

        let record = IOSRecentDocumentRecord(
            identifier: "ios:bookmark:\(url.path)",
            displayName: url.lastPathComponent,
            bookmarkData: bookmarkData,
            contentTypeIdentifier: contentTypeIdentifier,
            lastOpenedAt: openedAt,
            byteCount: byteCount
        )

        records.removeAll { $0.identifier == record.identifier }
        records.insert(record, at: 0)
    }

    public func record(identifier: String) -> IOSRecentDocumentRecord? {
        records.first { $0.identifier == identifier }
    }
}

public enum IOSBookmarkResolution: Equatable, Sendable {
    case resolved(URL, handle: MobileDocumentHandle)
    case permissionLost
}

public struct IOSBookmarkResolver: Equatable, Sendable {
    public init() {}

    public func resolve(
        record: IOSRecentDocumentRecord,
        resolvedURL: URL?,
        isStale: Bool
    ) -> IOSBookmarkResolution {
        guard !isStale, let resolvedURL else {
            return .permissionLost
        }

        return .resolved(resolvedURL, handle: record.handle)
    }
}

extension MarkdownLineEnding {
    public static func detect(in source: String) -> MarkdownLineEnding {
        let hasCRLF = source.contains("\r\n")
        let normalized = source.replacingOccurrences(of: "\r\n", with: "")
        let hasLF = normalized.contains("\n")

        switch (hasCRLF, hasLF) {
        case (true, true):
            return .mixed
        case (true, false):
            return .crlf
        case (false, true):
            return .lf
        case (false, false):
            return .none
        }
    }
}

private extension String {
    func droppingLeadingUnicodeBOM() -> String {
        guard first == "\u{FEFF}" else {
            return self
        }
        return String(dropFirst())
    }

    func normalizedToLF() -> String {
        replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
    }
}

#if canImport(UIKit) && canImport(UniformTypeIdentifiers)
import UIKit
import UniformTypeIdentifiers

@available(iOS 14.0, *)
public struct IOSDocumentPickerConfiguration: Equatable, Sendable {
    public let allowedContentTypes: [UTType]
    public let allowsMultipleSelection: Bool

    public init(
        allowedContentTypes: [UTType] = [.plainText],
        allowsMultipleSelection: Bool = false
    ) {
        self.allowedContentTypes = allowedContentTypes
        self.allowsMultipleSelection = allowsMultipleSelection
    }

    public func makeDocumentPicker() -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(
            forOpeningContentTypes: allowedContentTypes,
            asCopy: false
        )
        picker.allowsMultipleSelection = allowsMultipleSelection
        return picker
    }
}
#endif
