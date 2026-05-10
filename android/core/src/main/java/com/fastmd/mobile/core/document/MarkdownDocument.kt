package com.fastmd.mobile.core.document

data class MarkdownDocument(
    val title: String,
    val source: String,
    val origin: DocumentOrigin,
    val isWritable: Boolean,
) {
    val lineCount: Int
        get() = source.lineSequence().count().coerceAtLeast(1)
}

enum class DocumentOrigin {
    AppCreated,
    StorageAccessFramework,
    SharedText,
    FileUriFallback,
}
