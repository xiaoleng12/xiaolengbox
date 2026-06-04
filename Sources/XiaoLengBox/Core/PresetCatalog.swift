import Foundation

/// Provides built-in tool categories with preset tools for common developer and security tools.
/// On first launch, these presets are auto-populated into the user's toolbox.
/// Also supports special category types: sticky notes, PDF viewer, and Markdown viewer.
struct PresetCatalog {

    // MARK: - Preset Category Definition

    struct PresetCategory {
        let name: String
        let icon: String          // SF Symbol name
        let type: String          // "normal", "sticky", "pdf", "md"
        let tools: [ToolDetector.PresetTool]
        let metadataFile: String? // bundled demo filename for pdf/md types (e.g. "demo.pdf")

        init(name: String, icon: String, type: String = "normal",
             tools: [ToolDetector.PresetTool] = [], metadataFile: String? = nil) {
            self.name = name
            self.icon = icon
            self.type = type
            self.tools = tools
            self.metadataFile = metadataFile
        }
    }

    // MARK: - AI应用

    static let aiAppTools: [ToolDetector.PresetTool] = [
        ToolDetector.PresetTool(
            id: "claude",
            name: "Claude Code",
            type: .either,
            searchPaths: [
                "/Applications/Claude Code.app",
                "/Applications/Claude.app",
                "~/Applications/Claude Code.app",
                "~/.local/bin/claude",
                "<NPM>/claude",
                "<BREW>/bin/claude"
            ],
            installHint: "Download from claude.ai or npm install -g @anthropic-ai/claude-code"
        ),
        ToolDetector.PresetTool(
            id: "cc-switch",
            name: "CC Switch",
            type: .app,
            searchPaths: [
                "/Applications/CC Switch.app",
                "~/Applications/CC Switch.app"
            ],
            installHint: "Download from github.com/farion1231/cc-switch"
        ),
        ToolDetector.PresetTool(
            id: "codex",
            name: "OpenAI Codex",
            type: .either,
            searchPaths: [
                "/Applications/Codex.app",
                "~/Applications/Codex.app",
                "<NPM>/codex",
                "<BREW>/bin/codex"
            ],
            installHint: "Download from openai.com or npm install -g @openai/codex"
        ),
        ToolDetector.PresetTool(
            id: "qoderwork",
            name: "QoderWork",
            type: .app,
            searchPaths: [
                "/Applications/QoderWork CN.app",
                "/Applications/QoderWork.app",
                "/Applications/Qoder.app",
                "~/Applications/QoderWork CN.app",
                "~/Applications/QoderWork.app"
            ],
            installHint: "Download from qoder.com"
        ),
        ToolDetector.PresetTool(
            id: "vscode",
            name: "VS Code",
            type: .app,
            searchPaths: ["/Applications/Visual Studio Code.app"],
            installHint: "brew install --cask visual-studio-code"
        ),
        ToolDetector.PresetTool(
            id: "trae",
            name: "Trae",
            type: .app,
            searchPaths: [
                "/Applications/Trae.app",
                "~/Applications/Trae.app"
            ],
            installHint: "Download from trae.ai"
        ),
        ToolDetector.PresetTool(
            id: "cursor",
            name: "Cursor",
            type: .app,
            searchPaths: ["/Applications/Cursor.app"],
            installHint: "brew install --cask cursor"
        ),
        ToolDetector.PresetTool(
            id: "ollama",
            name: "Ollama",
            type: .either,
            searchPaths: [
                "/Applications/Ollama.app",
                "<BREW>/bin/ollama"
            ],
            installHint: "brew install ollama"
        ),
        ToolDetector.PresetTool(
            id: "lm-studio",
            name: "LM Studio",
            type: .app,
            searchPaths: ["/Applications/LM Studio.app"],
            installHint: "brew install --cask lm-studio"
        ),
        ToolDetector.PresetTool(
            id: "demo-folder",
            name: "桌面文件夹",
            type: .either,
            searchPaths: ["~/Desktop"],
            installHint: "系统自带文件夹"
        ),
        ToolDetector.PresetTool(
            id: "demo-script",
            name: "示例脚本",
            type: .either,
            searchPaths: [],
            installHint: "工具箱自带演示脚本"
        ),
        ToolDetector.PresetTool(
            id: "demo-md",
            name: "示例文档",
            type: .either,
            searchPaths: [],
            installHint: "工具箱自带演示文档"
        ),
    ]

