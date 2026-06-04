import AppKit
import UniformTypeIdentifiers

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
            var tool = tools[indexPath.item]
            if case .failure(let err) = ToolLauncher.launch(tool) {
                switch err {
                case .appNotFound:
                    let alert = NSAlert()
                    alert.messageText = "未找到 \(tool.name)"
                    alert.informativeText = "是否要在「应用程序」文件夹中查找？"
                    alert.addButton(withTitle: "浏览...")
                    alert.addButton(withTitle: "取消")
                    if alert.runModal() == .alertFirstButtonReturn {
                        let panel = NSOpenPanel()
                        panel.directoryURL = URL(fileURLWithPath: "/Applications")
                        panel.allowsMultipleSelection = false
                        panel.canChooseDirectories = true
                        panel.canChooseFiles = true
                        panel.allowedContentTypes = []
                        panel.message = "选择 .app、可执行文件或文件夹"
                        if panel.runModal() == .OK, let url = panel.url {
                            tool.appPath = url.path
                            tool.detectionStatus = .custom
                            DataStore.shared.updateTool(tool, in: cat.id)
                            self.currentCategory = DataStore.shared.categories.first(where: { $0.id == cat.id })
                            self.collectionView.reloadData()
                        }
                    }
                case .launchFailed(let e):
                    let alert = NSAlert()
                    alert.messageText = "启动失败"
                    alert.informativeText = e.localizedDescription
                    alert.runModal()
                }
            }
        }

        // 右键菜单
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "编辑路径", action: #selector(editToolPath), keyEquivalent: ""))
        menu.addItem(.separator())
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

    @objc func editToolPath() {
        guard let cat = currentCategory else { return }
        let tools = DataStore.shared.tools(for: cat.id)
        guard let indexPath = collectionView.selectionIndexPaths.first,
              indexPath.item < tools.count else { return }
        var tool = tools[indexPath.item]

        let alert = NSAlert()
        alert.messageText = "编辑路径 - \(tool.name)"
        alert.addButton(withTitle: "确定")
        alert.addButton(withTitle: "取消")

        let container = NSView(frame: NSRect(x: 0, y: 0, width: 300, height: 32))
        let pathField = NSTextField(frame: NSRect(x: 0, y: 4, width: 240, height: 24))
        pathField.stringValue = tool.appPath
        let browseBtn = NSButton(frame: NSRect(x: 248, y: 4, width: 52, height: 24))
        browseBtn.title = "选择"
        browseBtn.bezelStyle = .rounded
        browseBtn.target = self
        browseBtn.action = #selector(browsePath(_:))
        objc_setAssociatedObject(browseBtn, AssociatedKeys.pathField, pathField, .OBJC_ASSOCIATION_RETAIN)

        container.addSubview(pathField)
        container.addSubview(browseBtn)
        alert.accessoryView = container
        alert.window.initialFirstResponder = pathField

        guard alert.runModal() == .alertFirstButtonReturn else { return }

        let newPath = pathField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !newPath.isEmpty else {
            let e = NSAlert(); e.messageText = "路径不能为空"; e.runModal(); return
        }

        tool.appPath = newPath
        tool.detectionStatus = .custom
        DataStore.shared.updateTool(tool, in: cat.id)
        currentCategory = DataStore.shared.categories.first(where: { $0.id == cat.id })
        collectionView.reloadData()
    }

    @objc func importTools() {
        guard let cat = currentCategory else { return }

        // Step 1: 弹出导入说明对话框
        let introAlert = NSAlert()
        introAlert.messageText = "批量导入工具路径"

        let instructions = """
        📋 导入格式（每行一个工具）：

          工具名 路径：/Applications/XXX.app
          工具名 路径：/usr/local/bin/xxx

        示例：
          Claude Code 路径：/Users/me/.local/bin/claude
          nmap 路径：/opt/homebrew/bin/nmap
          Burp Suite 路径：/Applications/Burp Suite Professional.app

        💡 快速获取导入列表：
        复制下方提示词，粘贴到您本地的 Claude Code、Hermes 或其他 AI 工具中执行，即可自动生成导入文件：

        ─── 复制以下提示词 ───
        请扫描我电脑上已安装的开发工具和安全工具，检查以下路径：
        /Applications、/opt/homebrew/bin、/usr/local/bin、~/.local/bin、~/go/bin
        列出找到的所有工具，按以下格式输出：
        工具名 路径：完整路径
        每行一个，只输出结果，不要其他说明。
        ─── 提示词结束 ───

        将 AI 输出的内容保存为 .txt 文件，然后点击「继续导入」选择该文件即可。
        """

        introAlert.informativeText = instructions
        introAlert.addButton(withTitle: "继续导入")
        introAlert.addButton(withTitle: "取消")
        introAlert.alertStyle = .informational

        // 使用更宽的窗口以显示完整说明
        introAlert.window.setContentSize(NSSize(width: 520, height: 400))

        guard introAlert.runModal() == .alertFirstButtonReturn else { return }

        // Step 2: 选择 TXT 文件
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.plainText]
        panel.message = "选择工具路径文件（.txt）"
        guard panel.runModal() == .OK, let url = panel.url else { return }

        guard let content = try? String(contentsOf: url, encoding: .utf8) else {
            let e = NSAlert(); e.messageText = "无法读取文件"; e.runModal(); return
        }

        let lines = content.components(separatedBy: .newlines)
        var importCount = 0

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }

            // Format: {工具名} 路径：{path} or {工具名} 路径:{path}
            guard let range = trimmed.range(of: "路径[：:]", options: .regularExpression) else { continue }
            let name = trimmed[trimmed.startIndex..<range.lowerBound]
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let path = trimmed[range.upperBound...]
                .trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty, !path.isEmpty else { continue }

            // Try to find existing tool by name in current category
            var tools = DataStore.shared.tools(for: cat.id)
            if let idx = tools.firstIndex(where: { $0.name == name }) {
                tools[idx].appPath = path
                tools[idx].detectionStatus = .custom
                DataStore.shared.updateTool(tools[idx], in: cat.id)
            } else {
                let tool = Tool(id: UUID(), name: name, appPath: path, detectionStatus: .custom)
                DataStore.shared.addTool(tool, to: cat.id)
            }
            importCount += 1
        }

        currentCategory = DataStore.shared.categories.first(where: { $0.id == cat.id })
        collectionView.reloadData()

        let alert = NSAlert()
        alert.messageText = "成功导入 \(importCount) 个工具路径"
        alert.runModal()
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
