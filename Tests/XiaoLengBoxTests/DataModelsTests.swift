import Foundation
import AppKit
import Testing
@testable import XiaoLengBox

// MARK: - Tool Model Tests

@Test func toolCreationDefaults() {
    let tool = Tool(name: "Test", appPath: "/usr/bin/test")
    #expect(tool.name == "Test")
    #expect(tool.appPath == "/usr/bin/test")
    #expect(tool.detectionStatus == .custom)
    #expect(tool.presetId == nil)
}

@Test func toolCreationWithAllFields() {
    let tool = Tool(name: "nmap", appPath: "/opt/homebrew/bin/nmap",
                    detectionStatus: .detected, presetId: "nmap")
    #expect(tool.name == "nmap")
    #expect(tool.appPath == "/opt/homebrew/bin/nmap")
    #expect(tool.detectionStatus == .detected)
    #expect(tool.presetId == "nmap")
}

@Test func toolCodableRoundTrip() throws {
    let original = Tool(name: "nmap", appPath: "/opt/homebrew/bin/nmap",
                        detectionStatus: .detected, presetId: "nmap")
    let data = try JSONEncoder().encode(original)
    let decoded = try JSONDecoder().decode(Tool.self, from: data)
    #expect(decoded.name == original.name)
    #expect(decoded.appPath == original.appPath)
    #expect(decoded.detectionStatus == original.detectionStatus)
    #expect(decoded.presetId == original.presetId)
    #expect(decoded.id == original.id)
}

@Test func toolBackwardCompatibility_oldFormat() throws {
    // JSON without detectionStatus and presetId (old format)
    let json = """
    {"id":"E621E1F8-C36C-495A-93FC-0C247A3E6E5F","name":"old","appPath":"/usr/bin/old"}
    """
    let data = json.data(using: .utf8)!
    let tool = try JSONDecoder().decode(Tool.self, from: data)
    #expect(tool.name == "old")
    #expect(tool.appPath == "/usr/bin/old")
    #expect(tool.detectionStatus == .custom, "Should default to .custom")
    #expect(tool.presetId == nil, "Should default to nil")
}

@Test func toolBackwardCompatibility_partialFields() throws {
    // JSON with only detectionStatus but no presetId
    let json = """
    {"id":"E621E1F8-C36C-495A-93FC-0C247A3E6E5F","name":"partial","appPath":"/bin/ls","detectionStatus":"detected"}
    """
    let data = json.data(using: .utf8)!
    let tool = try JSONDecoder().decode(Tool.self, from: data)
    #expect(tool.detectionStatus == .detected)
    #expect(tool.presetId == nil)
}

@Test func toolUniqueIdGeneration() {
    let t1 = Tool(name: "a", appPath: "/a")
    let t2 = Tool(name: "a", appPath: "/a")
    #expect(t1.id != t2.id, "Each tool should get a unique UUID")
}

// MARK: - Category Model Tests

@Test func categoryCreationDefaults() {
    let cat = Category(name: "TestCat")
    #expect(cat.name == "TestCat")
    #expect(cat.tools.isEmpty)
    #expect(cat.type == "normal")
    #expect(cat.metadata == nil)
    #expect(cat.isPreset == nil)
    #expect(cat.presetIcon == nil)
}

@Test func categoryCreationFull() {
    let cat = Category(name: "Security", tools: [], type: "normal",
                       metadata: nil, isPreset: true, presetIcon: "shield.fill")
    #expect(cat.name == "Security")
    #expect(cat.isPreset == true)
    #expect(cat.presetIcon == "shield.fill")
}

@Test func categoryCodableRoundTrip() throws {
    let tool = Tool(name: "nmap", appPath: "/usr/bin/nmap",
                    detectionStatus: .detected, presetId: "nmap")
    let cat = Category(name: "TestCat", tools: [tool], type: "normal",
                       metadata: nil, isPreset: true, presetIcon: "hammer.fill")
    let data = try JSONEncoder().encode(cat)
    let decoded = try JSONDecoder().decode(Category.self, from: data)
    #expect(decoded.name == "TestCat")
    #expect(decoded.type == "normal")
    #expect(decoded.isPreset == true)
    #expect(decoded.presetIcon == "hammer.fill")
    #expect(decoded.tools.count == 1)
    #expect(decoded.tools.first?.name == "nmap")
}

