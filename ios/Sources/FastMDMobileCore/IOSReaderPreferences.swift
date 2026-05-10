import Foundation

public enum IOSReaderThemeScheme: String, CaseIterable, Equatable, Sendable {
    case light
    case dark
}

public struct IOSReaderPreferences: Equatable, Sendable {
    public let fontTier: MobileFontTier
    public let themeScheme: IOSReaderThemeScheme

    public init(
        fontTier: MobileFontTier = .default,
        themeScheme: IOSReaderThemeScheme = .light
    ) {
        self.fontTier = fontTier
        self.themeScheme = themeScheme
    }
}

public struct IOSReaderPreferencesStore: Equatable, Sendable {
    public let fontTierKey: String
    public let themeSchemeKey: String

    public init(
        fontTierKey: String = "fastmd.ios.reader.fontTier",
        themeSchemeKey: String = "fastmd.ios.reader.themeScheme"
    ) {
        self.fontTierKey = fontTierKey
        self.themeSchemeKey = themeSchemeKey
    }

    public func load(from defaults: UserDefaults = .standard) -> IOSReaderPreferences {
        let fontTier = defaults.string(forKey: fontTierKey)
            .flatMap(MobileFontTier.init(rawValue:)) ?? .default
        let themeScheme = defaults.string(forKey: themeSchemeKey)
            .flatMap(IOSReaderThemeScheme.init(rawValue:)) ?? .light

        return IOSReaderPreferences(fontTier: fontTier, themeScheme: themeScheme)
    }

    public func save(_ preferences: IOSReaderPreferences, to defaults: UserDefaults = .standard) {
        defaults.set(preferences.fontTier.rawValue, forKey: fontTierKey)
        defaults.set(preferences.themeScheme.rawValue, forKey: themeSchemeKey)
    }

    public func saveFontTier(_ fontTier: MobileFontTier, to defaults: UserDefaults = .standard) {
        defaults.set(fontTier.rawValue, forKey: fontTierKey)
    }

    public func saveThemeScheme(_ themeScheme: IOSReaderThemeScheme, to defaults: UserDefaults = .standard) {
        defaults.set(themeScheme.rawValue, forKey: themeSchemeKey)
    }
}

public enum NativeMarkdownTextSurface: String, CaseIterable, Equatable, Sendable {
    case heading1
    case heading2
    case heading3
    case heading4
    case heading5
    case heading6
    case paragraph
    case blockquote
    case listItem
    case tableCell
    case code
    case richFallback
    case imageFallback
    case footnote
    case htmlFallback
}

public struct NativeMarkdownTextMetrics: Equatable, Sendable {
    public let pointSize: Double
    public let lineHeightMultiple: Double
    public let usesMonospace: Bool
    public let isHeader: Bool
    public let usesDynamicTypeTextStyle: Bool
    public let dynamicTypeTextStyle: String

    public init(
        pointSize: Double,
        lineHeightMultiple: Double,
        usesMonospace: Bool = false,
        isHeader: Bool = false,
        usesDynamicTypeTextStyle: Bool = true,
        dynamicTypeTextStyle: String = "body"
    ) {
        self.pointSize = pointSize
        self.lineHeightMultiple = lineHeightMultiple
        self.usesMonospace = usesMonospace
        self.isHeader = isHeader
        self.usesDynamicTypeTextStyle = usesDynamicTypeTextStyle
        self.dynamicTypeTextStyle = dynamicTypeTextStyle
    }
}

public struct NativeMarkdownTypography: Equatable, Sendable {
    public let fontTier: MobileFontTier

    public init(fontTier: MobileFontTier) {
        self.fontTier = fontTier
    }

    public func metrics(for surface: NativeMarkdownTextSurface) -> NativeMarkdownTextMetrics {
        switch surface {
        case .heading1:
            return headerMetrics(scale: 1.80)
        case .heading2:
            return headerMetrics(scale: 1.55)
        case .heading3:
            return headerMetrics(scale: 1.35)
        case .heading4:
            return headerMetrics(scale: 1.20)
        case .heading5:
            return headerMetrics(scale: 1.10)
        case .heading6:
            return headerMetrics(scale: 1.00)
        case .code:
            return NativeMarkdownTextMetrics(
                pointSize: fontTier.monospacePointSize,
                lineHeightMultiple: fontTier.lineHeightMultiple,
                usesMonospace: true,
                dynamicTypeTextStyle: "body"
            )
        case .paragraph,
             .blockquote,
             .listItem,
             .tableCell,
             .richFallback,
             .imageFallback,
             .footnote,
             .htmlFallback:
            return NativeMarkdownTextMetrics(
                pointSize: fontTier.bodyPointSize,
                lineHeightMultiple: fontTier.lineHeightMultiple,
                dynamicTypeTextStyle: "body"
            )
        }
    }

    public func surface(for block: NativeMarkdownBlockPresentation) -> NativeMarkdownTextSurface? {
        switch block.role {
        case .heading:
            switch block.headingLevel ?? 1 {
            case 1:
                return .heading1
            case 2:
                return .heading2
            case 3:
                return .heading3
            case 4:
                return .heading4
            case 5:
                return .heading5
            default:
                return .heading6
            }
        case .paragraph:
            return .paragraph
        case .blockquote:
            return .blockquote
        case .unorderedList, .orderedList, .taskList:
            return .listItem
        case .table:
            return .tableCell
        case .codeFence:
            return .code
        case .richFallback:
            return .richFallback
        case .image:
            return .imageFallback
        case .footnote:
            return .footnote
        case .htmlFallback:
            return .htmlFallback
        case .horizontalRule:
            return nil
        }
    }

    private func headerMetrics(scale: Double) -> NativeMarkdownTextMetrics {
        NativeMarkdownTextMetrics(
            pointSize: fontTier.bodyPointSize * scale,
            lineHeightMultiple: fontTier.lineHeightMultiple,
            isHeader: true,
            dynamicTypeTextStyle: "headline"
        )
    }
}

public struct IOSReaderSemanticColorTokens: Equatable, Sendable {
    public let background: String
    public let primaryText: String
    public let secondaryText: String
    public let accent: String
    public let separator: String
    public let blockSurface: String
    public let quoteBar: String
    public let warning: String

    public init(
        background: String,
        primaryText: String,
        secondaryText: String,
        accent: String,
        separator: String,
        blockSurface: String,
        quoteBar: String,
        warning: String
    ) {
        self.background = background
        self.primaryText = primaryText
        self.secondaryText = secondaryText
        self.accent = accent
        self.separator = separator
        self.blockSurface = blockSurface
        self.quoteBar = quoteBar
        self.warning = warning
    }

    public static func tokens(for scheme: IOSReaderThemeScheme) -> IOSReaderSemanticColorTokens {
        switch scheme {
        case .light:
            return IOSReaderSemanticColorTokens(
                background: "reader.background.light",
                primaryText: "reader.text.primary.light",
                secondaryText: "reader.text.secondary.light",
                accent: "reader.accent.light",
                separator: "reader.separator.light",
                blockSurface: "reader.blockSurface.light",
                quoteBar: "reader.quoteBar.light",
                warning: "reader.warning.light"
            )
        case .dark:
            return IOSReaderSemanticColorTokens(
                background: "reader.background.dark",
                primaryText: "reader.text.primary.dark",
                secondaryText: "reader.text.secondary.dark",
                accent: "reader.accent.dark",
                separator: "reader.separator.dark",
                blockSurface: "reader.blockSurface.dark",
                quoteBar: "reader.quoteBar.dark",
                warning: "reader.warning.dark"
            )
        }
    }
}