    // MARK: - 网络安全工具

    static let netsecTools: [ToolDetector.PresetTool] = [
        ToolDetector.PresetTool(
            id: "sqlmap",
            name: "sqlmap",
            type: .cli,
            searchPaths: [
                "<BREW>/bin/sqlmap",
                "/usr/local/bin/sqlmap",
                "~/tools/sqlmap/sqlmap.py"
            ],
            installHint: "brew install sqlmap"
        ),
        ToolDetector.PresetTool(
            id: "nmap",
            name: "nmap",
            type: .cli,
            searchPaths: [
                "<BREW>/bin/nmap",
                "/usr/local/bin/nmap"
            ],
            installHint: "brew install nmap"
        ),
        ToolDetector.PresetTool(
            id: "tscanplus",
            name: "TScanPlus",
            type: .either,
            searchPaths: [
                "/Applications/TScanPlus.app",
                "/usr/local/bin/TScanPlus",
                "~/tools/TScanPlus"
            ],
            installHint: "Download from github.com/TideSec/TscanPlus"
        ),
        ToolDetector.PresetTool(
            id: "dirsearch",
            name: "dirsearch",
            type: .cli,
            searchPaths: [
                "~/tools/dirsearch/dirsearch.py",
                "/opt/dirsearch/dirsearch.py"
            ],
            installHint: "git clone https://github.com/maurosoria/dirsearch.git ~/tools/dirsearch"
        ),
        ToolDetector.PresetTool(
            id: "nuclei",
            name: "nuclei",
            type: .cli,
            searchPaths: [
                "<GO>/nuclei",
                "<BREW>/bin/nuclei",
                "<PDTM>/nuclei"
            ],
            installHint: "brew install nuclei"
        ),
        ToolDetector.PresetTool(
            id: "burpsuite",
            name: "Burp Suite",
            type: .app,
            searchPaths: [
                "/Applications/Burp Suite Professional.app",
                "/Applications/Burp Suite Community Edition.app"
            ],
            installHint: "brew install --cask burp-suite"
        ),
        ToolDetector.PresetTool(
            id: "yakit",
            name: "Yakit",
            type: .app,
            searchPaths: [
                "/Applications/Yakit.app",
                "~/Applications/Yakit.app"
            ],
            installHint: "Download from github.com/yaklang/yakit"
        ),
        ToolDetector.PresetTool(
            id: "wireshark",
            name: "Wireshark",
            type: .app,
            searchPaths: ["/Applications/Wireshark.app"],
            installHint: "brew install --cask wireshark-app"
        ),
    ]

    // MARK: - All Preset Categories

    static let allPresetCategories: [PresetCategory] = [
        PresetCategory(
            name: "AI应用",
            icon: "brain.head.profile",
            type: "normal",
            tools: aiAppTools
        ),
        PresetCategory(
            name: "网络安全工具",
            icon: "shield.lefthalf.filled",
            type: "normal",
            tools: netsecTools
        ),
        PresetCategory(
            name: "便签",
            icon: "note.text",
            type: "sticky"
        ),
        PresetCategory(
            name: "PDF",
            icon: "doc.richtext",
            type: "pdf",
            metadataFile: "demo.pdf"
        ),
        PresetCategory(
            name: "Markdown",
            icon: "markdown",
            type: "md",
            metadataFile: "demo.md"
        ),
    ]

    // MARK: - Demo File Resolution

