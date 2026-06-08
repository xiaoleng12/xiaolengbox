import AppKit

// MARK: - AI Provider Presets

struct AIProviderPreset {
    let id: String
    let name: String
    let baseUrl: String
    let models: [String]
}

enum AIProviderCatalog {
    static let all: [AIProviderPreset] = [
        AIProviderPreset(id: "deepseek", name: "DeepSeek", baseUrl: "https://api.deepseek.com/v1",
                         models: ["deepseek-v4-flash", "deepseek-v4-pro", "deepseek-chat", "deepseek-reasoner"]),
        AIProviderPreset(id: "openai", name: "OpenAI", baseUrl: "https://api.openai.com/v1",
                         models: ["gpt-4o", "gpt-4o-mini", "gpt-4-turbo", "gpt-3.5-turbo"]),
        AIProviderPreset(id: "moonshot", name: "Moonshot (月之暗面)", baseUrl: "https://api.moonshot.cn/v1",
                         models: ["moonshot-v1-8k", "moonshot-v1-32k", "moonshot-v1-128k"]),
        AIProviderPreset(id: "zhipu", name: "智谱 AI (GLM)", baseUrl: "https://open.bigmodel.cn/api/paas/v4",
                         models: ["glm-4-plus", "glm-4-flash", "glm-4-long"]),
        AIProviderPreset(id: "siliconflow", name: "SiliconFlow", baseUrl: "https://api.siliconflow.cn/v1",
                         models: ["deepseek-ai/DeepSeek-V4", "deepseek-ai/DeepSeek-R1",
                                  "Qwen/Qwen2.5-72B-Instruct", "THUDM/glm-4-9b-chat"]),
        AIProviderPreset(id: "ollama", name: "Ollama (本地)", baseUrl: "http://localhost:11434/v1",
                         models: ["llama3", "qwen2", "deepseek-r1", "codellama", "mistral"]),
        AIProviderPreset(id: "custom", name: "自定义", baseUrl: "", models: []),
    ]
    static func find(id: String) -> AIProviderPreset? { all.first { $0.id == id } }
}

// MARK: - FAQ

struct FAQEntry { let question: String; let answer: String }

enum FAQCatalog {
    static let entries: [FAQEntry] = [
        FAQEntry(question: "如何添加工具？",
                 answer: "点击右上角「＋ 添加工具」按钮，输入工具名称和可执行文件路径即可。\n\n例如添加 VS Code：\n• 名称：VS Code\n• 路径：/usr/local/bin/code\n\n工具箱会自动检测路径是否存在。"),
        FAQEntry(question: "如何批量导入工具？",
                 answer: "点击右上角「↓ 导入工具」按钮，按格式粘贴文本（每行一个）：\n\nnmap 路径：/opt/homebrew/bin/nmap\nhydra 路径：/opt/homebrew/bin/hydra\nwireshark 路径：/Applications/Wireshark.app"),
        FAQEntry(question: "安装指引怎么用？",
                 answer: "点击顶部「? 安装指引」按钮，弹出所有工具的安装命令（如 brew install nmap），点击复制即可。还可以点「编辑」自定义安装提示。"),
        FAQEntry(question: "如何使用 AI 助手？",
                 answer: "1. 点击顶部「AI 助手」进入聊天\n2. 点「⚙ 配置」选择服务商（如 DeepSeek）\n3. 填入 API Key，选择模型，保存\n4. 开始对话！AI 会自动读取工具箱状态"),
        FAQEntry(question: "支持哪些 AI 服务商？",
                 answer: "• DeepSeek — 性价比高，推荐国内\n• OpenAI — GPT-4o 等\n• Moonshot — 月之暗面\n• 智谱 AI — GLM 系列\n• SiliconFlow — 开源模型聚合\n• Ollama — 本地运行（免 Key）\n• 自定义 — 任何 OpenAI 兼容 API"),
        FAQEntry(question: "工具检测状态含义？",
                 answer: "• 绿色 ✓ — 已检测到安装\n• 蓝色 ✓ — 自定义路径\n• 红色 ✗ — 未找到，需安装\n\n点击已安装工具图标可直接启动。"),
        FAQEntry(question: "如何设置壁纸和玻璃模式？",
                 answer: "1. 点「壁纸」选择图片\n2. 点「✦ 玻璃」切换模糊模式\n3. 拖滑块调透明度\n4. 点「✕ 清除」恢复默认"),
    ]
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
        let nameStr = isSystem ? "系统提示" : (isUser ? "我" : "AI 助手")
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
            // Position at bottom-right of bubble
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

// MARK: - AI Chat Panel

class AIChatPanel: NSView {
    private let scrollView = NSScrollView()
    private let chatContainer = NSView()  // documentView, frame-based
    private let inputField = NSTextField()
    private let sendButton = NSButton()
    private let settingsButton = NSButton()
    private let faqButton = NSButton()
    private var inputRowRef: NSStackView?
    private var messages: [ChatMessage] = []
    private var isLoading = false
    private var faqPanel: FAQPanelView?
    private var totalContentHeight: CGFloat = 0

    struct ChatMessage { let role: String; let content: String }

