import AppKit
import UniformTypeIdentifiers

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
        tableView.allowsEmptySelection = true
        tableView.allowsMultipleSelection = true

        // 启用拖拽排序
        tableView.registerForDraggedTypes([dragType])
        tableView.setDraggingSourceOperationMask(.move, forLocal: true)

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "删除分类", action: #selector(deleteCategory), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "批量删除选中分类", action: #selector(deleteSelectedCategories), keyEquivalent: ""))
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

        let customView = NSView(frame: NSRect(x: 0, y: 0, width: 240, height: 60))
        let field = NSTextField(frame: NSRect(x: 0, y: 32, width: 240, height: 24))
        field.placeholderString = "分类名称"

        let typePopup = NSPopUpButton(frame: NSRect(x: 0, y: 0, width: 240, height: 24), pullsDown: false)
        typePopup.addItems(withTitles: ["普通工具", "便签", "PDF 阅读器", "Markdown 笔记"])

        customView.addSubview(field)
        customView.addSubview(typePopup)
        alert.accessoryView = customView
        alert.window.initialFirstResponder = field

        guard alert.runModal() == .alertFirstButtonReturn else { return }

        var name = field.stringValue
        let typeIndex = typePopup.indexOfSelectedItem
        let typeString = typeIndex == 1 ? "sticky" : (typeIndex == 2 ? "pdf" : (typeIndex == 3 ? "md" : "normal"))
        var metadata: String? = nil

        if typeString == "pdf" || typeString == "md" {
            let panel = NSOpenPanel()
            panel.allowsMultipleSelection = false
            panel.canChooseDirectories = false
            if typeString == "pdf" {
                panel.allowedContentTypes = [.pdf]
                panel.message = "选择要绑定的 PDF 文件"
            } else {
                let mdType = UTType(filenameExtension: "md") ?? .plainText
                let markdownType = UTType(filenameExtension: "markdown") ?? .plainText
                panel.allowedContentTypes = [mdType, markdownType]
                panel.message = "选择要绑定的 Markdown 文件"
            }

            guard panel.runModal() == .OK, let url = panel.url else { return }
            metadata = url.path
            if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                name = url.deletingPathExtension().lastPathComponent
            }
        }

        guard Validation.isCategoryNameValid(name) else {
            let err = NSAlert(); err.messageText = "分类名称不能为空"; err.runModal(); return
        }

        DataStore.shared.addCategory(name, type: typeString, metadata: metadata)
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
        tableView.deselectAll(nil)
    }

    @objc func deleteSelectedCategories() {
        let selected = tableView.selectedRowIndexes
        guard !selected.isEmpty else { return }
        let cats = selected.map { DataStore.shared.categories[$0] }
        let names = cats.map { "「\($0.name)」" }.joined(separator: "、")
        let alert = NSAlert()
        alert.messageText = "批量删除分类"
        alert.informativeText = "将删除 \(selected.count) 个分类：\(names)\n这些分类下的所有工具也会被删除。"
        alert.addButton(withTitle: "删除")
        alert.addButton(withTitle: "取消")
        alert.buttons[0].hasDestructiveAction = true
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        for cat in cats {
            DataStore.shared.deleteCategory(id: cat.id)
        }
        tableView.reloadData()
        tableView.deselectAll(nil)
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
        // 只在单选时触发导航，多选时不跳转
        guard tableView.selectedRowIndexes.count == 1 else { return }
        let row = tableView.selectedRowIndexes.first!
        guard row < DataStore.shared.categories.count else { return }
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
