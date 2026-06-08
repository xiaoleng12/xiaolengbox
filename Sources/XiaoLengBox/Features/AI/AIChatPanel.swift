import AppKit

// MARK: - Chat Bubble View (IM Style)

private class ChatBubbleView: NSView {

    init(text: String, role: String) {
        super.init(frame: .zero)
        wantsLayer = true

        let isUser = role == "user"
        let isSystem = role == "system"

        // ---- Avatar ----
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

        // ---- Name Label ----
        let nameLabel = NSTextField(labelWithString: isSystem ? "系统提示" : (isUser ? "我" : "AI 助手"))
        nameLabel.font = .systemFont(ofSize: 11)
        nameLabel.textColor = .secondaryLabelColor
        nameLabel.translatesAutoresizingMaskIntoConstraints = false

        // ---- Bubble ----
        let bubble = NSView()
        bubble.wantsLayer = true
        bubble.layer?.cornerRadius = 10
        bubble.translatesAutoresizingMaskIntoConstraints = false

        let bubbleBg: NSColor
        if isSystem { bubbleBg = NSColor(white: 0.93, alpha: 1) }
        else if isUser { bubbleBg = NSColor(red: 0.57, green: 0.77, blue: 0.36, alpha: 1) }
        else { bubbleBg = NSColor(white: 0.95, alpha: 1) }
        bubble.layer?.backgroundColor = bubbleBg.cgColor

        // ---- Text View (Markdown) ----
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

        if isSystem {
            textView.textStorage?.setAttributedString(MarkdownRenderer.render(text, compact: true))
        } else {
            textView.textStorage?.setAttributedString(MarkdownRenderer.render(text))
        }

        // Measure text height
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

        // ---- Copy Button (assistant/user only) ----
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

        // ---- Assemble ----
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

        for (lineIdx, line) in lines.enumerated() {
            // --- fenced code block toggle ---
            if line.trimmingCharacters(in: .whitespaces).hasPrefix("```") {
                if inCodeBlock {
                    result.append(makeCodeBlock(codeLines.joined(separator: "\n")))
                    codeLines = []
                    inCodeBlock = false
                } else {
                    inCodeBlock = true
                }
                if lineIdx < lines.count - 1 { result.append(newline(compact: compact)) }
                continue
            }

            if inCodeBlock {
                codeLines.append(line)
                continue
            }

            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.isEmpty {
                if lineIdx < lines.count - 1 { result.append(newline(compact: compact)) }
            } else if trimmed.hasPrefix("### ") {
                result.append(heading(String(trimmed.dropFirst(4)), level: 3, compact: compact))
            } else if trimmed.hasPrefix("## ") {
                result.append(heading(String(trimmed.dropFirst(3)), level: 2, compact: compact))
            } else if trimmed.hasPrefix("# ") {
                result.append(heading(String(trimmed.dropFirst(2)), level: 1, compact: compact))
            } else if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") {
                result.append(bulletLine(String(trimmed.dropFirst(2)), compact: compact))
            } else if let m = trimmed.range(of: #"^\d+\.\s"#, options: .regularExpression) {
                let num = String(trimmed[..<m.upperBound])
                let body = String(trimmed[m.upperBound...])
                result.append(numberedLine(num, body, compact: compact))
            } else {
                result.append(applyInline(trimmed, baseSize: compact ? 12 : 13))
            }

            if lineIdx < lines.count - 1 { result.append(newline(compact: compact)) }
        }

        // Unclosed code block
        if inCodeBlock && !codeLines.isEmpty {
            result.append(makeCodeBlock(codeLines.joined(separator: "\n")))
        }