    override init(frame: NSRect) { super.init(frame: frame); wantsLayer = true; buildUI() }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Build UI

    private func buildUI() {
        layer?.backgroundColor = NSColor(white: 0.97, alpha: 1).cgColor

        // chatContainer: frame-based documentView
        chatContainer.wantsLayer = true
        scrollView.documentView = chatContainer
        scrollView.hasVerticalScroller = true
        scrollView.drawsBackground = false
        scrollView.automaticallyAdjustsContentInsets = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        inputField.placeholderString = "输入消息… (例如: 帮我推荐安全工具并生成导入列表)"
        inputField.font = .systemFont(ofSize: 13); inputField.isEditable = true
        inputField.bezelStyle = .roundedBezel; inputField.target = self
        inputField.action = #selector(sendMessage); inputField.translatesAutoresizingMaskIntoConstraints = false

        sendButton.title = "发送"; sendButton.bezelStyle = .rounded
        sendButton.target = self; sendButton.action = #selector(sendMessage)
        sendButton.keyEquivalent = "\r"; sendButton.translatesAutoresizingMaskIntoConstraints = false

        settingsButton.title = "⚙ 配置"; settingsButton.bezelStyle = .rounded
        settingsButton.target = self; settingsButton.action = #selector(showSettings)
        settingsButton.translatesAutoresizingMaskIntoConstraints = false

        faqButton.title = "? 常见问题"; faqButton.bezelStyle = .rounded
        faqButton.target = self; faqButton.action = #selector(toggleFAQ)
        faqButton.translatesAutoresizingMaskIntoConstraints = false

        let inputRow = NSStackView(views: [faqButton, settingsButton, inputField, sendButton])
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
            settingsButton.widthAnchor.constraint(equalToConstant: 70),
            sendButton.widthAnchor.constraint(equalToConstant: 55),
            inputRow.heightAnchor.constraint(equalToConstant: 32),
        ])

