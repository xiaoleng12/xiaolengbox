import AppKit
import Foundation

// MARK: - 数据模型

struct Tool: Codable, Identifiable {
    let id: UUID
    var name: String
    var appPath: String  // .app、可执行文件、或文件夹路径均可
}

struct Category: Codable, Identifiable {
    let id: UUID
    var name: String
    var tools: [Tool]
}

// MARK: - 验证

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

// MARK: - 数据存储

class DataStore {
    static let shared = DataStore()
    var categories: [Category] = []
    var wallpaperPath: String = ""
    var glassMode: String = "glass"  // "glass" = 毛玻璃, "clear" = 清晰
    var glassOpacity: Double = 0.8   // 玻璃程度 0.01-1.0

    private struct StoreData: Codable {
        var categories: [Category]
        var wallpaperPath: String
        var glassMode: String
        var glassOpacity: Double

        // 兼容旧数据文件
        init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            categories = try container.decode([Category].self, forKey: .categories)
            wallpaperPath = try container.decodeIfPresent(String.self, forKey: .wallpaperPath) ?? ""
            glassMode = try container.decodeIfPresent(String.self, forKey: .glassMode) ?? "glass"
            glassOpacity = try container.decodeIfPresent(Double.self, forKey: .glassOpacity) ?? 0.8
        }

        init(categories: [Category], wallpaperPath: String, glassMode: String, glassOpacity: Double) {
            self.categories = categories
            self.wallpaperPath = wallpaperPath
            self.glassMode = glassMode
            self.glassOpacity = glassOpacity
        }

        private enum CodingKeys: String, CodingKey {
            case categories, wallpaperPath, glassMode, glassOpacity
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
        } else {
            // 文件不存在或解码失败：用默认数据初始化，不自动保存（保护用户文件）
            categories = defaultData()
            wallpaperPath = ""
            glassMode = "glass"
            glassOpacity = 0.8
        }
    }

    func save() {
        let store = StoreData(categories: categories, wallpaperPath: wallpaperPath, glassMode: glassMode, glassOpacity: glassOpacity)
        guard let data = try? JSONEncoder().encode(store) else { return }
        try? data.write(to: dataFilePath(), options: .atomic)
    }

    func defaultData() -> [Category] {
        return []
    }

    @discardableResult
    func addCategory(_ name: String) -> Bool {
        guard Validation.isCategoryNameValid(name) else { return false }
        categories.append(Category(id: UUID(), name: name.trimmingCharacters(in: .whitespacesAndNewlines), tools: []))
        save()
        return true
    }

    func deleteCategory(id: UUID) {
        categories.removeAll { $0.id == id }
        save()
    }

    @discardableResult
    func addTool(_ tool: Tool, to categoryId: UUID) -> Bool {
        guard let idx = categories.firstIndex(where: { $0.id == categoryId }) else { return false }
        categories[idx].tools.append(tool)
        save()
        return true
    }

    func deleteTool(id: UUID, from categoryId: UUID) {
        guard let idx = categories.firstIndex(where: { $0.id == categoryId }) else { return }
        categories[idx].tools.removeAll { $0.id == id }
        save()
    }

    func tools(for categoryId: UUID) -> [Tool] {
        categories.first(where: { $0.id == categoryId })?.tools ?? []
    }
}

// MARK: - 启动工具

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
        // 文件夹：用 Finder 打开
        var isDir: ObjCBool = false
        FileManager.default.fileExists(atPath: path, isDirectory: &isDir)
        if isDir.boolValue && !path.hasSuffix(".app") {
            NSWorkspace.shared.open(url)
            return .success(())
        }
        // .app：用 openApplication
        if path.hasSuffix(".app") {
            NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration()) { _, _ in }
            return .success(())
        }
        // 可执行文件：直接 open（让系统决定如何处理）
        NSWorkspace.shared.open(url)
        return .success(())
    }
}

// MARK: - 通知

