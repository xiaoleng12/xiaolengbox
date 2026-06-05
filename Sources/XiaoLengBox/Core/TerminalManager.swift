import Foundation

class TerminalManager {
    nonisolated(unsafe) static let shared = TerminalManager()
    private var currentProcess: Process?

    func executeCommand(_ command: String, completion: @escaping @Sendable (String, Bool) -> Void) {
        currentProcess?.terminate()

        let task = Process()
        task.launchPath = "/bin/zsh"
        task.arguments = ["-c", command]

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        task.standardOutput = outputPipe
        task.standardError = errorPipe

        task.terminationHandler = { [weak self] process in
            let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: outputData, encoding: .utf8) ?? ""
            let errorOutput = String(data: errorData, encoding: .utf8) ?? ""
            let combined = errorOutput.isEmpty ? output : output + "\n" + errorOutput
            DispatchQueue.main.async {
                self?.currentProcess = nil
                completion(combined, process.terminationStatus == 0)
            }
        }

        currentProcess = task
        task.launch()
    }

    func stopCommand() {
        currentProcess?.terminate()
        currentProcess = nil
    }
}
