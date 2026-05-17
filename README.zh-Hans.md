# FoxClean

FoxClean 是一个免费、开源的 macOS 清理和优化工具。它结合了 SwiftUI 原生应用、
共享 Swift 核心库，以及 `fox` 命令行工具。

## 快速开始

```sh
brew bundle
xcodegen generate
script/verify_local.sh --launch
```

## 功能亮点

- App 和 CLI 共用 `FoxCleanCore`。
- 破坏性操作默认 dry-run，确认后也优先移动到 Trash。
- 操作日志使用 JSONL，并支持 rollback。
- 包含应用扫描、系统垃圾扫描、orphan 检测、磁盘分析、系统状态、安装包清理、
  项目构建产物清理、优化任务、shell completion 和 quick launcher scripts。
- 无 telemetry、无 subscription，MIT 许可。

## 发布说明

公开发布仍需要 Developer ID signing、notarization，以及仓库或包管理器发布权限。
