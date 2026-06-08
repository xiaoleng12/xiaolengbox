import AppKit

class MainWindowController: NSWindowController {
    private let categoryVC = CategoryListViewController()
    private let toolVC = ToolListViewController()
    private let stickyNotesCanvas = StickyNotesCanvasView()
    private let pdfPanel = PDFViewerPanel()
    private let pdfOutlineView = PDFOutlineListView()
    private var mdPanel = MDViewerPanel()
    private let mdOutlineView = MDOutlineListView()
    private let aiPanel = AIChatPanel()

    private let leftContainer = NSView()
    private let pdfOutlineContainer = NSView()
    private let mdOutlineContainer = NSView()
    private let rightContainer = NSView()
    private var bgImageView: NSImageView?
    private var floatingTerminal: FloatingTerminalWindowController?
    private var terminalBtn: NSButton?
    private var currentViewType: String = ""  // 跟踪当前显示的视图类型
    private var activeMDPanelID = UUID()

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

        // PDF outline integration
        pdfPanel.onPDFLoaded = { [weak self] doc in
            self?.pdfOutlineView.loadOutline(from: doc)
        }
        pdfOutlineView.onOutlineItemSelected = { [weak self] page in
            self?.pdfPanel.goTo(page: page)
        }

        // MD outline integration
        configureMDPanel(mdPanel, id: activeMDPanelID)
        mdOutlineView.onOutlineItemSelected = { [weak self] item in
            self?.mdPanel.goTo(item: item)
        }
    }

    private func configureMDPanel(_ panel: MDViewerPanel, id: UUID) {
        panel.onMDLoaded = { [weak self] items in
            guard let self = self, self.activeMDPanelID == id else { return }
            self.mdOutlineView.loadOutline(items: items)
        }
    }

    private func attachRightView(_ targetView: NSView) {
        rightContainer.subviews.forEach { $0.removeFromSuperview() }
        rightContainer.addSubview(targetView)
        NSLayoutConstraint.activate([
            targetView.topAnchor.constraint(equalTo: rightContainer.topAnchor),
            targetView.leadingAnchor.constraint(equalTo: rightContainer.leadingAnchor),
            targetView.trailingAnchor.constraint(equalTo: rightContainer.trailingAnchor),
            targetView.bottomAnchor.constraint(equalTo: rightContainer.bottomAnchor),
        ])
    }

    private func showMarkdownCategory(_ cat: Category) {
        currentViewType = "md"
        showMDOutline()
        mdOutlineView.loadOutline(items: [])

        let panel = MDViewerPanel()
        let panelID = UUID()
        activeMDPanelID = panelID
        panel.translatesAutoresizingMaskIntoConstraints = false
        configureMDPanel(panel, id: panelID)
        mdPanel = panel
        attachRightView(panel)

        if let path = cat.metadata {
            panel.loadMD(from: URL(fileURLWithPath: path))
        }
    }

    private func setupSplitView() {
        let split = NSSplitView()
        split.isVertical = true
        split.dividerStyle = .thin

        leftContainer.translatesAutoresizingMaskIntoConstraints = false
        rightContainer.translatesAutoresizingMaskIntoConstraints = false

        // Setup left container default view
        categoryVC.view.translatesAutoresizingMaskIntoConstraints = false
        leftContainer.addSubview(categoryVC.view)
        NSLayoutConstraint.activate([
            categoryVC.view.topAnchor.constraint(equalTo: leftContainer.topAnchor),
            categoryVC.view.leadingAnchor.constraint(equalTo: leftContainer.leadingAnchor),
            categoryVC.view.trailingAnchor.constraint(equalTo: leftContainer.trailingAnchor),
            categoryVC.view.bottomAnchor.constraint(equalTo: leftContainer.bottomAnchor),
        ])

        // Setup PDF Outline Container
        pdfOutlineContainer.translatesAutoresizingMaskIntoConstraints = false
        pdfOutlineContainer.isHidden = true
        
        let pdfBackBtn = NSButton(title: "◀ 返回", target: self, action: #selector(showCategoryList))
        pdfBackBtn.bezelStyle = .rounded
        pdfBackBtn.translatesAutoresizingMaskIntoConstraints = false
        
        pdfOutlineView.translatesAutoresizingMaskIntoConstraints = false
        
        pdfOutlineContainer.addSubview(pdfBackBtn)
        pdfOutlineContainer.addSubview(pdfOutlineView)
        NSLayoutConstraint.activate([
            pdfBackBtn.topAnchor.constraint(equalTo: pdfOutlineContainer.topAnchor, constant: 8),
            pdfBackBtn.leadingAnchor.constraint(equalTo: pdfOutlineContainer.leadingAnchor, constant: 8),
            
            pdfOutlineView.topAnchor.constraint(equalTo: pdfBackBtn.bottomAnchor, constant: 8),
            pdfOutlineView.leadingAnchor.constraint(equalTo: pdfOutlineContainer.leadingAnchor),
            pdfOutlineView.trailingAnchor.constraint(equalTo: pdfOutlineContainer.trailingAnchor),
            pdfOutlineView.bottomAnchor.constraint(equalTo: pdfOutlineContainer.bottomAnchor),
        ])

        // Setup MD Outline Container
        mdOutlineContainer.translatesAutoresizingMaskIntoConstraints = false
        mdOutlineContainer.isHidden = true
        
        let mdBackBtn = NSButton(title: "◀ 返回", target: self, action: #selector(showCategoryList))
        mdBackBtn.bezelStyle = .rounded
        mdBackBtn.translatesAutoresizingMaskIntoConstraints = false
        
        mdOutlineView.translatesAutoresizingMaskIntoConstraints = false
        
        mdOutlineContainer.addSubview(mdBackBtn)
        mdOutlineContainer.addSubview(mdOutlineView)
        NSLayoutConstraint.activate([
            mdBackBtn.topAnchor.constraint(equalTo: mdOutlineContainer.topAnchor, constant: 8),
            mdBackBtn.leadingAnchor.constraint(equalTo: mdOutlineContainer.leadingAnchor, constant: 8),
            
            mdOutlineView.topAnchor.constraint(equalTo: mdBackBtn.bottomAnchor, constant: 8),
            mdOutlineView.leadingAnchor.constraint(equalTo: mdOutlineContainer.leadingAnchor),
            mdOutlineView.trailingAnchor.constraint(equalTo: mdOutlineContainer.trailingAnchor),
            mdOutlineView.bottomAnchor.constraint(equalTo: mdOutlineContainer.bottomAnchor),
        ])

        leftContainer.addSubview(pdfOutlineContainer)
        leftContainer.addSubview(mdOutlineContainer)
        NSLayoutConstraint.activate([
            pdfOutlineContainer.topAnchor.constraint(equalTo: leftContainer.topAnchor),
            pdfOutlineContainer.leadingAnchor.constraint(equalTo: leftContainer.leadingAnchor),
            pdfOutlineContainer.trailingAnchor.constraint(equalTo: leftContainer.trailingAnchor),
            pdfOutlineContainer.bottomAnchor.constraint(equalTo: leftContainer.bottomAnchor),
            
            mdOutlineContainer.topAnchor.constraint(equalTo: leftContainer.topAnchor),
            mdOutlineContainer.leadingAnchor.constraint(equalTo: leftContainer.leadingAnchor),
            mdOutlineContainer.trailingAnchor.constraint(equalTo: leftContainer.trailingAnchor),
            mdOutlineContainer.bottomAnchor.constraint(equalTo: leftContainer.bottomAnchor),
        ])

        split.addArrangedSubview(leftContainer)
        split.addArrangedSubview(rightContainer)
        split.setHoldingPriority(.defaultLow, forSubviewAt: 0)
        split.setHoldingPriority(.defaultLow + 1, forSubviewAt: 1)

        toolVC.view.translatesAutoresizingMaskIntoConstraints = false
        stickyNotesCanvas.translatesAutoresizingMaskIntoConstraints = false
        pdfPanel.translatesAutoresizingMaskIntoConstraints = false
        mdPanel.translatesAutoresizingMaskIntoConstraints = false
        aiPanel.translatesAutoresizingMaskIntoConstraints = false

        categoryVC.onCategorySelected = { [weak self] cat in
            guard let self = self else { return }

            if cat.type == "md" {
                self.showMarkdownCategory(cat)
                return
            }

            // 同类型切换：不移除视图，仅更新内容，避免打断 WKWebView 状态
            if cat.type == self.currentViewType {
                if cat.type == "pdf", let path = cat.metadata {
                    self.pdfPanel.loadPDF(from: URL(fileURLWithPath: path))
                } else if cat.type == "sticky" {
                    self.stickyNotesCanvas.categoryId = cat.id
                } else if cat.type == "normal" {
                    self.toolVC.reload(for: cat)
                }
                return
            }

            self.currentViewType = cat.type
            self.rightContainer.subviews.forEach { $0.removeFromSuperview() }

            let targetView: NSView
            if cat.type == "sticky" {
                targetView = self.stickyNotesCanvas
                self.stickyNotesCanvas.categoryId = cat.id
            } else if cat.type == "pdf" {
                targetView = self.pdfPanel
                self.showPDFOutline()
            } else {
                targetView = self.toolVC.view
            }

            self.rightContainer.addSubview(targetView)
            NSLayoutConstraint.activate([
                targetView.topAnchor.constraint(equalTo: self.rightContainer.topAnchor),
                targetView.leadingAnchor.constraint(equalTo: self.rightContainer.leadingAnchor),
                targetView.trailingAnchor.constraint(equalTo: self.rightContainer.trailingAnchor),
                targetView.bottomAnchor.constraint(equalTo: self.rightContainer.bottomAnchor),
            ])

            // 在视图加入层级之后再加载内容，确保 WKWebView 正常渲染
            if cat.type == "pdf" {
                if let path = cat.metadata {
                    self.pdfPanel.loadPDF(from: URL(fileURLWithPath: path))
                }
            } else if cat.type != "sticky" {
                self.toolVC.reload(for: cat)
            }
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

        let delCatBtn = NSButton(title: "🗑", target: categoryVC, action: #selector(CategoryListViewController.deleteSelectedCategories))
        delCatBtn.bezelStyle = .inline
        delCatBtn.isBordered = false
        delCatBtn.font = .systemFont(ofSize: 14)
        delCatBtn.contentTintColor = NSColor(red: 1.0, green: 0.35, blue: 0.35, alpha: 1)
        delCatBtn.translatesAutoresizingMaskIntoConstraints = false

        // 中间：功能按钮组
        let terminalButton = NSButton(title: "  终端", target: self, action: #selector(toggleTerminal))
        terminalButton.bezelStyle = .rounded
        terminalButton.translatesAutoresizingMaskIntoConstraints = false
        terminalBtn = terminalButton

        let aiButton = NSButton(title: " AI 助手", target: self, action: #selector(toggleAIPanel))
        aiButton.bezelStyle = .rounded
        aiButton.translatesAutoresizingMaskIntoConstraints = false

        let funcBtnStack = NSStackView(views: [terminalButton, aiButton])
        funcBtnStack.orientation = .horizontal
        funcBtnStack.spacing = 8
        funcBtnStack.translatesAutoresizingMaskIntoConstraints = false

        // 右侧：功能区
        let toolLabel = NSTextField(labelWithString: "工作区")
        toolLabel.font = .boldSystemFont(ofSize: 13)
        toolLabel.textColor = .white
        toolLabel.translatesAutoresizingMaskIntoConstraints = false

        let addToolBtn = NSButton(title: "＋ 添加工具", target: toolVC, action: #selector(ToolListViewController.addTool))
        addToolBtn.bezelStyle = .rounded
        addToolBtn.translatesAutoresizingMaskIntoConstraints = false

        let importToolBtn = NSButton(title: "↓ 导入工具", target: toolVC, action: #selector(ToolListViewController.importTools))
        importToolBtn.bezelStyle = .rounded
        importToolBtn.translatesAutoresizingMaskIntoConstraints = false

        let installGuideBtn = NSButton(title: "? 安装指引", target: toolVC, action: #selector(ToolListViewController.showInstallGuide(_:)))
        installGuideBtn.bezelStyle = .rounded
        installGuideBtn.translatesAutoresizingMaskIntoConstraints = false

        let wallpaperBtn = NSButton(title: "  壁纸", target: toolVC, action: #selector(ToolListViewController.changeWallpaper))
        wallpaperBtn.bezelStyle = .rounded
        wallpaperBtn.translatesAutoresizingMaskIntoConstraints = false

        let clearWallBtn = NSButton(title: "✕ 清除", target: toolVC, action: #selector(ToolListViewController.clearWallpaper))
        clearWallBtn.bezelStyle = .rounded
        clearWallBtn.translatesAutoresizingMaskIntoConstraints = false

        let isGlass = DataStore.shared.glassMode == "glass"
        let glassBtn = NSButton(title: isGlass ? "✦ 玻璃" : "◻ 清晰", target: toolVC, action: #selector(ToolListViewController.toggleGlassMode))
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

        let btnStack = NSStackView(views: [glassBtn, opStack, clearWallBtn, wallpaperBtn, addToolBtn, importToolBtn, installGuideBtn])
        btnStack.orientation = .horizontal
        btnStack.spacing = 8
        btnStack.translatesAutoresizingMaskIntoConstraints = false

        topBar.addSubview(catLabel)
        topBar.addSubview(addCatBtn)
        topBar.addSubview(delCatBtn)
        topBar.addSubview(funcBtnStack)
        topBar.addSubview(toolLabel)
        topBar.addSubview(btnStack)
        NSLayoutConstraint.activate([
            topBar.heightAnchor.constraint(equalToConstant: 44),
            catLabel.leadingAnchor.constraint(equalTo: topBar.leadingAnchor, constant: 16),
            catLabel.centerYAnchor.constraint(equalTo: topBar.centerYAnchor),
            addCatBtn.leadingAnchor.constraint(equalTo: catLabel.trailingAnchor, constant: 4),
            addCatBtn.centerYAnchor.constraint(equalTo: topBar.centerYAnchor),
            delCatBtn.leadingAnchor.constraint(equalTo: addCatBtn.trailingAnchor, constant: 2),
            delCatBtn.centerYAnchor.constraint(equalTo: topBar.centerYAnchor),
            funcBtnStack.centerXAnchor.constraint(equalTo: topBar.centerXAnchor),
            funcBtnStack.centerYAnchor.constraint(equalTo: topBar.centerYAnchor),
            toolLabel.leadingAnchor.constraint(equalTo: funcBtnStack.trailingAnchor, constant: 16),
            toolLabel.centerYAnchor.constraint(equalTo: topBar.centerYAnchor),
            btnStack.trailingAnchor.constraint(equalTo: topBar.trailingAnchor, constant: -16),
            btnStack.centerYAnchor.constraint(equalTo: topBar.centerYAnchor),
        ])

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

        DispatchQueue.main.async {
            let totalWidth = split.frame.width
            split.setPosition(totalWidth * 0.2, ofDividerAt: 0)
        }
    }

    @objc private func showPDFOutline() {
        categoryVC.view.isHidden = true
        mdOutlineContainer.isHidden = true
        pdfOutlineContainer.isHidden = false
    }

    @objc private func showMDOutline() {
        categoryVC.view.isHidden = true
        pdfOutlineContainer.isHidden = true
        mdOutlineContainer.isHidden = false
    }

    @objc private func showCategoryList() {
        pdfOutlineContainer.isHidden = true
        mdOutlineContainer.isHidden = true
        categoryVC.view.isHidden = false
    }

    @objc private func toggleTerminal() {
        if floatingTerminal == nil {
            floatingTerminal = FloatingTerminalWindowController()
        }

        if let terminal = floatingTerminal {
            if terminal.window?.isVisible == true {
                terminal.close()
                terminalBtn?.title = "  终端"
            } else {
                terminal.window?.makeKeyAndOrderFront(nil)
                terminal.window?.center()
                terminalBtn?.title = "  终端 ✕"
            }
        }
    }

    @objc private func toggleAIPanel() {
        if currentViewType == "ai" {
            // 已在 AI 面板 → 回到分类列表的第一个分类
            showCategoryList()
            categoryVC.selectFirst()
        } else {
            // 切换到 AI 面板
            currentViewType = "ai"
            showCategoryList()  // 确保左侧显示分类列表
            aiPanel.translatesAutoresizingMaskIntoConstraints = false
            attachRightView(aiPanel)
        }
    }

    private func setupWallpaper() {
        let path = DataStore.shared.wallpaperPath
        if !path.isEmpty, let img = NSImage(contentsOfFile: path) {
            bgImageView?.image = img
        } else {
            // Fall back to bundled default wallpaper
            bgImageView?.image = loadDefaultWallpaper()
        }
    }

    @objc private func onWallpaperChanged(_ note: Notification) {
        if let path = note.object as? String, !path.isEmpty,
           let img = NSImage(contentsOfFile: path) {
            bgImageView?.image = img
        } else {
            // Clear or empty → fall back to bundled default
            bgImageView?.image = loadDefaultWallpaper()
        }
    }

    private func loadDefaultWallpaper() -> NSImage? {
        // 1) Try Bundle.main
        if let bundlePath = Bundle.main.path(forResource: "wallpaper_default", ofType: "png") {
            return NSImage(contentsOfFile: bundlePath)
        }
        // 2) Fall back to <executable-dir>/../Resources/wallpaper_default.png
        let exeURL = URL(fileURLWithPath: CommandLine.arguments[0])
        let resourcePath = exeURL
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Resources")
            .appendingPathComponent("wallpaper_default.png")
            .path
        return NSImage(contentsOfFile: resourcePath)
    }

    func selectFirstCategory() {
        categoryVC.selectFirst()
    }
}
