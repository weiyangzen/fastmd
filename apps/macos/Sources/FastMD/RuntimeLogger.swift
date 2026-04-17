import Foundation

enum RuntimeLogger {
    private static let queue = DispatchQueue(label: "FastMD.RuntimeLogger")
    nonisolated(unsafe) private static let formatter = ISO8601DateFormatter()
    private static let verboseDiagnosticsEnabled = ProcessInfo.processInfo.environment["FASTMD_VERBOSE_LOGS"] == "1"
    private static let perfMetricsEnabled = ProcessInfo.processInfo.environment["FASTMD_PERF_LOGS"] == "1"
    nonisolated(unsafe) private static var fileHandle: FileHandle?

    static let logFileURL: URL = {
        let base = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Logs/FastMD", isDirectory: true)
        return base.appendingPathComponent("runtime.log", isDirectory: false)
    }()

    static func markSession(_ title: String) {
        log("===== \(title) =====")
    }

    static func log(_ message: String) {
        if isPerfMetric(message), !perfMetricsEnabled {
            return
        }
        if isVerboseDiagnostic(message), !verboseDiagnosticsEnabled {
            return
        }

        let timestamp = formatter.string(from: Date())
        let line = "[\(timestamp)] \(message)\n"

        queue.async {
            let directory = logFileURL.deletingLastPathComponent()
            try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

            if !FileManager.default.fileExists(atPath: logFileURL.path) {
                try? Data().write(to: logFileURL, options: .atomic)
            }

            if fileHandle == nil {
                fileHandle = try? FileHandle(forWritingTo: logFileURL)
            }

            if let handle = fileHandle {
                _ = try? handle.seekToEnd()
                try? handle.write(contentsOf: Data(line.utf8))
            }
        }

        print("[FastMD] \(message)")
    }

    private static func isPerfMetric(_ message: String) -> Bool {
        message.hasPrefix("Preview perf metric [")
    }

    private static func isVerboseDiagnostic(_ message: String) -> Bool {
        message.hasPrefix("Resolver AX lineage:")
            || message.hasPrefix("Resolver row subtree:")
            || message.hasPrefix("Resolver non-list anchor subtree:")
            || message.hasPrefix("Resolver ancestor-context subtree:")
            || message.hasPrefix("Resolver nearest-row subtree:")
    }
}
