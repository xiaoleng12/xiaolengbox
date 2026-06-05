# XiaoLengBox / 小冷工具箱

A native macOS developer toolbox launcher built with Swift and AppKit. Designed for developers and cybersecurity professionals who need quick access to their daily tools.

macOS 原生开发者工具箱启动器，使用 Swift + AppKit 构建。专为开发者和网络安全从业者设计，提供工具分类管理、一键启动、毛玻璃主题等原生体验。

![XiaoLengBox Screenshot](Resources/screenshot.png)

## Features / 功能

**Tool Management / 工具管理**
- Categorized tool launcher with drag-to-reorder
- Auto-detection of 30+ popular tools (AI coding assistants, security scanners, dev tools)
- Preset categories: AI Harness, NetSec Scanner, DevTools
- Custom categories for any .app, executable, or folder

**Built-in Features / 内置功能**
- PDF Reader with outline navigation
- Markdown Editor (Vditor WYSIWYG, like Typora)
- Floating Terminal with command history
- Sticky Notes with text, images, drag & resize

**Native Experience / 原生体验**
- Glassmorphism / clear dual-mode with adjustable opacity
- Custom wallpaper background
- Zero Electron overhead — pure Swift + AppKit
- Fast startup, low memory footprint

## Requirements / 环境要求

- macOS 13.0+ (Ventura or later)
- Xcode Command Line Tools (for building from source)

## Quick Start / 快速开始

### Option 1: Download Pre-built App / 直接下载 .app

If you just want to use the toolbox without building from source, download the pre-built app directly from this repository:

如果不想编译，直接下载仓库中已打包好的应用：

```bash
# Clone the repository / 克隆仓库
git clone https://github.com/xiaoleng12/XiaoLengBox.git
cd XiaoLengBox

# Launch the app / 启动应用
open "小冷工具箱.app"
```

Or download the `.app` bundle from the [Releases](../../releases) page if available.
也可以从 [Releases](../../releases) 页面下载（如有发布）。

The pre-built app includes all resources (demo PDF, Markdown, shell script, and default wallpaper).
预编译的应用已包含所有资源文件（示例 PDF、Markdown、脚本和默认壁纸）。

---

### Option 2: Build from Source / 从源码编译

#### Prerequisites / 环境要求

- macOS 13.0+ (Ventura or later)
- Xcode Command Line Tools / Xcode 命令行工具:
  ```bash
  xcode-select --install
  ```

#### Using Build Script (Recommended) / 使用编译脚本（推荐）

```bash
# Clone / 克隆
git clone https://github.com/xiaoleng12/XiaoLengBox.git
cd XiaoLengBox

# Build debug version / 编译调试版
./build.sh

# Or build release version with .app bundle / 或编译正式版并打包 .app
./build.sh release
```

The release build will automatically create `小冷工具箱.app` in the project root with all resources bundled.
正式版编译会自动在项目根目录生成 `小冷工具箱.app`，包含所有资源文件。

#### Manual Build / 手动编译

```bash
# Clone / 克隆
git clone https://github.com/xiaoleng12/XiaoLengBox.git
cd XiaoLengBox

# Debug build and run / 编译调试版并运行
swift build
swift run

# Release build / 编译正式版
swift build -c release

# Package as .app / 打包为 .app
./build.sh release
```

#### Project Structure / 项目结构

```
XiaoLengBox/
├── 小冷工具箱.app/       # Pre-built app (download this to use directly)
│   └── Contents/
│       ├── MacOS/        # Executable
│       └── Resources/    # Bundled resources (PDF, MD, wallpaper, etc.)
├── Sources/              # Source code / 源代码
├── Resources/            # Source resources / 源资源文件
├── Tests/                # Unit tests / 单元测试
├── build.sh              # Build script / 编译脚本
└── Package.swift         # Swift Package manifest
```

## Preset Tool Categories / 内置工具分类

### AI应用 / AI Applications
Pre-configured AI development tools with auto-detection of installed apps and CLIs.
预置 AI 开发工具，自动检测已安装的应用和命令行工具。

Claude Code, CC Switch, OpenAI Codex, QoderWork, VS Code, Trae, Cursor, Ollama, LM Studio

### 网络安全工具 / Cybersecurity Tools
Essential security scanning and penetration testing tools for authorized security professionals.
面向授权安全从业者的常用扫描与渗透测试工具。

sqlmap, nmap, TScanPlus, dirsearch, nuclei, Burp Suite, Yakit, Wireshark

### 便签 / Sticky Notes
Built-in sticky note canvas for quick memos and annotations.
内置便签画布，随时记录笔记和备忘。

### PDF / PDF Viewer
Integrated PDF reader with outline navigation for reviewing technical documents.
内置 PDF 阅读器，支持大纲导航，方便查阅技术文档。

### Markdown / Markdown Editor
WYSIWYG Markdown editor powered by Vditor, similar to Typora experience.
基于 Vditor 的所见即所得 Markdown 编辑器，类似 Typora 体验。

Tools are auto-detected on first launch. If a tool is not found, an install hint is shown and you can set the path manually or batch-import via TXT file.
工具在首次启动时自动检测。未找到的工具会显示安装提示，您也可以手动编辑路径或通过 TXT 文件批量导入。

## Architecture / 架构

```
Sources/XiaoLengBox/
├── App/          # AppDelegate + entry point
├── Models/       # Data models + persistence layer
├── Core/         # ToolLauncher, ToolDetector, PresetCatalog, TerminalManager
├── Features/
│   ├── Terminal/    # Floating terminal window
│   ├── PDF/         # PDF viewer + outline
│   ├── Markdown/    # WKWebView + Vditor editor
│   └── StickyNotes/ # Draggable sticky notes canvas
├── UI/           # Category list, tool grid, theme
└── Windows/      # Main window controller
```

## Roadmap / 路线图

- [ ] Windows support (Tauri-based cross-platform version)
- [ ] Plugin system for custom tool categories
- [ ] Dark mode auto-switching
- [ ] Export/import toolbox configuration
- [ ] More preset categories (Cloud/DevOps, Data Science)

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

MIT License. See [LICENSE](LICENSE).