extension Notification.Name {
    static let wallpaperChanged = Notification.Name("xiaolengbox.wallpaperChanged")
    static let glassModeChanged = Notification.Name("xiaolengbox.glassModeChanged")
}

// MARK: - 颜色

extension NSColor {
    static let tbBackground = NSColor(red: 0.97, green: 0.97, blue: 0.97, alpha: 1.0)
    static let tbSidebar    = NSColor(red: 0.93, green: 0.93, blue: 0.93, alpha: 1.0)
    static let tbAccent     = NSColor(red: 0.20, green: 0.47, blue: 0.95, alpha: 1)
    static let tbText       = NSColor(red: 0.13, green: 0.13, blue: 0.13, alpha: 1)
    static let tbSubtext    = NSColor(red: 0.50, green: 0.50, blue: 0.50, alpha: 1)
}

// MARK: - CategoryListViewController

class CategoryListViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
    var onCategorySelected: ((Category) -> Void)?
    private let tableView = NSTableView()
    private let scrollView = NSScrollView()
    private let dragType = NSPasteboard.PasteboardType("com.xiaolengbox.category.drag")
    private let effectView = NSVisualEffectView()

    override func loadView() {
        let root = NSView()
        root.wantsLayer = true

        effectView.blendingMode = .withinWindow
        effectView.state = .active
        applyGlassStyle()
        effectView.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(effectView)
        NSLayoutConstraint.activate([
            effectView.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            effectView.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            effectView.topAnchor.constraint(equalTo: root.topAnchor),
            effectView.bottomAnchor.constraint(equalTo: root.bottomAnchor),
        ])

        view = root
        buildUI()
        NotificationCenter.default.addObserver(self, selector: #selector(onGlassModeChanged),
                                               name: .glassModeChanged, object: nil)
    }

    private func applyGlassStyle() {
        let store = DataStore.shared
        if store.glassMode == "glass" {
            effectView.isHidden = false
            effectView.material = .hudWindow
            effectView.alphaValue = CGFloat(store.glassOpacity)
        } else {
            // 清晰模式：隐藏毛玻璃，让壁纸直接透出
            effectView.isHidden = true
        }
    }

    @objc private func onGlassModeChanged() {
        applyGlassStyle()
    }

    func buildUI() {
        let col = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("cat"))
        col.isEditable = false
        tableView.addTableColumn(col)
        tableView.headerView = nil
        tableView.backgroundColor = .clear
        tableView.rowHeight = 36
        tableView.delegate = self
        tableView.dataSource = self
        tableView.selectionHighlightStyle = .regular
        tableView.allowsEmptySelection = false

        // 启用拖拽排序
        tableView.registerForDraggedTypes([dragType])
        tableView.setDraggingSourceOperationMask(.move, forLocal: true)

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "删除分类", action: #selector(deleteCategory), keyEquivalent: ""))
        tableView.menu = menu

        scrollView.documentView = tableView
        scrollView.hasVerticalScroller = true
        scrollView.drawsBackground = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    func reload() { tableView.reloadData() }

    func selectFirst() {
        guard !DataStore.shared.categories.isEmpty else { return }
        tableView.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
        onCategorySelected?(DataStore.shared.categories[0])
    }

    @objc func addCategory() {
        let alert = NSAlert()
        alert.messageText = "新建分类"
        alert.addButton(withTitle: "确定")
        alert.addButton(withTitle: "取消")
        let field = NSTextField(frame: NSRect(x: 0, y: 0, width: 240, height: 24))
        field.placeholderString = "分类名称"
        alert.accessoryView = field
        alert.window.initialFirstResponder = field
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        let name = field.stringValue
        guard Validation.isCategoryNameValid(name) else {
            let err = NSAlert(); err.messageText = "分类名称不能为空"; err.runModal(); return
        }
        DataStore.shared.addCategory(name)
        tableView.reloadData()
        let row = DataStore.shared.categories.count - 1
        tableView.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
        onCategorySelected?(DataStore.shared.categories[row])
    }

    @objc private func deleteCategory() {
        let row = tableView.clickedRow >= 0 ? tableView.clickedRow : tableView.selectedRow
        guard row >= 0, row < DataStore.shared.categories.count else { return }
        let cat = DataStore.shared.categories[row]
        let alert = NSAlert()
        alert.messageText = "删除分类「\(cat.name)」？"
        alert.informativeText = "该分类下的所有工具也会被删除。"
        alert.addButton(withTitle: "删除")
        alert.addButton(withTitle: "取消")
        alert.buttons[0].hasDestructiveAction = true
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        DataStore.shared.deleteCategory(id: cat.id)
        tableView.reloadData()
        let newRow = min(row, DataStore.shared.categories.count - 1)
        if newRow >= 0 {
            tableView.selectRowIndexes(IndexSet(integer: newRow), byExtendingSelection: false)
            onCategorySelected?(DataStore.shared.categories[newRow])
        }
    }

    // MARK: NSTableViewDataSource
    func numberOfRows(in tableView: NSTableView) -> Int { DataStore.shared.categories.count }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cat = DataStore.shared.categories[row]
        let cell = NSTextField(labelWithString: cat.name)
        cell.font = .systemFont(ofSize: 14)
        cell.textColor = .tbText
        cell.translatesAutoresizingMaskIntoConstraints = false
        let container = NSView()
        container.addSubview(cell)
        NSLayoutConstraint.activate([
            cell.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            cell.centerYAnchor.constraint(equalTo: container.centerYAnchor),
        ])
        return container
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        let row = tableView.selectedRow
        guard row >= 0, row < DataStore.shared.categories.count else { return }
        onCategorySelected?(DataStore.shared.categories[row])
    }

    // MARK: 拖拽排序
    func tableView(_ tableView: NSTableView, pasteboardWriterForRow row: Int) -> NSPasteboardWriting? {
        let item = NSPasteboardItem()
        item.setString(String(row), forType: dragType)
        return item
    }

    func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo,
                   proposedRow row: Int, proposedDropOperation op: NSTableView.DropOperation) -> NSDragOperation {
        if op == .above { return .move }
        return []
    }

    func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo,
                   row: Int, dropOperation: NSTableView.DropOperation) -> Bool {
        guard let str = info.draggingPasteboard.string(forType: dragType),
              let fromRow = Int(str) else { return false }
        let toRow = row > fromRow ? row - 1 : row
        guard fromRow != toRow else { return false }

        tableView.beginUpdates()
        var cats = DataStore.shared.categories
        let moved = cats.remove(at: fromRow)
        cats.insert(moved, at: toRow)
        DataStore.shared.categories = cats
        DataStore.shared.save()
        tableView.moveRow(at: fromRow, to: toRow)
        tableView.endUpdates()

        tableView.selectRowIndexes(IndexSet(integer: toRow), byExtendingSelection: false)
        onCategorySelected?(DataStore.shared.categories[toRow])
        return true
    }
}

