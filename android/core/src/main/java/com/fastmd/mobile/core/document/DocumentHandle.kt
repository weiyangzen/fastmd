package com.fastmd.mobile.core.document

@JvmInline
value class DocumentHandleId(
    val value: String,
) {
    init {
        require(value.isNotBlank()) { "DocumentHandleId cannot be blank." }
    }
}

enum class MobilePlatform {
    Android,
}

enum class DocumentReferenceKind {
    AppCreated,
    AndroidContentUri,
    AndroidFileUri,
    SharedText,
}

enum class DocumentPermissionGrant {
    None,
    TransientRead,
    TransientReadWrite,
    PersistedRead,
    PersistedReadWrite,
    Lost,
}

data class PlatformDocumentReference(
    val kind: DocumentReferenceKind,
    val rawReference: String,
    val scheme: String? = null,
    val authority: String? = null,
) {
    init {
        require(rawReference.isNotBlank()) { "Document reference cannot be blank." }
        require(!scheme.equals("javascript", ignoreCase = true)) {
            "Document references cannot use javascript: URLs."
        }
        require(!scheme.equals("data", ignoreCase = true)) {
            "Document references cannot use data: URLs."
        }
    }

    companion object {
        fun androidContentUri(uriString: String, authority: String? = null): PlatformDocumentReference =
            PlatformDocumentReference(
                kind = DocumentReferenceKind.AndroidContentUri,
                rawReference = uriString,
                scheme = "content",
                authority = authority,
            )

        fun androidFileUri(uriString: String): PlatformDocumentReference =
            PlatformDocumentReference(
                kind = DocumentReferenceKind.AndroidFileUri,
                rawReference = uriString,
                scheme = "file",
            )

        fun sharedText(token: String): PlatformDocumentReference =
            PlatformDocumentReference(
                kind = DocumentReferenceKind.SharedText,
                rawReference = token,
            )

        fun appCreated(token: String): PlatformDocumentReference =
            PlatformDocumentReference(
                kind = DocumentReferenceKind.AppCreated,
                rawReference = token,
            )
    }
}

data class MobileDocumentHandle(
    val id: DocumentHandleId,
    val platform: MobilePlatform,
    val reference: PlatformDocumentReference,
    val displayName: String?,
    val permissionGrant: DocumentPermissionGrant,
    val lastKnownSizeBytes: Long? = null,
    val lastKnownModifiedEpochMillis: Long? = null,
) {
    init {
        require(displayName?.isNotBlank() != false) { "Display name cannot be blank when present." }
        require(lastKnownSizeBytes == null || lastKnownSizeBytes >= 0L) {
            "Document size cannot be negative."
        }
        require(lastKnownModifiedEpochMillis == null || lastKnownModifiedEpochMillis >= 0L) {
            "Modified time cannot be negative."
        }
    }

    val isWritable: Boolean
        get() = permissionGrant == DocumentPermissionGrant.TransientReadWrite ||
            permissionGrant == DocumentPermissionGrant.PersistedReadWrite

    val isPermissionLost: Boolean
        get() = permissionGrant == DocumentPermissionGrant.Lost
}
