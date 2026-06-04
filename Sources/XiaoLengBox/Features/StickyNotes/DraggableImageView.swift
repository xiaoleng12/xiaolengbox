import AppKit

class DraggableImageView: NSImageView {
    var onFrameChanged: (() -> Void)?
    private var isDragging = false
    private var isResizing = false
    private var dragStart: NSPoint = .zero
    private let handleSize: CGFloat = 16

    override var acceptsFirstResponder: Bool { return true }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        imageScaling = .scaleProportionallyUpOrDown
        imageAlignment = .alignCenter
        wantsLayer = true
    }

    required init?(coder: NSCoder) { fatalError() }

    private func isOnResizeHandle(_ point: NSPoint) -> Bool {
        return point.x >= bounds.width - handleSize && point.y <= handleSize
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        guard image != nil else { return }
        // Draw resize handle in bottom-right corner
        let hx = bounds.width - handleSize
        let hy: CGFloat = 0
        let handleRect = NSRect(x: hx, y: hy, width: handleSize, height: handleSize)
        NSColor.black.withAlphaComponent(0.25).setFill()
        let bg = NSBezierPath(roundedRect: handleRect, xRadius: 3, yRadius: 3)
        bg.fill()
        // Draw diagonal lines
        NSColor.white.withAlphaComponent(0.8).setStroke()
        let line = NSBezierPath()
        line.lineWidth = 1.5
        line.move(to: NSPoint(x: hx + 4, y: hy + handleSize - 4))
        line.line(to: NSPoint(x: hx + handleSize - 4, y: hy + 4))
        line.move(to: NSPoint(x: hx + 7, y: hy + handleSize - 4))
        line.line(to: NSPoint(x: hx + handleSize - 4, y: hy + 7))
        line.stroke()
    }

    override func mouseDown(with event: NSEvent) {
        let pt = convert(event.locationInWindow, from: nil)
        if isOnResizeHandle(pt) { isResizing = true } else { isDragging = true }
        dragStart = event.locationInWindow
    }

    override func mouseDragged(with event: NSEvent) {
        let loc = event.locationInWindow
        let dx = loc.x - dragStart.x
        let dy = loc.y - dragStart.y
        guard dx != 0 || dy != 0 else { return }

        var f = frame
        if isResizing {
            let aspect = f.width / max(f.height, 1)
            let delta = max(abs(dx), abs(dy))
            let sign: CGFloat = (dx + dy) >= 0 ? 1 : -1
            if abs(dx) >= abs(dy) {
                f.size.width = max(30, f.size.width + delta * sign)
                f.size.height = f.size.width / aspect
            } else {
                f.size.height = max(30, f.size.height + delta * sign)
                f.size.width = f.size.height * aspect
            }
        } else if isDragging {
            f.origin.x += dx
            f.origin.y += dy
        }
        frame = f
        dragStart = loc
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        isDragging = false
        isResizing = false
        onFrameChanged?()
    }

    override func resetCursorRects() {
        super.resetCursorRects()
        if image != nil {
            let handleRect = NSRect(x: bounds.width - handleSize, y: 0, width: handleSize, height: handleSize)
            addCursorRect(handleRect, cursor: .crosshair)
        }
    }
}
