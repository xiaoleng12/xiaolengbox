# XiaoLengBox User Guide / 小冷工具箱 使用指南

XiaoLengBox is a developer and security toolkit manager built for macOS. It lets you organize, launch, and monitor your daily tools through an intuitive interface.

小冷工具箱是一款专为 macOS 用户打造的开发者与安全工具集管理平台。通过直观的界面，您可以轻松管理、启动和监控各类常用工具。

---

## Features / 功能介绍

### Tool Management / 工具管理
- **Auto-Detection**: Automatically scans for installed developer and security tools on your system — no manual path setup needed.
- **One-Click Launch**: Start any detected application or CLI tool directly from the toolbox interface.
- **Install Hints**: For tools not yet installed, convenient install commands prompts are provided.

- **自动检测**：自动扫描系统中已安装的开发工具和安全工具，无需手动配置路径
- **一键启动**：从工具箱界面直接启动任意已检测到的应用程序或命令行工具
- **安装提示**：对于未安装的工具，提供便捷的安装命令提示

### Category Management / 分类管理
- **Preset Categories**: Built-in AI Applications, Cybersecurity Tools and more — ready to use out of the box.
- **Custom Categories**: Create your own categories to organize tools by project or purpose.
- **Sticky Note Categories**: Add sticky note type categories for quick memos and annotations.

- **预置分类**：内置 AI应用、网络安全工具 等常用分类，开箱即用
- **自定义分类**：支持创建自定义分类，按项目或用途组织工具
- **便签分类**：添加便签类型的分类，随时记录笔记和备忘信息

### Document Viewing / 文档查看
- **PDF Reader**: Built-in PDF viewer with outline navigation for reviewing technical documents.
- **Markdown Editor**: WYSIWYG Markdown editing and preview, ideal for writing technical notes.

- **PDF 阅读器**：内置 PDF 查看功能，支持大纲导航，方便阅读技术文档
- **Markdown 编辑器**：支持 Markdown 实时预览和编辑，适合编写技术笔记

### Terminal Integration / 终端集成
- **Embedded Terminal**: Open a terminal without leaving the toolbox — execute commands right where you are.
- **Floating Window**: The terminal supports a floating window mode with freely adjustable position and size.

- **内嵌终端**：无需离开工具箱即可打开终端，执行命令行操作
- **浮动窗口**：终端支持浮动窗口模式，可自由调整位置和大小

### Personalization / 个性化
- **Glassmorphism Effect**: Native macOS glass visual effect with adjustable opacity.
- **Custom Wallpaper**: Set your own in-app wallpaper to create a personalized workspace.

- **毛玻璃效果**：支持 macOS 原生毛玻璃视觉效果，可调节透明度
- **自定义壁纸**：支持设置应用内壁纸，打造个性化的工作环境

---

## Shortcuts / 快捷键

| Shortcut / 快捷键 | Action / 功能 |
|--------|------|
| `Cmd + T` | Open embedded terminal / 打开内嵌终端 |
| `Cmd + N` | New category / 新建分类 |
| `Cmd + Delete` | Delete selected tool or category / 删除选中的工具或分类 |
| `Cmd + R` | Rescan all tools / 重新扫描所有工具 |
| `Cmd + ,` | Open settings / 打开设置 |
| `Esc` | Close floating window / 关闭浮动窗口 |
| `F5` | Refresh tool detection / 刷新工具检测状态 |

---

## Tips / 提示

1. **First Launch / 首次启动**: The toolbox auto-detects installed tools and marks their status. Green means detected, gray means not found.
工具箱会自动检测系统中已安装的工具并标记状态。绿色表示已检测到，灰色表示未找到。

2. **Path Placeholders / 路径占位符**: Smart path resolution is supported, including:
工具箱支持智能路径解析，包括：
   - `<BREW>` — Homebrew install path (Apple Silicon: `/opt/homebrew`, Intel: `/usr/local`)
   - `<NPM>` — npm global install path / npm 全局安装路径
   - `<GO>` — Go tools install path / Go 语言工具安装路径 (`~/go/bin`)
   - `<PDTM>` — ProjectDiscovery tool manager path / ProjectDiscovery 工具管理器路径

3. **Glob Patterns / Glob 模式**: Search paths support wildcard matching (e.g. `*`), useful for directories with uncertain version numbers.
搜索路径支持通配符匹配（如 `*`），适用于版本号不确定的扩展目录。

4. **Data Persistence / 数据持久化**: All configuration and tool states are auto-saved in `xiaolengbox_data.json` alongside the application.
所有配置和工具状态自动保存在应用目录下的 `xiaolengbox_data.json` 文件中。

5. **Security Tools / 安全工具**: Cybersecurity tools in the NetSec category are for authorized security testing only. Please use them within legal boundaries.
网络安全工具分类中的工具仅供授权的安全测试使用，请确保在合法授权范围内使用。

---

> XiaoLengBox v3.0 — Your macOS development and security toolkit companion
> 小冷工具箱 v3.0 — 您的 macOS 开发与安全工具管理助手
