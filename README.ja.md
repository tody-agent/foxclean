# FoxClean

FoxClean は、無料でオープンソースの macOS クリーナー兼最適化ツールです。
SwiftUI のネイティブアプリ、共有 Swift コア、`fox` CLI を組み合わせています。

## クイックスタート

```sh
brew bundle
xcodegen generate
script/verify_local.sh --launch
```

## 主な機能

- アプリと CLI は `FoxCleanCore` を共有します。
- 破壊的な操作はデフォルトで dry-run になり、確認後もまず Trash に移動します。
- 操作ログは JSONL 形式で、rollback に対応します。
- アプリスキャン、不要ファイル検出、orphan 検出、ディスク解析、システム状態、
  installer cleanup、project purge、最適化タスク、shell completion、quick launcher
  scripts を含みます。
- Telemetry なし、subscription なし、MIT ライセンスです。

## リリースについて

公開配布には Developer ID signing、notarization、repository/package manager の
公開権限が必要です。
