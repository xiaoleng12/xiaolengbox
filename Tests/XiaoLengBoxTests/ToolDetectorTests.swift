import XCTest
@testable import XiaoLengBox

final class ToolDetectorTests: XCTestCase {

    func testArchitectureDetection() {
        // Should return a valid boolean
        let _ = ToolDetector.isAppleSilicon
        XCTAssertNotNil(ToolDetector.brewPrefix)
        XCTAssertTrue(ToolDetector.brewPrefix == "/opt/homebrew" || ToolDetector.brewPrefix == "/usr/local")
    }

    func testDetectNonExistentTool() {
        let tool = ToolDetector.PresetTool(
            id: "nonexistent-tool-xyz",
            name: "NonExistent",
            type: .cli,
            searchPaths: ["/tmp/this/does/not/exist"],
            installHint: "N/A"
        )
        let result = ToolDetector.detect(tool)
        XCTAssertNil(result)
    }

    func testDetectExistingTool() {
        // /usr/bin/which should always exist on macOS
        let tool = ToolDetector.PresetTool(
            id: "which",
            name: "which",
            type: .cli,
            searchPaths: ["/usr/bin/which"],
            installHint: "N/A"
        )
        let result = ToolDetector.detect(tool)
        XCTAssertEqual(result, "/usr/bin/which")
    }

    func testWhichTool() {
        // `ls` should always be findable
        let result = ToolDetector.whichTool("ls")
        XCTAssertNotNil(result)
    }

    func testWhichNonExistent() {
        let result = ToolDetector.whichTool("totally-fake-tool-12345")
        XCTAssertNil(result)
    }

    func testDetectAll() {
        let tools: [ToolDetector.PresetTool] = [
            ToolDetector.PresetTool(id: "ls", name: "ls", type: .cli, searchPaths: ["/bin/ls"], installHint: "N/A"),
            ToolDetector.PresetTool(id: "fake-xyz", name: "Fake", type: .cli, searchPaths: ["/no/path"], installHint: "N/A"),
        ]
        let results = ToolDetector.detectAll(tools)
        XCTAssertEqual(results.count, 2)
        XCTAssertNotNil(results[0].1) // ls should be found
        XCTAssertNil(results[1].1)    // fake should not be found
    }
}