    /// Resolves the absolute path for a bundled demo file.
    /// Tries Bundle.main first, then falls back to the executable's sibling Resources directory.
    static func resolveDemoFile(name: String, ext: String) -> String {
        let filename = "\(name).\(ext)"

        // 1) Try Bundle.main (works when running inside a proper .app bundle)
        if let bundlePath = Bundle.main.path(forResource: name, ofType: ext) {
            return bundlePath
        }

        // 2) Fall back to <executable-dir>/Resources/<filename>
        let exeURL = URL(fileURLWithPath: CommandLine.arguments[0])
        let resourcePath = exeURL
            .deletingLastPathComponent()
            .appendingPathComponent("Resources")
            .appendingPathComponent(filename)
            .path

        return resourcePath
    }

    // MARK: - Glob Pattern Detection

    /// Checks whether a search path contains glob wildcard characters.
    private static func isGlobPattern(_ path: String) -> Bool {
        return path.contains("*") || path.contains("?") || path.contains("[")
    }

    /// Expands a glob pattern and returns the first matching path, or nil.
    private static func firstGlobMatch(_ pattern: String) -> String? {
        let fm = FileManager.default
        let home = fm.homeDirectoryForCurrentUser.path
        let expanded = pattern
            .replacingOccurrences(of: "~", with: home)
            .replacingOccurrences(of: "<BREW>", with: ToolDetector.brewPrefix)
            .replacingOccurrences(of: "<GO>", with: ToolDetector.goBin)
            .replacingOccurrences(of: "<PDTM>", with: ToolDetector.pdtmBin)
            .replacingOccurrences(of: "<NPM>", with: ToolDetector.npmGlobalBin ?? "")

        // Separate directory from the glob filename component
        let nsPattern = expanded as NSString
        let directory = nsPattern.deletingLastPathComponent
        let fileGlob = nsPattern.lastPathComponent

        guard fm.fileExists(atPath: directory) else { return nil }

        guard let contents = try? fm.contentsOfDirectory(atPath: directory) else { return nil }

        // Simple wildcard matching supporting * and ?
        for item in contents.sorted().reversed() {
            if globMatch(item, pattern: fileGlob) {
                return (directory as NSString).appendingPathComponent(item)
            }
        }
        return nil
    }

    /// Simple filename glob matcher (supports * and ? wildcards).
    private static func globMatch(_ string: String, pattern: String) -> Bool {
        let sChars = Array(string)
        let pChars = Array(pattern)
        let sLen = sChars.count
        let pLen = pChars.count

        var sIdx = 0
        var pIdx = 0
        var starPIdx = -1
        var starSIdx = -1

        while sIdx < sLen {
            if pIdx < pLen && (pChars[pIdx] == "?" || pChars[pIdx] == sChars[sIdx]) {
                sIdx += 1
                pIdx += 1
            } else if pIdx < pLen && pChars[pIdx] == "*" {
                starPIdx = pIdx
                starSIdx = sIdx
                pIdx += 1
            } else if starPIdx >= 0 {
                pIdx = starPIdx + 1
                starSIdx += 1
                sIdx = starSIdx
            } else {
                return false
            }
        }

        while pIdx < pLen && pChars[pIdx] == "*" {
            pIdx += 1
        }

        return pIdx == pLen
    }

    /// Detects a preset tool, handling both exact paths and glob patterns.
    /// Returns the resolved path if found, nil otherwise.
    private static func detectTool(_ presetTool: ToolDetector.PresetTool) -> String? {
        let fm = FileManager.default
        let home = fm.homeDirectoryForCurrentUser.path

        for rawPath in presetTool.searchPaths {
            let expanded = rawPath
                .replacingOccurrences(of: "~", with: home)
                .replacingOccurrences(of: "<BREW>", with: ToolDetector.brewPrefix)
                .replacingOccurrences(of: "<GO>", with: ToolDetector.goBin)
                .replacingOccurrences(of: "<PDTM>", with: ToolDetector.pdtmBin)
                .replacingOccurrences(of: "<NPM>", with: ToolDetector.npmGlobalBin ?? "")

            if expanded.isEmpty { continue }

            if isGlobPattern(expanded) {
                if let match = firstGlobMatch(rawPath) {
                    return match
                }
            } else if fm.fileExists(atPath: expanded) {
                return expanded
            }
        }

        // Fallback: check if the tool is in PATH using `which`
        if presetTool.type != .app {
            if let whichPath = ToolDetector.whichTool(presetTool.id) {
                return whichPath
            }
        }

        return nil
    }

