import AppKit
import PDFKit

class PDFOutlineListView: NSView, NSOutlineViewDataSource, NSOutlineViewDelegate {
    private let outlineView = NSOutlineView()
    private let scrollView = NSScrollView()
    private let headerLabel = NSTextField(labelWithString: "PDF 目录")
    private var pdfOutline: PDFOutline?
    var onOutlineItemSelected: ((PDFPage) -> Void)?

    override init(frame: NSRect) { super.init(frame: frame); setupUI() }
    required init?(coder: NSCoder) { super.init(coder: coder); setupUI() }

    private func setupUI() {
        wantsLayer = true
        headerLabel.font = .boldSystemFont(ofSize: 12)
        headerLabel.textColor = .white
        headerLabel.translatesAutoresizingMaskIntoConstraints = false

        let col = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("outline"))
        col.isEditable = false
        outlineView.addTableColumn(col)
        outlineView.outlineTableColumn = col
        outlineView.headerView = nil
        outlineView.backgroundColor = .clear
        outlineView.rowHeight = 28
        outlineView.dataSource = self
        outlineView.delegate = self

        scrollView.documentView = outlineView
        scrollView.hasVerticalScroller = true
        scrollView.drawsBackground = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(headerLabel)
        addSubview(scrollView)
        NSLayoutConstraint.activate([
            headerLabel.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            headerLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            scrollView.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 4),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    func loadOutline(from document: PDFDocument?) {
        pdfOutline = document?.outlineRoot
        if pdfOutline == nil, let doc = document {
            let root = PDFOutline()
            for i in 0..<doc.pageCount {
                let item = PDFOutline()
                item.label = "第 \(i + 1) 页"
                if let page = doc.page(at: i) {
                    item.destination = PDFDestination(page: page, at: NSPoint(x: 0, y: page.bounds(for: .mediaBox).height))
                }
                root.insertChild(item, at: i)
            }
            pdfOutline = root
        }
        outlineView.reloadData()
        outlineView.expandItem(nil, expandChildren: true)
    }

    func outlineView(_ ov: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if let o = item as? PDFOutline { return o.numberOfChildren }
        return pdfOutline?.numberOfChildren ?? 0
    }
    func outlineView(_ ov: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if let o = item as? PDFOutline { return o.child(at: index) as Any }
        return pdfOutline!.child(at: index) as Any
    }
    func outlineView(_ ov: NSOutlineView, isItemExpandable item: Any) -> Bool {
        (item as? PDFOutline)?.numberOfChildren ?? 0 > 0
    }
    func outlineView(_ ov: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        guard let outline = item as? PDFOutline else { return nil }
        let cell = NSTextField(labelWithString: outline.label ?? "未命名")
        cell.font = .systemFont(ofSize: 12)
        cell.textColor = .tbText
        cell.lineBreakMode = .byTruncatingTail
        return cell
    }
    func outlineViewSelectionDidChange(_ notification: Notification) {
        let row = outlineView.selectedRow
        guard row >= 0, let item = outlineView.item(atRow: row) as? PDFOutline,
              let dest = item.destination, let page = dest.page else { return }
        onOutlineItemSelected?(page)
    }
}
