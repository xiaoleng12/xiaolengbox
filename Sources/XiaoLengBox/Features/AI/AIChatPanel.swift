import AppKit

// MARK: - FAQ

struct FAQEntry { let question: String; let answer: String }

enum FAQCatalog {
    static let entries: [FAQEntry] = [
        FAQEntry(question: "如何用命令行添加分类？",
                 answer: PresetAnswers.addCategory),
        FAQEntry(question: "如何用命令行添加工具/应用？",
                 answer: PresetAnswers.addTool),
        FAQEntry(question: "如何用命令行添加 PDF？",
                 answer: PresetAnswers.addPDF),
        FAQEntry(question: "如何用命令行添加 Markdown 文档？",
                 answer: PresetAnswers.addMarkdown),
        FAQEntry(question: "如何用命令行添加便签？",
                 answer: PresetAnswers.addSticky),
        FAQEntry(question: "如何查看所有分类和工具？",
                 answer: PresetAnswers.viewAll),
        FAQEntry(question: "工具检测状态含义？",
                 answer: "• 绿色 ✓ — 已检测到安装\n• 蓝色 ✓ — 自定义路径\n• 红色 ✗ — 未找到，需安装\n\n点击已安装工具图标可直接启动。"),
        FAQEntry(question: "如何设置壁纸和玻璃模式？",
                 answer: "1. 点「壁纸」选择图片\n2. 点「✦ 玻璃」切换模糊模式\n3. 拖滑块调透明度\n4. 点「✕ 清除」恢复默认"),
    ]
}

// MARK: - Preset Answers (command-line templates)

enum PresetAnswers {

    static let welcome = """
    你好！我是小冷工具箱助手，可以帮你通过命令行管理工具箱内容。

    你可以问我：
    • 如何用命令行添加**分类**
    • 如何用命令行添加**工具/应用**
    • 如何用命令行添加 **PDF**
    • 如何用命令行添加 **Markdown**
    • 如何用命令行添加**便签**
    • 如何**查看**所有分类和工具

    也可以点击左下角「? 常见问题」快速查看。
    """

    static let notFound = """
    抱歉，我没有理解你的问题。你可以试试：

    • 输入 **添加分类** — 查看命令行添加分类的方法
    • 输入 **添加工具** — 查看命令行添加工具的方法
    • 输入 **添加 PDF** — 查看命令行添加 PDF 的方法
    • 输入 **添加 Markdown** — 查看命令行添加文档的方法
    • 输入 **查看分类** — 查看所有分类和工具

    也可以点击左下角「? 常见问题」浏览全部帮助。
    """

    static let addCategory = """
    ### 命令行添加分类

    数据文件位于工具箱可执行文件同级目录下：
    `<工具箱路径>/Contents/MacOS/xiaolengbox_data.json`

    以下命令用 `$DATA_FILE` 代替数据文件的实际路径，**请替换为你的实际路径**。
    操作前请先**关闭工具箱**，修改后**重新打开**生效。

    **添加应用分类：**
    ```
    jq '.categories += [{"id":(now|tostring|sha1), "name":"你的分类名", "type":"normal", "tools":[], "isPreset":false}]' "$DATA_FILE" > tmp.json && mv tmp.json "$DATA_FILE"
    ```

    **添加 PDF 分类：**
    ```
    jq '.categories += [{"id":(now|tostring|sha1), "name":"你的PDF分类", "type":"pdf", "metadata":"/你的/pdf/文件路径.pdf", "tools":[], "isPreset":false}]' "$DATA_FILE" > tmp.json && mv tmp.json "$DATA_FILE"
    ```

    **添加 Markdown 分类：**
    ```
    jq '.categories += [{"id":(now|tostring|sha1), "name":"你的文档分类", "type":"md", "metadata":"/你的/md/文件路径.md", "tools":[], "isPreset":false}]' "$DATA_FILE" > tmp.json && mv tmp.json "$DATA_FILE"
    ```

    **添加便签分类：**
    ```
    jq '.categories += [{"id":(now|tostring|sha1), "name":"你的便签", "type":"sticky", "tools":[], "isPreset":false}]' "$DATA_FILE" > tmp.json && mv tmp.json "$DATA_FILE"
    ```

    **Python 方式（更易读）：**
    ```
    python3 -c "
    import json, uuid
    path = '$DATA_FILE'  # 替换为实际路径
    with open(path) as f: data = json.load(f)
    data['categories'].append({
        'id': str(uuid.uuid4()), 'name': '你的分类名',
        'type': 'normal', 'tools': [], 'isPreset': False,
        'presetIcon': None, 'metadata': None
    })
    with open(path, 'w') as f: json.dump(data, f, ensure_ascii=False, indent=2)
    "
    ```
    """

