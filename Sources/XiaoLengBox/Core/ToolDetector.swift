import Foundation

/// Auto-detects installed tools by checking common installation paths on macOS.
/// Supports both Apple Silicon (/opt/homebrew) and Intel (/usr/local) architectures.
struct ToolDetector {

    /// Represents a preset tool definition with known installation paths.
    struct PresetTool {
        let id: String
        let name: String
        let type: ToolType
        let searchPaths: [String]
        let installHint: String

        enum ToolType {
            case app
            case cli
            case either
        }
    }

    // MARK: - Architecture Detection

    static var isAppleSilicon: Bool {
        #if arch(arm64)
        return true
        #else
        return false
        #endif
    }

    static var brewPrefix: String {
        isAppleSilicon ? "/opt/homebrew" : "/usr/local"
    }

    // MARK: - Common Path Helpers

    /// Returns the npm global bin directory if available.
    static var npmGlobalBin: String? {
        // Check common npm global locations
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let candidates = [
            "\(home)/.npm-global/bin",
            "/usr/local/bin",
            "\(brewPrefix)/bin"
        ]
        for path in candidates {
            if FileManager.default.fileExists(atPath: path) {
                return path
            }
        }
        return nil
    }

    /// Returns the Go bin directory if available.
    static var goBin: String {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        return "\(home)/go/bin"
    }

    /// Returns the pdtm (ProjectDiscovery Tool Manager) bin directory.
    static var pdtmBin: String {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        return "\(home)/.pdtm/go/bin"
    }

    // MARK: - Detection

    /// Attempts to find a tool at any of its known paths.
    /// Returns the resolved path if found, nil otherwise.
    static func detect(_ tool: PresetTool) -> String? {
        let fm = FileManager.default
        let home = fm.homeDirectoryForCurrentUser.path

        for rawPath in tool.searchPaths {
            let path = rawPath
                .replacingOccurrences(of: "~", with: home)
                .replacingOccurrences(of: "<BREW>", with: brewPrefix)
                .replacingOccurrences(of: "<GO>", with: goBin)
                .replacingOccurrences(of: "<PDTM>", with: pdtmBin)
                .replacingOccurrences(of: "<NPM>", with: npmGlobalBin ?? "")

            if path.isEmpty { continue }
            if fm.fileExists(atPath: path) {
                return path
            }
        }

        // Fallback: check if the tool is in PATH using `which`
        if tool.type != .app {
            if let whichPath = whichTool(tool.id) {
                return whichPath
            }
        }

        return nil
    }

    /// Uses `which` to find a tool in the system PATH.
    static func whichTool(_ name: String) -> String? {
        let process = Process()
        process.launchPath = "/usr/bin/which"
        process.arguments = [name]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()
        process.launch()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else { return nil }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let path = String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return path.isEmpty ? nil : path
    }

    /// Detects all preset tools and returns a list of (tool, detectedPath?) pairs.
    static func detectAll(_ tools: [PresetTool]) -> [(PresetTool, String?)] {
        return tools.map { tool in
            let path = detect(tool)
            return (tool, path)
        }
    }
}