        return result
    }

    // MARK: Block elements

    private static func newline(compact: Bool) -> NSAttributedString {
        let s = NSMutableAttributedString(string: "\n")
        let p = NSMutableParagraphStyle()
        p.paragraphSpacingBefore = 0
        p.paragraphSpacing = compact ? 2 : 3
        s.addAttribute(.paragraphStyle, value: p, range: NSRange(location: 0, length: 1))
        return s
    }

    private static func heading(_ text: String, level: Int, compact: Bool) -> NSAttributedString {
        let sizes: [Int: CGFloat] = [1: 18, 2: 16, 3: 14]
        let attr = NSMutableAttributedString()
        attr.append(applyInline(text, baseSize: sizes[level] ?? 14, bold: true))
        let p = NSMutableParagraphStyle()
        p.paragraphSpacingBefore = compact ? 4 : 8
        p.paragraphSpacing = compact ? 2 : 4
        attr.addAttribute(.paragraphStyle, value: p, range: NSRange(location: 0, length: attr.length))
        return attr
    }

    private static func bulletLine(_ text: String, compact: Bool) -> NSAttributedString {
        let attr = NSMutableAttributedString(string: "•  ", attributes: [
            .font: NSFont.systemFont(ofSize: compact ? 12 : 13),
            .foregroundColor: NSColor.labelColor,
        ])
        attr.append(applyInline(text, baseSize: compact ? 12 : 13))
        let p = NSMutableParagraphStyle()
        p.headIndent = 14
        p.paragraphSpacingBefore = 1
        p.paragraphSpacing = 1
        attr.addAttribute(.paragraphStyle, value: p, range: NSRange(location: 0, length: attr.length))
        return attr
    }

    private static func numberedLine(_ num: String, _ body: String, compact: Bool) -> NSAttributedString {
        let attr = NSMutableAttributedString(string: num, attributes: [
            .font: NSFont.systemFont(ofSize: compact ? 12 : 13),
            .foregroundColor: NSColor.labelColor,
        ])
        attr.append(applyInline(body, baseSize: compact ? 12 : 13))
        let p = NSMutableParagraphStyle()
        p.headIndent = 18
        p.paragraphSpacingBefore = 1
        p.paragraphSpacing = 1
        attr.addAttribute(.paragraphStyle, value: p, range: NSRange(location: 0, length: attr.length))
        return attr
    }

    private static func makeCodeBlock(_ code: String) -> NSAttributedString {
        let trimmed = code.hasSuffix("\n") ? String(code.dropLast()) : code
        let font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        let attr = NSMutableAttributedString(string: trimmed, attributes: [
            .font: font,
            .foregroundColor: NSColor(red: 0.85, green: 0.25, blue: 0.45, alpha: 1),
            .backgroundColor: NSColor(white: 0.94, alpha: 1),
        ])
        let p = NSMutableParagraphStyle()
        p.paragraphSpacingBefore = 6
        p.paragraphSpacing = 4
        p.headIndent = 8
        p.tailIndent = -8
        attr.addAttribute(.paragraphStyle, value: p, range: NSRange(location: 0, length: attr.length))
        // Kerning for readability
        attr.addAttribute(.kern, value: 0.3, range: NSRange(location: 0, length: attr.length))
        return attr
    }

    // MARK: Inline formatting

    private static func applyInline(_ text: String, baseSize: CGFloat, bold: Bool = false) -> NSAttributedString {
        let base: [NSAttributedString.Key: Any] = [
            .font: bold ? NSFont.boldSystemFont(ofSize: baseSize) : NSFont.systemFont(ofSize: baseSize),
            .foregroundColor: NSColor.labelColor,
        ]
        let attr = NSMutableAttributedString(string: text, attributes: base)

        // 1) Inline code  `code`
        replacePattern(attr, regex: "`([^`]+)`", baseSize: baseSize) { str, range in
            str.addAttribute(.font, value: NSFont.monospacedSystemFont(ofSize: baseSize - 1, weight: .regular), range: range)
            str.addAttribute(.backgroundColor, value: NSColor(white: 0.90, alpha: 1), range: range)
            str.addAttribute(.foregroundColor, value: NSColor(red: 0.80, green: 0.20, blue: 0.40, alpha: 1), range: range)
        }

        // 2) Bold  **text**
        replacePattern(attr, regex: "\\*\\*([^*]+)\\*\\*", baseSize: baseSize) { str, range in
            str.addAttribute(.font, value: NSFont.boldSystemFont(ofSize: baseSize), range: range)
        }

        // 3) Italic  *text*  (single * only)
        replacePattern(attr, regex: "(?<!\\*)\\*(?!\\*)([^*]+)\\*(?!\\*)", baseSize: baseSize) { str, range in
            let f = NSFontManager.shared.convert(NSFont.systemFont(ofSize: baseSize), toHaveTrait: .italicFontMask)
            str.addAttribute(.font, value: f, range: range)
        }

        // 4) Links  [text](url)
        if let re = try? NSRegularExpression(pattern: "\\[([^\\]]+)\\]\\(([^)]+)\\)") {
            let matches = re.matches(in: attr.string, range: NSRange(location: 0, length: attr.length))
            for m in matches.reversed() {
                guard m.numberOfRanges >= 3 else { continue }
                let urlStr = attr.attributedSubstring(from: m.range(at: 2)).string
                let linkText = attr.attributedSubstring(from: m.range(at: 1)).string
                guard let url = URL(string: urlStr) else { continue }

                let linkAttr = NSMutableAttributedString(string: linkText, attributes: [
                    .font: NSFont.systemFont(ofSize: baseSize),
                    .foregroundColor: NSColor.linkColor,
                    .link: url,
                    .underlineStyle: NSUnderlineStyle.single.rawValue,
                ])
                attr.replaceCharacters(in: m.range, with: linkAttr)
            }
        }

        return attr
    }

    private static func replacePattern(
        _ attr: NSMutableAttributedString,
        regex: String,
        baseSize: CGFloat,
        apply: (NSMutableAttributedString, NSRange) -> Void
    ) {
        guard let re = try? NSRegularExpression(pattern: regex) else { return }
        let matches = re.matches(in: attr.string, range: NSRange(location: 0, length: attr.length))

        for m in matches.reversed() {
            guard m.numberOfRanges >= 2 else { continue }
            let inner = m.range(at: 1)
            let full = m.range
            let content = attr.attributedSubstring(from: inner)

            // Replace full match with inner content first
            let replacement = NSMutableAttributedString(attributedString: content)
            attr.replaceCharacters(in: full, with: replacement)

            // Now apply formatting on the replaced range
            let newRange = NSRange(location: full.location, length: content.length)
            if newRange.location + newRange.length <= attr.length {
                apply(attr, newRange)
            }
        }
    }
}