// MARK: - ToolItemView (NSCollectionViewItem)

class ToolItemView: NSCollectionViewItem {
    static let identifier = NSUserInterfaceItemIdentifier("ToolItem")

    private let iconView = NSImageView()
    private let nameLabel = NSTextField(labelWithString: "")
    private let cardEffect = NSVisualEffectView()

    override func loadView() {
        let root = NSView()
        root.wantsLayer = true
        root.layer?.cornerRadius = 10
        root.layer?.masksToBounds = true

        cardEffect.blendingMode = .withinWindow
        cardEffect.state = .active
        cardEffect.material = DataStore.shared.glassMode == "glass" ? .popover : .windowBackground
        cardEffect.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(cardEffect)
        NSLayoutConstraint.activate([
            cardEffect.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            cardEffect.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            cardEffect.topAnchor.constraint(equalTo: root.topAnchor),
            cardEffect.bottomAnchor.constraint(equalTo: root.bottomAnchor),
        ])

        iconView.imageScaling = .scaleProportionallyUpOrDown
        iconView.translatesAutoresizingMaskIntoConstraints = false

        nameLabel.font = .systemFont(ofSize: 12)
        nameLabel.textColor = .tbText
        nameLabel.alignment = .center
        nameLabel.lineBreakMode = .byTruncatingTail
        nameLabel.translatesAutoresizingMaskIntoConstraints = false

        root.addSubview(iconView)
        root.addSubview(nameLabel)
        NSLayoutConstraint.activate([
            iconView.topAnchor.constraint(equalTo: root.topAnchor, constant: 12),
            iconView.centerXAnchor.constraint(equalTo: root.centerXAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 52),
            iconView.heightAnchor.constraint(equalToConstant: 52),
            nameLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 6),
            nameLabel.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 4),
            nameLabel.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -4),
        ])

        view = root
    }

    func configure(with tool: Tool) {
        nameLabel.stringValue = tool.name
        // 文件夹用系统文件夹图标，其他用文件图标
        var isDir: ObjCBool = false
        FileManager.default.fileExists(atPath: tool.appPath, isDirectory: &isDir)
        if isDir.boolValue && !tool.appPath.hasSuffix(".app") {
            iconView.image = NSWorkspace.shared.icon(for: .folder)
        } else {
            iconView.image = NSWorkspace.shared.icon(forFile: tool.appPath)
        }
        applyCardStyle()
    }

    private func applyCardStyle() {
        let isGlass = DataStore.shared.glassMode == "glass"
        if isGlass {
            cardEffect.isHidden = false
            cardEffect.material = isSelected ? .selection : .popover
            cardEffect.blendingMode = .withinWindow
        } else {
            // 清晰模式：卡片透明，只保留选中高亮
            if isSelected {
                cardEffect.isHidden = false
                cardEffect.material = .selection
                cardEffect.blendingMode = .withinWindow
            } else {
                cardEffect.isHidden = true
            }
        }
    }

    override var isSelected: Bool {
        didSet {
            applyCardStyle()
        }
    }
}

