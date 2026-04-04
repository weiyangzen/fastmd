import Foundation

private final class VendorAssetBundleMarker {}

enum VendorAssetLoader {
    private static let urlsByName: [String: URL] = buildURLIndex()

    static func text(named fileName: String) -> String {
        guard let url = url(named: fileName),
              let data = try? Data(contentsOf: url),
              let text = String(data: data, encoding: .utf8)
        else {
            RuntimeLogger.log("Failed to load vendor text asset \(fileName)")
            return ""
        }
        return text
    }

    static func data(named fileName: String) -> Data? {
        guard let url = url(named: fileName) else {
            RuntimeLogger.log("Failed to locate vendor data asset \(fileName)")
            return nil
        }

        guard let data = try? Data(contentsOf: url) else {
            RuntimeLogger.log("Failed to read vendor data asset \(fileName)")
            return nil
        }

        return data
    }

    private static func url(named fileName: String) -> URL? {
        urlsByName[fileName]
    }

    private static func buildURLIndex() -> [String: URL] {
        var urlsByName: [String: URL] = [:]

        for bundle in candidateBundles() {
            guard let resourceURL = bundle.resourceURL else {
                continue
            }

            let enumerator = FileManager.default.enumerator(
                at: resourceURL,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: [.skipsHiddenFiles]
            )

            while let fileURL = enumerator?.nextObject() as? URL {
                guard let values = try? fileURL.resourceValues(forKeys: [.isRegularFileKey]),
                      values.isRegularFile == true
                else {
                    continue
                }
                urlsByName[fileURL.lastPathComponent] = fileURL
            }
        }

        return urlsByName
    }

    private static func candidateBundles() -> [Bundle] {
        var bundles: [Bundle] = []

        #if SWIFT_PACKAGE
        bundles.append(Bundle.module)
        #endif

        bundles.append(Bundle.main)
        bundles.append(Bundle(for: VendorAssetBundleMarker.self))
        bundles.append(contentsOf: Bundle.allBundles)
        bundles.append(contentsOf: Bundle.allFrameworks)

        var seen = Set<String>()
        return bundles.filter { bundle in
            let path = bundle.bundleURL.path
            return seen.insert(path).inserted
        }
    }

    static func inlineKaTeXCSS() -> String {
        var css = text(named: "katex.min.css")
        guard !css.isEmpty else {
            return css
        }

        let pattern = #"url\((?:\.\./)?fonts/([^)]+)\)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return css
        }

        let matches = regex.matches(in: css, range: NSRange(css.startIndex..<css.endIndex, in: css)).reversed()
        for match in matches {
            guard let fullRange = Range(match.range(at: 0), in: css),
                  let fileRange = Range(match.range(at: 1), in: css)
            else {
                continue
            }

            let fileName = String(css[fileRange])
            guard let data = data(named: fileName) else {
                continue
            }

            let mimeType = mimeType(for: fileName)
            let encoded = data.base64EncodedString()
            css.replaceSubrange(fullRange, with: "url(data:\(mimeType);base64,\(encoded))")
        }

        return css
    }

    private static func mimeType(for fileName: String) -> String {
        if fileName.hasSuffix(".woff2") { return "font/woff2" }
        if fileName.hasSuffix(".woff") { return "font/woff" }
        if fileName.hasSuffix(".ttf") { return "font/ttf" }
        return "application/octet-stream"
    }
}