    // MARK: - First Launch Setup

    /// Installs preset categories on first launch. Only adds categories whose names
    /// don't already exist in the store, preserving backward compatibility.
    static func installPresetsIfNeeded() {
        let store = DataStore.shared
        let existingNames = Set(store.categories.map { $0.name })

        for preset in allPresetCategories {
            // Skip if a category with this name already exists (backward compatibility)
            if existingNames.contains(preset.name) { continue }

            // Resolve metadata for special types (pdf, md)
            var metadata: String? = nil
            if let metaFile = preset.metadataFile {
                let ns = metaFile as NSString
                metadata = resolveDemoFile(
                    name: ns.deletingPathExtension,
                    ext: ns.pathExtension
                )
            }

            // Detect and build tool entries
            var tools: [Tool] = []
            for presetTool in preset.tools {
                var detectedPath = detectTool(presetTool)

                // Special resolution for bundled demo items
                if detectedPath == nil {
                    switch presetTool.id {
                    case "demo-script":
                        detectedPath = resolveDemoFile(name: "demo", ext: "sh")
                    case "demo-md":
                        detectedPath = resolveDemoFile(name: "demo", ext: "md")
                    default:
                        break
                    }
                }

                let status: DetectionStatus = detectedPath != nil ? .detected : .notFound
                let tool = Tool(
                    name: presetTool.name,
                    appPath: detectedPath ?? "",
                    detectionStatus: status,
                    presetId: presetTool.id
                )
                tools.append(tool)
            }

            let cat = Category(
                name: preset.name,
                tools: tools,
                type: preset.type,
                metadata: metadata,
                isPreset: true,
                presetIcon: preset.icon
            )
            store.categories.append(cat)
        }

        store.save()
    }

    /// Re-scans all preset tools and updates their detection status.
    /// Only rescans categories marked as presets with type "normal".
    static func rescanAll() {
        let store = DataStore.shared

        for catIndex in store.categories.indices {
            guard store.categories[catIndex].isPreset == true else { continue }
            guard store.categories[catIndex].type == "normal" else { continue }

            for toolIndex in store.categories[catIndex].tools.indices {
                let tool = store.categories[catIndex].tools[toolIndex]

                // Find matching preset tool definition
                guard let presetId = tool.presetId,
                      let presetTool = findPresetTool(id: presetId) else { continue }

                let detectedPath = detectTool(presetTool)
                    ?? {
                        switch presetTool.id {
                        case "demo-script": return resolveDemoFile(name: "demo", ext: "sh")
                        case "demo-md":     return resolveDemoFile(name: "demo", ext: "md")
                        default:            return nil
                        }
                    }()
                store.categories[catIndex].tools[toolIndex].appPath = detectedPath ?? tool.appPath
                store.categories[catIndex].tools[toolIndex].detectionStatus =
                    detectedPath != nil ? .detected : .notFound
            }
        }

        store.save()
    }

    // MARK: - Lookup Helpers

    /// Finds a preset tool definition by its ID across all categories.
    static func findPresetTool(id: String) -> ToolDetector.PresetTool? {
        for preset in allPresetCategories {
            if let tool = preset.tools.first(where: { $0.id == id }) {
                return tool
            }
        }
        return nil
    }

    /// Gets the install hint for a preset tool by its ID.
    static func installHint(for presetId: String) -> String? {
        return findPresetTool(id: presetId)?.installHint
    }
}
