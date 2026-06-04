import XCTest
@testable import XiaoLengBox

final class DataModelsTests: XCTestCase {

    func testToolCreation() {
        let tool = Tool(name: "Test", appPath: "/usr/bin/test")
        XCTAssertEqual(tool.name, "Test")
        XCTAssertEqual(tool.appPath, "/usr/bin/test")
        XCTAssertEqual(tool.detectionStatus, .custom)
        XCTAssertNil(tool.presetId)
    }

    func testToolCodable() throws {
        let original = Tool(name: "nmap", appPath: "/opt/homebrew/bin/nmap", detectionStatus: .detected, presetId: "nmap")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Tool.self, from: data)
        XCTAssertEqual(decoded.name, "nmap")
        XCTAssertEqual(decoded.appPath, "/opt/homebrew/bin/nmap")
        XCTAssertEqual(decoded.detectionStatus, .detected)
        XCTAssertEqual(decoded.presetId, "nmap")
    }

    func testToolBackwardCompatibility() throws {
        // Old format without detectionStatus and presetId
        let json = """
        {"id":"E621E1F8-C36C-495A-93FC-0C247A3E6E5F","name":"old","appPath":"/usr/bin/old"}
        """
        let data = json.data(using: .utf8)!
        let tool = try JSONDecoder().decode(Tool.self, from: data)
        XCTAssertEqual(tool.name, "old")
        XCTAssertEqual(tool.detectionStatus, .custom) // default
        XCTAssertNil(tool.presetId)
    }

    func testCategoryCodable() throws {
        let cat = Category(name: "TestCat", tools: [], type: "normal", isPreset: true, presetIcon: "hammer.fill")
        let data = try JSONEncoder().encode(cat)
        let decoded = try JSONDecoder().decode(Category.self, from: data)
        XCTAssertEqual(decoded.name, "TestCat")
        XCTAssertEqual(decoded.type, "normal")
        XCTAssertEqual(decoded.isPreset, true)
        XCTAssertEqual(decoded.presetIcon, "hammer.fill")
    }

    func testValidation() {
        XCTAssertTrue(Validation.isCategoryNameValid("Valid Name"))
        XCTAssertFalse(Validation.isCategoryNameValid(""))
        XCTAssertFalse(Validation.isCategoryNameValid("   "))
        XCTAssertTrue(Validation.isToolNameValid("nmap"))
        XCTAssertFalse(Validation.isToolNameValid(""))
        XCTAssertFalse(Validation.isAppPathValid(""))
        XCTAssertTrue(Validation.isAppPathValid("/usr/bin/ls"))
        XCTAssertFalse(Validation.isAppPathValid("/nonexistent/path"))
    }

    func testDetectionStatus() throws {
        for status in [DetectionStatus.detected, .notFound, .custom, .detecting] {
            let data = try JSONEncoder().encode(status)
            let decoded = try JSONDecoder().decode(DetectionStatus.self, from: data)
            XCTAssertEqual(decoded, status)
        }
    }
}
