package com.fastmd.mobile.core.document

import com.fastmd.mobile.core.error.FastMdErrorCode

enum class MarkdownEncoding {
    Utf8,
    Utf8Bom,
}

enum class MarkdownLineEnding {
    Lf,
    Crlf,
    Mixed,
    Unknown,
}

enum class DocumentWriteCapability {
    Writable,
    ReadOnly,
    Unknown,
}

data class MarkdownFileMetadata(
    val displayName: String?,
    val mimeType: String?,
    val sizeBytes: Long?,
    val lastModifiedEpochMillis: Long?,
    val encoding: MarkdownEncoding,
    val lineEnding: MarkdownLineEnding,
) {
    init {
        require(displayName?.isNotBlank() != false) { "Display name cannot be blank when present." }
        require(sizeBytes == null || sizeBytes >= 0L) { "File size cannot be negative." }
        require(lastModifiedEpochMillis == null || lastModifiedEpochMillis >= 0L) {
            "Modified time cannot be negative."
        }
    }
}

sealed interface MarkdownLoadResult {
    data class Loaded(
        val document: MarkdownDocument,
        val handle: MobileDocumentHandle,
        val metadata: MarkdownFileMetadata,
        val writeCapability: DocumentWriteCapability,
        val origin: DocumentOrigin,
    ) : MarkdownLoadResult {
        init {
            require(document.origin == origin) { "Document origin and load origin must match." }
            require(document.isWritable == (writeCapability == DocumentWriteCapability.Writable)) {
                "Document writability and load write capability must match."
            }
        }
    }

    data class Failed(
        val code: FastMdErrorCode,
        val message: String,
        val recoverable: Boolean,
    ) : MarkdownLoadResult {
        init {
            require(message.isNotBlank()) { "Load failure message cannot be blank." }
        }
    }
}

sealed interface MarkdownSaveResult {
    data class Saved(
        val document: MarkdownDocument,
        val metadata: MarkdownFileMetadata,
    ) : MarkdownSaveResult

    data class Failed(
        val code: FastMdErrorCode,
        val message: String,
        val recoverable: Boolean,
    ) : MarkdownSaveResult {
        init {
            require(message.isNotBlank()) { "Save failure message cannot be blank." }
        }
    }
}
