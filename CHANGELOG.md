# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/), and this project adheres to [Semantic Versioning](https://semver.org/).

## [3.0.0] - 2026-06-04

### Added
- **Preset tool categories**: AI Harness, NetSec Scanner, DevTools with 30+ pre-configured tools
- **Auto-detection engine**: Automatically detects installed tools on macOS (supports both Apple Silicon and Intel paths)
- **Install hints**: Shows installation instructions for tools that are not yet installed
- **SF Symbols icons**: Built-in category icons using system SF Symbols
- **Modular architecture**: Refactored from single-file to modular project structure
- **Swift Package Manager**: Full SPM support with Package.swift
- **Unit tests**: Test coverage for data models, tool detection, and preset catalog
- **CI/CD**: GitHub Actions workflow for build, test, and lint
- **Community files**: CONTRIBUTING.md, issue templates, PR template

### Changed
- Refactored monolithic 2700-line Swift file into 18 modular source files
- Data models now support `DetectionStatus` and `presetId` fields (backward compatible)
- Category model now supports `isPreset` and `presetIcon` fields
- First launch now auto-populates preset categories

## [2.2.0] - 2026-05-04

### Fixed
- Multiple Markdown files sharing content via single editor instance
- MD category not showing outline on first click
- Markdown binding path lost after restart

### Added
- Font size and line height controls in Markdown editor
- H1/H2/H3, quote, todo, table, code block, link, image, and divider shortcuts
- Image insertion copies to per-file assets directory with relative paths

## [2.1.0] - 2026-05-04

### Changed
- Upgraded Markdown editor from split-pane to Vditor WYSIWYG (Typora-like experience)

### Added
- Full GFM support (tables, task lists, code highlighting)
- Dark theme toolbar, Cmd+S save, outline navigation, real-time word count

## [2.0.0] - 2026-04-28

### Added
- PDF Reader with page navigation
- Floating Terminal window with command history
- Sticky Notes with text and image support
