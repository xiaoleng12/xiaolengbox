import Foundation
import Testing
@testable import XiaoLengBox

// MARK: - Architecture Detection Tests

@Test func architectureDetectionReturnsBoolean() {
    let _ = ToolDetector.isAppleSilicon
    // Just ensure it doesn't crash - result depends on hardware
}

@Test func brewPrefixIsValid() {
    let prefix = ToolDetector.brewPrefix
    #expect(prefix == "/opt/homebrew" || prefix == "/usr/local",
            "Brew prefix should be /opt/homebrew (ARM) or /usr/local (Intel)")
}

@Test func brewPrefixMatchesArchitecture() {
    if ToolDetector.isAppleSilicon {
        #expect(ToolDetector.brewPrefix == "/opt/homebrew")
    } else {
        #expect(ToolDetector.brewPrefix == "/usr/local")
    }
}

// MARK: - Common Path Helper Tests

@Test func goBinPathFormat() {
    let goBin = ToolDetector.goBin
    #expect(goBin.hasSuffix("/go/bin"), "Go bin should end with /go/bin")
    #expect(goBin.hasPrefix("/"), "Go bin should be an absolute path")
}

@Test func pdtmBinPathFormat() {
    let pdtmBin = ToolDetector.pdtmBin
    #expect(pdtmBin.hasSuffix("/.pdtm/go/bin"), "PDTM bin should end with /.pdtm/go/bin")
    #expect(pdtmBin.hasPrefix("/"), "PDTM bin should be an absolute path")
}

@Test func npmGlobalBinReturnsValue() {
    // npmGlobalBin may be nil if npm isn't installed, but it shouldn't crash
    let _ = ToolDetector.npmGlobalBin
}

// MARK: - Tool Detection Tests

@Test func detectNonExistentToolReturnsNil() {
    let tool = ToolDetector.PresetTool(
        id: "nonexistent-tool-xyz-123",
        name: "NonExistent",
        type: .cli,
        searchPaths: ["/tmp/this/does/not/exist/at/all"],
        installHint: "N/A"
    )
    let result = ToolDetector.detect(tool)
    #expect(result == nil, "Non-existent tool should return nil")
}

@Test func detectExistingSystemTool() {
    // /usr/bin/which should always exist on macOS
    let tool = ToolDetector.PresetTool(
        id: "which",
        name: "which",
        type: .cli,
        searchPaths: ["/usr/bin/which"],
        installHint: "N/A"
    )
    let result = ToolDetector.detect(tool)
    #expect(result == "/usr/bin/which")
}

@Test func detectExistingBinLs() {
    let tool = ToolDetector.PresetTool(
        id: "ls",
        name: "ls",
        type: .cli,
        searchPaths: ["/bin/ls"],
        installHint: "N/A"
    )
    let result = ToolDetector.detect(tool)
    #expect(result == "/bin/ls")
}

@Test func detectAppTypeSkipsWhichFallback() {
    // .app type tools should NOT fall back to `which`
    let tool = ToolDetector.PresetTool(
        id: "ls",  // ls exists in PATH
        name: "FakeApp",
        type: .app,  // but type is .app, so `which` should not be used
        searchPaths: ["/Applications/DoesNotExist.app"],
        installHint: "N/A"
    )
    let result = ToolDetector.detect(tool)
    #expect(result == nil, ".app type should not fall back to which")
}

@Test func detectCliTypeUsesWhichFallback() {
    // .cli and .either types should fall back to `which`
    let tool = ToolDetector.PresetTool(
        id: "ls",  // ls exists in PATH
        name: "ls",
        type: .cli,
        searchPaths: ["/nonexistent/path/ls"],  // explicit path doesn't exist
        installHint: "N/A"
    )
    let result = ToolDetector.detect(tool)
    #expect(result != nil, ".cli type should fall back to which and find ls")
}

@Test func detectEitherTypeUsesWhichFallback() {
    let tool = ToolDetector.PresetTool(
        id: "ls",
        name: "ls",
        type: .either,
        searchPaths: ["/nonexistent/path/ls"],
        installHint: "N/A"
    )
    let result = ToolDetector.detect(tool)
    #expect(result != nil, ".either type should fall back to which and find ls")
}

// MARK: - Placeholder Expansion Tests

