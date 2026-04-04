import Foundation

enum RuntimeLogger {
    private static let queue = DispatchQueue(label: "FastMD.RuntimeLogger")

    static let logFileURL: URL = {
        let base = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Logs/FastMD", isDirectory: true)
        return base.appendingPathComponent("runtime.log", isDirectory: false)
    }()

    static func markSession(_ title: String) {
        log("===== \(title) =====")
    }

    static func log(_ message: String) {
        let formatter = ISO8601DateFormatter()
        let timestamp = formatter.string(from: Date())
        let line = "[\(timestamp)] \(message)\n"

        queue.async {
            let directory = logFileURL.deletingLastPathComponent()
            try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

            if !FileManager.default.fileExists(atPath: logFileURL.path) {
                try? Data().write(to: logFileURL, options: .atomic)
            }

            if let handle = try? FileHandle(forWritingTo: logFileURL) {
                defer { try? handle.close() }
                _ = try? handle.seekToEnd()
                try? handle.write(contentsOf: Data(line.utf8))
            }
        }

        print("[FastMD] \(message)")
    }
}
