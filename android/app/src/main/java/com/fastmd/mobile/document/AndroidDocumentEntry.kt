package com.fastmd.mobile.document

import android.content.ContentResolver
import android.content.Context
import android.content.Intent
import android.database.Cursor
import android.net.Uri
import android.os.Build
import android.provider.OpenableColumns
import com.fastmd.mobile.core.document.DocumentHandleId
import com.fastmd.mobile.core.document.DocumentOrigin
import com.fastmd.mobile.core.document.DocumentPermissionGrant
import com.fastmd.mobile.core.document.DocumentReferenceKind
import com.fastmd.mobile.core.document.DocumentWriteCapability
import com.fastmd.mobile.core.document.MarkdownDocument
import com.fastmd.mobile.core.document.MarkdownEncoding
import com.fastmd.mobile.core.document.MarkdownFileMetadata
import com.fastmd.mobile.core.document.MarkdownLineEnding
import com.fastmd.mobile.core.document.MarkdownLoadResult
import com.fastmd.mobile.core.document.MarkdownSaveResult
import com.fastmd.mobile.core.document.MarkdownSourceCodec
import com.fastmd.mobile.core.document.MobileDocumentHandle
import com.fastmd.mobile.core.document.MobilePlatform
import com.fastmd.mobile.core.document.PlatformDocumentReference
import com.fastmd.mobile.core.document.RecentDocumentMetadata
import com.fastmd.mobile.core.error.FastMdErrorCode
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.File
import java.io.IOException
import java.nio.charset.CharacterCodingException
import java.nio.charset.StandardCharsets

sealed interface AndroidDocumentEntry {
    data object Launcher : AndroidDocumentEntry

    data class ViewUri(
        val uri: Uri,
        val mimeType: String?,
        val flags: Int,
    ) : AndroidDocumentEntry

    data class SharedText(
        val text: String,
    ) : AndroidDocumentEntry

    data class SharedUri(
        val uri: Uri,
        val mimeType: String?,
        val flags: Int,
    ) : AndroidDocumentEntry
}

object AndroidDocumentEntryParser {
    fun parse(intent: Intent?): AndroidDocumentEntry {
        if (intent == null) {
            return AndroidDocumentEntry.Launcher
        }

        return when (intent.action) {
            Intent.ACTION_VIEW -> {
                val uri = intent.data
                if (uri == null) {
                    AndroidDocumentEntry.Launcher
                } else {
                    AndroidDocumentEntry.ViewUri(
                        uri = uri,
                        mimeType = intent.type,
                        flags = intent.flags,
                    )
                }
            }

            Intent.ACTION_SEND -> parseSend(intent)
            else -> AndroidDocumentEntry.Launcher
        }
    }

    private fun parseSend(intent: Intent): AndroidDocumentEntry {
        val stream = intent.getUriExtra(Intent.EXTRA_STREAM)
        if (stream != null) {
            return AndroidDocumentEntry.SharedUri(
                uri = stream,
                mimeType = intent.type,
                flags = intent.flags,
            )
        }

        val sharedText = intent.getStringExtra(Intent.EXTRA_TEXT)
        return if (sharedText.isNullOrBlank()) {
            AndroidDocumentEntry.Launcher
        } else {
            AndroidDocumentEntry.SharedText(sharedText)
        }
    }

    private fun Intent.getUriExtra(name: String): Uri? =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            getParcelableExtra(name, Uri::class.java)
        } else {
            @Suppress("DEPRECATION")
            getParcelableExtra(name) as? Uri
        }
}