        DispatchQueue.main.async { [weak self] in self?.showWelcome() }
    }

    private func showWelcome() {
        if DataStore.shared.aiApiKey.isEmpty {
            appendMessage("欢迎使用小冷工具箱 AI 助手！\n\n请先点击「⚙ 配置」选择服务商并填入 API Key。\n\n左下角「? 常见问题」可以查看使用帮助。", role: "system")
        } else {
            appendMessage("AI 助手已就绪！我可以帮你：\n- 分析工具箱安装状态\n- 推荐缺失工具\n- 生成批量导入列表\n\n试试问：**「帮我扫描一下还缺哪些安全工具？」**", role: "system")
        }
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

    // MARK: - Settings

    @objc private func showSettings() {
        let alert = NSAlert(); alert.messageText = "AI 服务配置"
        alert.addButton(withTitle: "保存"); alert.addButton(withTitle: "取消")
        let store = DataStore.shared
        let c = NSView(frame: NSRect(x: 0, y: 0, width: 380, height: 195))

        let pLabel = mkLabel("服务商：", y: 170)
        let pPopup = NSPopUpButton(frame: NSRect(x: 80, y: 168, width: 300, height: 26))
        for p in AIProviderCatalog.all { pPopup.addItem(withTitle: p.name); pPopup.lastItem?.representedObject = p.id }

        let kLabel = mkLabel("API Key：", y: 132)
        let kField = NSSecureTextField(frame: NSRect(x: 80, y: 132, width: 300, height: 24))
        kField.placeholderString = "sk-..."; kField.stringValue = store.aiApiKey

        let mLabel = mkLabel("模型：", y: 96)
        let mPopup = NSPopUpButton(frame: NSRect(x: 80, y: 94, width: 300, height: 26))

        let uLabel = mkLabel("API 地址：", y: 60)
        let uField = NSTextField(frame: NSRect(x: 80, y: 58, width: 300, height: 24))
        uLabel.isHidden = true; uField.isHidden = true

        let hint = NSTextField(labelWithString: "选择服务商后填入 API Key 即可，Ollama 本地无需 Key")
        hint.frame = NSRect(x: 80, y: 28, width: 300, height: 18); hint.font = .systemFont(ofSize: 11); hint.textColor = .secondaryLabelColor

        let saved = store.aiProvider.isEmpty ? "deepseek" : store.aiProvider
        if let idx = AIProviderCatalog.all.firstIndex(where: { $0.id == saved }) { pPopup.selectItem(at: idx) }
        fillModels(mPopup, pid: saved, current: store.aiModel)
        uField.stringValue = store.aiBaseUrl
        let isCustom = saved == "custom"; uLabel.isHidden = !isCustom; uField.isHidden = !isCustom

        pPopup.target = self; pPopup.action = #selector(onProvider(_:))
        objc_setAssociatedObject(pPopup, "mp", mPopup, .OBJC_ASSOCIATION_RETAIN)
        objc_setAssociatedObject(pPopup, "ul", uLabel, .OBJC_ASSOCIATION_RETAIN)
        objc_setAssociatedObject(pPopup, "uf", uField, .OBJC_ASSOCIATION_RETAIN)

        [pLabel, pPopup, kLabel, kField, mLabel, mPopup, uLabel, uField, hint].forEach { c.addSubview($0) }
        alert.accessoryView = c; alert.window.initialFirstResponder = kField
        guard alert.runModal() == .alertFirstButtonReturn else { return }

        let pid = (pPopup.selectedItem?.representedObject as? String) ?? "deepseek"
        store.aiProvider = pid; store.aiApiKey = kField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        if pid == "custom" { store.aiBaseUrl = uField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines); store.aiModel = mPopup.titleOfSelectedItem ?? "gpt-4o" }
        else if let preset = AIProviderCatalog.find(id: pid) { store.aiBaseUrl = preset.baseUrl; store.aiModel = mPopup.titleOfSelectedItem ?? preset.models[0] }
        store.save()
        appendMessage("AI 配置已更新（\(AIProviderCatalog.find(id: pid)?.name ?? pid) / \(store.aiModel)）", role: "system")
    }

    @objc private func onProvider(_ s: NSPopUpButton) {
        guard let pid = s.selectedItem?.representedObject as? String,
              let mp = objc_getAssociatedObject(s, "mp") as? NSPopUpButton,
              let ul = objc_getAssociatedObject(s, "ul") as? NSTextField,
              let uf = objc_getAssociatedObject(s, "uf") as? NSTextField else { return }
        fillModels(mp, pid: pid, current: nil)
        let ic = pid == "custom"; ul.isHidden = !ic; uf.isHidden = !ic
        if !ic, let p = AIProviderCatalog.find(id: pid) { uf.stringValue = p.baseUrl }
    }

    private func fillModels(_ popup: NSPopUpButton, pid: String, current: String?) {
        popup.removeAllItems()
        if let p = AIProviderCatalog.find(id: pid) { for m in p.models { popup.addItem(withTitle: m) } }
        if let c = current, !c.isEmpty, popup.indexOfItem(withTitle: c) == -1 { popup.addItem(withTitle: c) }
        if let c = current, !c.isEmpty { popup.selectItem(withTitle: c) }
    }

    private func mkLabel(_ t: String, y: CGFloat) -> NSTextField {
        let l = NSTextField(labelWithString: t); l.frame = NSRect(x: 0, y: y, width: 78, height: 24); l.font = .systemFont(ofSize: 12); return l
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

    // MARK: - Send & API

    @objc private func sendMessage() {
        let text = inputField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isLoading else { return }
        let store = DataStore.shared
        guard !store.aiApiKey.isEmpty || store.aiProvider == "ollama", !store.aiBaseUrl.isEmpty else {
            appendMessage("请先点击「⚙ 配置」选择服务商并填入 API Key。", role: "system"); return
        }
        inputField.stringValue = ""
        appendMessage(text, role: "user")
        isLoading = true; sendButton.isEnabled = false; sendButton.title = "..."

        var apiMsgs: [[String: String]] = []
        apiMsgs.append(["role": "system", "content": """
        你是「小冷工具箱」的 AI 助手。帮助用户管理开发和安全工具。
        能力：分析工具箱状态、推荐工具、生成导入列表、解答工具问题。
        导入格式：工具名 路径：/完整/路径（每行一个）
        当前状态：\(store.generateToolboxContext())
        用中文回答，简洁实用。
        """])
        for m in messages where m.role != "system" { apiMsgs.append(["role": m.role, "content": m.content]) }

        callAI(apiMsgs) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false; self?.sendButton.isEnabled = true; self?.sendButton.title = "发送"
                switch result {
                case .success(let reply): self?.appendMessage(reply, role: "assistant")
                case .failure(let err): self?.appendMessage("请求失败: \(err.localizedDescription)", role: "system")
                }
            }
        }
    }

    private func callAI(_ msgs: [[String: String]], completion: @escaping (Result<String, Error>) -> Void) {
        let store = DataStore.shared
        var base = store.aiBaseUrl; if base.hasSuffix("/") { base = String(base.dropLast()) }
        guard let url = URL(string: "\(base)/chat/completions") else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "无效 API 地址"]))); return
        }
        var req = URLRequest(url: url); req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if !store.aiApiKey.isEmpty { req.setValue("Bearer \(store.aiApiKey)", forHTTPHeaderField: "Authorization") }
        req.timeoutInterval = 120
        req.httpBody = try? JSONSerialization.data(withJSONObject: ["model": store.aiModel, "messages": msgs, "temperature": 0.7, "max_tokens": 4096])

        URLSession.shared.dataTask(with: req) { data, resp, err in
            if let err = err { completion(.failure(err)); return }
            guard let data = data else { completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "无响应"]))); return }
            if let h = resp as? HTTPURLResponse, h.statusCode != 200 {
                let b = String(data: data, encoding: .utf8) ?? "?"; completion(.failure(NSError(domain: "", code: h.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP \(h.statusCode): \(String(b.prefix(200)))"]))); return
            }
            do {
                let j = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                let ch = j?["choices"] as? [[String: Any]]
                let msg = ch?.first?["message"] as? [String: Any]
                completion(.success(msg?["content"] as? String ?? "无响应"))
            } catch { completion(.failure(error)) }
        }.resume()
    }
}
