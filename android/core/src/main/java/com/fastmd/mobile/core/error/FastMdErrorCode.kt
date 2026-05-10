package com.fastmd.mobile.core.error

enum class FastMdErrorCategory {
    Open,
    Read,
    Parse,
    Render,
    Search,
    Edit,
    Save,
    Link,
    Permission,
    Security,
}

enum class FastMdErrorCode(
    val category: FastMdErrorCategory,
) {
    OpenUnsupportedType(FastMdErrorCategory.Open),
    OpenMissingDocument(FastMdErrorCategory.Open),
    OpenProviderRejected(FastMdErrorCategory.Open),

    ReadIoFailure(FastMdErrorCategory.Read),
    ReadUnsupportedEncoding(FastMdErrorCategory.Read),
    ReadTooLarge(FastMdErrorCategory.Read),

    ParseFailed(FastMdErrorCategory.Parse),
    ParseSourceRangeUnavailable(FastMdErrorCategory.Parse),

    RenderFailed(FastMdErrorCategory.Render),
    RenderUnsupportedRichBlock(FastMdErrorCategory.Render),

    SearchFailed(FastMdErrorCategory.Search),
    SearchQueryTooLarge(FastMdErrorCategory.Search),

    EditDirtyBufferConflict(FastMdErrorCategory.Edit),
    EditBlockRangeStale(FastMdErrorCategory.Edit),

    SaveReadOnly(FastMdErrorCategory.Save),
    SaveIoFailure(FastMdErrorCategory.Save),
    SaveExternalMutationConflict(FastMdErrorCategory.Save),

    LinkRequiresConfirmation(FastMdErrorCategory.Link),
    LinkBlockedScheme(FastMdErrorCategory.Link),

    PermissionLost(FastMdErrorCategory.Permission),
    PermissionPersistFailed(FastMdErrorCategory.Permission),

    SecurityBlockedContent(FastMdErrorCategory.Security),
    SecurityNetworkRendererBlocked(FastMdErrorCategory.Security),
}
