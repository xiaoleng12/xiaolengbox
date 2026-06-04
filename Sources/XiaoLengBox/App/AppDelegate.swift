import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    var windowController: MainWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        DataStore.shared.load()

        // Install preset categories on first launch
        PresetCatalog.installPresetsIfNeeded()

        windowController = MainWindowController()
        windowController?.showWindow(nil)
        windowController?.selectFirstCategory()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}
