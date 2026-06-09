import Foundation

class DataStore {
    nonisolated(unsafe) static let shared = DataStore()
    var categories: [Category] = []
    var wallpaperPath: String = ""
    var glassMode: String = "glass"
    var glassOpacity: Double = 0.8
    var stickyNotes: [StickyNoteModel] = []
    var terminalWindowFrame: String?

    private struct StoreData: Codable {
        var categories: [Category]
        var wallpaperPath: String
        var glassMode: String
        var glassOpacity: Double
        var stickyNotes: [StickyNoteModel]
        var terminalWindowFrame: String?
        var aiBaseUrl: String?
        var aiApiKey: String?
        var aiModel: String?
        var aiProvider: String?

        init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            categories = try container.decode([Category].self, forKey: .categories)
            wallpaperPath = try container.decodeIfPresent(String.self, forKey: .wallpaperPath) ?? ""
            glassMode = try container.decodeIfPresent(String.self, forKey: .glassMode) ?? "glass"
            glassOpacity = try container.decodeIfPresent(Double.self, forKey: .glassOpacity) ?? 0.8
            stickyNotes = try container.decodeIfPresent([StickyNoteModel].self, forKey: .stickyNotes) ?? []
            terminalWindowFrame = try container.decodeIfPresent(String.self, forKey: .terminalWindowFrame)
            aiBaseUrl = try container.decodeIfPresent(String.self, forKey: .aiBaseUrl) ?? ""
            aiApiKey = try container.decodeIfPresent(String.self, forKey: .aiApiKey) ?? ""
            aiModel = try container.decodeIfPresent(String.self, forKey: .aiModel) ?? "gpt-4o"
            aiProvider = try container.decodeIfPresent(String.self, forKey: .aiProvider) ?? ""
        }

        init(categories: [Category], wallpaperPath: String, glassMode: String, glassOpacity: Double, stickyNotes: [StickyNoteModel], terminalWindowFrame: String?, aiBaseUrl: String, aiApiKey: String, aiModel: String, aiProvider: String) {
            self.categories = categories
            self.wallpaperPath = wallpaperPath
            self.glassMode = glassMode
            self.glassOpacity = glassOpacity
            self.stickyNotes = stickyNotes
            self.terminalWindowFrame = terminalWindowFrame
            self.aiBaseUrl = aiBaseUrl
            self.aiApiKey = aiApiKey
            self.aiModel = aiModel
            self.aiProvider = aiProvider
        }

        private enum CodingKeys: String, CodingKey {
            case categories, wallpaperPath, glassMode, glassOpacity, stickyNotes, terminalWindowFrame, aiBaseUrl, aiApiKey, aiModel, aiProvider
        }
    }

    private func dataFilePath() -> URL {
        let exe = URL(fileURLWithPath: CommandLine.arguments[0])
        return exe.deletingLastPathComponent().appendingPathComponent("xiaolengbox_data.json")
    }

    func load() {
        let path = dataFilePath()
        if let data = try? Data(contentsOf: path),
           let decoded = try? JSONDecoder().decode(StoreData.self, from: data) {
            categories = decoded.categories
            wallpaperPath = decoded.wallpaperPath
            glassMode = decoded.glassMode
            glassOpacity = decoded.glassOpacity
            stickyNotes = decoded.stickyNotes
            terminalWindowFrame = decoded.terminalWindowFrame
        } else {
            categories = []
            wallpaperPath = ""
            glassMode = "glass"
            glassOpacity = 0.8
            stickyNotes = []
            terminalWindowFrame = nil
        }
    }

    func save() {
        let store = StoreData(categories: categories, wallpaperPath: wallpaperPath, glassMode: glassMode, glassOpacity: glassOpacity, stickyNotes: stickyNotes, terminalWindowFrame: terminalWindowFrame, aiBaseUrl: "", aiApiKey: "", aiModel: "", aiProvider: "")
        guard let data = try? JSONEncoder().encode(store) else { return }
        try? data.write(to: dataFilePath(), options: .atomic)
    }

    @discardableResult
    func addCategory(_ name: String, type: String = "normal", metadata: String? = nil, isPreset: Bool = false, presetIcon: String? = nil) -> Bool {
        guard Validation.isCategoryNameValid(name) else { return false }
        let cat = Category(id: UUID(), name: name.trimmingCharacters(in: .whitespacesAndNewlines), tools: [], type: type, metadata: metadata, isPreset: isPreset, presetIcon: presetIcon)
        categories.append(cat)
        save()
        return true
    }

    func deleteCategory(id: UUID) {
        categories.removeAll { $0.id == id }
        stickyNotes.removeAll { $0.categoryId == id }
        save()
    }

    @discardableResult
    func addTool(_ tool: Tool, to categoryId: UUID) -> Bool {
        guard let idx = categories.firstIndex(where: { $0.id == categoryId }) else { return false }
        categories[idx].tools.append(tool)
        save()
        return true
    }

    func updateTool(_ tool: Tool, in categoryId: UUID) {
        guard let catIdx = categories.firstIndex(where: { $0.id == categoryId }),
              let toolIdx = categories[catIdx].tools.firstIndex(where: { $0.id == tool.id }) else { return }
        categories[catIdx].tools[toolIdx] = tool
        save()
    }

    func deleteTool(id: UUID, from categoryId: UUID) {
        guard let idx = categories.firstIndex(where: { $0.id == categoryId }) else { return }
        categories[idx].tools.removeAll { $0.id == id }
        save()
    }

    func tools(for categoryId: UUID) -> [Tool] {
        categories.first(where: { $0.id == categoryId })?.tools ?? []
    }

    // MARK: - Sticky Notes

    func stickyNotes(for categoryId: UUID) -> [StickyNoteModel] {
        stickyNotes.filter { $0.categoryId == categoryId }
    }

    @discardableResult
    func addStickyNote(to categoryId: UUID) -> StickyNoteModel {
        let note = StickyNoteModel(
            id: UUID(),
            content: "",
            imagePath: nil,
            frameX: 100,
            frameY: 100,
            frameWidth: 200,
            frameHeight: 150,
            categoryId: categoryId,
            createdAt: Date()
        )
        stickyNotes.append(note)
        save()
        return note
    }

    func updateStickyNote(_ note: StickyNoteModel) {
        if let idx = stickyNotes.firstIndex(where: { $0.id == note.id }) {
            stickyNotes[idx] = note
            save()
        }
    }

    func deleteStickyNote(id: UUID) {
        stickyNotes.removeAll { $0.id == id }
        save()
    }
}