    static let addTool = """
    ### 命令行添加工具/应用

    数据文件：`<工具箱路径>/Contents/MacOS/xiaolengbox_data.json`
    用 `$DATA_FILE` 代替实际路径，**请替换为你的实际路径**。
    操作前请先**关闭工具箱**，修改后**重新打开**生效。

    **向已有分类添加工具：**
    ```
    jq '(.categories[] | select(.name=="你的分类名") | .tools) += [{"id":(now|tostring|sha1), "name":"工具名", "appPath":"/你的/工具/路径", "detectionStatus":"custom"}]' "$DATA_FILE" > tmp.json && mv tmp.json "$DATA_FILE"
    ```

    **批量导入（每行一个，格式：`工具名 路径：/完整路径`）：**
    ```
    nmap 路径：/opt/homebrew/bin/nmap
    hydra 路径：/opt/homebrew/bin/hydra
    wireshark 路径：/Applications/Wireshark.app
    ```
    在工具箱界面点击右上角「↓ 导入工具」粘贴即可。

    **Python 方式：**
    ```
    python3 -c "
    import json, uuid
    path = '$DATA_FILE'  # 替换为实际路径
    with open(path) as f: data = json.load(f)
    for cat in data['categories']:
        if cat['name'] == '你的分类名':
            cat['tools'].append({
                'id': str(uuid.uuid4()), 'name': '工具名',
                'appPath': '/你的/工具/路径',
                'detectionStatus': 'custom',
                'presetId': None, 'customInstallHint': None
            })
            break
    with open(path, 'w') as f: json.dump(data, f, ensure_ascii=False, indent=2)
    "
    ```
    """

    static let addPDF = """
    ### 命令行添加 PDF 文档

    数据文件：`<工具箱路径>/Contents/MacOS/xiaolengbox_data.json`
    用 `$DATA_FILE` 代替实际路径，**请替换为你的实际路径**。
    操作前请先**关闭工具箱**，修改后**重新打开**生效。

    **添加 PDF 分类：**
    ```
    jq '.categories += [{"id":(now|tostring|sha1), "name":"你的PDF分类名", "type":"pdf", "metadata":"/你的/pdf/文件路径.pdf", "tools":[], "isPreset":false}]' "$DATA_FILE" > tmp.json && mv tmp.json "$DATA_FILE"
    ```

    **Python 方式：**
    ```
    python3 -c "
    import json, uuid
    path = '$DATA_FILE'  # 替换为实际路径
    with open(path) as f: data = json.load(f)
    data['categories'].append({
        'id': str(uuid.uuid4()), 'name': '你的PDF分类名',
        'type': 'pdf', 'metadata': '/你的/pdf/文件路径.pdf',
        'tools': [], 'isPreset': False, 'presetIcon': None
    })
    with open(path, 'w') as f: json.dump(data, f, ensure_ascii=False, indent=2)
    "
    ```

    注意：`metadata` 字段填写 PDF 文件的**完整路径**，工具箱会自动加载显示。
    """

    static let addMarkdown = """
    ### 命令行添加 Markdown 文档

    数据文件：`<工具箱路径>/Contents/MacOS/xiaolengbox_data.json`
    用 `$DATA_FILE` 代替实际路径，**请替换为你的实际路径**。
    操作前请先**关闭工具箱**，修改后**重新打开**生效。

    **添加 Markdown 分类：**
    ```
    jq '.categories += [{"id":(now|tostring|sha1), "name":"你的文档分类名", "type":"md", "metadata":"/你的/md/文件路径.md", "tools":[], "isPreset":false}]' "$DATA_FILE" > tmp.json && mv tmp.json "$DATA_FILE"
    ```

    **Python 方式：**
    ```
    python3 -c "
    import json, uuid
    path = '$DATA_FILE'  # 替换为实际路径
    with open(path) as f: data = json.load(f)
    data['categories'].append({
        'id': str(uuid.uuid4()), 'name': '你的文档分类名',
        'type': 'md', 'metadata': '/你的/md/文件路径.md',
        'tools': [], 'isPreset': False, 'presetIcon': None
    })
    with open(path, 'w') as f: json.dump(data, f, ensure_ascii=False, indent=2)
    "
    ```

    注意：`metadata` 字段填写 Markdown 文件的**完整路径**。
    """

