import AppKit
import UniformTypeIdentifiers

class StickyNoteView: NSView {
    var noteModel: StickyNoteModel
    var onDelete: ((StickyNoteModel) -> Void)?
    var onUpdate: ((StickyNoteModel) -> Void)?

    private let headerView = NSView()
    private let titleLabel = NSTextField(labelWithString: "便签")
    private let deleteBtn = NSButton(title: "✕", target: nil, action: nil)
    private let textView = NSTextView()
    private let imageView = DraggableImageView()
    private let addImageBtn = NSButton(title: "+图", target: nil, action: nil)
    private var isDragging = false
    private var dragStartPoint: NSPoint = .zero
    private var resizeCorner: ResizeCorner = .none

    enum ResizeCorner {
        case none, bottomRight
    }

    init(model: StickyNoteModel) {
        self.noteModel = model
        super.init(frame: NSRect(x: model.frameX, y: model.frameY, width: model.frameWidth, height: model.frameHeight))
        setupUI()
        setupContextMenu()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        wantsLayer = true
        layer?.backgroundColor = NSColor(red: 1.0, green: 0.95, blue: 0.7, alpha: 1.0).cgColor
        layer?.cornerRadius = 8
        layer?.shadowColor = NSColor.black.cgColor
        layer?.shadowOpacity = 0.2
        layer?.shadowOffset = CGSize(width: 2, height: 2)
        layer?.shadowRadius = 4

        headerView.wantsLayer = true
        headerView.layer?.backgroundColor = NSColor(red: 1.0, green: 0.85, blue: 0.4, alpha: 1.0).cgColor
        headerView.layer?.cornerRadius = 8
        headerView.layer?.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        headerView.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.font = .boldSystemFont(ofSize: 11)
        titleLabel.textColor = NSColor(white: 0.3, alpha: 1.0)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        deleteBtn.bezelStyle = .inline
        deleteBtn.isBordered = false
        deleteBtn.font = .systemFont(ofSize: 12)
        deleteBtn.target = self
        deleteBtn.action = #selector(deleteNote)
        deleteBtn.translatesAutoresizingMaskIntoConstraints = false

        let increaseFontBtn = NSButton(title: "A+", target: self, action: #selector(increaseFont))
        increaseFontBtn.bezelStyle = .inline
        increaseFontBtn.isBordered = false
        increaseFontBtn.font = .systemFont(ofSize: 10)
        increaseFontBtn.translatesAutoresizingMaskIntoConstraints = false

        let decreaseFontBtn = NSButton(title: "A-", target: self, action: #selector(decreaseFont))
        decreaseFontBtn.bezelStyle = .inline
        decreaseFontBtn.isBordered = false
        decreaseFontBtn.font = .systemFont(ofSize: 10)
        decreaseFontBtn.translatesAutoresizingMaskIntoConstraints = false

        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = true
        scrollView.backgroundColor = .clear
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        textView.isEditable = true
        textView.isSelectable = true
        textView.isRichText = false
        let fontSize = noteModel.fontSize ?? 12.0
        textView.font = .systemFont(ofSize: fontSize)
        textView.textColor = NSColor(white: 0.2, alpha: 1.0)
        textView.backgroundColor = .clear
        textView.autoresizingMask = [.width]
        textView.textContainerInset = NSSize(width: 4, height: 4)
        textView.delegate = self
        textView.string = noteModel.content

        scrollView.documentView = textView

        addImageBtn.bezelStyle = .rounded
        addImageBtn.font = .systemFont(ofSize: 10)
        addImageBtn.target = self
        addImageBtn.action = #selector(addImage)
        addImageBtn.translatesAutoresizingMaskIntoConstraints = false

        if let imagePath = noteModel.imagePath,
           FileManager.default.fileExists(atPath: imagePath) {
            imageView.image = NSImage(contentsOfFile: imagePath)
            imageView.isHidden = false
        } else {
            imageView.isHidden = true
        }

        clipsToBounds = true

        let imgX = noteModel.imageX ?? 8
        let imgY = noteModel.imageY ?? 50
        let imgW = noteModel.imageWidth ?? 120
        let imgH = noteModel.imageHeight ?? 120
        imageView.frame = NSRect(x: imgX, y: imgY, width: imgW, height: imgH)
        imageView.onFrameChanged = { [weak self] in
            guard let self = self else { return }
            self.noteModel.imageX = self.imageView.frame.origin.x
            self.noteModel.imageY = self.imageView.frame.origin.y
            self.noteModel.imageWidth = self.imageView.frame.width
            self.noteModel.imageHeight = self.imageView.frame.height
            self.onUpdate?(self.noteModel)
        }

        addSubview(headerView)
        headerView.addSubview(titleLabel)
        headerView.addSubview(increaseFontBtn)
        headerView.addSubview(decreaseFontBtn)
        headerView.addSubview(deleteBtn)
        addSubview(scrollView)
        addSubview(addImageBtn)
        addSubview(imageView)

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: topAnchor),
            headerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 24),

            titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 8),
            titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),

            deleteBtn.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -4),
            deleteBtn.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),

            increaseFontBtn.trailingAnchor.constraint(equalTo: deleteBtn.leadingAnchor, constant: -4),
            increaseFontBtn.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),

            decreaseFontBtn.trailingAnchor.constraint(equalTo: increaseFontBtn.leadingAnchor, constant: -4),
            decreaseFontBtn.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),

            scrollView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: addImageBtn.topAnchor, constant: -4),

            addImageBtn.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            addImageBtn.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            addImageBtn.widthAnchor.constraint(equalToConstant: 36),

        ])
    }

    @objc private func increaseFont() {
        let currentSize = noteModel.fontSize ?? 12.0
        let newSize = min(currentSize + 2, 48.0)
        noteModel.fontSize = newSize
        textView.font = .systemFont(ofSize: newSize)
        onUpdate?(noteModel)
    }

    @objc private func decreaseFont() {
        let currentSize = noteModel.fontSize ?? 12.0
        let newSize = max(currentSize - 2, 8.0)
        noteModel.fontSize = newSize
        textView.font = .systemFont(ofSize: newSize)
        onUpdate?(noteModel)
    }

    private func setupContextMenu() {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "删除便签", action: #selector(deleteNote), keyEquivalent: ""))
        self.menu = menu
    }

    @objc private func deleteNote() {
        onDelete?(noteModel)
    }

    @objc private func addImage() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [.jpeg, .png, .gif, .heic, .tiff, .bmp]
        panel.message = "选择图片添加到便签"

        guard panel.runModal() == .OK, let url = panel.url else { return }

        let documentsDir = URL(fileURLWithPath: CommandLine.arguments[0]).deletingLastPathComponent()
        let imagesDir = documentsDir.appendingPathComponent("sticky_images")

        try? FileManager.default.createDirectory(at: imagesDir, withIntermediateDirectories: true)

        let fileName = "\(UUID().uuidString).\(url.pathExtension)"
        let destURL = imagesDir.appendingPathComponent(fileName)

        try? FileManager.default.copyItem(at: url, to: destURL)

        noteModel.imagePath = destURL.path
        imageView.image = NSImage(contentsOfFile: destURL.path)
        if imageView.frame.width < 20 || imageView.frame.height < 20 {
            imageView.frame = NSRect(x: 8, y: 50, width: 120, height: 120)
        }
        imageView.isHidden = false

        noteModel.imageX = imageView.frame.origin.x
        noteModel.imageY = imageView.frame.origin.y
        noteModel.imageWidth = imageView.frame.width
        noteModel.imageHeight = imageView.frame.height
        onUpdate?(noteModel)
    }

    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)

        if point.x > frame.width - 20 && point.y < 20 {
            resizeCorner = .bottomRight
        } else {
            isDragging = true
        }
        dragStartPoint = event.locationInWindow
        window?.makeFirstResponder(self)
    }

    override func mouseDragged(with event: NSEvent) {
        let newLocation = event.locationInWindow
        let deltaX = newLocation.x - dragStartPoint.x
        let deltaY = newLocation.y - dragStartPoint.y

        if resizeCorner == .bottomRight {
            let newWidth = max(150, frame.width + deltaX)
            // macOS coordinates: origin is bottom-left, so dragging down (negative deltaY) increases height if top stays fixed.
            // But since origin is bottom, decreasing origin.y and increasing height is needed to expand downwards.
            // Alternatively, changing frame size directly anchors it at bottom left. Let's anchor top-left.
            let newHeight = max(100, frame.height - deltaY)
            var newFrame = frame
            newFrame.size = NSSize(width: newWidth, height: min(newHeight, 500))

            // Adjust origin to anchor top-left
            newFrame.origin.y = frame.maxY - newFrame.height
            frame = newFrame
            dragStartPoint = newLocation
        } else if isDragging {
            frame.origin.x += deltaX
            frame.origin.y += deltaY
            dragStartPoint = newLocation
        }
    }

    override func mouseUp(with event: NSEvent) {
        isDragging = false
        resizeCorner = .none

        noteModel.frameX = frame.origin.x
        noteModel.frameY = frame.origin.y
        noteModel.frameWidth = frame.width
        noteModel.frameHeight = frame.height
        onUpdate?(noteModel)
    }

    override func becomeFirstResponder() -> Bool {
        layer?.borderWidth = 2
        layer?.borderColor = NSColor.tbAccent.cgColor
        return true
    }

    override func resignFirstResponder() -> Bool {
        layer?.borderWidth = 0
        return true
    }
}

extension StickyNoteView: NSTextViewDelegate {
    func textDidChange(_ notification: Notification) {
        noteModel.content = textView.string
        onUpdate?(noteModel)
    }
}
