import AppKit

struct MDOutlineItem {
    let title: String
    let level: Int
}

class MDOutlineListView: NSView, NSOutlineViewDataSource, NSOutlineViewDelegate {
    private let outlineView = NSOutlineView()
    private let scrollView = NSScrollView()
    private var items: [MDOutlineItem] = []
    var onOutlineItemSelected: ((MDOutlineItem) -> Void)?

    override init(frame: NSRect) { super.init(frame: frame); setupUI() }
    required init?(coder: NSCoder) { super.init(coder: coder); setupUI() }

    private func setupUI() {
        let col = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("MDColumn"))
        col.title = "目录"
        outlineView.addTableColumn(col)
        outlineView.outlineTableColumn = col
        outlineView.headerView = nil
        outlineView.dataSource = self
        outlineView.delegate = self
        outlineView.rowHeight = 24
        outlineView.backgroundColor = .clear

        scrollView.documentView = outlineView
        scrollView.hasVerticalScroller = true
        scrollView.drawsBackground = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    func loadOutline(items: [MDOutlineItem]) {
        self.items = items
        outlineView.reloadData()
    }

    func outlineView(_ ov: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if item == nil { return items.count }
        return 0 // Flat list for simplicity
    }
    func outlineView(_ ov: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        return items[index]
    }
    func outlineView(_ ov: NSOutlineView, isItemExpandable item: Any) -> Bool { false }
    func outlineView(_ ov: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        guard let outlineItem = item as? MDOutlineItem else { return nil }
        let cell = NSTextField(labelWithString: String(repeating: "  ", count: max(0, outlineItem.level - 1)) + outlineItem.title)
        cell.font = .systemFont(ofSize: 12)
        cell.textColor = .tbText
        cell.lineBreakMode = .byTruncatingTail
        return cell
    }
    func outlineViewSelectionDidChange(_ notification: Notification) {
        let row = outlineView.selectedRow
        guard row >= 0 else { return }
        onOutlineItemSelected?(items[row])
    }
}