@Test func placeholderExpansion_tildeReplacement() {
    let home = FileManager.default.homeDirectoryForCurrentUser.path
    let tool = ToolDetector.PresetTool(
        id: "test-home",
        name: "Test",
        type: .cli,
        searchPaths: ["~/Desktop"],  // ~ should expand to home
        installHint: "N/A"
    )
    let result = ToolDetector.detect(tool)
    // ~/Desktop should exist on macOS
    #expect(result == "\(home)/Desktop")
}

@Test func placeholderExpansion_brewPrefix() {
    // Create a tool that searches the brew prefix directory itself (which exists)
    let tool = ToolDetector.PresetTool(
        id: "test-brew",
        name: "Test",
        type: .cli,
        searchPaths: ["<BREW>/bin"],  // brew bin directory should exist if brew is installed
        installHint: "N/A"
    )
    let result = ToolDetector.detect(tool)
    if FileManager.default.fileExists(atPath: "\(ToolDetector.brewPrefix)/bin") {
        #expect(result != nil)
        #expect(result?.contains(ToolDetector.brewPrefix) == true)
    }
}

@Test func placeholderExpansion_npmPlaceholderWithEmptyNpm() {
    // When npm is not found, <NPM> expands to empty string, path should be skipped
    let tool = ToolDetector.PresetTool(
        id: "test-npm-empty",
        name: "Test",
        type: .cli,
        searchPaths: ["<NPM>/nonexistent"],
        installHint: "N/A"
    )
    // This should not crash even if npm is not installed
    let _ = ToolDetector.detect(tool)
}

// MARK: - whichTool Tests

@Test func whichToolFindsLs() {
    let result = ToolDetector.whichTool("ls")
    #expect(result != nil, "Should find ls in PATH")
    #expect(result?.contains("ls") == true)
}

@Test func whichToolFindsSh() {
    let result = ToolDetector.whichTool("sh")
    #expect(result != nil, "Should find sh in PATH")
}

@Test func whichToolReturnsNilForFakeTool() {
    let result = ToolDetector.whichTool("totally-fake-tool-abc123xyz")
    #expect(result == nil, "Should return nil for non-existent tool")
}

@Test func whichToolReturnsTrimmedPath() {
    let result = ToolDetector.whichTool("ls")
    if let path = result {
        #expect(!path.hasPrefix(" "), "Path should not have leading whitespace")
        #expect(!path.hasSuffix("\n"), "Path should not have trailing newline")
        #expect(path.hasPrefix("/"), "Path should be absolute")
    }
}

// MARK: - detectAll Tests

@Test func detectAllReturnsCorrectCount() {
    let tools: [ToolDetector.PresetTool] = [
        ToolDetector.PresetTool(id: "ls", name: "ls", type: .cli,
                                searchPaths: ["/bin/ls"], installHint: "N/A"),
        ToolDetector.PresetTool(id: "fake-xyz", name: "Fake", type: .cli,
                                searchPaths: ["/no/such/path"], installHint: "N/A"),
        ToolDetector.PresetTool(id: "cat", name: "cat", type: .cli,
                                searchPaths: ["/bin/cat"], installHint: "N/A"),
    ]
    let results = ToolDetector.detectAll(tools)
    #expect(results.count == 3, "Should return one result per input tool")
}

@Test func detectAllCorrectlyIdentifiesFoundAndMissing() {
    let tools: [ToolDetector.PresetTool] = [
        ToolDetector.PresetTool(id: "ls", name: "ls", type: .cli,
                                searchPaths: ["/bin/ls"], installHint: "N/A"),
        ToolDetector.PresetTool(id: "fake-xyz", name: "Fake", type: .cli,
                                searchPaths: ["/no/such/path"], installHint: "N/A"),
    ]
    let results = ToolDetector.detectAll(tools)
    #expect(results[0].1 != nil, "ls should be found")
    #expect(results[1].1 == nil, "fake tool should not be found")
}

@Test func detectAllEmptyInput() {
    let results = ToolDetector.detectAll([])
    #expect(results.isEmpty, "Empty input should return empty output")
}

// MARK: - PresetTool Structure Tests

@Test func presetToolPropertiesAccessible() {
    let tool = ToolDetector.PresetTool(
        id: "test-tool",
        name: "Test Tool",
        type: .either,
        searchPaths: ["/path/a", "/path/b", "/path/c"],
        installHint: "brew install test"
    )
    #expect(tool.id == "test-tool")
    #expect(tool.name == "Test Tool")
    #expect(tool.searchPaths.count == 3)
    #expect(tool.installHint == "brew install test")
}