    static let addSticky = """
    ### 命令行添加便签分类

    数据文件：`<工具箱路径>/Contents/MacOS/xiaolengbox_data.json`
    用 `$DATA_FILE` 代替实际路径，**请替换为你的实际路径**。
    操作前请先**关闭工具箱**，修改后**重新打开**生效。

    ```
    jq '.categories += [{"id":(now|tostring|sha1), "name":"你的便签名", "type":"sticky", "tools":[], "isPreset":false}]' "$DATA_FILE" > tmp.json && mv tmp.json "$DATA_FILE"
    ```

    **Python 方式：**
    ```
    python3 -c "
    import json, uuid
    path = '$DATA_FILE'  # 替换为实际路径
    with open(path) as f: data = json.load(f)
    data['categories'].append({
        'id': str(uuid.uuid4()), 'name': '你的便签名',
        'type': 'sticky', 'tools': [], 'isPreset': False,
        'presetIcon': None, 'metadata': None
    })
    with open(path, 'w') as f: json.dump(data, f, ensure_ascii=False, indent=2)
    "
    ```
    """

    static let viewAll = """
    ### 查看所有分类和工具

    数据文件：`<工具箱路径>/Contents/MacOS/xiaolengbox_data.json`
    用 `$DATA_FILE` 代替实际路径。

    **查看所有分类名称和类型：**
    ```
    jq '.categories[] | {name, type}' "$DATA_FILE"
    ```

    **查看某个分类下的所有工具：**
    ```
    jq '.categories[] | select(.name=="分类名") | .tools[] | {name, appPath}' "$DATA_FILE"
    ```

    **导出完整工具箱状态：**
    ```
    jq '.' "$DATA_FILE"
    ```

    **数据文件结构说明：**
    ```
    {
      "categories": [
        {
          "id": "UUID",
          "name": "分类名称",
          "type": "normal",      // normal=应用, pdf=PDF, md=Markdown, sticky=便签
          "metadata": null,      // pdf/md 类型时为文件路径
          "tools": [
            {
              "id": "UUID",
              "name": "工具名",
              "appPath": "/工具/路径",
              "detectionStatus": "custom",
              "presetId": null,
              "customInstallHint": null
            }
          ]
        }
      ]
    }
    ```
    """

    static let toolboxOverview: () -> String = {
        var lines = "### 工具箱当前状态\n\n"
        let store = DataStore.shared
        if store.categories.isEmpty {
            lines += "工具箱暂无分类。可以问我如何用命令行添加分类和工具。\n"
        } else {
            for cat in store.categories where cat.type == "normal" {
                lines += "**\(cat.name)**"
                if cat.tools.isEmpty {
                    lines += " — (空)\n"
                } else {
                    lines += " — \(cat.tools.count) 个工具\n"
                    for tool in cat.tools.prefix(5) {
                        lines += "  • \(tool.name)\n"
                    }
                    if cat.tools.count > 5 {
                        lines += "  • ... 还有 \(cat.tools.count - 5) 个\n"
                    }
                }
                lines += "\n"
            }
        }
        return lines
    }
}

// MARK: - Keyword Matching

struct PresetTrigger {
    let keywords: [[String]]  // each sub-array = variants; match if ≥1 variant from EACH group
    let answer: String
}

enum PresetMatcher {
    static let triggers: [PresetTrigger] = [
        // Specific operations (more keyword groups = higher specificity)
        PresetTrigger(
            keywords: [["添加", "新建", "创建", "导入", "增加"], ["分类"]],
            answer: PresetAnswers.addCategory),
        PresetTrigger(
            keywords: [["添加", "导入", "增加"], ["工具", "应用", "app"]],
            answer: PresetAnswers.addTool),
        PresetTrigger(
            keywords: [["添加", "导入", "增加"], ["pdf"]],
            answer: PresetAnswers.addPDF),
        PresetTrigger(
            keywords: [["添加", "导入", "增加"], ["md", "markdown", "文档"]],
            answer: PresetAnswers.addMarkdown),
        PresetTrigger(
            keywords: [["添加", "导入", "增加"], ["便签", "sticky", "笔记", "备忘"]],
            answer: PresetAnswers.addSticky),

        // View operations
        PresetTrigger(
            keywords: [["查看", "列出", "显示", "所有"], ["分类", "工具"]],
            answer: PresetAnswers.viewAll),
        PresetTrigger(
            keywords: [["查看", "列出", "显示"], ["所有", "全部", "列表"]],
            answer: PresetAnswers.viewAll),
    ]

