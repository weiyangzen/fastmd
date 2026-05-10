package com.fastmd.mobile.core.diagnostics

import com.fastmd.mobile.core.document.DocumentOrigin
import com.fastmd.mobile.core.document.MarkdownFileMetadata
import com.fastmd.mobile.core.document.MobilePlatform
import com.fastmd.mobile.core.error.FastMdErrorCategory
import com.fastmd.mobile.core.performance.AndroidPerformanceProfile

enum class DiagnosticsOperationStatus {
    NotRun,
    Pass,
    Failed,
    Blocked,
}

enum class DiagnosticsFileSizeBucket(
    val label: String,
) {
    Unknown("unknown"),
    Empty("0 B"),
    Tiny("1 B-100 KB"),
    Small("100 KB-1 MB"),
    Medium("1 MB-5 MB"),
    Large("5 MB-20 MB"),
    Huge("20 MB+");

    companion object {
        fun fromBytes(sizeBytes: Long?): DiagnosticsFileSizeBucket =
            when {
                sizeBytes == null -> Unknown
                sizeBytes == 0L -> Empty
                sizeBytes <= 100L * 1024L -> Tiny
                sizeBytes <= 1L * 1024L * 1024L -> Small
                sizeBytes <= 5L * 1024L * 1024L -> Medium
                sizeBytes <= 20L * 1024L * 1024L -> Large
                else -> Huge
            }
    }
}

data class DiagnosticsOperation(
    val status: DiagnosticsOperationStatus = DiagnosticsOperationStatus.NotRun,
    val durationMillis: Long? = null,
    val itemCount: Int? = null,
) {
    init {
        require(durationMillis == null || durationMillis >= 0L) { "Duration cannot be negative." }
        require(itemCount == null || itemCount >= 0) { "Item count cannot be negative." }
    }

    fun toRedactedLine(name: String): String {
        val parts = mutableListOf("$name=${status.name}")
        durationMillis?.let { parts += "durationMs=$it" }
        itemCount?.let { parts += "count=$it" }
        return parts.joinToString(separator = " ")
    }
}

data class LocalDiagnosticsReport(
    val platform: MobilePlatform,
    val deviceClass: AndroidPerformanceProfile,
    val rendererProfile: String,
    val documentPresent: Boolean,
    val documentOrigin: DocumentOrigin?,
    val documentWritable: Boolean?,
    val fileSizeBucket: DiagnosticsFileSizeBucket,
    val parse: DiagnosticsOperation = DiagnosticsOperation(),
    val render: DiagnosticsOperation = DiagnosticsOperation(),
    val search: DiagnosticsOperation = DiagnosticsOperation(),
    val save: DiagnosticsOperation = DiagnosticsOperation(),
    val lastErrorCategory: FastMdErrorCategory? = null,
) {
    init {
        require(rendererProfile.isNotBlank()) { "Renderer profile cannot be blank." }
        require(!rendererProfile.contains("://")) { "Renderer profile must not contain URIs." }
        require(!rendererProfile.contains('/')) { "Renderer profile must not contain paths." }
    }

    fun withDocument(
        metadata: MarkdownFileMetadata,
        origin: DocumentOrigin,
        writable: Boolean,
    ): LocalDiagnosticsReport =
        copy(
            documentPresent = true,
            documentOrigin = origin,
            documentWritable = writable,
            fileSizeBucket = DiagnosticsFileSizeBucket.fromBytes(metadata.sizeBytes),
            lastErrorCategory = null,
        )

    fun withoutDocument(errorCategory: FastMdErrorCategory? = null): LocalDiagnosticsReport =
        copy(
            documentPresent = false,
            documentOrigin = null,
            documentWritable = null,
            fileSizeBucket = DiagnosticsFileSizeBucket.Unknown,
            lastErrorCategory = errorCategory,
        )

    fun toRedactedText(): String =
        DiagnosticsRedactionPolicy.requireRedacted(
            listOf(
                "platform=${platform.name}",
                "deviceClass=${deviceClass.name}",
                "rendererProfile=$rendererProfile",
                "documentPresent=$documentPresent",
                "documentOrigin=${documentOrigin?.name ?: "None"}",
                "documentWritable=${documentWritable?.toString() ?: "unknown"}",
                "fileSizeBucket=${fileSizeBucket.label}",
                parse.toRedactedLine("parse"),
                render.toRedactedLine("render"),
                search.toRedactedLine("search"),
                save.toRedactedLine("save"),
                "lastErrorCategory=${lastErrorCategory?.name ?: "None"}",
            ).joinToString(separator = "\n"),
        )

    companion object {
        fun initial(
            platform: MobilePlatform,
            deviceClass: AndroidPerformanceProfile,
            rendererProfile: String = "NativeCompose",
        ): LocalDiagnosticsReport =
            LocalDiagnosticsReport(
                platform = platform,
                deviceClass = deviceClass,
                rendererProfile = rendererProfile,
                documentPresent = false,
                documentOrigin = null,
                documentWritable = null,
                fileSizeBucket = DiagnosticsFileSizeBucket.Unknown,
            )
    }
}
