import AppKit
import PDFKit

class PDFViewerPanel: NSView {
    let pdfView = PDFView()
    private let toolbar = NSView()
    private let fileLabel = NSTextField(labelWithString: "未打开文件")
    private let pageLabel = NSTextField(labelWithString: "")
    var onPDFLoaded: ((PDFDocument) -> Void)?

    override init(frame: NSRect) { super.init(frame: frame); setupUI() }
    required init?(coder: NSCoder) { super.init(coder: coder); setupUI() }

    private func setupUI() {
        wantsLayer = true
        toolbar.wantsLayer = true
        toolbar.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.3).cgColor
        toolbar.translatesAutoresizingMaskIntoConstraints = false

        let prevBtn = NSButton(title: "◀", target: self, action: #selector(prevPage))
        prevBtn.bezelStyle = .rounded
        prevBtn.translatesAutoresizingMaskIntoConstraints = false

        let nextBtn = NSButton(title: "▶", target: self, action: #selector(nextPage))
        nextBtn.bezelStyle = .rounded
        nextBtn.translatesAutoresizingMaskIntoConstraints = false

        fileLabel.font = .systemFont(ofSize: 12)
        fileLabel.textColor = .white
        fileLabel.lineBreakMode = .byTruncatingMiddle
        fileLabel.translatesAutoresizingMaskIntoConstraints = false

        pageLabel.font = .monospacedDigitSystemFont(ofSize: 12, weight: .regular)
        pageLabel.textColor = .white.withAlphaComponent(0.8)
        pageLabel.translatesAutoresizingMaskIntoConstraints = false

        toolbar.addSubview(fileLabel)
        toolbar.addSubview(prevBtn)
        toolbar.addSubview(pageLabel)
        toolbar.addSubview(nextBtn)
        NSLayoutConstraint.activate([
            fileLabel.leadingAnchor.constraint(equalTo: toolbar.leadingAnchor, constant: 12),
            fileLabel.centerYAnchor.constraint(equalTo: toolbar.centerYAnchor),
            fileLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 300),
            nextBtn.trailingAnchor.constraint(equalTo: toolbar.trailingAnchor, constant: -8),
            nextBtn.centerYAnchor.constraint(equalTo: toolbar.centerYAnchor),
            pageLabel.trailingAnchor.constraint(equalTo: nextBtn.leadingAnchor, constant: -8),
            pageLabel.centerYAnchor.constraint(equalTo: toolbar.centerYAnchor),
            prevBtn.trailingAnchor.constraint(equalTo: pageLabel.leadingAnchor, constant: -8),
            prevBtn.centerYAnchor.constraint(equalTo: toolbar.centerYAnchor),
        ])

        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.backgroundColor = NSColor(white: 0.2, alpha: 1.0)
        pdfView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(toolbar)
        addSubview(pdfView)
        NSLayoutConstraint.activate([
            toolbar.topAnchor.constraint(equalTo: topAnchor),
            toolbar.leadingAnchor.constraint(equalTo: leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: trailingAnchor),
            toolbar.heightAnchor.constraint(equalToConstant: 36),
            pdfView.topAnchor.constraint(equalTo: toolbar.bottomAnchor),
            pdfView.leadingAnchor.constraint(equalTo: leadingAnchor),
            pdfView.trailingAnchor.constraint(equalTo: trailingAnchor),
            pdfView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        NotificationCenter.default.addObserver(self, selector: #selector(pageChanged),
                                               name: Notification.Name.PDFViewPageChanged, object: pdfView)
    }

    func loadPDF(from url: URL) {
        guard let doc = PDFDocument(url: url) else {
            let a = NSAlert(); a.messageText = "无法加载 PDF"; a.informativeText = url.path; a.runModal(); return
        }
        pdfView.document = doc
        fileLabel.stringValue = url.lastPathComponent
        updatePageLabel()
        onPDFLoaded?(doc)
    }

    @objc private func pageChanged() { updatePageLabel() }
    private func updatePageLabel() {
        guard let doc = pdfView.document, let page = pdfView.currentPage else { pageLabel.stringValue = ""; return }
        let idx = doc.index(for: page)
        pageLabel.stringValue = "\(idx + 1) / \(doc.pageCount)"
    }
    @objc private func prevPage() { pdfView.goToPreviousPage(nil) }
    @objc private func nextPage() { pdfView.goToNextPage(nil) }
    func goTo(page: PDFPage) { pdfView.go(to: page) }
}