    // Topic-level triggers (single keyword group, for "how to use" / "help" / overview)
    static let topicTriggers: [PresetTrigger] = [
        PresetTrigger(
            keywords: [["命令行", "终端", "cli", "命令"]],
            answer: PresetAnswers.addCategory),
        PresetTrigger(
            keywords: [["怎么用", "使用方法", "帮助", "help"]],
            answer: PresetAnswers.welcome),
        PresetTrigger(
            keywords: [["状态", "概览", "有什么", "有哪些"]],
            answer: PresetAnswers.toolboxOverview()),
    ]

    static func match(_ input: String) -> String {
        let q = input.lowercased()

        // Try specific multi-keyword triggers first
        for t in triggers {
            if t.keywords.allSatisfy({ group in group.contains(where: { q.contains($0) }) }) {
                return t.answer
            }
        }

        // Try topic-level triggers
        for t in topicTriggers {
            if t.keywords.allSatisfy({ group in group.contains(where: { q.contains($0) }) }) {
                return t.answer
            }
        }

        // Fallback
        return PresetAnswers.notFound
    }
}

// MARK: - FAQ Panel

private class FAQPanelView: NSView {
    var onQuestionTapped: ((FAQEntry) -> Void)?
    var onClose: (() -> Void)?

    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
        layer?.backgroundColor = NSColor(white: 0.98, alpha: 1).cgColor
        layer?.cornerRadius = 12
        layer?.borderWidth = 1
        layer?.borderColor = NSColor(white: 0.85, alpha: 1).cgColor

        let header = NSView()
        header.translatesAutoresizingMaskIntoConstraints = false
        let title = NSTextField(labelWithString: "常见问题")
        title.font = .boldSystemFont(ofSize: 14)
        title.translatesAutoresizingMaskIntoConstraints = false
        let closeBtn = NSButton(title: "✕", target: self, action: #selector(doClose))
        closeBtn.bezelStyle = .inline; closeBtn.isBordered = false
        closeBtn.contentTintColor = .secondaryLabelColor
        closeBtn.translatesAutoresizingMaskIntoConstraints = false
        header.addSubview(title); header.addSubview(closeBtn)

        let scroll = NSScrollView()
        scroll.hasVerticalScroller = true; scroll.drawsBackground = false
        scroll.translatesAutoresizingMaskIntoConstraints = false
        let stack = NSStackView(); stack.orientation = .vertical; stack.alignment = .leading; stack.spacing = 2
        stack.translatesAutoresizingMaskIntoConstraints = false

        for (i, faq) in FAQCatalog.entries.enumerated() {
            let btn = NSButton(title: "  \(faq.question)", target: self, action: #selector(tap(_:)))
            btn.bezelStyle = .inline; btn.isBordered = false
            btn.font = .systemFont(ofSize: 13)
            btn.contentTintColor = NSColor(red: 0.2, green: 0.45, blue: 0.85, alpha: 1)
            btn.alignment = .left; btn.tag = i
            btn.translatesAutoresizingMaskIntoConstraints = false
            stack.addArrangedSubview(btn)
        }
        scroll.documentView = stack
        addSubview(header); addSubview(scroll)
        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            header.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            header.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            header.heightAnchor.constraint(equalToConstant: 28),
            title.leadingAnchor.constraint(equalTo: header.leadingAnchor),
            title.centerYAnchor.constraint(equalTo: header.centerYAnchor),
            closeBtn.trailingAnchor.constraint(equalTo: header.trailingAnchor),
            closeBtn.centerYAnchor.constraint(equalTo: header.centerYAnchor),
            scroll.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 4),
            scroll.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            scroll.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
            scroll.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            stack.topAnchor.constraint(equalTo: scroll.contentView.topAnchor),
            stack.leadingAnchor.constraint(equalTo: scroll.contentView.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: scroll.contentView.trailingAnchor),
        ])
    }
    required init?(coder: NSCoder) { fatalError() }
    @objc private func tap(_ s: NSButton) { if s.tag < FAQCatalog.entries.count { onQuestionTapped?(FAQCatalog.entries[s.tag]) } }
    @objc private func doClose() { onClose?() }
}

// MARK: - Chat Bubble (Frame-Based)

private class ChatBubbleView: NSView {
    let contentHeight: CGFloat