class AndroidMarkdownDocumentLoader(
    private val context: Context,
) {
    suspend fun load(entry: AndroidDocumentEntry): MarkdownLoadResult =
        when (entry) {
            AndroidDocumentEntry.Launcher -> MarkdownLoadResult.Failed(
                code = FastMdErrorCode.OpenMissingDocument,
                message = "No Markdown document was provided.",
                recoverable = true,
            )

            is AndroidDocumentEntry.SharedText -> loadSharedText(entry.text)
            is AndroidDocumentEntry.SharedUri -> loadUri(
                uri = entry.uri,
                mimeType = entry.mimeType,
                grantFlags = entry.flags,
                origin = DocumentOrigin.StorageAccessFramework,
                persistIfAllowed = false,
            )

            is AndroidDocumentEntry.ViewUri -> loadUri(
                uri = entry.uri,
                mimeType = entry.mimeType,
                grantFlags = entry.flags,
                origin = if (entry.uri.scheme == ContentResolver.SCHEME_FILE) {
                    DocumentOrigin.FileUriFallback
                } else {
                    DocumentOrigin.StorageAccessFramework
                },
                persistIfAllowed = true,
            )
        }

    suspend fun loadSafSelection(uri: Uri): MarkdownLoadResult =
        loadUri(
            uri = uri,
            mimeType = context.contentResolver.getType(uri),
            grantFlags = Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION,
            origin = DocumentOrigin.StorageAccessFramework,
            persistIfAllowed = true,
        )

    suspend fun loadRecentDocument(recent: RecentDocumentMetadata): MarkdownLoadResult {
        if (!recent.canAttemptReopen) {
            return MarkdownLoadResult.Failed(
                code = FastMdErrorCode.OpenUnsupportedType,
                message = "This recent document cannot be reopened from its stored handle.",
                recoverable = true,
            )
        }

        val uri = Uri.parse(recent.reference.rawReference)
        return loadUri(
            uri = uri,
            mimeType = null,
            grantFlags = 0,
            origin = if (recent.reference.kind == DocumentReferenceKind.AndroidFileUri) {
                DocumentOrigin.FileUriFallback
            } else {
                DocumentOrigin.StorageAccessFramework
            },
            persistIfAllowed = false,
            storedPermissionGrant = recent.permissionGrant,
        )
    }

    suspend fun loadRecoveryHandle(handle: MobileDocumentHandle): MarkdownLoadResult {
        if (
            handle.reference.kind != DocumentReferenceKind.AndroidContentUri &&
            handle.reference.kind != DocumentReferenceKind.AndroidFileUri
        ) {
            return MarkdownLoadResult.Failed(
                code = FastMdErrorCode.OpenUnsupportedType,
                message = "This recovery draft cannot reopen its original document handle.",
                recoverable = true,
            )
        }

        val uri = Uri.parse(handle.reference.rawReference)
        return loadUri(
            uri = uri,
            mimeType = null,
            grantFlags = 0,
            origin = if (handle.reference.kind == DocumentReferenceKind.AndroidFileUri) {
                DocumentOrigin.FileUriFallback
            } else {
                DocumentOrigin.StorageAccessFramework
            },
            persistIfAllowed = false,
            storedPermissionGrant = handle.permissionGrant,
        )
    }

    suspend fun save(
        handle: MobileDocumentHandle?,
        originalMetadata: MarkdownFileMetadata?,
        originalSource: String,
        draftSource: String,
        originalOrigin: DocumentOrigin,
    ): MarkdownSaveResult =
        withContext(Dispatchers.IO) {
            if (handle == null || originalMetadata == null || !handle.isWritable) {
                return@withContext MarkdownSaveResult.Failed(
                    code = FastMdErrorCode.SaveReadOnly,
                    message = "This document does not have a writable Android handle.",
                    recoverable = true,
                )
            }

            val preparedSave = MarkdownSourceCodec.prepareForSave(
                draftSource = draftSource,
                encoding = originalMetadata.encoding,
                lineEnding = originalMetadata.lineEnding,
            )

            try {
                val currentSource = readCurrentDocumentSource(handle)
                if (currentSource != originalSource) {
                    return@withContext MarkdownSaveResult.Failed(
                        code = FastMdErrorCode.SaveExternalMutationConflict,
                        message = "The document changed outside FastMD. Reload before saving to avoid overwriting newer content.",
                        recoverable = true,
                    )
                }

                when (handle.reference.kind) {
                    DocumentReferenceKind.AndroidContentUri -> {
                        val uri = Uri.parse(handle.reference.rawReference)
                        context.contentResolver.openOutputStream(uri, "wt")?.use { output ->
                            output.write(preparedSave.bytes)
                        } ?: return@withContext MarkdownSaveResult.Failed(
                            code = FastMdErrorCode.SaveIoFailure,
                            message = "The document provider returned no writable stream.",
                            recoverable = true,
                        )
                    }

                    DocumentReferenceKind.AndroidFileUri -> {
                        val file = Uri.parse(handle.reference.rawReference).path?.let(::File)
                            ?: return@withContext MarkdownSaveResult.Failed(
                                code = FastMdErrorCode.SaveIoFailure,
                                message = "The file URI did not contain a writable path.",
                                recoverable = true,
                            )
                        val canonicalPath = file.canonicalPath
                        val appOwned = canonicalPath.startsWith(context.filesDir.canonicalPath) ||
                            canonicalPath.startsWith(context.cacheDir.canonicalPath)
                        if (!appOwned) {
                            return@withContext MarkdownSaveResult.Failed(
                                code = FastMdErrorCode.SaveReadOnly,
                                message = "Non app-owned file:// documents are read-only.",
                                recoverable = true,
                            )
                        }
                        file.writeBytes(preparedSave.bytes)
                    }

                    else -> return@withContext MarkdownSaveResult.Failed(
                        code = FastMdErrorCode.SaveReadOnly,
                        message = "This document origin is read-only in Stage 1.",
                        recoverable = true,
                    )
                }

                val savedMetadata = originalMetadata.copy(
                    sizeBytes = preparedSave.bytes.size.toLong(),
                    encoding = originalMetadata.encoding,
                    lineEnding = preparedSave.lineEnding,
                )
                MarkdownSaveResult.Saved(
                    document = MarkdownDocument(
                        title = originalMetadata.displayName ?: handle.displayName ?: "Markdown document",
                        source = preparedSave.source,
                        origin = originalOrigin,
                        isWritable = true,
                    ),
                    metadata = savedMetadata,
                )
            } catch (exception: SecurityException) {
                MarkdownSaveResult.Failed(
                    code = FastMdErrorCode.PermissionLost,
                    message = exception.message ?: "FastMD no longer has permission to write this document.",
                    recoverable = true,
                )
            } catch (exception: CharacterCodingException) {
                MarkdownSaveResult.Failed(
                    code = FastMdErrorCode.ReadUnsupportedEncoding,
                    message = "The backing document is no longer valid UTF-8, so FastMD left the draft unsaved.",
                    recoverable = false,
                )
            } catch (exception: IOException) {
                MarkdownSaveResult.Failed(
                    code = FastMdErrorCode.SaveIoFailure,
                    message = exception.message ?: "The document could not be saved.",
                    recoverable = true,
                )
            } catch (exception: IllegalArgumentException) {
                MarkdownSaveResult.Failed(
                    code = FastMdErrorCode.SaveIoFailure,
                    message = exception.message ?: "The document reference is not writable.",
                    recoverable = true,
                )
            }
        }

    private fun readCurrentDocumentSource(handle: MobileDocumentHandle): String =
        when (handle.reference.kind) {
            DocumentReferenceKind.AndroidContentUri -> {
                val uri = Uri.parse(handle.reference.rawReference)
                val bytes = context.contentResolver.openInputStream(uri)?.use { input ->
                    input.readBytes()
                } ?: throw IOException("The document provider returned no readable stream.")
                MarkdownSourceCodec.decodeUtf8(bytes).source
            }

            DocumentReferenceKind.AndroidFileUri -> {
                val file = Uri.parse(handle.reference.rawReference).path?.let(::File)
                    ?: throw IOException("The file URI did not contain a readable path.")
                file.readBytes().let(MarkdownSourceCodec::decodeUtf8).source
            }

            else -> throw IOException("This document origin cannot be reread before save.")
        }

    private suspend fun loadSharedText(text: String): MarkdownLoadResult =
        withContext(Dispatchers.Default) {
            val displayName = "Shared text"
            val document = MarkdownDocument(
                title = displayName,
                source = text,
                origin = DocumentOrigin.SharedText,
                isWritable = false,
            )
            val handle = MobileDocumentHandle(
                id = DocumentHandleId("shared-text:${text.hashCode()}"),
                platform = MobilePlatform.Android,
                reference = PlatformDocumentReference.sharedText("shared-text"),
                displayName = displayName,
                permissionGrant = DocumentPermissionGrant.None,
            )

            MarkdownLoadResult.Loaded(
                document = document,
                handle = handle,
                metadata = MarkdownFileMetadata(
                    displayName = displayName,
                    mimeType = "text/plain",
                    sizeBytes = text.toByteArray(StandardCharsets.UTF_8).size.toLong(),
                    lastModifiedEpochMillis = null,
                    encoding = if (text.startsWith('\uFEFF')) MarkdownEncoding.Utf8Bom else MarkdownEncoding.Utf8,
                    lineEnding = MarkdownSourceCodec.detectLineEnding(text),
                ),
                writeCapability = DocumentWriteCapability.ReadOnly,
                origin = DocumentOrigin.SharedText,
            )
        }

    private suspend fun loadUri(
        uri: Uri,
        mimeType: String?,
        grantFlags: Int,
        origin: DocumentOrigin,
        persistIfAllowed: Boolean,
        storedPermissionGrant: DocumentPermissionGrant? = null,
    ): MarkdownLoadResult =
        withContext(Dispatchers.IO) {
            try {
                if (uri.scheme != ContentResolver.SCHEME_CONTENT && uri.scheme != ContentResolver.SCHEME_FILE) {
                    return@withContext MarkdownLoadResult.Failed(
                        code = FastMdErrorCode.OpenUnsupportedType,
                        message = "Only content:// and file:// Markdown document references are supported.",
                        recoverable = true,
                    )
                }
                val normalized = normalizeUri(
                    uri = uri,
                    grantFlags = grantFlags,
                    persistIfAllowed = persistIfAllowed,
                    storedPermissionGrant = storedPermissionGrant,
                )
                val metadata = queryMetadata(uri, mimeType)
                val bytes = context.contentResolver.openInputStream(uri)?.use { input ->
                    input.readBytes()
                } ?: return@withContext MarkdownLoadResult.Failed(
                    code = FastMdErrorCode.ReadIoFailure,
                    message = "The document provider returned no readable stream.",
                    recoverable = true,
                )
                val decoded = MarkdownSourceCodec.decodeUtf8(bytes)
                val displayName = metadata.displayName ?: uri.lastPathSegment ?: "Markdown document"
                val writeCapability = normalized.writeCapability
                val document = MarkdownDocument(
                    title = displayName,
                    source = decoded.source,
                    origin = origin,
                    isWritable = writeCapability == DocumentWriteCapability.Writable,
                )

                MarkdownLoadResult.Loaded(
                    document = document,
                    handle = MobileDocumentHandle(
                        id = DocumentHandleId("${uri.scheme ?: "uri"}:${uri.hashCode()}"),
                        platform = MobilePlatform.Android,
                        reference = normalized.reference,
                        displayName = displayName,
                        permissionGrant = normalized.permissionGrant,
                        lastKnownSizeBytes = metadata.sizeBytes,
                        lastKnownModifiedEpochMillis = metadata.lastModifiedEpochMillis,
                    ),
                    metadata = metadata.copy(
                        displayName = displayName,
                        encoding = decoded.encoding,
                        lineEnding = MarkdownSourceCodec.detectLineEnding(decoded.source),
                    ),
                    writeCapability = writeCapability,
                    origin = origin,
                )
            } catch (exception: SecurityException) {
                MarkdownLoadResult.Failed(
                    code = FastMdErrorCode.PermissionLost,
                    message = exception.message ?: "FastMD no longer has permission to read this document.",
                    recoverable = true,
                )
            } catch (exception: CharacterCodingException) {
                MarkdownLoadResult.Failed(
                    code = FastMdErrorCode.ReadUnsupportedEncoding,
                    message = "Only UTF-8 Markdown documents are supported in Stage 1.",
                    recoverable = false,
                )
            } catch (exception: IOException) {
                MarkdownLoadResult.Failed(
                    code = FastMdErrorCode.ReadIoFailure,
                    message = exception.message ?: "The document could not be read.",
                    recoverable = true,
                )
            } catch (exception: IllegalArgumentException) {
                MarkdownLoadResult.Failed(
                    code = FastMdErrorCode.OpenUnsupportedType,
                    message = exception.message ?: "The document reference is not supported.",
                    recoverable = true,
                )
            }
        }

    private fun normalizeUri(
        uri: Uri,
        grantFlags: Int,
        persistIfAllowed: Boolean,
        storedPermissionGrant: DocumentPermissionGrant?,
    ): NormalizedAndroidUri {
        val scheme = uri.scheme
        if (scheme == ContentResolver.SCHEME_FILE) {
            val appOwned = uri.path
                ?.let(::File)
                ?.canonicalPath
                ?.let { canonicalPath ->
                    canonicalPath.startsWith(context.filesDir.canonicalPath) ||
                        canonicalPath.startsWith(context.cacheDir.canonicalPath)
                }
                ?: false

            return NormalizedAndroidUri(
                reference = PlatformDocumentReference.androidFileUri(uri.toString()),
                permissionGrant = if (appOwned) {
                    DocumentPermissionGrant.TransientReadWrite
                } else {
                    DocumentPermissionGrant.TransientRead
                },
                writeCapability = if (appOwned) DocumentWriteCapability.Writable else DocumentWriteCapability.ReadOnly,
            )
        }

        val storedPersistedRead = storedPermissionGrant == DocumentPermissionGrant.PersistedRead ||
            storedPermissionGrant == DocumentPermissionGrant.PersistedReadWrite
        val storedPersistedWrite = storedPermissionGrant == DocumentPermissionGrant.PersistedReadWrite
        val readGranted = grantFlags.hasFlag(Intent.FLAG_GRANT_READ_URI_PERMISSION) || storedPersistedRead
        val writeGranted = grantFlags.hasFlag(Intent.FLAG_GRANT_WRITE_URI_PERMISSION) || storedPersistedWrite
        val persisted = storedPersistedRead || (
            persistIfAllowed &&
                grantFlags.hasFlag(Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION) &&
                tryPersistableUriPermission(uri, readGranted, writeGranted)
            )
        val permissionGrant = when {
            persisted && writeGranted -> DocumentPermissionGrant.PersistedReadWrite
            persisted -> DocumentPermissionGrant.PersistedRead
            writeGranted -> DocumentPermissionGrant.TransientReadWrite
            readGranted -> DocumentPermissionGrant.TransientRead
            else -> DocumentPermissionGrant.None
        }

        return NormalizedAndroidUri(
            reference = PlatformDocumentReference.androidContentUri(
                uriString = uri.toString(),
                authority = uri.authority,
            ),
            permissionGrant = permissionGrant,
            writeCapability = if (writeGranted) DocumentWriteCapability.Writable else DocumentWriteCapability.ReadOnly,
        )
    }

    private fun tryPersistableUriPermission(
        uri: Uri,
        readGranted: Boolean,
        writeGranted: Boolean,
    ): Boolean {
        var persistFlags = 0
        if (readGranted) {
            persistFlags = persistFlags or Intent.FLAG_GRANT_READ_URI_PERMISSION
        }
        if (writeGranted) {
            persistFlags = persistFlags or Intent.FLAG_GRANT_WRITE_URI_PERMISSION
        }
        if (persistFlags == 0) {
            return false
        }

        return try {
            context.contentResolver.takePersistableUriPermission(uri, persistFlags)
            true
        } catch (_: SecurityException) {
            false
        } catch (_: IllegalArgumentException) {
            false
        }
    }

    private fun queryMetadata(uri: Uri, explicitMimeType: String?): MarkdownFileMetadata {
        val resolver = context.contentResolver
        var displayName: String? = null
        var sizeBytes: Long? = null

        resolver.query(uri, METADATA_COLUMNS, null, null, null)?.use { cursor ->
            displayName = cursor.stringValue(OpenableColumns.DISPLAY_NAME)
            sizeBytes = cursor.longValue(OpenableColumns.SIZE)
        }

        return MarkdownFileMetadata(
            displayName = displayName,
            mimeType = explicitMimeType ?: resolver.getType(uri),
            sizeBytes = sizeBytes,
            lastModifiedEpochMillis = null,
            encoding = MarkdownEncoding.Utf8,
            lineEnding = MarkdownLineEnding.Unknown,
        )
    }

    private data class NormalizedAndroidUri(
        val reference: PlatformDocumentReference,
        val permissionGrant: DocumentPermissionGrant,
        val writeCapability: DocumentWriteCapability,
    )

    private companion object {
        val METADATA_COLUMNS = arrayOf(OpenableColumns.DISPLAY_NAME, OpenableColumns.SIZE)
    }
}

private fun Int.hasFlag(flag: Int): Boolean = this and flag == flag

private fun Cursor.stringValue(columnName: String): String? {
    if (!moveToFirst()) {
        return null
    }
    val index = getColumnIndex(columnName)
    return if (index >= 0 && !isNull(index)) getString(index) else null
}

private fun Cursor.longValue(columnName: String): Long? {
    if (!moveToFirst()) {
        return null
    }
    val index = getColumnIndex(columnName)
    return if (index >= 0 && !isNull(index)) getLong(index).takeIf { it >= 0L } else null
}
