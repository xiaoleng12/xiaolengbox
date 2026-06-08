import Foundation

class DataStore {
    nonisolated(unsafe) static let shared = DataStore()
    var categories: [Category] = []
    var wallpaperPath: String = ""
    var glassMode: String = "glass"
    var glassOpacity: Double = 0.8
    var stickyNotes: [StickyNoteModel] = []
    var terminalWindowFrame: String?

    // AI integration settings
    var aiBaseUrl: String = ""
    var aiApiKey: String = ""
    var aiModel: String = "gpt-4o"
    var aiProvider: String = ""

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
            aiBaseUrl = decoded.aiBaseUrl ?? ""
            aiApiKey = decoded.aiApiKey ?? ""
            aiModel = decoded.aiModel ?? "gpt-4o"
            aiProvider = decoded.aiProvider ?? ""
        } else {
            categories = []
            wallpaperPath = ""
            glassMode = "glass"
            glassOpacity = 0.8
            stickyNotes = []
            terminalWindowFrame = nil
            aiBaseUrl = ""
            aiApiKey = ""
            aiModel = "gpt-4o"
            aiProvider = ""
        }
    }

    func save() {
        let store = StoreData(categories: categories, wallpaperPath: wallpaperPath, glassMode: glassMode, glassOpacity: glassOpacity, stickyNotes: stickyNotes, terminalWindowFrame: terminalWindowFrame, aiBaseUrl: aiBaseUrl, aiApiKey: aiApiKey, aiModel: aiModel, aiProvider: aiProvider)
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

    // MARK: - AI Context Generation

    /// Generates a text description of the current toolbox state for AI system prompts.
    func generateToolboxContext() -> String {
        var lines: [String] = []
        lines.append("=== 小冷工具箱 当前状态 ===")
        lines.append("")

        for cat in categories where cat.type == "normal" {
            lines.append("【\(cat.name)】")
            let tools = cat.tools
            if tools.isEmpty {
                lines.append("  (空)")
            } else {
                for tool in tools {
                    let status: String
                    switch tool.detectionStatus {
                    case .detected: status = "✓ 已检测"
                    case .custom:   status = "✓ 自定义路径"
                    case .notFound: status = "✗ 未安装"
                    case .detecting: status = "… 检测中"
                    }
                    let pathInfo = tool.appPath.isEmpty ? "" : " → \(tool.appPath)"
                    let hint = tool.customInstallHint ?? tool.presetId.flatMap { PresetCatalog.findPresetTool(id: $0)?.installHint } ?? ""
                    lines.append("  - \(tool.name) [\(status)]\(pathInfo)")
                    if !hint.isEmpty { lines.append("    安装提示: \(hint)") }
                }
            }
            lines.append("")
        }

        lines.append("=== 批量导入格式 ===")
        lines.append("工具名 路径：/完整/路径/到/工具")
        lines.append("示例：hydra 路径：/opt/homebrew/bin/hydra")
        lines.append("")
        lines.append("=== 可用预置工具（可建议用户安装的） ===")
        let allPresetIds = Set(categories.flatMap { $0.tools.compactMap { $0.presetId } })
        for preset in PresetCatalog.allPresetCategories where preset.type == "normal" {
            for tool in preset.tools where !tool.id.hasPrefix("demo-") {
                if !allPresetIds.contains(tool.id) {
                    lines.append("  - \(tool.name): \(tool.installHint)")
                }
            }
        }

        return lines.joined(separator: "\n")
    }

    /// Generates CLI help text: data file path, JSON structure, and example commands.
    func generateCLIHelp() -> String {
        return """

        === 命令行操作指南 ===

        数据文件位于可执行文件同级目录下，文件名为 xiaolengbox_data.json。
        用户需要自行确认可执行文件的实际位置，数据文件就在它旁边。
        以下示例用 $DATA_FILE 代替数据文件的实际路径，用户需替换为自己的路径。

        数据格式为 JSON，结构如下：
        {
          "categories": [
            {
              "id": "UUID",
              "name": "分类名称",
              "type": "normal",          // normal=应用工具, pdf=PDF文档, md=Markdown, sticky=便签
              "metadata": null,           // pdf/md类型时为文件路径
              "tools": [
                {
                  "id": "UUID",
                  "name": "工具名",
                  "appPath": "/path/to/app",
                  "detectionStatus": "custom",
                  "presetId": null,
                  "customInstallHint": null
                }
              ]
            }
          ]
        }

        常用操作（需先关闭工具箱，改完后重新打开）：

        1. 查看所有分类：
        jq '.categories[] | {name, type}' "$DATA_FILE"

        2. 添加一个应用分类：
        jq '.categories += [{"id":(now|tostring|sha1), "name":"新分类", "type":"normal", "tools":[], "isPreset":false}]' "$DATA_FILE" > tmp.json && mv tmp.json "$DATA_FILE"

        3. 向分类添加工具（替换分类名和路径）：
        jq '(.categories[] | select(.name=="分类名") | .tools) += [{"id":(now|tostring|sha1), "name":"工具名", "appPath":"/usr/local/bin/tool", "detectionStatus":"custom"}]' "$DATA_FILE" > tmp.json && mv tmp.json "$DATA_FILE"

        4. 添加 PDF 分类（metadata 为文件路径）：
        jq '.categories += [{"id":(now|tostring|sha1), "name":"我的PDF", "type":"pdf", "metadata":"/path/to/file.pdf", "tools":[], "isPreset":false}]' "$DATA_FILE" > tmp.json && mv tmp.json "$DATA_FILE"

        5. 添加 Markdown 分类：
        jq '.categories += [{"id":(now|tostring|sha1), "name":"我的文档", "type":"md", "metadata":"/path/to/file.md", "tools":[], "isPreset":false}]' "$DATA_FILE" > tmp.json && mv tmp.json "$DATA_FILE"

        6. 添加便签分类：
        jq '.categories += [{"id":(now|tostring|sha1), "name":"我的便签", "type":"sticky", "tools":[], "isPreset":false}]' "$DATA_FILE" > tmp.json && mv tmp.json "$DATA_FILE"

        7. 用 Python 添加（更易读）：
        python3 -c "
        import json, uuid
        path = '替换为数据文件路径'
        with open(path) as f: data = json.load(f)
        data['categories'].append({
            'id': str(uuid.uuid4()), 'name': '新分类', 'type': 'normal',
            'tools': [], 'isPreset': False, 'presetIcon': None, 'metadata': None
        })
        with open(path, 'w') as f: json.dump(data, f, ensure_ascii=False, indent=2)
        "

        重要：回答用户时，请告诉用户先找到小冷工具箱.app 的位置，
        数据文件在 小冷工具箱.app/Contents/MacOS/xiaolengbox_data.json。
        修改前请先备份，修改后需重启工具箱生效。
        """
    }
}
