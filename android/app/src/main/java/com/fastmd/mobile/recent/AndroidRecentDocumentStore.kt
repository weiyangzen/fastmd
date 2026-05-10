package com.fastmd.mobile.recent

import android.content.Context
import android.net.Uri
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.emptyPreferences
import androidx.datastore.preferences.core.stringSetPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import com.fastmd.mobile.core.document.DocumentHandleId
import com.fastmd.mobile.core.document.DocumentPermissionGrant
import com.fastmd.mobile.core.document.DocumentReferenceKind
import com.fastmd.mobile.core.document.DocumentWriteCapability
import com.fastmd.mobile.core.document.MarkdownLoadResult
import com.fastmd.mobile.core.document.MarkdownFileMetadata
import com.fastmd.mobile.core.document.MobileDocumentHandle
import com.fastmd.mobile.core.document.PlatformDocumentReference
import com.fastmd.mobile.core.document.RecentDocumentMetadata
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.map

private val Context.fastMdRecentDocumentsDataStore by preferencesDataStore(
    name = "fastmd_recent_documents",
)

private val recentDocumentsPreference = stringSetPreferencesKey("recent_documents")
private const val MAX_RECENT_DOCUMENTS = 12
private const val ENCODED_FIELD_COUNT = 12

class AndroidRecentDocumentStore(
    context: Context,
) {
    private val dataStore = context.fastMdRecentDocumentsDataStore

    val recentDocuments: Flow<List<RecentDocumentMetadata>> =
        dataStore.data
            .catch { exception ->
                if (exception is java.io.IOException) {
                    emit(emptyPreferences())
                } else {
                    throw exception
                }
            }
            .map { preferences ->
                preferences[recentDocumentsPreference]
                    .orEmpty()
                    .mapNotNull(::decode)
                    .sortedByDescending { it.lastOpenedEpochMillis }
            }

    suspend fun recordLoaded(result: MarkdownLoadResult.Loaded) {
        val recent = result.toRecentDocumentMetadata() ?: return

        upsert(recent)
    }

    suspend fun recordSaved(
        handle: MobileDocumentHandle?,
        metadata: MarkdownFileMetadata,
    ) {
        if (handle == null) {
            return
        }
        val recent = handle.toRecentDocumentMetadata(metadata) ?: return
        upsert(recent)
    }

    private suspend fun upsert(recent: RecentDocumentMetadata) {
        try {
            dataStore.edit { preferences ->
                val existing = preferences[recentDocumentsPreference]
                    .orEmpty()
                    .mapNotNull(::decode)
                    .filterNot { it.handleId == recent.handleId || it.reference == recent.reference }
                preferences[recentDocumentsPreference] = (listOf(recent) + existing)
                    .take(MAX_RECENT_DOCUMENTS)
                    .map(::encode)
                    .toSet()
            }
        } catch (_: java.io.IOException) {
        }
    }

    private fun MarkdownLoadResult.Loaded.toRecentDocumentMetadata(): RecentDocumentMetadata? {
        if (handle.reference.kind == DocumentReferenceKind.SharedText) {
            return null
        }
        if (handle.reference.kind != DocumentReferenceKind.AndroidContentUri &&
            handle.reference.kind != DocumentReferenceKind.AndroidFileUri
        ) {
            return null
        }

        return RecentDocumentMetadata(
            handleId = handle.id,
            reference = handle.reference,
            displayName = metadata.displayName ?: handle.displayName,
            permissionGrant = handle.permissionGrant,
            lastKnownSizeBytes = metadata.sizeBytes ?: handle.lastKnownSizeBytes,
            lastKnownModifiedEpochMillis = metadata.lastModifiedEpochMillis
                ?: handle.lastKnownModifiedEpochMillis,
            lastOpenedEpochMillis = System.currentTimeMillis(),
            writeCapability = writeCapability,
        )
    }

    private fun MobileDocumentHandle.toRecentDocumentMetadata(
        metadata: MarkdownFileMetadata,
    ): RecentDocumentMetadata? {
        if (reference.kind == DocumentReferenceKind.SharedText) {
            return null
        }
        if (reference.kind != DocumentReferenceKind.AndroidContentUri &&
            reference.kind != DocumentReferenceKind.AndroidFileUri
        ) {
            return null
        }

        return RecentDocumentMetadata(
            handleId = id,
            reference = reference,
            displayName = metadata.displayName ?: displayName,
            permissionGrant = permissionGrant,
            lastKnownSizeBytes = metadata.sizeBytes ?: lastKnownSizeBytes,
            lastKnownModifiedEpochMillis = metadata.lastModifiedEpochMillis
                ?: lastKnownModifiedEpochMillis,
            lastOpenedEpochMillis = System.currentTimeMillis(),
            writeCapability = if (isWritable) DocumentWriteCapability.Writable else DocumentWriteCapability.ReadOnly,
        )
    }
}

private fun encode(recent: RecentDocumentMetadata): String =
    listOf(
        "1",
        recent.handleId.value,
        recent.reference.kind.name,
        recent.reference.rawReference,
        recent.reference.scheme.orEmpty(),
        recent.reference.authority.orEmpty(),
        recent.displayName.orEmpty(),
        recent.permissionGrant.name,
        recent.lastKnownSizeBytes?.toString().orEmpty(),
        recent.lastKnownModifiedEpochMillis?.toString().orEmpty(),
        recent.lastOpenedEpochMillis.toString(),
        recent.writeCapability.name,
    ).joinToString(separator = "|") { Uri.encode(it) }

private fun decode(encoded: String): RecentDocumentMetadata? {
    val parts = encoded.split("|").map(Uri::decode)
    if (parts.size != ENCODED_FIELD_COUNT || parts[0] != "1") {
        return null
    }

    return try {
        RecentDocumentMetadata(
            handleId = DocumentHandleId(parts[1]),
            reference = PlatformDocumentReference(
                kind = DocumentReferenceKind.valueOf(parts[2]),
                rawReference = parts[3],
                scheme = parts[4].ifBlank { null },
                authority = parts[5].ifBlank { null },
            ),
            displayName = parts[6].ifBlank { null },
            permissionGrant = DocumentPermissionGrant.valueOf(parts[7]),
            lastKnownSizeBytes = parts[8].toLongOrNull(),
            lastKnownModifiedEpochMillis = parts[9].toLongOrNull(),
            lastOpenedEpochMillis = parts[10].toLong(),
            writeCapability = DocumentWriteCapability.valueOf(parts[11]),
        )
    } catch (_: IllegalArgumentException) {
        null
    }
}
