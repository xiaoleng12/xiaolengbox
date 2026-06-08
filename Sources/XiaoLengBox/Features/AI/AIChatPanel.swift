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
                         models: ["deepseek-chat", "deepseek-reasoner"]),
        AIProviderPreset(id: "openai", name: "OpenAI", baseUrl: "https://api.openai.com/v1",
                         models: ["gpt-4o", "gpt-4o-mini", "gpt-4-turbo", "gpt-3.5-turbo"]),
        AIProviderPreset(id: "moonshot", name: "Moonshot (月之暗面)", baseUrl: "https://api.moonshot.cn/v1",
                         models: ["moonshot-v1-8k", "moonshot-v1-32k", "moonshot-v1-128k"]),
        AIProviderPreset(id: "zhipu", name: "智谱 AI (GLM)", baseUrl: "https://open.bigmodel.cn/api/paas/v4",
                         models: ["glm-4-plus", "glm-4-flash", "glm-4-long"]),
        AIProviderPreset(id: "siliconflow", name: "SiliconFlow", baseUrl: "https://api.siliconflow.cn/v1",
                         models: ["deepseek-ai/DeepSeek-V3", "deepseek-ai/DeepSeek-R1",
                                  "Qwen/Qwen2.5-72B-Instruct", "THUDM/glm-4-9b-chat"]),
        AIProviderPreset(id: "ollama", name: "Ollama (本地)", baseUrl: "http://localhost:11434/v1",
                         models: ["llama3", "qwen2", "deepseek-r1", "codellama", "mistral"]),
        AIProviderPreset(id: "custom", name: "自定义", baseUrl: "", models: []),
    ]

    static func find(id: String) -> AIProviderPreset? {
        all.first { $0.id == id }
    }
}

// MARK: - FAQ Entries

struct FAQEntry {
    let question: String
    let answer: String
}

enum FAQCatalog {
    static let entries: [FAQEntry] = [
        FAQEntry(
            question: "如何添加工具？",
            answer: "点击右上角「＋ 添加工具」按钮，输入工具名称和可执行文件路径即可。\n\n例如添加 VS Code：\n- 名称：`VS Code`\n- 路径：`/usr/local/bin/code`\n\n工具箱会自动检测路径是否存在，并在工具图标旁显示安装状态。"
        ),
        FAQEntry(
            question: "如何批量导入工具？",
            answer: "点击右上角「↓ 导入工具」按钮，按以下格式粘贴文本（每行一个工具）：\n\n```\nnmap 路径：/opt/homebrew/bin/nmap\nhydra 路径：/opt/homebrew/bin/hydra\nwireshark 路径：/Applications/Wireshark.app\n```\n\n支持 `.app` 应用路径和命令行工具路径。"
        ),
        FAQEntry(
            question: "安装指引怎么用？",
            answer: "点击顶部「? 安装指引」按钮，会弹出所有工具的安装命令：\n- `brew install nmap`\n- `brew install hydra`\n- 或直接打开下载链接\n\n点击每条旁边的复制按钮即可复制到剪贴板。你还可以点「编辑」自定义安装提示。"
        ),
        FAQEntry(
            question: "如何使用 AI 助手？",
            answer: "1. 点击顶部「AI 助手」进入聊天面板\n2. 点击「⚙ 配置」选择服务商（如 DeepSeek）\n3. 填入 API Key，选择模型\n4. 保存后即可与 AI 对话\n\nAI 会自动读取你的工具箱状态，可以帮你分析缺失工具、推荐安装、生成导入列表。"
        ),
        FAQEntry(
            question: "支持哪些 AI 服务商？",
            answer: "目前支持以下服务商（选一个填 Key 即可）：\n- **DeepSeek** — 性价比高，推荐国内用户\n- **OpenAI** — GPT-4o 等模型\n- **Moonshot** — 月之暗面，支持长文本\n- **智谱 AI** — GLM 系列模型\n- **SiliconFlow** — 多种开源模型聚合\n- **Ollama** — 本地运行开源模型（无需 API Key）\n- **自定义** — 任何兼容 OpenAI 格式的 API"
        ),
        FAQEntry(
            question: "工具检测状态含义？",
            answer: "工具图标旁的状态标记：\n- **绿色 ✓** — 已检测到安装\n- **蓝色 ✓** — 自定义路径（手动指定）\n- **红色 ✗** — 未找到，需要安装\n\n点击工具图标可以直接启动（已安装的情况下）。"
        ),
        FAQEntry(
            question: "如何设置壁纸和玻璃模式？",
            answer: "1. 点击「壁纸」按钮选择一张图片作为背景\n2. 点击「✦ 玻璃」切换玻璃模糊模式\n3. 拖动滑块调整玻璃透明度\n4. 点击「✕ 清除」移除壁纸恢复默认\n\n玻璃模式下工具卡片会有半透明磨砂效果。"
        ),
    ]
}