// MARK: - ToolListViewController

class ToolListViewController: NSViewController,
    NSCollectionViewDataSource, NSCollectionViewDelegate {

    var currentCategory: Category?
    private let collectionView = DoubleClickCollectionView()
    private let scrollView = NSScrollView()
    private let effectView = NSVisualEffectView()
    var glassBtn: NSButton?
    var opacitySlider: NSSlider?
    var opacityPctLabel: NSTextField?

    override func loadView() {
        let root = NSView()
        root.wantsLayer = true

        effectView.blendingMode = .withinWindow
        effectView.state = .active
        applyGlassStyle()
        effectView.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(effectView)
        NSLayoutConstraint.activate([
            effectView.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            effectView.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            effectView.topAnchor.constraint(equalTo: root.topAnchor),
            effectView.bottomAnchor.constraint(equalTo: root.bottomAnchor),
        ])

        view = root
        buildUI()
        NotificationCenter.default.addObserver(self, selector: #selector(onGlassModeChanged),
                                               name: .glassModeChanged, object: nil)
    }

    private func applyGlassStyle() {
        let store = DataStore.shared
        if store.glassMode == "glass" {
            effectView.isHidden = false
            effectView.material = .hudWindow
            effectView.alphaValue = CGFloat(store.glassOpacity)
        } else {
            // 清晰模式：隐藏毛玻璃，让壁纸直接透出
            effectView.isHidden = true
        }
    }

    @objc private func onGlassModeChanged() {
        applyGlassStyle()
        updateOpacityUI()
        collectionView.reloadData()
    }

    private func updateOpacityUI() {
        let isGlass = DataStore.shared.glassMode == "glass"
        opacitySlider?.superview?.isHidden = !isGlass  // opStack
        glassBtn?.title = isGlass ? "✦ 玻璃" : "◻ 清晰"
    }

    private func buildUI() {
        // 网格布局
        let layout = NSCollectionViewFlowLayout()
        layout.itemSize = NSSize(width: 90, height: 90)
        layout.minimumInteritemSpacing = 12
        layout.minimumLineSpacing = 12
        layout.sectionInset = NSEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)

        collectionView.collectionViewLayout = layout
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.backgroundColors = [.clear]
        collectionView.isSelectable = true
        collectionView.allowsEmptySelection = true
        collectionView.register(ToolItemView.self, forItemWithIdentifier: ToolItemView.identifier)

        // 双击回调
        collectionView.onDoubleClick = { [weak self] indexPath in
            guard let self, let cat = self.currentCategory else { return }
            let tools = DataStore.shared.tools(for: cat.id)
            guard indexPath.item < tools.count else { return }
            let tool = tools[indexPath.item]
            if case .failure(let err) = ToolLauncher.launch(tool) {
                let alert = NSAlert()
                alert.messageText = "启动失败"
                switch err {
                case .appNotFound(let p): alert.informativeText = "找不到：\(p)"
                case .launchFailed(let e): alert.informativeText = e.localizedDescription
                }
                alert.runModal()
            }
        }

        // 右键菜单
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "删除工具", action: #selector(deleteTool), keyEquivalent: ""))
        collectionView.menu = menu

        scrollView.documentView = collectionView
        scrollView.hasVerticalScroller = true
        scrollView.drawsBackground = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    func reload(for category: Category) {
        currentCategory = category
        collectionView.reloadData()
    }

    @objc func addTool() {
        guard let cat = currentCategory else { return }

        let alert = NSAlert()
        alert.messageText = "添加工具"
        alert.addButton(withTitle: "确定")
        alert.addButton(withTitle: "取消")

        let container = NSView(frame: NSRect(x: 0, y: 0, width: 300, height: 64))
        let nameField = NSTextField(frame: NSRect(x: 0, y: 36, width: 300, height: 24))
        nameField.placeholderString = "工具名称"
        let pathField = NSTextField(frame: NSRect(x: 0, y: 4, width: 240, height: 24))
        pathField.placeholderString = "路径（.app、可执行文件、文件夹）"
        let browseBtn = NSButton(frame: NSRect(x: 248, y: 4, width: 52, height: 24))
        browseBtn.title = "选择"
        browseBtn.bezelStyle = .rounded
        browseBtn.target = self
        browseBtn.action = #selector(browsePath(_:))
        browseBtn.tag = 0
        objc_setAssociatedObject(browseBtn, AssociatedKeys.pathField, pathField, .OBJC_ASSOCIATION_RETAIN)

        container.addSubview(nameField)
        container.addSubview(pathField)
        container.addSubview(browseBtn)
        alert.accessoryView = container
        alert.window.initialFirstResponder = nameField

        guard alert.runModal() == .alertFirstButtonReturn else { return }

        let name = nameField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        let path = pathField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)

        guard Validation.isToolNameValid(name) else {
            let e = NSAlert(); e.messageText = "工具名称不能为空"; e.runModal(); return
        }
        guard Validation.isAppPathValid(path) else {
            let e = NSAlert(); e.messageText = "路径无效，请选择存在的 .app、可执行文件或文件夹"; e.runModal(); return
        }

        let tool = Tool(id: UUID(), name: name, appPath: path)
        DataStore.shared.addTool(tool, to: cat.id)
        currentCategory = DataStore.shared.categories.first(where: { $0.id == cat.id })
        collectionView.reloadData()
    }

    @objc private func browsePath(_ sender: NSButton) {
        let pathField = objc_getAssociatedObject(sender, AssociatedKeys.pathField) as? NSTextField
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = true
        panel.allowedContentTypes = []
        panel.message = "选择 .app、可执行文件或文件夹"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        pathField?.stringValue = url.path
    }

    @objc private func deleteTool() {
        guard let cat = currentCategory else { return }
        let tools = DataStore.shared.tools(for: cat.id)
        guard let indexPath = collectionView.selectionIndexPaths.first,
              indexPath.item < tools.count else { return }
        let tool = tools[indexPath.item]
        let alert = NSAlert()
        alert.messageText = "删除工具「\(tool.name)」？"
        alert.addButton(withTitle: "删除")
        alert.addButton(withTitle: "取消")
        alert.buttons[0].hasDestructiveAction = true
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        DataStore.shared.deleteTool(id: tool.id, from: cat.id)
        currentCategory = DataStore.shared.categories.first(where: { $0.id == cat.id })
        collectionView.reloadData()
    }

    @objc func changeWallpaper() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [.jpeg, .png, .heic, .tiff, .bmp]
        panel.message = "选择工具箱背景图片"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        DataStore.shared.wallpaperPath = url.path
        DataStore.shared.save()
        NotificationCenter.default.post(name: .wallpaperChanged, object: url.path)
    }

    @objc func clearWallpaper() {
        DataStore.shared.wallpaperPath = ""
        DataStore.shared.save()
        NotificationCenter.default.post(name: .wallpaperChanged, object: nil)
    }

    @objc func toggleGlassMode() {
        let isGlass = DataStore.shared.glassMode == "glass"
        DataStore.shared.glassMode = isGlass ? "clear" : "glass"
        DataStore.shared.save()
        glassBtn?.title = DataStore.shared.glassMode == "glass" ? "✦ 玻璃" : "◻ 清晰"
        NotificationCenter.default.post(name: .glassModeChanged, object: nil)
    }

    @objc func opacityChanged(_ sender: NSSlider) {
        let val = Double(sender.floatValue)
        DataStore.shared.glassOpacity = val
        DataStore.shared.save()
        opacityPctLabel?.stringValue = "\(Int(val * 100))%"
        // 实时更新玻璃效果
        effectView.alphaValue = CGFloat(val)
    }

    // MARK: NSCollectionViewDataSource
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let cat = currentCategory else { return 0 }
        return DataStore.shared.tools(for: cat.id).count
    }

    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = collectionView.makeItem(withIdentifier: ToolItemView.identifier, for: indexPath) as! ToolItemView
        if let cat = currentCategory {
            let tools = DataStore.shared.tools(for: cat.id)
            if indexPath.item < tools.count {
                item.configure(with: tools[indexPath.item])
            }
        }
        return item
    }

    // 双击启动
    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        // 单击选中，双击通过 mouseDown 处理
    }
}

