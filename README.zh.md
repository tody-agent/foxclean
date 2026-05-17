# FoxClean

FoxClean 是一款强大、免费且开源的 macOS 清理与优化工具。它结合了美观的原生 SwiftUI 应用程序、共享的 Swift 核心以及多功能的 `fox` 命令行界面 (CLI)。专为希望完全控制 Mac 性能的用户设计，没有遥测（telemetry）、没有订阅费、也没有隐藏费用。

![Home](screenshot/home.png)
*一个时尚、原生的 SwiftUI 界面，保持您的 Mac 清洁和优化。*

## 🚀 主要功能

### 🖥️ 原生 SwiftUI 应用程序
FoxClean 附带一个基于 PureMac 的现代、快速且原生的 macOS 应用程序界面。
- **应用扫描器**: 快速查找并管理已安装的应用程序。
- **垃圾扫描器**: 识别并清理不必要的文件、缓存和日志，以释放空间。
- **残留检测**: 检测先前卸载应用程序后遗留的文件。
- **系统状态与磁盘分析器**: 监控 Mac 的健康状况并实时可视化磁盘使用情况。

![Clean](screenshot/clean.png)
*深度系统扫描和垃圾清理实况。*

### 🛠️ 共享 `FoxCleanCore`
FoxClean 的核心是一个强大的共享引擎，确保应用程序与 CLI 之间的一致性。
- **空运行清理 (Dry-run)**: 在进行任何更改前预览将被删除的内容。
- **废纸篓优先**: 默认将文件安全移至废纸篓，防止意外丢失数据。
- **操作日志与回滚**: 维护 JSONL 操作日志，允许您在需要时回滚更改。
- **项目清理与安装包清理**: 快速删除繁重的项目目录（如 `node_modules` 或 `.build`）以及残留的安装包。

![Uninstall](screenshot/uninstall.png)
*安全彻底地卸载应用程序及其相关数据。*

### 💻 强大的 `fox` CLI
对于高级用户和开发者，`fox` CLI 提供了对系统的全面控制:
- 可用命令: `scan`, `clean`, `uninstall`, `log`, `analyze`, `status`, `purge`, `installer`, `optimize`, `open`, `touchid`, 和 `completion`。

![Options](screenshot/options.png)
*用于自定义清理的附加选项和设置。*

## 🔒 安全第一

我们将您的数据安全放在首位。
- **默认空运行**: 所有破坏性的 CLI 操作默认都处于空运行模式。
- **移至废纸篓**: 使用 `--confirm` 标志显式地将项目移至废纸篓。
- **永久删除**: 真正的永久删除需要同时使用 `--permanent` 和 `--confirm-permanent` 标志，以防止意外灾难。

## 🏗️ 构建说明

从源码构建 FoxClean 应用程序和 CLI：

```sh
# 使用 Homebrew 安装依赖
brew bundle

# 生成 Xcode 项目
xcodegen generate

# 构建 macOS 应用程序
xcodebuild -scheme FoxCleanApp -destination 'platform=macOS' build

# 运行 Swift 测试
swift test

# 验证 CLI 工具
swift run fox --version
```

## 📜 许可证与隐私

- **无遥测**: FoxClean 不会跟踪您、收集数据或向远程服务器发送任何信息。
- **无订阅**: 永久 100% 免费。
- **MIT 许可证**: 开源且由社区驱动。有关更多详细信息，请参见 [LICENSE](LICENSE) 文件。

---

*使用 FoxClean 让您的 Mac 焕然一新！*