// MARK: - FAQ Panel (Bottom-Left Overlay)

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
        buildUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func buildUI() {
        // Header
        let header = NSStackView()
        header.orientation = .horizontal
        header.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = NSTextField(labelWithString: "常见问题")
        titleLabel.font = .boldSystemFont(ofSize: 14)

        let closeBtn = NSButton(title: "✕", target: self, action: #selector(closePanel))
        closeBtn.bezelStyle = .inline
        closeBtn.isBordered = false
        closeBtn.font = .systemFont(ofSize: 14)
        closeBtn.contentTintColor = .secondaryLabelColor

        header.addArrangedSubview(titleLabel)
        header.addArrangedSubview(NSView())  // spacer
        header.addArrangedSubview(closeBtn)

        // Scroll area for questions
        let scroll = NSScrollView()
        scroll.hasVerticalScroller = true
        scroll.drawsBackground = false
        scroll.translatesAutoresizingMaskIntoConstraints = false

        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 2
        stack.translatesAutoresizingMaskIntoConstraints = false

        for (idx, faq) in FAQCatalog.entries.enumerated() {
            let btn = NSButton(title: "  \(faq.question)", target: self, action: #selector(tapFAQ(_:)))
            btn.bezelStyle = .inline
            btn.isBordered = false
            btn.font = .systemFont(ofSize: 13)
            btn.contentTintColor = NSColor(red: 0.2, green: 0.45, blue: 0.85, alpha: 1)
            btn.alignment = .left
            btn.tag = idx
            btn.translatesAutoresizingMaskIntoConstraints = false
            stack.addArrangedSubview(btn)
        }

        scroll.documentView = stack
        addSubview(header)
        addSubview(scroll)

        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            header.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            header.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            header.heightAnchor.constraint(equalToConstant: 28),

            scroll.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 4),
            scroll.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 6),
            scroll.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -6),
            scroll.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),

            stack.topAnchor.constraint(equalTo: scroll.contentView.topAnchor),
            stack.leadingAnchor.constraint(equalTo: scroll.contentView.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: scroll.contentView.trailingAnchor),
        ])
    }

    @objc private func tapFAQ(_ sender: NSButton) {
        guard sender.tag < FAQCatalog.entries.count else { return }
        onQuestionTapped?(FAQCatalog.entries[sender.tag])
    }

    @objc private func closePanel() {
        onClose?()
    }
}

// MARK: - Chat Bubble View (IM Style)

private class ChatBubbleView: NSView {

