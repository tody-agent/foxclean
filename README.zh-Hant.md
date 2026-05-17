# FoxClean

FoxClean 是免費、開源的 macOS 清理與最佳化工具。它結合 SwiftUI 原生 App、
共享 Swift 核心，以及 `fox` CLI。

## 快速開始

```sh
brew bundle
xcodegen generate
script/verify_local.sh --launch
```

## 功能重點

- App 與 CLI 共用 `FoxCleanCore`。
- 破壞性操作預設為 dry-run，確認後也優先移到 Trash。
- 操作記錄使用 JSONL，並支援 rollback。
- 包含 App 掃描、系統垃圾掃描、orphan 偵測、磁碟分析、系統狀態、安裝檔清理、
  專案建置產物清理、最佳化任務、shell completion 與 quick launcher scripts。
- 無 telemetry、無 subscription，MIT 授權。

## 發布說明

公開發布仍需要 Developer ID signing、notarization，以及 repository 或 package
manager 發布權限。