// MARK: - AI Chat Panel

class AIChatPanel: NSView {

    private let scrollView = NSScrollView()
    private let chatContainer = NSView()
    private let inputField = NSTextField()
    private let sendButton = NSButton()
    private let settingsButton = NSButton()
    private var messages: [ChatMessage] = []
    private var isLoading = false

    struct ChatMessage {
        let role: String  // "user", "assistant", or "system"
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

        let inputRow = NSStackView(views: [settingsButton, inputField, sendButton])
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

            settingsButton.widthAnchor.constraint(equalToConstant: 70),
            sendButton.widthAnchor.constraint(equalToConstant: 55),
            inputRow.heightAnchor.constraint(equalToConstant: 32),
        ])

        // Welcome message
        if DataStore.shared.aiApiKey.isEmpty {
            appendMessage("欢迎使用小冷工具箱 AI 助手！请先点击「⚙ 配置」设置 API 地址和密钥。\n\n**支持的 API：**\n- OpenAI (`https://api.openai.com/v1`)\n- DeepSeek (`https://api.deepseek.com/v1`)\n- Ollama 本地 (`http://localhost:11434/v1`)\n- 其他兼容 OpenAI 格式的服务", role: "system")
        } else {
            appendMessage("AI 助手已就绪！我可以帮你：\n- 分析当前工具箱的安装状态\n- 推荐缺失的安全/开发工具\n- 生成批量导入列表\n- 回答工具使用问题\n\n试试问：**「帮我扫描一下还缺哪些安全工具？」**", role: "system")
        }
    }

    // MARK: - Settings Dialog

    @objc private func showSettings() {
        let alert = NSAlert()
        alert.messageText = "AI 服务配置"
        alert.addButton(withTitle: "保存")
        alert.addButton(withTitle: "取消")

        let store = DataStore.shared
        let container = NSView(frame: NSRect(x: 0, y: 0, width: 380, height: 130))

        let urlLabel = NSTextField(labelWithString: "API 地址：")
        urlLabel.frame = NSRect(x: 0, y: 100, width: 80, height: 24)
        let urlField = NSTextField(frame: NSRect(x: 80, y: 100, width: 300, height: 24))
        urlField.placeholderString = "https://api.openai.com/v1"
        urlField.stringValue = store.aiBaseUrl

        let keyLabel = NSTextField(labelWithString: "API 密钥：")
        keyLabel.frame = NSRect(x: 0, y: 66, width: 80, height: 24)
        let keyField = NSSecureTextField(frame: NSRect(x: 80, y: 66, width: 300, height: 24))
        keyField.placeholderString = "sk-..."
        keyField.stringValue = store.aiApiKey

        let modelLabel = NSTextField(labelWithString: "模型名称：")
        modelLabel.frame = NSRect(x: 0, y: 32, width: 80, height: 24)
        let modelField = NSTextField(frame: NSRect(x: 80, y: 32, width: 300, height: 24))
        modelField.placeholderString = "gpt-4o"
        modelField.stringValue = store.aiModel

        let hintLabel = NSTextField(labelWithString: "支持 OpenAI / DeepSeek / Ollama 等兼容 API")
        hintLabel.frame = NSRect(x: 80, y: 6, width: 300, height: 18)
        hintLabel.font = .systemFont(ofSize: 11)
        hintLabel.textColor = .secondaryLabelColor

        [urlLabel, urlField, keyLabel, keyField, modelLabel, modelField, hintLabel].forEach { container.addSubview($0) }
        alert.accessoryView = container
        alert.window.initialFirstResponder = urlField

        guard alert.runModal() == .alertFirstButtonReturn else { return }

        store.aiBaseUrl = urlField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        store.aiApiKey = keyField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        store.aiModel = modelField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "gpt-4o" : modelField.stringValue
        store.save()

        appendMessage("AI 配置已更新（模型: \(store.aiModel)），可以开始对话了！", role: "system")
    }

    // MARK: - Message Display (Incremental, Bottom-Growing)

    private func appendMessage(_ text: String, role: String) {
        messages.append(ChatMessage(role: role, content: text))

        let bubble = ChatBubbleView(text: text, role: role)
        bubble.translatesAutoresizingMaskIntoConstraints = false
        chatContainer.addSubview(bubble)

        let prevCount = chatContainer.subviews.count - 1
        let topConstraint: NSLayoutConstraint
        if prevCount > 0 {
            let prev = chatContainer.subviews[prevCount - 1]
            topConstraint = bubble.topAnchor.constraint(equalTo: prev.bottomAnchor, constant: 14)
        } else {
            topConstraint = bubble.topAnchor.constraint(equalTo: chatContainer.topAnchor, constant: 8)
        }

        NSLayoutConstraint.activate([
            topConstraint,
            bubble.leadingAnchor.constraint(equalTo: chatContainer.leadingAnchor, constant: 8),
            bubble.trailingAnchor.constraint(equalTo: chatContainer.trailingAnchor, constant: -8),
        ])

        chatContainer.layoutSubtreeIfNeeded()

        // Grow container
        let totalH = chatContainer.subviews.reduce(0) { max($0, $1.frame.maxY) } + 8
        chatContainer.frame = NSRect(x: 0, y: 0,
                                      width: scrollView.contentSize.width,
                                      height: max(totalH, scrollView.contentSize.height))

        scrollToBottom()
    }

    private func scrollToBottom() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self,
                  let last = self.chatContainer.subviews.last else { return }
            self.scrollView.contentView.scroll(to: NSPoint(x: 0, y: max(0, last.frame.maxY - self.scrollView.contentSize.height + 8)))
            self.scrollView.reflectScrolledClipView(self.scrollView.contentView)
        }
    }

    // MARK: - Send Message & API Call

    @objc private func sendMessage() {
        let text = inputField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isLoading else { return }

        let store = DataStore.shared
        guard !store.aiApiKey.isEmpty, !store.aiBaseUrl.isEmpty else {
            appendMessage("请先配置 AI 服务的 API 地址和密钥。", role: "system")
            return
        }

        inputField.stringValue = ""
        appendMessage(text, role: "user")
        isLoading = true
        sendButton.isEnabled = false
        sendButton.title = "..."

        // Build messages array for API
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
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "无效的 API 地址"])))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(store.aiApiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 60

        let body: [String: Any] = [
            "model": store.aiModel,
            "messages": messages,
            "temperature": 0.7,
            "max_tokens": 2048
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
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
                completion(.failure(NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP \(httpResponse.statusCode): \(errorBody)"])))
                return
            }
            do {
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                let choices = json?["choices"] as? [[String: Any]]
                let message = choices?.first?["message"] as? [String: Any]
                let content = message?["content"] as? String ?? "无响应内容"
                completion(.success(content))
            } catch {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "解析响应失败"])))
            }
        }.resume()
    }
}
