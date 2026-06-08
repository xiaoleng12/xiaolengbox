import AppKit

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
        let role: String  // "user" or "assistant"
        let content: String
    }

    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
        buildUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func buildUI() {
        // Chat scroll view
        chatContainer.wantsLayer = true
        scrollView.documentView = chatContainer
        scrollView.hasVerticalScroller = true
        scrollView.drawsBackground = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        // Input field
        inputField.placeholderString = "输入消息... (例如: 帮我推荐安全工具并生成导入列表)"
        inputField.font = .systemFont(ofSize: 13)
        inputField.isEditable = true
        inputField.isBezeled = true
        inputField.bezelStyle = .roundedBezel
        inputField.target = self
        inputField.action = #selector(sendMessage)
        inputField.translatesAutoresizingMaskIntoConstraints = false

        // Send button
        sendButton.title = "发送"
        sendButton.bezelStyle = .rounded
        sendButton.target = self
        sendButton.action = #selector(sendMessage)
        sendButton.translatesAutoresizingMaskIntoConstraints = false

        // Settings button
        settingsButton.title = "⚙ 配置"
        settingsButton.bezelStyle = .rounded
        settingsButton.target = self
        settingsButton.action = #selector(showSettings)
        settingsButton.translatesAutoresizingMaskIntoConstraints = false

        // Input row
        let inputRow = NSStackView(views: [settingsButton, inputField, sendButton])
        inputRow.orientation = .horizontal
        inputRow.spacing = 8
        inputRow.translatesAutoresizingMaskIntoConstraints = false

        addSubview(scrollView)
        addSubview(inputRow)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),

            inputRow.topAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: 8),
            inputRow.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            inputRow.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            inputRow.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),

            settingsButton.widthAnchor.constraint(equalToConstant: 70),
            sendButton.widthAnchor.constraint(equalToConstant: 50),
            inputRow.heightAnchor.constraint(equalToConstant: 32),
        ])

        // Show welcome or settings prompt
        if DataStore.shared.aiApiKey.isEmpty {
            appendSystemMessage("请先点击「⚙ 配置」设置 AI 服务的 API 地址和密钥，然后就可以和我对话了。\n\n支持的 API：\n• OpenAI (https://api.openai.com/v1)\n• DeepSeek (https://api.deepseek.com/v1)\n• Ollama 本地 (http://localhost:11434/v1)\n• 其他兼容 OpenAI 格式的服务")
        } else {
            appendSystemMessage("AI 助手已就绪！我可以帮你：\n• 分析当前工具箱的安装状态\n• 推荐缺失的安全/开发工具\n• 生成批量导入列表\n• 回答工具使用问题\n\n试试问：「帮我扫描一下还缺哪些安全工具？」")
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

        appendSystemMessage("✓ AI 配置已更新 (模型: \(store.aiModel))，可以开始对话了！")
    }

    // MARK: - Message Display

    private func appendMessage(_ text: String, role: String) {
        messages.append(ChatMessage(role: role, content: text))
        rebuildChatView()
    }

    private func appendSystemMessage(_ text: String) {
        appendMessage(text, role: "system")
    }

    private func rebuildChatView() {
        chatContainer.subviews.forEach { $0.removeFromSuperview() }
        var yPos: CGFloat = 8

        for msg in messages {
            let bubble = makeBubble(msg.content, role: msg.role)
            bubble.frame.origin = CGPoint(x: msg.role == "user" ? 60 : 8, y: yPos)
            chatContainer.addSubview(bubble)
            yPos += bubble.frame.height + 8
        }

        chatContainer.frame = NSRect(x: 0, y: 0, width: scrollView.contentSize.width, height: yPos)
        scrollView.documentView = chatContainer

        // Scroll to bottom
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let maxScroll = self.chatContainer.frame.height - self.scrollView.contentSize.height
            if maxScroll > 0 {
                self.scrollView.contentView.scroll(to: NSPoint(x: 0, y: maxScroll))
            }
        }
    }

    private func makeBubble(_ text: String, role: String) -> NSView {
        let isUser = role == "user"
        let isSystem = role == "system"

        let bubble = NSView()
        bubble.wantsLayer = true

        let bgColor: NSColor
        let textColor: NSColor
        if isSystem {
            bgColor = NSColor(white: 0.2, alpha: 0.8)
            textColor = NSColor.white.withAlphaComponent(0.8)
        } else if isUser {
            bgColor = NSColor(red: 0.2, green: 0.45, blue: 0.8, alpha: 1)
            textColor = .white
        } else {
            bgColor = NSColor(white: 0.22, alpha: 1)
            textColor = NSColor.white.withAlphaComponent(0.9)
        }
        bubble.layer?.backgroundColor = bgColor.cgColor
        bubble.layer?.cornerRadius = 8

        let label = NSTextField(labelWithString: text)
        label.font = isSystem ? .systemFont(ofSize: 12) : .systemFont(ofSize: 13)
        label.textColor = textColor
        label.preferredMaxLayoutWidth = 360
        label.translatesAutoresizingMaskIntoConstraints = false

        bubble.addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: bubble.topAnchor, constant: 10),
            label.leadingAnchor.constraint(equalTo: bubble.leadingAnchor, constant: 12),
            label.trailingAnchor.constraint(equalTo: bubble.trailingAnchor, constant: -12),
            label.bottomAnchor.constraint(equalTo: bubble.bottomAnchor, constant: -10),
        ])

        // Calculate size
        label.sizeToFit()
        let width = min(label.frame.width + 24, 400)
        let height = label.frame.height + 20
        bubble.frame = NSRect(x: 0, y: 0, width: width, height: height)

        // Copy button for assistant messages (non-system)
        if !isSystem && !text.isEmpty {
            let copyBtn = NSButton(title: "复制", target: self, action: #selector(copyBubbleText(_:)))
            copyBtn.bezelStyle = .inline
            copyBtn.isBordered = false
            copyBtn.font = .systemFont(ofSize: 10)
            copyBtn.contentTintColor = NSColor.white.withAlphaComponent(0.5)
            copyBtn.toolTip = text
            copyBtn.translatesAutoresizingMaskIntoConstraints = false
            bubble.addSubview(copyBtn)
            NSLayoutConstraint.activate([
                copyBtn.trailingAnchor.constraint(equalTo: bubble.trailingAnchor, constant: -4),
                copyBtn.bottomAnchor.constraint(equalTo: bubble.bottomAnchor, constant: -2),
            ])
        }

        return bubble
    }

    @objc private func copyBubbleText(_ sender: NSButton) {
        guard let text = sender.toolTip else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        let orig = sender.title
        sender.title = "✓"
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { sender.title = orig }
    }

    // MARK: - Send Message & API Call

    @objc private func sendMessage() {
        let text = inputField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        guard !isLoading else { return }

        let store = DataStore.shared
        guard !store.aiApiKey.isEmpty, !store.aiBaseUrl.isEmpty else {
            appendSystemMessage("请先配置 AI 服务的 API 地址和密钥。")
            return
        }

        inputField.stringValue = ""
        appendMessage(text, role: "user")
        isLoading = true
        sendButton.isEnabled = false
        sendButton.title = "..."

        // Build messages array
        var apiMessages: [[String: String]] = []

        // System prompt with toolbox context
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

        // API call
        callAI(messages: apiMessages) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                self?.sendButton.isEnabled = true
                self?.sendButton.title = "发送"

                switch result {
                case .success(let reply):
                    self?.appendMessage(reply, role: "assistant")
                case .failure(let error):
                    self?.appendSystemMessage("⚠ 请求失败: \(error.localizedDescription)")
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