    init(text: String, role: String) {
        super.init(frame: .zero)
        wantsLayer = true

        let isUser = role == "user"
        let isSystem = role == "system"

        // Avatar
        let avatar = NSView()
        avatar.wantsLayer = true
        avatar.layer?.cornerRadius = 16
        avatar.translatesAutoresizingMaskIntoConstraints = false

        let avatarLabel = NSTextField(labelWithString: isSystem ? "💡" : (isUser ? "我" : "AI"))
        avatarLabel.font = .systemFont(ofSize: isSystem ? 14 : 12, weight: .medium)
        avatarLabel.alignment = .center
        avatarLabel.textColor = .white
        avatarLabel.translatesAutoresizingMaskIntoConstraints = false
        avatar.addSubview(avatarLabel)

        NSLayoutConstraint.activate([
            avatar.widthAnchor.constraint(equalToConstant: 32),
            avatar.heightAnchor.constraint(equalToConstant: 32),
            avatarLabel.centerXAnchor.constraint(equalTo: avatar.centerXAnchor),
            avatarLabel.centerYAnchor.constraint(equalTo: avatar.centerYAnchor),
        ])

        let avatarBg: NSColor
        if isSystem { avatarBg = NSColor(white: 0.4, alpha: 1) }
        else if isUser { avatarBg = NSColor(red: 0.35, green: 0.65, blue: 1.0, alpha: 1) }
        else { avatarBg = NSColor(red: 0.45, green: 0.80, blue: 0.45, alpha: 1) }
        avatar.layer?.backgroundColor = avatarBg.cgColor

        // Name
        let nameLabel = NSTextField(labelWithString: isSystem ? "系统提示" : (isUser ? "我" : "AI 助手"))
        nameLabel.font = .systemFont(ofSize: 11)
        nameLabel.textColor = .secondaryLabelColor
        nameLabel.translatesAutoresizingMaskIntoConstraints = false

        // Bubble
        let bubble = NSView()
        bubble.wantsLayer = true
        bubble.layer?.cornerRadius = 10
        bubble.translatesAutoresizingMaskIntoConstraints = false

        let bubbleBg: NSColor
        if isSystem { bubbleBg = NSColor(white: 0.93, alpha: 1) }
        else if isUser { bubbleBg = NSColor(red: 0.57, green: 0.77, blue: 0.36, alpha: 1) }
        else { bubbleBg = NSColor(white: 0.95, alpha: 1) }
        bubble.layer?.backgroundColor = bubbleBg.cgColor

        // Text
        let textView = NSTextView()
        textView.isEditable = false
        textView.isSelectable = true
        textView.drawsBackground = false
        textView.isRichText = false
        textView.textContainerInset = .zero
        textView.textContainer?.lineFragmentPadding = 0
        textView.translatesAutoresizingMaskIntoConstraints = false

        let maxTextWidth: CGFloat = 380
        textView.maxSize = NSSize(width: maxTextWidth, height: .greatestFiniteMagnitude)

        textView.textStorage?.setAttributedString(
            MarkdownRenderer.render(text, compact: isSystem)
        )

        textView.layoutManager?.ensureLayout(for: textView.textContainer!)
        let usedRect = textView.layoutManager!.usedRect(for: textView.textContainer!)
        let textHeight = max(ceil(usedRect.height) + 4, 20)
        let textWidth = min(ceil(usedRect.width) + 4, maxTextWidth)

        bubble.addSubview(textView)
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: bubble.topAnchor, constant: 10),
            textView.leadingAnchor.constraint(equalTo: bubble.leadingAnchor, constant: 14),
            textView.trailingAnchor.constraint(equalTo: bubble.trailingAnchor, constant: -14),
            textView.bottomAnchor.constraint(equalTo: bubble.bottomAnchor, constant: -10),
            textView.widthAnchor.constraint(equalToConstant: textWidth),
            textView.heightAnchor.constraint(equalToConstant: textHeight),
        ])

        // Copy button
        if !isSystem {
            let copyBtn = NSButton(title: "复制", target: self, action: #selector(copyText(_:)))
            copyBtn.bezelStyle = .inline
            copyBtn.isBordered = false
            copyBtn.font = .systemFont(ofSize: 10)
            copyBtn.contentTintColor = isUser
                ? NSColor.white.withAlphaComponent(0.6)
                : NSColor.black.withAlphaComponent(0.3)
            copyBtn.toolTip = text
            copyBtn.translatesAutoresizingMaskIntoConstraints = false
            bubble.addSubview(copyBtn)
            NSLayoutConstraint.activate([
                copyBtn.trailingAnchor.constraint(equalTo: bubble.trailingAnchor, constant: -6),
                copyBtn.bottomAnchor.constraint(equalTo: bubble.bottomAnchor, constant: -2),
            ])
        }

        // Assemble
        addSubview(nameLabel)
        addSubview(avatar)
        addSubview(bubble)

        let bubbleH = textHeight + 20

        if isUser {
            NSLayoutConstraint.activate([
                nameLabel.topAnchor.constraint(equalTo: topAnchor),
                nameLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
                avatar.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
                avatar.trailingAnchor.constraint(equalTo: trailingAnchor),
                bubble.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
                bubble.trailingAnchor.constraint(equalTo: avatar.leadingAnchor, constant: -8),
                bubble.bottomAnchor.constraint(equalTo: bottomAnchor),
                bubble.heightAnchor.constraint(equalToConstant: bubbleH),
            ])
        } else {
            NSLayoutConstraint.activate([
                nameLabel.topAnchor.constraint(equalTo: topAnchor),
                nameLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 40),
                avatar.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
                avatar.leadingAnchor.constraint(equalTo: leadingAnchor),
                bubble.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
                bubble.leadingAnchor.constraint(equalTo: avatar.trailingAnchor, constant: 8),
                bubble.bottomAnchor.constraint(equalTo: bottomAnchor),
                bubble.heightAnchor.constraint(equalToConstant: bubbleH),
            ])
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    @objc private func copyText(_ sender: NSButton) {
        guard let text = sender.toolTip else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        let orig = sender.title
        sender.title = "✓ 已复制"
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { sender.title = orig }
    }
}

// MARK: - Markdown Renderer

private enum MarkdownRenderer {