@Test func categoryBackwardCompatibility_oldFormat() throws {
    // JSON without type, isPreset, presetIcon, metadata
    let json = """
    {"id":"E621E1F8-C36C-495A-93FC-0C247A3E6E5F","name":"legacy","tools":[]}
    """
    let data = json.data(using: .utf8)!
    let cat = try JSONDecoder().decode(Category.self, from: data)
    #expect(cat.name == "legacy")
    #expect(cat.type == "normal", "Should default to normal")
    #expect(cat.isPreset == nil)
    #expect(cat.presetIcon == nil)
}

// MARK: - DetectionStatus Tests

@Test func detectionStatusAllCases() throws {
    let cases: [DetectionStatus] = [.detected, .notFound, .custom, .detecting]
    for status in cases {
        let data = try JSONEncoder().encode(status)
        let decoded = try JSONDecoder().decode(DetectionStatus.self, from: data)
        #expect(decoded == status, "Status \(status) should round-trip through JSON")
    }
}

@Test func detectionStatusRawValues() {
    #expect(DetectionStatus.detected.rawValue == "detected")
    #expect(DetectionStatus.notFound.rawValue == "notFound")
    #expect(DetectionStatus.custom.rawValue == "custom")
    #expect(DetectionStatus.detecting.rawValue == "detecting")
}

// MARK: - StickyNoteModel Tests

@Test func stickyNoteCreation() {
    let note = StickyNoteModel(
        id: UUID(), content: "Hello", imagePath: nil,
        frameX: 100, frameY: 200, frameWidth: 300, frameHeight: 150,
        categoryId: UUID(), createdAt: Date()
    )
    #expect(note.content == "Hello")
    #expect(note.frameX == 100)
    #expect(note.frameWidth == 300)
    #expect(note.imagePath == nil)
    #expect(note.fontSize == nil)
}

@Test func stickyNoteCodable() throws {
    let catId = UUID()
    let note = StickyNoteModel(
        id: UUID(), content: "Test note", imagePath: "/tmp/img.png",
        frameX: 50, frameY: 60, frameWidth: 200, frameHeight: 100,
        categoryId: catId, createdAt: Date(timeIntervalSince1970: 1000000),
        fontSize: 14
    )
    let data = try JSONEncoder().encode(note)
    let decoded = try JSONDecoder().decode(StickyNoteModel.self, from: data)
    #expect(decoded.content == "Test note")
    #expect(decoded.imagePath == "/tmp/img.png")
    #expect(decoded.categoryId == catId)
    #expect(decoded.fontSize == 14)
}

// MARK: - Validation Tests

@Test func categoryNameValidation() {
    #expect(Validation.isCategoryNameValid("Valid Name") == true)
    #expect(Validation.isCategoryNameValid("安全工具") == true)
    #expect(Validation.isCategoryNameValid("") == false)
    #expect(Validation.isCategoryNameValid("   ") == false)
    #expect(Validation.isCategoryNameValid("\n\t") == false)
}

@Test func toolNameValidation() {
    #expect(Validation.isToolNameValid("nmap") == true)
    #expect(Validation.isToolNameValid("Claude Code") == true)
    #expect(Validation.isToolNameValid("") == false)
    #expect(Validation.isToolNameValid("   ") == false)
}

@Test func appPathValidation() {
    // /bin/sh always exists on macOS
    #expect(Validation.isAppPathValid("/bin/sh") == true)
    #expect(Validation.isAppPathValid("/tmp") == true)
    #expect(Validation.isAppPathValid("") == false)
    #expect(Validation.isAppPathValid("   ") == false)
    #expect(Validation.isAppPathValid("/nonexistent/path/xyz") == false)
}

// MARK: - LaunchError Tests

@Test func launchErrorCases() {
    let notFound = LaunchError.appNotFound(path: "/fake")
    if case .appNotFound(let path) = notFound {
        #expect(path == "/fake")
    } else {
        Issue.record("Wrong error case")
    }
}

// MARK: - Notification Names

@Test func notificationNamesDefined() {
    #expect(Notification.Name.wallpaperChanged.rawValue == "xiaolengbox.wallpaperChanged")
    #expect(Notification.Name.glassModeChanged.rawValue == "xiaolengbox.glassModeChanged")
    #expect(Notification.Name.stickyNoteChanged.rawValue == "xiaolengbox.stickyNoteChanged")
    #expect(Notification.Name.terminalWindowChanged.rawValue == "xiaolengbox.terminalWindowChanged")
}
