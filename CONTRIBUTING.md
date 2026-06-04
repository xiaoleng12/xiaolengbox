# Contributing to XiaoLengBox

Thank you for your interest in contributing to XiaoLengBox! This document provides guidelines and information for contributors.

## Getting Started

### Prerequisites

- macOS 13.0+ (Ventura or later)
- Xcode 15+ or Xcode Command Line Tools
- Swift 5.9+

### Building

```bash
git clone https://github.com/yourusername/XiaoLengBox.git
cd XiaoLengBox
swift build
swift test
```

### Running

```bash
swift run
```

## Project Structure

```
Sources/XiaoLengBox/
├── App/              # AppDelegate + entry point
├── Models/           # Data models (Tool, Category, StickyNoteModel) + DataStore
├── Core/             # ToolLauncher, ToolDetector, PresetCatalog, TerminalManager
├── Features/
│   ├── Terminal/     # Floating terminal window controller
│   ├── PDF/          # PDF viewer panel + outline list
│   ├── Markdown/     # WKWebView-based Markdown editor (Vditor)
│   └── StickyNotes/  # Sticky note views + canvas
├── UI/               # Category list, tool grid, theme colors
└── Windows/          # Main window controller (composition root)
```

## Code Style

- Follow the [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- Use `// MARK: -` comments to organize code sections
- Keep each file focused on a single responsibility
- Use `NSColor` extension in `Theme.swift` for consistent colors
- Prefer `weak self` in closures to avoid retain cycles

## Adding a New Preset Tool

To add a tool to the preset catalog:

1. Open `Sources/XiaoLengBox/Core/PresetCatalog.swift`
2. Add a new `ToolDetector.PresetTool` entry to the appropriate category
3. Include at least 2-3 common installation paths
4. Add a clear `installHint` string

Example:

```swift
ToolDetector.PresetTool(
    id: "my-tool",
    name: "My Tool",
    type: .cli,
    searchPaths: [
        "<BREW>/bin/my-tool",
        "/usr/local/bin/my-tool",
        "~/tools/my-tool"
    ],
    installHint: "brew install my-tool"
),
```

## Pull Request Process

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/my-feature`
3. Make your changes and add tests if applicable
4. Ensure `swift build` and `swift test` pass
5. Submit a pull request with a clear description

## Reporting Issues

Use the GitHub issue templates:
- **Bug Report**: For unexpected behavior or crashes
- **Feature Request**: For new features or improvements

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
