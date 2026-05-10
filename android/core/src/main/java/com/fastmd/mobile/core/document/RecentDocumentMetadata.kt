package com.fastmd.mobile.core.document

data class RecentDocumentMetadata(
    val handleId: DocumentHandleId,
    val reference: PlatformDocumentReference,
    val displayName: String?,
    val permissionGrant: DocumentPermissionGrant,
    val lastKnownSizeBytes: Long?,
    val lastKnownModifiedEpochMillis: Long?,
    val lastOpenedEpochMillis: Long,
    val writeCapability: DocumentWriteCapability,
) {
    init {
        require(displayName?.isNotBlank() != false) { "Recent document display name cannot be blank." }
        require(lastKnownSizeBytes == null || lastKnownSizeBytes >= 0L) {
            "Recent document size cannot be negative."
        }
        require(lastKnownModifiedEpochMillis == null || lastKnownModifiedEpochMillis >= 0L) {
            "Recent document modified time cannot be negative."
        }
        require(lastOpenedEpochMillis >= 0L) { "Recent document open time cannot be negative." }
        require(reference.kind != DocumentReferenceKind.SharedText) {
            "Recent documents must not persist shared text content references."
        }
    }

    val canAttemptReopen: Boolean
        get() = reference.kind == DocumentReferenceKind.AndroidContentUri ||
            reference.kind == DocumentReferenceKind.AndroidFileUri
}