    init(text: String, role: String, maxWidth: CGFloat) {
        let isUser = role == "user"
        let isSystem = role == "system"
        let avatarSize: CGFloat = 32
        let gap: CGFloat = 8
        let bubbleHPad: CGFloat = 14
        let bubbleVPad: CGFloat = 10
        let maxTextW = maxWidth - avatarSize - gap - bubbleHPad * 2 - 20
        let textW = max(maxTextW, 100)

        // Measure text
        let attrStr = MarkdownRenderer.render(text, compact: isSystem)
        let measureView = NSTextView(frame: NSRect(x: 0, y: 0, width: textW, height: 0))
        measureView.textStorage?.setAttributedString(attrStr)
        measureView.textContainerInset = .zero
        measureView.textContainer?.lineFragmentPadding = 0
        measureView.textContainer?.containerSize = NSSize(width: textW, height: .greatestFiniteMagnitude)
        measureView.textContainer?.widthTracksTextView = true
        measureView.layoutManager?.ensureLayout(for: measureView.textContainer!)
        let usedRect = measureView.layoutManager!.usedRect(for: measureView.textContainer!)
        let textH = max(ceil(usedRect.height) + 2, 18)

        let nameH: CGFloat = 16
        let bubbleW = textW + bubbleHPad * 2
        let bubbleH = textH + bubbleVPad * 2
        contentHeight = nameH + 4 + bubbleH

        super.init(frame: NSRect(x: 0, y: 0, width: maxWidth, height: contentHeight))
        wantsLayer = true

        // Name
        let nameStr = isSystem ? "系统提示" : (isUser ? "我" : "助手")
        let name = NSTextField(labelWithString: nameStr)
        name.font = .systemFont(ofSize: 11)
        name.textColor = .secondaryLabelColor

        // Avatar
        let avatar = NSView()
        avatar.wantsLayer = true
        avatar.layer?.cornerRadius = avatarSize / 2
        let abg: NSColor = isSystem ? NSColor(white: 0.4, alpha: 1) : (isUser ? NSColor(red: 0.35, green: 0.65, blue: 1, alpha: 1) : NSColor(red: 0.45, green: 0.8, blue: 0.45, alpha: 1))
        avatar.layer?.backgroundColor = abg.cgColor
        let aLabel = NSTextField(labelWithString: isSystem ? "💡" : (isUser ? "我" : "AI"))
        aLabel.font = .systemFont(ofSize: 12, weight: .medium)
        aLabel.alignment = .center; aLabel.textColor = .white

        // Bubble bg
        let bubble = NSView()
        bubble.wantsLayer = true
        bubble.layer?.cornerRadius = 10
        let bbg: NSColor = isSystem ? NSColor(white: 0.96, alpha: 1) : (isUser ? NSColor(red: 0.56, green: 0.78, blue: 0.42, alpha: 1) : NSColor.white)
        bubble.layer?.backgroundColor = bbg.cgColor

        // Text (NSTextView, frame-based)
        let tv = NSTextView(frame: NSRect(x: 0, y: 0, width: textW, height: textH))
        tv.isEditable = false; tv.isSelectable = true
        tv.drawsBackground = false
        tv.textContainerInset = .zero
        tv.textContainer?.lineFragmentPadding = 0
        tv.textStorage?.setAttributedString(attrStr)

        bubble.addSubview(tv)

        // Copy button
        if !isSystem {
            let cp = NSButton(title: "复制", target: self, action: #selector(doCopy(_:)))
            cp.bezelStyle = .inline; cp.isBordered = false; cp.font = .systemFont(ofSize: 10)
            cp.contentTintColor = isUser ? NSColor.white.withAlphaComponent(0.6) : NSColor.black.withAlphaComponent(0.3)
            cp.toolTip = text
            bubble.addSubview(cp)
            cp.frame = NSRect(x: bubbleW - 40, y: 2, width: 34, height: 16)
        }

        // Layout with frames
        if isUser {
            name.frame = NSRect(x: maxWidth - bubbleW - 4, y: contentHeight - nameH, width: bubbleW, height: nameH)
            name.alignment = .right
            avatar.frame = NSRect(x: maxWidth - avatarSize, y: contentHeight - nameH - 4 - bubbleH + (bubbleH - avatarSize) / 2, width: avatarSize, height: avatarSize)
            bubble.frame = NSRect(x: maxWidth - avatarSize - gap - bubbleW, y: contentHeight - nameH - 4 - bubbleH, width: bubbleW, height: bubbleH)
        } else {
            name.frame = NSRect(x: avatarSize + gap, y: contentHeight - nameH, width: 200, height: nameH)
            avatar.frame = NSRect(x: 0, y: contentHeight - nameH - 4 - bubbleH + (bubbleH - avatarSize) / 2, width: avatarSize, height: avatarSize)
            bubble.frame = NSRect(x: avatarSize + gap, y: contentHeight - nameH - 4 - bubbleH, width: bubbleW, height: bubbleH)
        }
        tv.frame = NSRect(x: bubbleHPad, y: bubbleVPad, width: textW, height: textH)
        aLabel.frame = NSRect(x: 0, y: 0, width: avatarSize, height: avatarSize)

        addSubview(name); addSubview(avatar); addSubview(bubble)
        avatar.addSubview(aLabel)
    }

    required init?(coder: NSCoder) { fatalError() }

    @objc private func doCopy(_ s: NSButton) {
        guard let t = s.toolTip else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(t, forType: .string)
        let o = s.title; s.title = "✓ 已复制"
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { s.title = o }
    }
}

// MARK: - Markdown Renderer

private enum MarkdownRenderer {
    static func render(_ text: String, compact: Bool = false) -> NSAttributedString {
        let r = NSMutableAttributedString()
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        var inCode = false; var codeLines: [String] = []
        for (i, line) in lines.enumerated() {
            if line.trimmingCharacters(in: .whitespaces).hasPrefix("```") {
                if inCode { r.append(codeBlock(codeLines.joined(separator: "\n"))); codeLines = []; inCode = false }
                else { inCode = true }
                if i < lines.count - 1 { r.append(nl(compact)) }; continue
            }
            if inCode { codeLines.append(line); continue }
            let t = line.trimmingCharacters(in: .whitespaces)
            if t.isEmpty { if i < lines.count - 1 { r.append(nl(compact)) } }
            else if t.hasPrefix("### ") { r.append(heading(String(t.dropFirst(4)), lv: 3, c: compact)) }
            else if t.hasPrefix("## ") { r.append(heading(String(t.dropFirst(3)), lv: 2, c: compact)) }
            else if t.hasPrefix("# ") { r.append(heading(String(t.dropFirst(2)), lv: 1, c: compact)) }
            else if t.hasPrefix("- ") || t.hasPrefix("* ") { r.append(bullet(String(t.dropFirst(2)), c: compact)) }
            else if let m = t.range(of: #"^\d+\.\s"#, options: .regularExpression) { r.append(numItem(String(t[..<m.upperBound]), String(t[m.upperBound...]), c: compact)) }
            else { r.append(inline(t, sz: compact ? 12 : 13)) }
            if i < lines.count - 1 { r.append(nl(compact)) }
        }
        if inCode && !codeLines.isEmpty { r.append(codeBlock(codeLines.joined(separator: "\n"))) }
        return r
    }
    private static func nl(_ c: Bool) -> NSAttributedString {
        let s = NSMutableAttributedString(string: "\n"); let p = NSMutableParagraphStyle(); p.paragraphSpacing = c ? 2 : 3
        s.addAttribute(.paragraphStyle, value: p, range: NSRange(location: 0, length: 1)); return s
    }
    private static func heading(_ t: String, lv: Int, c: Bool) -> NSAttributedString {
        let sz: CGFloat = [1: 18, 2: 16, 3: 14][lv] ?? 14
        let a = NSMutableAttributedString(); a.append(inline(t, sz: sz, bold: true))
        let p = NSMutableParagraphStyle(); p.paragraphSpacingBefore = c ? 4 : 8; p.paragraphSpacing = c ? 2 : 4
        a.addAttribute(.paragraphStyle, value: p, range: NSRange(location: 0, length: a.length)); return a
    }
    private static func bullet(_ t: String, c: Bool) -> NSAttributedString {
        let a = NSMutableAttributedString(string: "•  ", attributes: [.font: NSFont.systemFont(ofSize: c ? 12 : 13), .foregroundColor: NSColor.labelColor])
        a.append(inline(t, sz: c ? 12 : 13)); let p = NSMutableParagraphStyle(); p.headIndent = 14; p.paragraphSpacing = 1
        a.addAttribute(.paragraphStyle, value: p, range: NSRange(location: 0, length: a.length)); return a
    }
    private static func numItem(_ n: String, _ b: String, c: Bool) -> NSAttributedString {
        let a = NSMutableAttributedString(string: n, attributes: [.font: NSFont.systemFont(ofSize: c ? 12 : 13), .foregroundColor: NSColor.labelColor])
        a.append(inline(b, sz: c ? 12 : 13)); let p = NSMutableParagraphStyle(); p.headIndent = 18; p.paragraphSpacing = 1
        a.addAttribute(.paragraphStyle, value: p, range: NSRange(location: 0, length: a.length)); return a
    }
    private static func codeBlock(_ code: String) -> NSAttributedString {
        let c = code.hasSuffix("\n") ? String(code.dropLast()) : code
        let a = NSMutableAttributedString(string: c, attributes: [
            .font: NSFont.monospacedSystemFont(ofSize: 12, weight: .regular),
            .foregroundColor: NSColor(red: 0.85, green: 0.25, blue: 0.45, alpha: 1),
            .backgroundColor: NSColor(white: 0.94, alpha: 1)])
        let p = NSMutableParagraphStyle(); p.paragraphSpacingBefore = 6; p.paragraphSpacing = 4; p.headIndent = 8; p.tailIndent = -8
        a.addAttribute(.paragraphStyle, value: p, range: NSRange(location: 0, length: a.length)); return a
    }
    private static func inline(_ text: String, sz: CGFloat, bold: Bool = false) -> NSAttributedString {
        let base: [NSAttributedString.Key: Any] = [.font: bold ? NSFont.boldSystemFont(ofSize: sz) : NSFont.systemFont(ofSize: sz), .foregroundColor: NSColor.labelColor]
        let a = NSMutableAttributedString(string: text, attributes: base)
        applyR(a, "`([^`]+)`", sz) { s, r in s.addAttribute(.font, value: NSFont.monospacedSystemFont(ofSize: sz-1, weight: .regular), range: r); s.addAttribute(.backgroundColor, value: NSColor(white: 0.9, alpha: 1), range: r); s.addAttribute(.foregroundColor, value: NSColor(red: 0.8, green: 0.2, blue: 0.4, alpha: 1), range: r) }
        applyR(a, "\\*\\*([^*]+)\\*\\*", sz) { s, r in s.addAttribute(.font, value: NSFont.boldSystemFont(ofSize: sz), range: r) }
        applyR(a, "(?<!\\*)\\*(?!\\*)([^*]+)\\*(?!\\*)", sz) { s, r in s.addAttribute(.font, value: NSFontManager.shared.convert(NSFont.systemFont(ofSize: sz), toHaveTrait: .italicFontMask), range: r) }
        if let re = try? NSRegularExpression(pattern: "\\[([^\\]]+)\\]\\(([^)]+)\\)") {
            for m in re.matches(in: a.string, range: NSRange(location: 0, length: a.length)).reversed() {
                guard m.numberOfRanges >= 3, let url = URL(string: a.attributedSubstring(from: m.range(at: 2)).string) else { continue }
                let lk = NSMutableAttributedString(string: a.attributedSubstring(from: m.range(at: 1)).string, attributes: [.font: NSFont.systemFont(ofSize: sz), .foregroundColor: NSColor.linkColor, .link: url, .underlineStyle: NSUnderlineStyle.single.rawValue])
                a.replaceCharacters(in: m.range, with: lk)
            }
        }
        return a
    }
    private static func applyR(_ a: NSMutableAttributedString, _ pat: String, _ sz: CGFloat, _ fn: (NSMutableAttributedString, NSRange) -> Void) {
        guard let re = try? NSRegularExpression(pattern: pat) else { return }
        for m in re.matches(in: a.string, range: NSRange(location: 0, length: a.length)).reversed() {
            guard m.numberOfRanges >= 2 else { continue }
            let inner = m.range(at: 1), content = a.attributedSubstring(from: inner)
            a.replaceCharacters(in: m.range, with: NSMutableAttributedString(attributedString: content))
            let nr = NSRange(location: m.range.location, length: content.length)
            if nr.location + nr.length <= a.length { fn(a, nr) }
        }
    }
}

// MARK: - Flipped NSView (Y=0 at top, grows downward)

private class FlippedView: NSView {
    override var isFlipped: Bool { true }
}

// MARK: - AI Chat Panel

class AIChatPanel: NSView {
    private let scrollView = NSScrollView()
    private let chatContainer = FlippedView()
    private let inputField = NSTextField()
    private let sendButton = NSButton()
    private let faqButton = NSButton()
    private var inputRowRef: NSStackView?
    private var messages: [ChatMessage] = []
    private var faqPanel: FAQPanelView?
    private var totalContentHeight: CGFloat = 0

