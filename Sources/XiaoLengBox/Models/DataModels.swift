import Foundation
import AppKit

// MARK: - Data Models

struct Tool: Codable, Identifiable {
    let id: UUID
    var name: String
    var appPath: String
    var detectionStatus: DetectionStatus
    var presetId: String?

    init(id: UUID = UUID(), name: String, appPath: String, detectionStatus: DetectionStatus = .custom, presetId: String? = nil) {
        self.id = id
        self.name = name
        self.appPath = appPath
        self.detectionStatus = detectionStatus
        self.presetId = presetId
    }

    private enum CodingKeys: String, CodingKey { case id, name, appPath, detectionStatus, presetId }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        appPath = try c.decode(String.self, forKey: .appPath)
        detectionStatus = try c.decodeIfPresent(DetectionStatus.self, forKey: .detectionStatus) ?? .custom
        presetId = try c.decodeIfPresent(String.self, forKey: .presetId)
    }
}

enum DetectionStatus: String, Codable {
    case detected
    case notFound
    case custom
    case detecting
}

struct Category: Codable, Identifiable {
    let id: UUID
    var name: String
    var tools: [Tool]
    var type: String
    var metadata: String?
    var isPreset: Bool?
    var presetIcon: String?

    init(id: UUID = UUID(), name: String, tools: [Tool] = [], type: String = "normal", metadata: String? = nil, isPreset: Bool? = nil, presetIcon: String? = nil) {
        self.id = id
        self.name = name
        self.tools = tools
        self.type = type
        self.metadata = metadata
        self.isPreset = isPreset
        self.presetIcon = presetIcon
    }

    private enum CodingKeys: String, CodingKey { case id, name, tools, type, metadata, isPreset, presetIcon }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        tools = try c.decode([Tool].self, forKey: .tools)
        type = try c.decodeIfPresent(String.self, forKey: .type) ?? "normal"
        metadata = try c.decodeIfPresent(String.self, forKey: .metadata)
        isPreset = try c.decodeIfPresent(Bool.self, forKey: .isPreset)
        presetIcon = try c.decodeIfPresent(String.self, forKey: .presetIcon)
    }
}

struct StickyNoteModel: Codable, Identifiable {
    let id: UUID
    var content: String
    var imagePath: String?
    var frameX: CGFloat
    var frameY: CGFloat
    var frameWidth: CGFloat
    var frameHeight: CGFloat
    var categoryId: UUID
    var createdAt: Date
    var fontSize: CGFloat?
    var imageX: CGFloat?
    var imageY: CGFloat?
    var imageWidth: CGFloat?
    var imageHeight: CGFloat?
}

// MARK: - Validation

struct Validation {
    static func isCategoryNameValid(_ name: String) -> Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    static func isToolNameValid(_ name: String) -> Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    static func isAppPathValid(_ path: String) -> Bool {
        let trimmed = path.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        return FileManager.default.fileExists(atPath: trimmed)
    }
}

// MARK: - Launch Error & Tool Launcher

enum LaunchError: Error {
    case appNotFound(path: String)
    case launchFailed(underlying: Error)
}

struct ToolLauncher {
    static func launch(_ tool: Tool) -> Result<Void, LaunchError> {
        let path = tool.appPath
        guard FileManager.default.fileExists(atPath: path) else {
            return .failure(.appNotFound(path: path))
        }
        let url = URL(fileURLWithPath: path)
        var isDir: ObjCBool = false
        FileManager.default.fileExists(atPath: path, isDirectory: &isDir)
        if isDir.boolValue && !path.hasSuffix(".app") {
            NSWorkspace.shared.open(url)
            return .success(())
        }
        if path.hasSuffix(".app") {
            NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration()) { _, _ in }
            return .success(())
        }
        NSWorkspace.shared.open(url)
        return .success(())
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let wallpaperChanged = Notification.Name("xiaolengbox.wallpaperChanged")
    static let glassModeChanged = Notification.Name("xiaolengbox.glassModeChanged")
    static let stickyNoteChanged = Notification.Name("xiaolengbox.stickyNoteChanged")
    static let terminalWindowChanged = Notification.Name("xiaolengbox.terminalWindowChanged")
}