private enum AssociatedKeys {
    static let pathField = UnsafeRawPointer(bitPattern: "pathField".hashValue)!
}

// 双击支持：用自定义 CollectionView 子类捕获双击
class DoubleClickCollectionView: NSCollectionView {
    var onDoubleClick: ((IndexPath) -> Void)?
    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        if event.clickCount == 2 {
            let point = convert(event.locationInWindow, from: nil)
            if let indexPath = indexPathForItem(at: point) {
                onDoubleClick?(indexPath)
            }
        }
    }
}

// MARK: - MainWindowController

class MainWindowController: NSWindowController {
    private let categoryVC = CategoryListViewController()
    private let toolVC = ToolListViewController()
    private var bgImageView: NSImageView?

    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 860, height: 580),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered, defer: false
        )
        window.title = "小冷工具箱"
        window.minSize = NSSize(width: 600, height: 400)
        window.center()
        self.init(window: window)
        setupSplitView()
        setupWallpaper()
        NotificationCenter.default.addObserver(self, selector: #selector(onWallpaperChanged(_:)),
                                               name: .wallpaperChanged, object: nil)
    }

    private func setupSplitView() {
        let split = NSSplitView()
        split.isVertical = true
        split.dividerStyle = .thin

        split.addArrangedSubview(categoryVC.view)
        split.addArrangedSubview(toolVC.view)
        split.setHoldingPriority(.defaultLow, forSubviewAt: 0)
        split.setHoldingPriority(.defaultLow + 1, forSubviewAt: 1)

        categoryVC.onCategorySelected = { [weak self] cat in
            self?.toolVC.reload(for: cat)
        }

        // 统一顶部栏
        let topBar = NSView()
        topBar.translatesAutoresizingMaskIntoConstraints = false
        topBar.wantsLayer = true
        topBar.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.35).cgColor

        // 左侧：分类 + ＋
        let catLabel = NSTextField(labelWithString: "分类")
        catLabel.font = .boldSystemFont(ofSize: 13)
        catLabel.textColor = .white
        catLabel.translatesAutoresizingMaskIntoConstraints = false

        let addCatBtn = NSButton(title: "＋", target: categoryVC, action: #selector(CategoryListViewController.addCategory))
        addCatBtn.bezelStyle = .inline
        addCatBtn.isBordered = false
        addCatBtn.font = .systemFont(ofSize: 18)
        addCatBtn.contentTintColor = NSColor(red: 0.35, green: 0.70, blue: 1.0, alpha: 1)
        addCatBtn.translatesAutoresizingMaskIntoConstraints = false

        // 右侧：工具列表 + 功能按钮
        let toolLabel = NSTextField(labelWithString: "工具列表")
        toolLabel.font = .boldSystemFont(ofSize: 13)
        toolLabel.textColor = .white
        toolLabel.translatesAutoresizingMaskIntoConstraints = false

        let addToolBtn = NSButton(title: "＋ 添加工具", target: toolVC, action: #selector(ToolListViewController.addTool))
        addToolBtn.bezelStyle = .rounded
        addToolBtn.translatesAutoresizingMaskIntoConstraints = false

        let wallpaperBtn = NSButton(title: "  壁纸", target: toolVC, action: #selector(ToolListViewController.changeWallpaper))
        wallpaperBtn.bezelStyle = .rounded
        wallpaperBtn.translatesAutoresizingMaskIntoConstraints = false

        let clearWallBtn = NSButton(title: "✕ 清除", target: toolVC, action: #selector(ToolListViewController.clearWallpaper))
        clearWallBtn.bezelStyle = .rounded
        clearWallBtn.translatesAutoresizingMaskIntoConstraints = false

        let isGlass = DataStore.shared.glassMode == "glass"
        let glassBtn = NSButton(title: isGlass ? "  玻璃" : "◻ 清晰", target: toolVC, action: #selector(ToolListViewController.toggleGlassMode))
        glassBtn.bezelStyle = .rounded
        glassBtn.translatesAutoresizingMaskIntoConstraints = false
        toolVC.glassBtn = glassBtn

        let opLabel = NSTextField(labelWithString: "玻璃:")
        opLabel.font = .systemFont(ofSize: 11)
        opLabel.textColor = .white.withAlphaComponent(0.7)
        opLabel.translatesAutoresizingMaskIntoConstraints = false

        let slider = NSSlider(value: DataStore.shared.glassOpacity, minValue: 0.01, maxValue: 1.0,
                              target: toolVC, action: #selector(ToolListViewController.opacityChanged(_:)))
        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.widthAnchor.constraint(equalToConstant: 80).isActive = true
        toolVC.opacitySlider = slider

        let pctLabel = NSTextField(labelWithString: "\(Int(DataStore.shared.glassOpacity * 100))%")
        pctLabel.font = .monospacedDigitSystemFont(ofSize: 11, weight: .regular)
        pctLabel.textColor = .white.withAlphaComponent(0.7)
        pctLabel.translatesAutoresizingMaskIntoConstraints = false
        pctLabel.widthAnchor.constraint(equalToConstant: 32).isActive = true
        toolVC.opacityPctLabel = pctLabel

        let opStack = NSStackView(views: [opLabel, slider, pctLabel])
        opStack.orientation = .horizontal
        opStack.spacing = 4
        opStack.translatesAutoresizingMaskIntoConstraints = false
        opStack.isHidden = !isGlass

        let btnStack = NSStackView(views: [glassBtn, opStack, clearWallBtn, wallpaperBtn, addToolBtn])
        btnStack.orientation = .horizontal
        btnStack.spacing = 8
        btnStack.translatesAutoresizingMaskIntoConstraints = false

        topBar.addSubview(catLabel)
        topBar.addSubview(addCatBtn)
        topBar.addSubview(toolLabel)
        topBar.addSubview(btnStack)
        NSLayoutConstraint.activate([
            topBar.heightAnchor.constraint(equalToConstant: 44),
            catLabel.leadingAnchor.constraint(equalTo: topBar.leadingAnchor, constant: 16),
            catLabel.centerYAnchor.constraint(equalTo: topBar.centerYAnchor),
            addCatBtn.leadingAnchor.constraint(equalTo: catLabel.trailingAnchor, constant: 4),
            addCatBtn.centerYAnchor.constraint(equalTo: topBar.centerYAnchor),
            toolLabel.leadingAnchor.constraint(equalTo: topBar.centerXAnchor, constant: 8),
            toolLabel.centerYAnchor.constraint(equalTo: topBar.centerYAnchor),
            btnStack.trailingAnchor.constraint(equalTo: topBar.trailingAnchor, constant: -16),
            btnStack.centerYAnchor.constraint(equalTo: topBar.centerYAnchor),
            btnStack.leadingAnchor.constraint(greaterThanOrEqualTo: toolLabel.trailingAnchor, constant: 8),
        ])

        // 背景图层 + topBar + split 叠加
        let container = NSView()
        let imgView = NSImageView()
        imgView.imageScaling = .scaleProportionallyUpOrDown
        imgView.layer?.contentsGravity = .resizeAspectFill
        imgView.translatesAutoresizingMaskIntoConstraints = false
        split.translatesAutoresizingMaskIntoConstraints = false
        topBar.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(imgView)
        container.addSubview(topBar)
        container.addSubview(split)
        NSLayoutConstraint.activate([
            imgView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            imgView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            imgView.topAnchor.constraint(equalTo: container.topAnchor),
            imgView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            topBar.topAnchor.constraint(equalTo: container.topAnchor),
            topBar.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            topBar.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            split.topAnchor.constraint(equalTo: topBar.bottomAnchor),
            split.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            split.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            split.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])
        bgImageView = imgView
        window?.contentView = container

        // 窗口显示后设置分类栏宽度为总宽度的 20%
        DispatchQueue.main.async {
            let totalWidth = split.frame.width
            split.setPosition(totalWidth * 0.2, ofDividerAt: 0)
        }
    }

    // 窗口大小变化时保持 20/80 比例
    private var splitView: NSSplitView?

    private func setupWallpaper() {
        let path = DataStore.shared.wallpaperPath
        guard !path.isEmpty, let img = NSImage(contentsOfFile: path) else { return }
        bgImageView?.image = img
    }

    @objc private func onWallpaperChanged(_ note: Notification) {
        if let path = note.object as? String,
           let img = NSImage(contentsOfFile: path) {
            bgImageView?.image = img
        } else {
            bgImageView?.image = nil
        }
    }

    func selectFirstCategory() {
        categoryVC.selectFirst()
    }
}

// MARK: - AppDelegate

class AppDelegate: NSObject, NSApplicationDelegate {
    var windowController: MainWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        DataStore.shared.load()
        windowController = MainWindowController()
        windowController?.showWindow(nil)
        windowController?.selectFirstCategory()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}

// MARK: - 入口

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.regular)
app.activate(ignoringOtherApps: true)
app.run()