    struct ChatMessage { let role: String; let content: String }

    override init(frame: NSRect) { super.init(frame: frame); wantsLayer = true; buildUI() }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Build UI

    private func buildUI() {
        layer?.backgroundColor = NSColor(white: 0.97, alpha: 1).cgColor

        chatContainer.wantsLayer = true
        scrollView.documentView = chatContainer
        scrollView.hasVerticalScroller = true
        scrollView.drawsBackground = false
        scrollView.automaticallyAdjustsContentInsets = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        inputField.placeholderString = "输入问题… (例如: 如何添加分类、如何添加工具)"
        inputField.font = .systemFont(ofSize: 13); inputField.isEditable = true
        inputField.bezelStyle = .roundedBezel; inputField.target = self
        inputField.action = #selector(sendMessage); inputField.translatesAutoresizingMaskIntoConstraints = false

        sendButton.title = "发送"; sendButton.bezelStyle = .rounded
        sendButton.target = self; sendButton.action = #selector(sendMessage)
        sendButton.keyEquivalent = "\r"; sendButton.translatesAutoresizingMaskIntoConstraints = false

        faqButton.title = "? 常见问题"; faqButton.bezelStyle = .rounded
        faqButton.target = self; faqButton.action = #selector(toggleFAQ)
        faqButton.translatesAutoresizingMaskIntoConstraints = false

        let inputRow = NSStackView(views: [faqButton, inputField, sendButton])
        inputRow.orientation = .horizontal; inputRow.spacing = 8
        inputRow.translatesAutoresizingMaskIntoConstraints = false
        inputRowRef = inputRow

        addSubview(scrollView); addSubview(inputRow)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            inputRow.topAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: 8),
            inputRow.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            inputRow.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            inputRow.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            faqButton.widthAnchor.constraint(equalToConstant: 90),
            sendButton.widthAnchor.constraint(equalToConstant: 55),
            inputRow.heightAnchor.constraint(equalToConstant: 32),
        ])

