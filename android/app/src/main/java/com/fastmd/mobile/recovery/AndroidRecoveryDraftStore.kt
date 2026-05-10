package com.fastmd.mobile.recovery

import android.content.Context
import com.fastmd.mobile.core.document.DocumentHandleId
import com.fastmd.mobile.core.document.DocumentOrigin
import com.fastmd.mobile.core.document.DocumentPermissionGrant
import com.fastmd.mobile.core.document.DocumentReferenceKind
import com.fastmd.mobile.core.document.MarkdownEncoding
import com.fastmd.mobile.core.document.MarkdownFileMetadata
import com.fastmd.mobile.core.document.MarkdownLineEnding
import com.fastmd.mobile.core.document.MobileDocumentHandle
import com.fastmd.mobile.core.document.MobilePlatform
import com.fastmd.mobile.core.document.PlatformDocumentReference
import com.fastmd.mobile.core.reader.FontTier
import com.fastmd.mobile.core.render.MarkdownBlockId
import com.fastmd.mobile.core.render.SourceRange
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream
import java.util.Properties
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

class AndroidRecoveryDraftStore(
    context: Context,
) {
    private val recoveryDir = File(context.filesDir, RECOVERY_DIR_NAME)
    private val metadataFile = File(recoveryDir, METADATA_FILE_NAME)
    private val draftFile = File(recoveryDir, DRAFT_FILE_NAME)
    private val originalBlockFile = File(recoveryDir, ORIGINAL_BLOCK_FILE_NAME)

    suspend fun save(draft: AndroidRecoveryDraft?) {
        if (draft == null) {
            clear()
            return
        }

        withContext(Dispatchers.IO) {
            recoveryDir.mkdirs()
            draftFile.writeText(draft.base.draftSource, Charsets.UTF_8)
            if (draft is AndroidRecoveryDraft.Block) {
                originalBlockFile.writeText(draft.originalBlockSource, Charsets.UTF_8)
            } else if (originalBlockFile.exists()) {
                originalBlockFile.delete()
            }
            FileOutputStream(metadataFile).use { output ->
                draft.toProperties().store(output, null)
            }
        }
    }

    suspend fun clear() {
        withContext(Dispatchers.IO) {
            listOf(metadataFile, draftFile, originalBlockFile).forEach { file ->
                if (file.exists()) {
                    file.delete()
                }
            }
            if (recoveryDir.exists() && recoveryDir.list()?.isEmpty() == true) {
                recoveryDir.delete()
            }
        }
    }

    suspend fun readSummary(): AndroidRecoveryDraftSummary? =
        withContext(Dispatchers.IO) {
            runCatching {
                readProperties()?.toSummary()
            }.getOrNull()
        }

    suspend fun readDraft(): AndroidRecoveryDraft? =
        withContext(Dispatchers.IO) {
            runCatching {
                val properties = readProperties() ?: return@runCatching null
                val draftSource = draftFile.takeIf { it.exists() }?.readText(Charsets.UTF_8)
                    ?: return@runCatching null
                val base = properties.toBaseDraft(draftSource) ?: return@runCatching null
                when (base.mode) {
                    AndroidRecoveryDraftMode.Source -> AndroidRecoveryDraft.Source(base)
                    AndroidRecoveryDraftMode.Block -> {
                        val originalBlockSource = originalBlockFile.takeIf { it.exists() }?.readText(Charsets.UTF_8)
                            ?: return@runCatching null
                        AndroidRecoveryDraft.Block(
                            base = base,
                            blockId = MarkdownBlockId(properties.requiredString(KEY_BLOCK_ID)),
                            originalSourceRange = SourceRange(
                                startLine = properties.requiredInt(KEY_BLOCK_START_LINE),
                                endLineInclusive = properties.requiredInt(KEY_BLOCK_END_LINE),
                                startOffset = properties.requiredInt(KEY_BLOCK_START_OFFSET),
                                endOffsetExclusive = properties.requiredInt(KEY_BLOCK_END_OFFSET),
                            ),
                            originalBlockSource = originalBlockSource,
                        )
                    }
                }
            }.getOrNull()
        }

    private fun readProperties(): Properties? {
        if (!metadataFile.exists() || !draftFile.exists()) {
            return null
        }
        return Properties().apply {
            FileInputStream(metadataFile).use(::load)
        }
    }

    private fun AndroidRecoveryDraft.toProperties(): Properties =
        Properties().also { properties ->
            val base = this.base
            properties[KEY_MODE] = base.mode.name
            properties[KEY_SAVED_AT] = base.savedAtEpochMillis.toString()
            properties[KEY_TITLE] = base.title
            properties[KEY_ORIGIN] = base.origin.name
            properties[KEY_FONT_TIER] = base.fontTier.name
            properties[KEY_HANDLE_ID] = base.handle.id.value
            properties[KEY_HANDLE_REFERENCE_KIND] = base.handle.reference.kind.name
            properties[KEY_HANDLE_RAW_REFERENCE] = base.handle.reference.rawReference
            properties.setNullable(KEY_HANDLE_SCHEME, base.handle.reference.scheme)
            properties.setNullable(KEY_HANDLE_AUTHORITY, base.handle.reference.authority)
            properties.setNullable(KEY_HANDLE_DISPLAY_NAME, base.handle.displayName)
            properties[KEY_HANDLE_PERMISSION_GRANT] = base.handle.permissionGrant.name
            properties.setNullable(KEY_HANDLE_SIZE_BYTES, base.handle.lastKnownSizeBytes?.toString())
            properties.setNullable(KEY_HANDLE_MODIFIED_AT, base.handle.lastKnownModifiedEpochMillis?.toString())
            properties.setNullable(KEY_METADATA_DISPLAY_NAME, base.metadata.displayName)
            properties.setNullable(KEY_METADATA_MIME_TYPE, base.metadata.mimeType)
            properties.setNullable(KEY_METADATA_SIZE_BYTES, base.metadata.sizeBytes?.toString())
            properties.setNullable(KEY_METADATA_MODIFIED_AT, base.metadata.lastModifiedEpochMillis?.toString())
            properties[KEY_METADATA_ENCODING] = base.metadata.encoding.name
            properties[KEY_METADATA_LINE_ENDING] = base.metadata.lineEnding.name
            if (this is AndroidRecoveryDraft.Block) {
                properties[KEY_BLOCK_ID] = blockId.value
                properties[KEY_BLOCK_START_LINE] = originalSourceRange.startLine.toString()
                properties[KEY_BLOCK_END_LINE] = originalSourceRange.endLineInclusive.toString()
                properties[KEY_BLOCK_START_OFFSET] = originalSourceRange.startOffset.toString()
                properties[KEY_BLOCK_END_OFFSET] = originalSourceRange.endOffsetExclusive.toString()
            }
        }

    private fun Properties.toBaseDraft(draftSource: String): AndroidRecoveryDraftBase? {
        val mode = enumValueOrNull<AndroidRecoveryDraftMode>(requiredString(KEY_MODE)) ?: return null
        val handle = MobileDocumentHandle(
            id = DocumentHandleId(requiredString(KEY_HANDLE_ID)),
            platform = MobilePlatform.Android,
            reference = PlatformDocumentReference(
                kind = enumValueOrNull<DocumentReferenceKind>(requiredString(KEY_HANDLE_REFERENCE_KIND)) ?: return null,
                rawReference = requiredString(KEY_HANDLE_RAW_REFERENCE),
                scheme = nullableString(KEY_HANDLE_SCHEME),
                authority = nullableString(KEY_HANDLE_AUTHORITY),
            ),
            displayName = nullableString(KEY_HANDLE_DISPLAY_NAME),
            permissionGrant = enumValueOrNull<DocumentPermissionGrant>(requiredString(KEY_HANDLE_PERMISSION_GRANT))
                ?: return null,
            lastKnownSizeBytes = nullableLong(KEY_HANDLE_SIZE_BYTES),
            lastKnownModifiedEpochMillis = nullableLong(KEY_HANDLE_MODIFIED_AT),
        )
        val metadata = MarkdownFileMetadata(
            displayName = nullableString(KEY_METADATA_DISPLAY_NAME),
            mimeType = nullableString(KEY_METADATA_MIME_TYPE),
            sizeBytes = nullableLong(KEY_METADATA_SIZE_BYTES),
            lastModifiedEpochMillis = nullableLong(KEY_METADATA_MODIFIED_AT),
            encoding = enumValueOrNull<MarkdownEncoding>(requiredString(KEY_METADATA_ENCODING)) ?: return null,
            lineEnding = enumValueOrNull<MarkdownLineEnding>(requiredString(KEY_METADATA_LINE_ENDING)) ?: return null,
        )
        return AndroidRecoveryDraftBase(
            mode = mode,
            savedAtEpochMillis = requiredLong(KEY_SAVED_AT),
            title = requiredString(KEY_TITLE),
            origin = enumValueOrNull<DocumentOrigin>(requiredString(KEY_ORIGIN)) ?: return null,
            fontTier = enumValueOrNull<FontTier>(requiredString(KEY_FONT_TIER)) ?: return null,
            handle = handle,
            metadata = metadata,
            draftSource = draftSource,
        )
    }

    private fun Properties.toSummary(): AndroidRecoveryDraftSummary? {
        val mode = enumValueOrNull<AndroidRecoveryDraftMode>(requiredString(KEY_MODE)) ?: return null
        return AndroidRecoveryDraftSummary(
            mode = mode,
            title = requiredString(KEY_TITLE),
            savedAtEpochMillis = requiredLong(KEY_SAVED_AT),
        )
    }

    private fun Properties.setNullable(key: String, value: String?) {
        if (value != null) {
            this[key] = value
        }
    }

    private fun Properties.requiredString(key: String): String =
        getProperty(key) ?: throw IllegalArgumentException("Missing recovery draft key: $key")

    private fun Properties.nullableString(key: String): String? =
        getProperty(key)

    private fun Properties.requiredLong(key: String): Long =
        requiredString(key).toLong()

    private fun Properties.nullableLong(key: String): Long? =
        getProperty(key)?.toLong()

    private fun Properties.requiredInt(key: String): Int =
        requiredString(key).toInt()

    private inline fun <reified T : Enum<T>> enumValueOrNull(value: String): T? =
        enumValues<T>().firstOrNull { it.name == value }

    private companion object {
        const val RECOVERY_DIR_NAME = "recovery-draft"
        const val METADATA_FILE_NAME = "metadata.properties"
        const val DRAFT_FILE_NAME = "draft.md"
        const val ORIGINAL_BLOCK_FILE_NAME = "original-block.md"
        const val KEY_MODE = "mode"
        const val KEY_SAVED_AT = "savedAtEpochMillis"
        const val KEY_TITLE = "title"
        const val KEY_ORIGIN = "origin"
        const val KEY_FONT_TIER = "fontTier"
        const val KEY_HANDLE_ID = "handleId"
        const val KEY_HANDLE_REFERENCE_KIND = "handleReferenceKind"
        const val KEY_HANDLE_RAW_REFERENCE = "handleRawReference"
        const val KEY_HANDLE_SCHEME = "handleScheme"
        const val KEY_HANDLE_AUTHORITY = "handleAuthority"
        const val KEY_HANDLE_DISPLAY_NAME = "handleDisplayName"
        const val KEY_HANDLE_PERMISSION_GRANT = "handlePermissionGrant"
        const val KEY_HANDLE_SIZE_BYTES = "handleSizeBytes"
        const val KEY_HANDLE_MODIFIED_AT = "handleModifiedAt"
        const val KEY_METADATA_DISPLAY_NAME = "metadataDisplayName"
        const val KEY_METADATA_MIME_TYPE = "metadataMimeType"
        const val KEY_METADATA_SIZE_BYTES = "metadataSizeBytes"
        const val KEY_METADATA_MODIFIED_AT = "metadataModifiedAt"
        const val KEY_METADATA_ENCODING = "metadataEncoding"
        const val KEY_METADATA_LINE_ENDING = "metadataLineEnding"
        const val KEY_BLOCK_ID = "blockId"
        const val KEY_BLOCK_START_LINE = "blockStartLine"
        const val KEY_BLOCK_END_LINE = "blockEndLine"
        const val KEY_BLOCK_START_OFFSET = "blockStartOffset"
        const val KEY_BLOCK_END_OFFSET = "blockEndOffset"
    }
}

enum class AndroidRecoveryDraftMode {
    Source,
    Block,
}

data class AndroidRecoveryDraftSummary(
    val mode: AndroidRecoveryDraftMode,
    val title: String,
    val savedAtEpochMillis: Long,
)

data class AndroidRecoveryDraftBase(
    val mode: AndroidRecoveryDraftMode,
    val savedAtEpochMillis: Long,
    val title: String,
    val origin: DocumentOrigin,
    val fontTier: FontTier,
    val handle: MobileDocumentHandle,
    val metadata: MarkdownFileMetadata,
    val draftSource: String,
)

sealed interface AndroidRecoveryDraft {
    val base: AndroidRecoveryDraftBase

    data class Source(
        override val base: AndroidRecoveryDraftBase,
    ) : AndroidRecoveryDraft

    data class Block(
        override val base: AndroidRecoveryDraftBase,
        val blockId: MarkdownBlockId,
        val originalSourceRange: SourceRange,
        val originalBlockSource: String,
    ) : AndroidRecoveryDraft
}