    static func render(_ text: String, compact: Bool = false) -> NSAttributedString {
        let result = NSMutableAttributedString()
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        var inCodeBlock = false
        var codeLines: [String] = []

        for (i, line) in lines.enumerated() {
            if line.trimmingCharacters(in: .whitespaces).hasPrefix("```") {
                if inCodeBlock {
                    result.append(makeCodeBlock(codeLines.joined(separator: "\n")))
                    codeLines = []
                    inCodeBlock = false
                } else { inCodeBlock = true }
                if i < lines.count - 1 { result.append(nl(compact)) }
                continue
            }
            if inCodeBlock { codeLines.append(line); continue }

            let t = line.trimmingCharacters(in: .whitespaces)
            if t.isEmpty {
                if i < lines.count - 1 { result.append(nl(compact)) }
            } else if t.hasPrefix("### ") {
                result.append(heading(String(t.dropFirst(4)), level: 3, compact: compact))
            } else if t.hasPrefix("## ") {
                result.append(heading(String(t.dropFirst(3)), level: 2, compact: compact))
            } else if t.hasPrefix("# ") {
                result.append(heading(String(t.dropFirst(2)), level: 1, compact: compact))
            } else if t.hasPrefix("- ") || t.hasPrefix("* ") {
                result.append(bullet(String(t.dropFirst(2)), compact: compact))
            } else if let m = t.range(of: #"^\d+\.\s"#, options: .regularExpression) {
                let num = String(t[..<m.upperBound])
                result.append(numbered(num, String(t[m.upperBound...]), compact: compact))
            } else {
                result.append(inline(t, size: compact ? 12 : 13))
            }
            if i < lines.count - 1 { result.append(nl(compact)) }
        }
        if inCodeBlock && !codeLines.isEmpty {
            result.append(makeCodeBlock(codeLines.joined(separator: "\n")))
        }
        return result
    }

    private static func nl(_ c: Bool) -> NSAttributedString {
        let s = NSMutableAttributedString(string: "\n")
        let p = NSMutableParagraphStyle(); p.paragraphSpacing = c ? 2 : 3
        s.addAttribute(.paragraphStyle, value: p, range: NSRange(location: 0, length: 1))
        return s
    }

    private static func heading(_ t: String, level: Int, compact: Bool) -> NSAttributedString {
        let sizes: [Int: CGFloat] = [1: 18, 2: 16, 3: 14]
        let a = NSMutableAttributedString()
        a.append(inline(t, size: sizes[level] ?? 14, bold: true))
        let p = NSMutableParagraphStyle()
        p.paragraphSpacingBefore = compact ? 4 : 8; p.paragraphSpacing = compact ? 2 : 4
        a.addAttribute(.paragraphStyle, value: p, range: NSRange(location: 0, length: a.length))
        return a
    }

    private static func bullet(_ t: String, compact: Bool) -> NSAttributedString {
        let a = NSMutableAttributedString(string: "•  ", attributes: [
            .font: NSFont.systemFont(ofSize: compact ? 12 : 13), .foregroundColor: NSColor.labelColor])
        a.append(inline(t, size: compact ? 12 : 13))
        let p = NSMutableParagraphStyle(); p.headIndent = 14; p.paragraphSpacing = 1
        a.addAttribute(.paragraphStyle, value: p, range: NSRange(location: 0, length: a.length))
        return a
    }

    private static func numbered(_ num: String, _ body: String, compact: Bool) -> NSAttributedString {
        let a = NSMutableAttributedString(string: num, attributes: [
            .font: NSFont.systemFont(ofSize: compact ? 12 : 13), .foregroundColor: NSColor.labelColor])
        a.append(inline(body, size: compact ? 12 : 13))
        let p = NSMutableParagraphStyle(); p.headIndent = 18; p.paragraphSpacing = 1
        a.addAttribute(.paragraphStyle, value: p, range: NSRange(location: 0, length: a.length))
        return a
    }

    private static func makeCodeBlock(_ code: String) -> NSAttributedString {
        let c = code.hasSuffix("\n") ? String(code.dropLast()) : code
        let a = NSMutableAttributedString(string: c, attributes: [
            .font: NSFont.monospacedSystemFont(ofSize: 12, weight: .regular),
            .foregroundColor: NSColor(red: 0.85, green: 0.25, blue: 0.45, alpha: 1),
            .backgroundColor: NSColor(white: 0.94, alpha: 1)])
        let p = NSMutableParagraphStyle()
        p.paragraphSpacingBefore = 6; p.paragraphSpacing = 4; p.headIndent = 8; p.tailIndent = -8
        a.addAttribute(.paragraphStyle, value: p, range: NSRange(location: 0, length: a.length))
        return a
    }

