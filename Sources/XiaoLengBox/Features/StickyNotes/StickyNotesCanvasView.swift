import AppKit

class StickyNotesCanvasView: NSView {
    var categoryId: UUID? {
        didSet {
            reloadNotes()
        }
    }

    private var noteViews: [StickyNoteView] = []
    var onNoteDeleted: ((StickyNoteModel) -> Void)?
    var onNoteUpdated: ((StickyNoteModel) -> Void)?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        setupContextMenu()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsLayer = true
        setupContextMenu()
    }

    private func setupContextMenu() {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "添加便签", action: #selector(addNewNote), keyEquivalent: ""))
        self.menu = menu
    }

    func reloadNotes() {
        noteViews.forEach { $0.removeFromSuperview() }
        noteViews.removeAll()

        guard let catId = categoryId else { return }

        let notes = DataStore.shared.stickyNotes(for: catId)
        for note in notes {
            let noteView = StickyNoteView(model: note)
            noteView.onDelete = { [weak self] model in
                DataStore.shared.deleteStickyNote(id: model.id)
                self?.reloadNotes()
                self?.onNoteDeleted?(model)
            }
            noteView.onUpdate = { [weak self] model in
                DataStore.shared.updateStickyNote(model)
                self?.onNoteUpdated?(model)
            }
            addSubview(noteView)
            noteViews.append(noteView)
        }
    }

    override func layout() {
        super.layout()
    }

    @objc private func addNewNote() {
        guard let catId = categoryId else { return }
        let note = DataStore.shared.addStickyNote(to: catId)
        reloadNotes()

        if let newView = noteViews.first(where: { $0.noteModel.id == note.id }) {
            newView.frame.origin = NSPoint(x: bounds.width / 2 - newView.frame.width / 2,
                                          y: bounds.height / 2 - newView.frame.height / 2)
        }
    }
}
