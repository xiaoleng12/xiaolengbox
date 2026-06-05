import Foundation
import Testing
@testable import XiaoLengBox

// MARK: - Preset Category Structure Tests

@Test func allPresetCategoriesExist() {
    let categories = PresetCatalog.allPresetCategories
    #expect(categories.count == 5, "Should have 5 preset categories")
    let names = categories.map { $0.name }
    #expect(names.contains("AI应用"))
    #expect(names.contains("网络安全工具"))
    #expect(names.contains("便签"))
    #expect(names.contains("PDF"))
    #expect(names.contains("Markdown"))
}

@Test func allCategoriesHaveNameAndIcon() {
    for category in PresetCatalog.allPresetCategories {
        #expect(!category.name.isEmpty, "Category should have a name")
        #expect(!category.icon.isEmpty, "Category should have an SF Symbol icon")
    }
}

// MARK: - AI应用 Category Tests

@Test func aiCategoryExists() {
    let ai = PresetCatalog.allPresetCategories.first { $0.name == "AI应用" }
    #expect(ai != nil)
    #expect(ai?.icon == "brain.head.profile")
    #expect(ai?.type == "normal")
}

@Test func aiCategoryContainsExpectedTools() {
    let ai = PresetCatalog.allPresetCategories.first { $0.name == "AI应用" }
    let toolIds = ai?.tools.map { $0.id } ?? []
    #expect(toolIds.contains("claude"), "Should contain Claude Code")
    #expect(toolIds.contains("codex"), "Should contain OpenAI Codex")
    #expect(toolIds.contains("qoderwork"), "Should contain QoderWork")
    #expect(toolIds.contains("vscode"), "Should contain VS Code")
    #expect(toolIds.contains("cursor"), "Should contain Cursor")
    #expect(toolIds.contains("ollama"), "Should contain Ollama")
    #expect(toolIds.contains("trae"), "Should contain Trae")
    #expect(toolIds.contains("lm-studio"), "Should contain LM Studio")
}

@Test func aiCategoryContainsDemoItems() {
    let ai = PresetCatalog.allPresetCategories.first { $0.name == "AI应用" }
    let toolIds = ai?.tools.map { $0.id } ?? []
    #expect(toolIds.contains("demo-folder"), "Should contain demo folder")
    #expect(toolIds.contains("demo-script"), "Should contain demo script")
    #expect(toolIds.contains("demo-md"), "Should contain demo markdown")
}

@Test func aiCategoryToolCount() {
    let ai = PresetCatalog.allPresetCategories.first { $0.name == "AI应用" }
    #expect((ai?.tools.count ?? 0) >= 11, "AI category should have at least 11 tools")
}

// MARK: - 网络安全工具 Category Tests

@Test func netsecCategoryExists() {
    let sec = PresetCatalog.allPresetCategories.first { $0.name == "网络安全工具" }
    #expect(sec != nil)
    #expect(sec?.icon == "shield.lefthalf.filled")
    #expect(sec?.type == "normal")
}

@Test func netsecCategoryContainsExpectedTools() {
    let sec = PresetCatalog.allPresetCategories.first { $0.name == "网络安全工具" }
    let toolIds = sec?.tools.map { $0.id } ?? []
    #expect(toolIds.contains("sqlmap"), "Should contain sqlmap")
    #expect(toolIds.contains("nmap"), "Should contain nmap")
    #expect(toolIds.contains("nuclei"), "Should contain nuclei")
    #expect(toolIds.contains("burpsuite"), "Should contain Burp Suite")
    #expect(toolIds.contains("yakit"), "Should contain Yakit")
    #expect(toolIds.contains("wireshark"), "Should contain Wireshark")
    #expect(toolIds.contains("tscanplus"), "Should contain TScanPlus")
    #expect(toolIds.contains("dirsearch"), "Should contain dirsearch")
}

@Test func netsecCategoryToolCount() {
    let sec = PresetCatalog.allPresetCategories.first { $0.name == "网络安全工具" }
    #expect((sec?.tools.count ?? 0) >= 8, "NetSec category should have at least 8 tools")
}

// MARK: - Special Category Tests

@Test func stickyNotesCategoryExists() {
    let sticky = PresetCatalog.allPresetCategories.first { $0.name == "便签" }
    #expect(sticky != nil)
    #expect(sticky?.type == "sticky")
    #expect(sticky?.icon == "note.text")
    #expect(sticky?.tools.isEmpty == true, "Sticky notes category should have no preset tools")
}

@Test func pdfCategoryExists() {
    let pdf = PresetCatalog.allPresetCategories.first { $0.name == "PDF" }
    #expect(pdf != nil)
    #expect(pdf?.type == "pdf")
    #expect(pdf?.icon == "doc.richtext")
    #expect(pdf?.metadataFile == "demo.pdf")
}

@Test func markdownCategoryExists() {
    let md = PresetCatalog.allPresetCategories.first { $0.name == "Markdown" }
    #expect(md != nil)
    #expect(md?.type == "md")
    #expect(md?.icon == "markdown")
    #expect(md?.metadataFile == "demo.md")
}

// MARK: - Tool ID Uniqueness Tests

@Test func allToolIdsAreUnique() {
    var ids = Set<String>()
    for category in PresetCatalog.allPresetCategories {
        for tool in category.tools {
            let result = ids.insert(tool.id)
            #expect(result.inserted, "Duplicate tool ID found: \(tool.id)")
        }
    }
}