    private static func inline(_ text: String, size: CGFloat, bold: Bool = false) -> NSAttributedString {
        let base: [NSAttributedString.Key: Any] = [
            .font: bold ? NSFont.boldSystemFont(ofSize: size) : NSFont.systemFont(ofSize: size),
            .foregroundColor: NSColor.labelColor]
        let a = NSMutableAttributedString(string: text, attributes: base)

        // `code`
        applyRegex(a, "`([^`]+)`", size: size) { s, r in
            s.addAttribute(.font, value: NSFont.monospacedSystemFont(ofSize: size - 1, weight: .regular), range: r)
            s.addAttribute(.backgroundColor, value: NSColor(white: 0.90, alpha: 1), range: r)
            s.addAttribute(.foregroundColor, value: NSColor(red: 0.80, green: 0.20, blue: 0.40, alpha: 1), range: r)
        }
        // **bold**
        applyRegex(a, "\\*\\*([^*]+)\\*\\*", size: size) { s, r in
            s.addAttribute(.font, value: NSFont.boldSystemFont(ofSize: size), range: r)
        }
        // *italic*
        applyRegex(a, "(?<!\\*)\\*(?!\\*)([^*]+)\\*(?!\\*)", size: size) { s, r in
            s.addAttribute(.font, value: NSFontManager.shared.convert(NSFont.systemFont(ofSize: size), toHaveTrait: .italicFontMask), range: r)
        }
        // [link](url)
        if let re = try? NSRegularExpression(pattern: "\\[([^\\]]+)\\]\\(([^)]+)\\)") {
            for m in re.matches(in: a.string, range: NSRange(location: 0, length: a.length)).reversed() {
                guard m.numberOfRanges >= 3 else { continue }
                let urlStr = a.attributedSubstring(from: m.range(at: 2)).string
                let linkText = a.attributedSubstring(from: m.range(at: 1)).string
                guard let url = URL(string: urlStr) else { continue }
                let link = NSMutableAttributedString(string: linkText, attributes: [
                    .font: NSFont.systemFont(ofSize: size), .foregroundColor: NSColor.linkColor,
                    .link: url, .underlineStyle: NSUnderlineStyle.single.rawValue])
                a.replaceCharacters(in: m.range, with: link)
            }
        }
        return a
    }

    private static func applyRegex(_ a: NSMutableAttributedString, _ pattern: String, size: CGFloat, apply: (NSMutableAttributedString, NSRange) -> Void) {
        guard let re = try? NSRegularExpression(pattern: pattern) else { return }
        for m in re.matches(in: a.string, range: NSRange(location: 0, length: a.length)).reversed() {
            guard m.numberOfRanges >= 2 else { continue }
            let inner = m.range(at: 1)
            let content = a.attributedSubstring(from: inner)
            let rep = NSMutableAttributedString(attributedString: content)
            a.replaceCharacters(in: m.range, with: rep)
            let nr = NSRange(location: m.range.location, length: content.length)
            if nr.location + nr.length <= a.length { apply(a, nr) }
        }
    }
}

// MARK: - AI Chat Panel (Main)

class AIChatPanel: NSView {

    private let scrollView = NSScrollView()
    private let chatContainer = NSView()
    private let inputField = NSTextField()
    private let sendButton = NSButton()
    private let settingsButton = NSButton()
    private let faqButton = NSButton()
    private var messages: [ChatMessage] = []
    private var isLoading = false
    private var faqPanel: FAQPanelView?

    struct ChatMessage {
        let role: String
        let content: String
    }

    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
        buildUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - UI Setup

