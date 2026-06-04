import AppKit

class ToolItemView: NSCollectionViewItem {
    static let identifier = NSUserInterfaceItemIdentifier("ToolItem")

    private let iconView = NSImageView()
    private let nameLabel = NSTextField(labelWithString: "")
    private let cardEffect = NSVisualEffectView()

    override func loadView() {
        let root = NSView()
        root.wantsLayer = true
        root.layer?.cornerRadius = 10
        root.layer?.masksToBounds = true

        cardEffect.blendingMode = .withinWindow
        cardEffect.state = .active
        cardEffect.material = DataStore.shared.glassMode == "glass" ? .popover : .windowBackground
        cardEffect.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(cardEffect)
        NSLayoutConstraint.activate([
            cardEffect.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            cardEffect.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            cardEffect.topAnchor.constraint(equalTo: root.topAnchor),
            cardEffect.bottomAnchor.constraint(equalTo: root.bottomAnchor),
        ])

        iconView.imageScaling = .scaleProportionallyUpOrDown
        iconView.translatesAutoresizingMaskIntoConstraints = false

        nameLabel.font = .systemFont(ofSize: 12)
        nameLabel.textColor = .tbText
        nameLabel.alignment = .center
        nameLabel.lineBreakMode = .byTruncatingTail
        nameLabel.translatesAutoresizingMaskIntoConstraints = false

        root.addSubview(iconView)
        root.addSubview(nameLabel)
        NSLayoutConstraint.activate([
            iconView.topAnchor.constraint(equalTo: root.topAnchor, constant: 12),
            iconView.centerXAnchor.constraint(equalTo: root.centerXAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 52),
            iconView.heightAnchor.constraint(equalToConstant: 52),
            nameLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 6),
            nameLabel.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 4),
            nameLabel.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -4),
        ])

        view = root
    }

    func configure(with tool: Tool) {
        nameLabel.stringValue = tool.name
        // 文件夹用系统文件夹图标，其他用文件图标
        var isDir: ObjCBool = false
        FileManager.default.fileExists(atPath: tool.appPath, isDirectory: &isDir)
        if isDir.boolValue && !tool.appPath.hasSuffix(".app") {
            iconView.image = NSWorkspace.shared.icon(for: .folder)
        } else {
            iconView.image = NSWorkspace.shared.icon(forFile: tool.appPath)
        }
        applyCardStyle()
    }

    private func applyCardStyle() {
        let isGlass = DataStore.shared.glassMode == "glass"
        if isGlass {
            cardEffect.isHidden = false
            cardEffect.material = isSelected ? .selection : .popover
            cardEffect.blendingMode = .withinWindow
        } else {
            // 清晰模式：卡片透明，只保留选中高亮
            if isSelected {
                cardEffect.isHidden = false
                cardEffect.material = .selection
                cardEffect.blendingMode = .withinWindow
            } else {
                cardEffect.isHidden = true
            }
        }
    }

    override var isSelected: Bool {
        didSet {
            applyCardStyle()
        }
    }
}

// 双击支持：用自定义 CollectionView 子类捕获双击
class DoubleClickCollectionView: NSCollectionView {
    var onDoubleClick: ((IndexPath) -> Void)?
    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        if event.clickCount == 2 {
            let point = convert(event.locationInWindow, from: nil)
            if let indexPath = indexPathForItem(at: point) {
                onDoubleClick?(indexPath)
            }
        }
    }
}