@Test func noEmptyToolNames() {
    for category in PresetCatalog.allPresetCategories {
        for tool in category.tools {
            #expect(!tool.name.isEmpty, "Tool should have a non-empty name")
        }
    }
}

// MARK: - Search Path Tests

@Test func normalToolsHaveSearchPaths() {
    // Only check "normal" type tools, not demo items which may have empty paths
    for category in PresetCatalog.allPresetCategories where category.type == "normal" {
        for tool in category.tools where !tool.id.hasPrefix("demo-") {
            #expect(!tool.searchPaths.isEmpty,
                    "\(tool.name) (\(tool.id)) should have at least one search path")
        }
    }
}

@Test func allToolsHaveInstallHints() {
    for category in PresetCatalog.allPresetCategories {
        for tool in category.tools {
            #expect(!tool.installHint.isEmpty,
                    "\(tool.name) should have an install hint")
        }
    }
}

// MARK: - Lookup Helper Tests

@Test func findPresetToolById() {
    let nmap = PresetCatalog.findPresetTool(id: "nmap")
    #expect(nmap != nil)
    #expect(nmap?.name == "nmap")
    #expect(nmap?.type == .cli)
}

@Test func findPresetToolById_aiTool() {
    let claude = PresetCatalog.findPresetTool(id: "claude")
    #expect(claude != nil)
    #expect(claude?.name == "Claude Code")
    #expect(claude?.type == .either)
}

@Test func findPresetToolById_nonExistent() {
    let fake = PresetCatalog.findPresetTool(id: "nonexistent-tool-xyz")
    #expect(fake == nil)
}

@Test func findPresetToolById_demoItems() {
    let demoFolder = PresetCatalog.findPresetTool(id: "demo-folder")
    #expect(demoFolder != nil)
    #expect(demoFolder?.name == "桌面文件夹")

    let demoScript = PresetCatalog.findPresetTool(id: "demo-script")
    #expect(demoScript != nil)

    let demoMd = PresetCatalog.findPresetTool(id: "demo-md")
    #expect(demoMd != nil)
}

@Test func installHintForKnownTools() {
    let nmapHint = PresetCatalog.installHint(for: "nmap")
    #expect(nmapHint != nil)
    #expect(nmapHint?.contains("brew") == true)

    let sqlmapHint = PresetCatalog.installHint(for: "sqlmap")
    #expect(sqlmapHint != nil)

    let burpHint = PresetCatalog.installHint(for: "burpsuite")
    #expect(burpHint != nil)
}

@Test func installHintForUnknownTool() {
    let hint = PresetCatalog.installHint(for: "totally-fake-tool")
    #expect(hint == nil)
}

// MARK: - Demo File Resolution Tests

@Test func resolveDemoFileReturnsPath() {
    let shPath = PresetCatalog.resolveDemoFile(name: "demo", ext: "sh")
    #expect(!shPath.isEmpty, "Should return a non-empty path")
    #expect(shPath.contains("demo.sh"), "Path should contain the filename")

    let mdPath = PresetCatalog.resolveDemoFile(name: "demo", ext: "md")
    #expect(!mdPath.isEmpty)
    #expect(mdPath.contains("demo.md"))
}

// MARK: - Tool Type Tests

@Test func toolTypesCorrectlyAssigned() {
    // CLI tools
    let nmap = PresetCatalog.findPresetTool(id: "nmap")
    #expect(nmap?.type == .cli, "nmap should be a CLI tool")

    let sqlmap = PresetCatalog.findPresetTool(id: "sqlmap")
    #expect(sqlmap?.type == .cli, "sqlmap should be a CLI tool")

    // App tools
    let vscode = PresetCatalog.findPresetTool(id: "vscode")
    #expect(vscode?.type == .app, "VS Code should be an app")

    let burp = PresetCatalog.findPresetTool(id: "burpsuite")
    #expect(burp?.type == .app, "Burp Suite should be an app")

    // Either type (can be app or CLI)
    let claude = PresetCatalog.findPresetTool(id: "claude")
    #expect(claude?.type == .either, "Claude Code should be either type")

    let codex = PresetCatalog.findPresetTool(id: "codex")
    #expect(codex?.type == .either, "Codex should be either type")

    let ollama = PresetCatalog.findPresetTool(id: "ollama")
    #expect(ollama?.type == .either, "Ollama should be either type")
}

// MARK: - Placeholder Expansion Tests

@Test func searchPathsContainExpectedPlaceholders() {
    // Verify that tools using various package managers have correct placeholders
    let nuclei = PresetCatalog.findPresetTool(id: "nuclei")
    let nucleiPaths = nuclei?.searchPaths ?? []
    #expect(nucleiPaths.contains { $0.contains("<GO>") }, "nuclei should search Go bin")
    #expect(nucleiPaths.contains { $0.contains("<BREW>") }, "nuclei should search Brew bin")
    #expect(nucleiPaths.contains { $0.contains("<PDTM>") }, "nuclei should search PDTM bin")

    let claude = PresetCatalog.findPresetTool(id: "claude")
    let claudePaths = claude?.searchPaths ?? []
    #expect(claudePaths.contains { $0.contains("<NPM>") }, "Claude should search NPM bin")
    #expect(claudePaths.contains { $0.contains("<BREW>") }, "Claude should search Brew bin")
}