    private func buildUI() {
        chatContainer.wantsLayer = true
        chatContainer.translatesAutoresizingMaskIntoConstraints = false
        scrollView.documentView = chatContainer
        scrollView.hasVerticalScroller = true
        scrollView.drawsBackground = false
        scrollView.automaticallyAdjustsContentInsets = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        // Input
        inputField.placeholderString = "输入消息… (例如: 帮我推荐安全工具并生成导入列表)"
        inputField.font = .systemFont(ofSize: 13)
        inputField.isEditable = true
        inputField.bezelStyle = .roundedBezel
        inputField.target = self
        inputField.action = #selector(sendMessage)
        inputField.translatesAutoresizingMaskIntoConstraints = false

        sendButton.title = "发送"
        sendButton.bezelStyle = .rounded
        sendButton.target = self
        sendButton.action = #selector(sendMessage)
        sendButton.keyEquivalent = "\r"
        sendButton.translatesAutoresizingMaskIntoConstraints = false

        settingsButton.title = "⚙ 配置"
        settingsButton.bezelStyle = .rounded
        settingsButton.target = self
        settingsButton.action = #selector(showSettings)
        settingsButton.translatesAutoresizingMaskIntoConstraints = false

        faqButton.title = "? 常见问题"
        faqButton.bezelStyle = .rounded
        faqButton.target = self
        faqButton.action = #selector(toggleFAQ)
        faqButton.translatesAutoresizingMaskIntoConstraints = false

        let inputRow = NSStackView(views: [faqButton, settingsButton, inputField, sendButton])
        inputRow.orientation = .horizontal
        inputRow.spacing = 8
        inputRow.translatesAutoresizingMaskIntoConstraints = false

        addSubview(scrollView)
        addSubview(inputRow)

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

        // Init container size after layout
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let h = max(self.scrollView.contentSize.height, 100)
            self.chatContainer.frame = NSRect(x: 0, y: 0, width: self.scrollView.contentSize.width, height: h)
            self.showWelcome()
        }
    }

    private func showWelcome() {
        if DataStore.shared.aiApiKey.isEmpty {
            appendMessage("欢迎使用小冷工具箱 AI 助手！\n\n请先点击「⚙ 配置」选择服务商并填入 API Key。\n\n左下角「? 常见问题」可以查看使用帮助。", role: "system")
        } else {
            appendMessage("AI 助手已就绪！我可以帮你：\n- 分析当前工具箱的安装状态\n- 推荐缺失的安全/开发工具\n- 生成批量导入列表\n- 回答工具使用问题\n\n试试问：**「帮我扫描一下还缺哪些安全工具？」**", role: "system")
        }
    }

    // MARK: - FAQ Panel

    @objc private func toggleFAQ() {
        if let panel = faqPanel {
            panel.removeFromSuperview()
            faqPanel = nil
            return
        }

        let panel = FAQPanelView(frame: .zero)
        panel.translatesAutoresizingMaskIntoConstraints = false
        panel.onQuestionTapped = { [weak self] entry in
            self?.appendMessage(entry.question, role: "user")
            self?.appendMessage(entry.answer, role: "assistant")
            self?.toggleFAQ() // close panel after selection
        }
        panel.onClose = { [weak self] in
            self?.toggleFAQ()
        }

        addSubview(panel)
        NSLayoutConstraint.activate([
            panel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            panel.bottomAnchor.constraint(equalTo: inputRow.bottomAnchor, constant: 40),
            panel.widthAnchor.constraint(equalToConstant: 280),
            panel.heightAnchor.constraint(equalToConstant: 320),
        ])
        faqPanel = panel
    }

    // Need a reference to inputRow for constraint
    private var inputRow: NSStackView {
        subviews.compactMap { $0 as? NSStackView }.first ?? NSStackView()
    }

    // MARK: - Settings Dialog (Preset Providers)

    @objc private func showSettings() {
        let alert = NSAlert()
        alert.messageText = "AI 服务配置"
        alert.addButton(withTitle: "保存")
        alert.addButton(withTitle: "取消")

        let store = DataStore.shared
        let container = NSView(frame: NSRect(x: 0, y: 0, width: 380, height: 195))

        // Provider dropdown
        let providerLabel = makeLabel("服务商：", y: 170)
        let providerPopup = NSPopUpButton(frame: NSRect(x: 80, y: 168, width: 300, height: 26))
        for p in AIProviderCatalog.all {
            providerPopup.addItem(withTitle: p.name)
            providerPopup.lastItem?.representedObject = p.id
        }

        // API Key
        let keyLabel = makeLabel("API Key：", y: 132)
        let keyField = NSSecureTextField(frame: NSRect(x: 80, y: 132, width: 300, height: 24))
        keyField.placeholderString = "sk-..."
        keyField.stringValue = store.aiApiKey

        // Model dropdown
        let modelLabel = makeLabel("模型：", y: 96)
        let modelPopup = NSPopUpButton(frame: NSRect(x: 80, y: 94, width: 300, height: 26))

        // Custom URL (hidden by default)
        let urlLabel = makeLabel("API 地址：", y: 60)
        let urlField = NSTextField(frame: NSRect(x: 80, y: 58, width: 300, height: 24))
        urlLabel.isHidden = true
        urlField.isHidden = true

        // Hint
        let hintLabel = NSTextField(labelWithString: "选择服务商后填入 API Key 即可，Ollama 本地无需 Key")
        hintLabel.frame = NSRect(x: 80, y: 28, width: 300, height: 18)
        hintLabel.font = .systemFont(ofSize: 11)
        hintLabel.textColor = .secondaryLabelColor

        // Restore previous selection
        let savedProvider = store.aiProvider.isEmpty ? "deepseek" : store.aiProvider
        if let idx = AIProviderCatalog.all.firstIndex(where: { $0.id == savedProvider }) {
            providerPopup.selectItem(at: idx)
        }
        populateModels(modelPopup, providerId: savedProvider, currentModel: store.aiModel)
        urlField.stringValue = store.aiBaseUrl
        urlLabel.isHidden = savedProvider != "custom"
        urlField.isHidden = savedProvider != "custom"

        // Provider change handler
        providerPopup.target = self
        providerPopup.action = #selector(providerChanged(_:))

        // Store references for handler via associated objects
        objc_setAssociatedObject(providerPopup, "modelPopup", modelPopup, .OBJC_ASSOCIATION_RETAIN)
        objc_setAssociatedObject(providerPopup, "urlLabel", urlLabel, .OBJC_ASSOCIATION_RETAIN)
        objc_setAssociatedObject(providerPopup, "urlField", urlField, .OBJC_ASSOCIATION_RETAIN)

        [providerLabel, providerPopup, keyLabel, keyField, modelLabel, modelPopup,
         urlLabel, urlField, hintLabel].forEach { container.addSubview($0) }

        alert.accessoryView = container
        alert.window.initialFirstResponder = keyField

        guard alert.runModal() == .alertFirstButtonReturn else { return }

        // Save
        let selectedId = (providerPopup.selectedItem?.representedObject as? String) ?? "deepseek"
        store.aiProvider = selectedId
        store.aiApiKey = keyField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)

        if selectedId == "custom" {
            store.aiBaseUrl = urlField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            store.aiModel = modelPopup.titleOfSelectedItem ?? "gpt-4o"
        } else if let preset = AIProviderCatalog.find(id: selectedId) {
            store.aiBaseUrl = preset.baseUrl
            store.aiModel = modelPopup.titleOfSelectedItem ?? preset.models.first ?? "gpt-4o"
        }
        store.save()

        appendMessage("AI 配置已更新（\(AIProviderCatalog.find(id: store.aiProvider)?.name ?? store.aiProvider) / \(store.aiModel)），可以开始对话了！", role: "system")
    }

    @objc private func providerChanged(_ sender: NSPopUpButton) {
        guard let providerId = sender.selectedItem?.representedObject as? String else { return }
        guard let modelPopup = objc_getAssociatedObject(sender, "modelPopup") as? NSPopUpButton,
              let urlLabel = objc_getAssociatedObject(sender, "urlLabel") as? NSTextField,
              let urlField = objc_getAssociatedObject(sender, "urlField") as? NSTextField else { return }

        populateModels(modelPopup, providerId: providerId, currentModel: nil)
        let isCustom = providerId == "custom"
        urlLabel.isHidden = !isCustom
        urlField.isHidden = !isCustom
        if !isCustom, let preset = AIProviderCatalog.find(id: providerId) {
            urlField.stringValue = preset.baseUrl
        }
    }

    private func populateModels(_ popup: NSPopUpButton, providerId: String, currentModel: String?) {
        popup.removeAllItems()
        if let preset = AIProviderCatalog.find(id: providerId) {
            for m in preset.models { popup.addItem(withTitle: m) }
        }
        if let model = currentModel, !model.isEmpty, popup.indexOfItem(withTitle: model) == -1 {
            popup.addItem(withTitle: model)
        }
        if let model = currentModel, !model.isEmpty { popup.selectItem(withTitle: model) }
    }

    private func makeLabel(_ text: String, y: CGFloat) -> NSTextField {
        let l = NSTextField(labelWithString: text)
        l.frame = NSRect(x: 0, y: y, width: 78, height: 24)
        l.font = .systemFont(ofSize: 12)
        return l
    }

    // MARK: - Message Display

    private func appendMessage(_ text: String, role: String) {
        messages.append(ChatMessage(role: role, content: text))

        let bubble = ChatBubbleView(text: text, role: role)
        bubble.translatesAutoresizingMaskIntoConstraints = false
        chatContainer.addSubview(bubble)

        let prevCount = chatContainer.subviews.count - 1
        let topC: NSLayoutConstraint
        if prevCount > 0 {
            topC = bubble.topAnchor.constraint(equalTo: chatContainer.subviews[prevCount - 1].bottomAnchor, constant: 14)
        } else {
            topC = bubble.topAnchor.constraint(equalTo: chatContainer.topAnchor, constant: 8)
        }

        NSLayoutConstraint.activate([
            topC,
            bubble.leadingAnchor.constraint(equalTo: chatContainer.leadingAnchor, constant: 8),
            bubble.trailingAnchor.constraint(equalTo: chatContainer.trailingAnchor, constant: -8),
        ])

        chatContainer.layoutSubtreeIfNeeded()
        updateContainerHeight()
        scrollToBottom()
    }

    private func updateContainerHeight() {
        let maxY = chatContainer.subviews.reduce(CGFloat(0)) { max($0, $1.frame.maxY) } + 8
        let w = scrollView.contentSize.width > 0 ? scrollView.contentSize.width : chatContainer.frame.width
        let h = max(maxY, scrollView.contentSize.height)
        chatContainer.frame = NSRect(x: 0, y: 0, width: w, height: h)
    }

    private func scrollToBottom() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self, let last = self.chatContainer.subviews.last else { return }
            let targetY = max(0, last.frame.maxY - self.scrollView.contentSize.height + 8)
            self.scrollView.contentView.scroll(to: NSPoint(x: 0, y: targetY))
            self.scrollView.reflectScrolledClipView(self.scrollView.contentView)
        }
    }

    // MARK: - Send Message & API

    @objc private func sendMessage() {
        let text = inputField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isLoading else { return }

        let store = DataStore.shared
        guard !store.aiApiKey.isEmpty || store.aiProvider == "ollama", !store.aiBaseUrl.isEmpty else {
            appendMessage("请先点击「⚙ 配置」选择服务商并填入 API Key。", role: "system")
            return
        }

        inputField.stringValue = ""
        appendMessage(text, role: "user")
        isLoading = true
        sendButton.isEnabled = false
        sendButton.title = "..."

        var apiMessages: [[String: String]] = []
        let systemPrompt = """
        你是「小冷工具箱」的 AI 助手。你帮助用户管理和优化他们的开发工具和安全工具集合。

        你的能力：
        1. 分析当前工具箱状态，指出缺失的工具
        2. 推荐适合用户需求的工具
        3. 生成符合导入格式的工具列表（用户可直接用于批量导入）
        4. 解答工具使用问题和安全最佳实践

        批量导入格式（重要）：
        当用户要求生成工具列表时，请按以下格式输出，每行一个：
        工具名 路径：/完整/安装/路径
        例如：hydra 路径：/opt/homebrew/bin/hydra

        当前工具箱状态：
        \(store.generateToolboxContext())

        请用中文回答，简洁实用。当推荐工具时，优先推荐 macOS 上常用的安全/开发工具。
        """

        apiMessages.append(["role": "system", "content": systemPrompt])
        for msg in messages where msg.role != "system" {
            apiMessages.append(["role": msg.role, "content": msg.content])
        }

        callAI(messages: apiMessages) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                self?.sendButton.isEnabled = true
                self?.sendButton.title = "发送"
                switch result {
                case .success(let reply):
                    self?.appendMessage(reply, role: "assistant")
                case .failure(let error):
                    self?.appendMessage("请求失败: \(error.localizedDescription)", role: "system")
                }
            }
        }
    }

    private func callAI(messages: [[String: String]], completion: @escaping (Result<String, Error>) -> Void) {
        let store = DataStore.shared
        var baseUrl = store.aiBaseUrl
        if baseUrl.hasSuffix("/") { baseUrl = String(baseUrl.dropLast()) }
        let urlStr = "\(baseUrl)/chat/completions"

        guard let url = URL(string: urlStr) else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "无效的 API 地址: \(urlStr)"])))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if !store.aiApiKey.isEmpty {
            request.setValue("Bearer \(store.aiApiKey)", forHTTPHeaderField: "Authorization")
        }
        request.timeoutInterval = 120

        let body: [String: Any] = [
            "model": store.aiModel,
            "messages": messages,
            "temperature": 0.7,
            "max_tokens": 4096
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "无响应数据"])))
                return
            }
            if let http = response as? HTTPURLResponse, http.statusCode != 200 {
                let body = String(data: data, encoding: .utf8) ?? "Unknown"
                completion(.failure(NSError(domain: "", code: http.statusCode,
                    userInfo: [NSLocalizedDescriptionKey: "HTTP \(http.statusCode): \(body.prefix(200))"])))
                return
            }
            do {
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                let choices = json?["choices"] as? [[String: Any]]
                let message = choices?.first?["message"] as? [String: Any]
                let content = message?["content"] as? String ?? "无响应内容"
                completion(.success(content))
            } catch {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "解析响应失败: \(error.localizedDescription)"])))
            }
        }.resume()
    }
}