        DispatchQueue.main.async { [weak self] in self?.showWelcome() }
    }

    private func showWelcome() {
        appendMessage(PresetAnswers.welcome, role: "system")
    }

    // MARK: - FAQ

    @objc private func toggleFAQ() {
        if let p = faqPanel { p.removeFromSuperview(); faqPanel = nil; return }
        let panel = FAQPanelView(frame: .zero)
        panel.translatesAutoresizingMaskIntoConstraints = false
        panel.onQuestionTapped = { [weak self] entry in
            self?.appendMessage(entry.question, role: "user")
            self?.appendMessage(entry.answer, role: "assistant")
            self?.toggleFAQ()
        }
        panel.onClose = { [weak self] in self?.toggleFAQ() }
        addSubview(panel)
        NSLayoutConstraint.activate([
            panel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            panel.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -4),
            panel.widthAnchor.constraint(equalToConstant: 280),
            panel.heightAnchor.constraint(equalToConstant: 320),
        ])
        faqPanel = panel
    }

    // MARK: - Append Message (Frame-Based)

    private func containerWidth() -> CGFloat {
        let sw = scrollView.contentSize.width
        if sw > 0 { return sw }
        return max(bounds.width - 24, 400)
    }

    private func appendMessage(_ text: String, role: String) {
        messages.append(ChatMessage(role: role, content: text))

        let w = containerWidth()
        let bubble = ChatBubbleView(text: text, role: role, maxWidth: w)
        let y = totalContentHeight
        bubble.frame = NSRect(x: 0, y: y, width: w, height: bubble.contentHeight)
        chatContainer.addSubview(bubble)

        totalContentHeight += bubble.contentHeight + 14
        let finalH = max(totalContentHeight, scrollView.contentSize.height)
        chatContainer.frame = NSRect(x: 0, y: 0, width: w, height: finalH)
        scrollToBottom()
    }

    private func scrollToBottom() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let maxScroll = self.chatContainer.frame.height - self.scrollView.contentSize.height
            if maxScroll > 0 {
                self.scrollView.contentView.scroll(to: NSPoint(x: 0, y: maxScroll))
                self.scrollView.reflectScrolledClipView(self.scrollView.contentView)
            }
        }
    }

    // MARK: - Send (Keyword Matching)

    @objc private func sendMessage() {
        let text = inputField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        inputField.stringValue = ""
        appendMessage(text, role: "user")
        let answer = PresetMatcher.match(text)
        appendMessage(answer, role: "assistant")
    }
}
