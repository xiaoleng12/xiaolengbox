# 小冷工具箱

一个 macOS 桌面工具启动器，支持分类管理、壁纸背景、毛玻璃/清晰双模式切换。

使用swift编写，超级棒的系统级原生体验，当前版本可以添加脚本、下载好的app、电脑上的文件夹，超级好用。

## 使用方法

双击 `xiaolengbox` 即可运行。

## 功能

- **分类管理**：左侧栏管理工具分类，支持拖拽排序
- **工具启动**：双击工具图标启动，支持添加 .app、可执行文件、文件夹，给出路径即可
- **壁纸背景**：设置图片作为工具箱背景，毛玻璃模式下模糊透出
- **玻璃/清晰切换**：一键切换毛玻璃和清晰两种显示模式
- **玻璃程度调节**：滑块控制毛玻璃透明度（1%-100%）
- **数据持久化**：分类和工具自动保存，重启不丢失

## 文件说明

```
xiaolengbox          # 可执行文件，双击运行
xiaolengbox.swift    # 源码
xiaolengbox_data.json # 用户数据（自动生成）
```

## 方式一：从源码编译（生成命令行可执行文件）

```bash
swiftc xiaolengbox.swift -o xiaolengbox -framework Cocoa
```

需要 macOS 13+ 和 Xcode Command Line Tools。执行后生成 `xiaolengbox`，双击即可运行。

## 方式二：打包成 App（推荐）

直接运行以下命令，一步完成编译 + 打包：

```bash
swiftc xiaolengbox.swift -o xiaolengbox -framework Cocoa && mkdir -p xiaolengbox.app/Contents/MacOS && cp xiaolengbox xiaolengbox.app/Contents/MacOS/ && echo '<?xml version="1.0" encoding="UTF-8"?><!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd"><plist version="1.0"><dict><key>CFBundleExecutable</key><string>xiaolengbox</string><key>CFBundleIdentifier</key><string>com.xiaolengbox</string><key>CFBundleName</key><string>小冷工具箱</string><key>CFBundleVersion</key><string>1.0</string><key>CFBundlePackageType</key><string>APPL</string></dict></plist>' > xiaolengbox.app/Contents/Info.plist && chmod +x xiaolengbox.app/Contents/MacOS/xiaolengbox && rm -f xiaolengbox
```

执行后只会生成 `xiaolengbox.app`，中间编译的 `xiaolengbox` 命令行文件会被自动清理。
