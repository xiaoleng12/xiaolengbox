import AppKit

class FloatingTerminalWindowController: NSWindowController {
    private let outputTextView = NSTextView()
    private let inputTextField = NSTextField()
    private let scrollView = NSScrollView()
    private var historyCommands: [String] = []
    private var historyIndex: Int = -1
    private var currentDirectory: String = FileManager.default.currentDirectoryPath

    convenience init() {
        let window = KeyablePanel(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 400),
            styleMask: [.titled, .closable, .resizable, .utilityWindow, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        window.title = "终端"
        window.isFloatingPanel = true
        window.level = .floating
        window.minSize = NSSize(width: 400, height: 300)
        window.center()

        if let savedFrame = DataStore.shared.terminalWindowFrame,
           let rect = NSRectFromString(savedFrame) as NSRect?, rect.width > 0 {
            window.setFrame(rect, display: true)
        }

        self.init(window: window)
        setupUI()

        NotificationCenter.default.addObserver(self, selector: #selector(windowDidMove),
                                               name: NSWindow.didMoveNotification, object: window)
        NotificationCenter.default.addObserver(self, selector: #selector(windowDidResize),
                                               name: NSWindow.didResizeNotification, object: window)
    }

    private func setupUI() {
        guard let window, let contentView = window.contentView else { return }

        contentView.wantsLayer = true
        contentView.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.9).cgColor

        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = true
        scrollView.backgroundColor = NSColor.black.withAlphaComponent(0.9)
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        outputTextView.isEditable = false
        outputTextView.isSelectable = true
        outputTextView.backgroundColor = NSColor.black.withAlphaComponent(0.9)
        outputTextView.textColor = NSColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0)
        outputTextView.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        outputTextView.autoresizingMask = [.width]
        outputTextView.textContainerInset = NSSize(width: 8, height: 8)

        scrollView.documentView = outputTextView

        let inputContainer = NSView()
        inputContainer.wantsLayer = true
        inputContainer.layer?.backgroundColor = NSColor(white: 0.15, alpha: 1.0).cgColor
        inputContainer.translatesAutoresizingMaskIntoConstraints = false

        let promptLabel = NSTextField(labelWithString: "❯")
        promptLabel.textColor = NSColor(red: 0.3, green: 0.8, blue: 0.3, alpha: 1.0)
        promptLabel.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        promptLabel.translatesAutoresizingMaskIntoConstraints = false

        inputTextField.isBordered = false
        inputTextField.backgroundColor = .clear
        inputTextField.textColor = .white
        inputTextField.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        inputTextField.focusRingType = .none
        inputTextField.delegate = self
        inputTextField.translatesAutoresizingMaskIntoConstraints = false

        inputContainer.addSubview(promptLabel)
        inputContainer.addSubview(inputTextField)

        contentView.addSubview(scrollView)
        contentView.addSubview(inputContainer)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: contentView.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: inputContainer.topAnchor),

            inputContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            inputContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            inputContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            inputContainer.heightAnchor.constraint(equalToConstant: 36),

            promptLabel.leadingAnchor.constraint(equalTo: inputContainer.leadingAnchor, constant: 8),
            promptLabel.centerYAnchor.constraint(equalTo: inputContainer.centerYAnchor),

            inputTextField.leadingAnchor.constraint(equalTo: promptLabel.trailingAnchor, constant: 8),
            inputTextField.trailingAnchor.constraint(equalTo: inputContainer.trailingAnchor, constant: -8),
            inputTextField.centerYAnchor.constraint(equalTo: inputContainer.centerYAnchor),
        ])

        appendOutput("Welcome to 小冷工具箱 Terminal\nType 'help' for commands.\n", isCommand: false)
    }

    private func appendOutput(_ text: String, isCommand: Bool) {
        let color: NSColor = isCommand ? NSColor(red: 0.3, green: 0.8, blue: 0.3, alpha: 1.0) : NSColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0)
        let attrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: color,
            .font: NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        ]
        let attrString = NSAttributedString(string: text, attributes: attrs)
        outputTextView.textStorage?.append(attrString)
        outputTextView.scrollToEndOfDocument(nil)
    }

    @objc private func windowDidMove(_ notification: Notification) {
        saveWindowFrame()
    }

    @objc private func windowDidResize(_ notification: Notification) {
        saveWindowFrame()
    }

    private func saveWindowFrame() {
        guard let window = window else { return }
        DataStore.shared.terminalWindowFrame = NSStringFromRect(window.frame)
        DataStore.shared.save()
    }

    func executeCommand(_ command: String) {
        if command.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return
        }

        historyCommands.append(command)
        historyIndex = historyCommands.count

        if command == "clear" || command == "cls" {
            outputTextView.string = ""
            return
        }

        if command == "help" {
            appendOutput("Available commands:\n  clear/cls - Clear screen\n  cd <path> - Change directory\n  exit - Close terminal\n", isCommand: false)
            return
        }

        if command.starts(with: "cd ") {
            let path = String(command.dropFirst(3)).trimmingCharacters(in: .whitespacesAndNewlines)
            let expandedPath = (path as NSString).expandingTildeInPath
            if FileManager.default.changeCurrentDirectoryPath(expandedPath) {
                currentDirectory = FileManager.default.currentDirectoryPath
            }
            appendOutput("\n", isCommand: false)
            return
        }

        if command == "exit" {
            close()
            return
        }

        appendOutput("$ \(command)\n", isCommand: true)

        TerminalManager.shared.executeCommand(command) { [weak self] output, success in
            guard let self = self else { return }
            self.appendOutput(output, isCommand: false)
            if !output.hasSuffix("\n") {
                self.appendOutput("\n", isCommand: false)
            }
        }
    }
}

extension FloatingTerminalWindowController: NSTextFieldDelegate {
    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if commandSelector == #selector(insertNewline(_:)) {
            let command = inputTextField.stringValue
            inputTextField.stringValue = ""
            executeCommand(command)
            return true
        } else if commandSelector == #selector(moveUp(_:)) {
            if historyIndex > 0 {
                historyIndex -= 1
                inputTextField.stringValue = historyCommands[historyIndex]
            }
            return true
        } else if commandSelector == #selector(moveDown(_:)) {
            if historyIndex < historyCommands.count - 1 {
                historyIndex += 1
                inputTextField.stringValue = historyCommands[historyIndex]
            } else {
                historyIndex = historyCommands.count
                inputTextField.stringValue = ""
            }
            return true
        } else if commandSelector == #selector(cancelOperation(_:)) {
            inputTextField.stringValue = ""
            return true
        }
        return false
    }
}
