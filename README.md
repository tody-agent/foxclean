# FoxClean

FoxClean is a powerful, free, and open-source macOS cleaner and optimizer. It combines a beautiful native SwiftUI application with a shared Swift core and the versatile `fox` Command Line Interface (CLI). Designed for users who want complete control over their Mac's performance without telemetry, subscriptions, or hidden fees.

![Home](screenshot/home.png)
*A sleek, native SwiftUI interface to keep your Mac clean and optimized.*

## 🚀 Key Features

### 🖥️ Native SwiftUI Application
FoxClean comes with a modern, fast, and native macOS application interface based on PureMac.
- **App Scanner**: Quickly find and manage installed applications.
- **Junk Scanner**: Identify and clean up unnecessary files, caches, and logs to free up space.
- **Orphan Detection**: Detect leftover files from previously uninstalled applications.
- **System Status & Disk Analyzer**: Monitor your Mac's health and visualize disk usage in real-time.

![Clean](screenshot/clean.png)
*Deep system scanning and junk cleaning in action.*

### 🛠️ Shared `FoxCleanCore`
At its heart, FoxClean uses a robust shared core that ensures consistency between the app and the CLI.
- **Dry-run Cleaning**: See what will be deleted before making any changes.
- **Trash-first Deletion**: Safely move files to the Trash by default, preventing accidental data loss.
- **Operation Logs & Rollback**: Maintains JSONL operation logs, allowing you to rollback changes if needed.
- **Project Purge & Installer Cleanup**: Quickly remove heavy project directories (like `node_modules` or `.build`) and leftover installers.

![Uninstall](screenshot/uninstall.png)
*Safely completely uninstall applications and their associated data.*

### 💻 Powerful `fox` CLI
For power users and developers, the `fox` CLI offers comprehensive control over your system:
- Available commands: `scan`, `clean`, `uninstall`, `log`, `analyze`, `status`, `purge`, `installer`, `optimize`, `open`, `touchid`, and `completion`.

![Options](screenshot/options.png)
*Additional options and settings for customized cleaning.*

## 🔒 Safety First

We prioritize your data's safety.
- **Dry-run by default**: All destructive CLI actions default to dry-run mode.
- **Trash moves**: Use the `--confirm` flag to explicitly move items to the Trash.
- **Permanent Deletion**: True permanent deletion requires both `--permanent` and `--confirm-permanent` flags, preventing accidental disasters.

## 💡 Motivation & The "Vibe Coding" Challenge

**Why build another Mac cleaner?**
The macOS ecosystem has many cleaner apps (like CleanMyMac, Onyx, Pearcleaner), but most suffer from key pain points:
- **Commercial & Closed Source:** Often heavy, subscription-based, bloated with telemetry tracking, or containing intrusive ads.
- **Open-source Limitations:** Frequently lack a polished, modern UI, or they are just basic bash scripts without the power of deep native integration.

**The "Vibe Coding" Problem**
In the era of AI-assisted development ("vibe coding"), building a full-fledged macOS app with file-system privileges and complex SwiftUI state management from scratch is a nightmare. AI often struggles and gets confused by massive `project.pbxproj` files, which easily lead to merge conflicts and tightly coupled architectures. The original sources didn't meet the needs of a modern AI-driven workflow because they relied on traditional, hard-to-maintain Xcode project structures.

**Our Solution**
FoxClean solves this by combining the beautiful native SwiftUI user experience from **PureMac** with powerful cleanup rules inspired by **Mole**. 
By utilizing `XcodeGen` (`project.yml`), FoxClean completely separates the Core logic (`FoxCleanCore`), the CLI tool (`FoxCleanCLI`), and the UI (`FoxCleanApp`). This modular architecture is completely "vibe coding" friendly—AI only needs to modify clean Swift files and a simple YAML file, avoiding `pbxproj` merge conflicts entirely.

## 🙏 Acknowledgements

FoxClean stands on the shoulders of giants. Special thanks to:
- **momenbasel** for [PureMac](https://github.com/momenbasel/PureMac) - Providing the beautiful native SwiftUI baseline and scan engine architecture.
- **tw93** for [Mole](https://github.com/tw93/mole) - Inspiring the robust cleanup rules and CLI workflows.
- The open-source community for tools like `XcodeGen` that made this modern architecture possible.

## 🗑️ Uninstalling FoxClean

If you ever need to remove FoxClean from your system, you have two options:

**1. Standard macOS way:**
- Open `Finder` and go to the `Applications` folder.
- Drag `FoxClean.app` to the Trash (or right-click and select "Move to Trash").
- Empty the Trash.

**2. Complete removal via CLI:**
To completely remove FoxClean and all its associated data (caches, preferences, logs, etc.), you can use its own CLI before deleting the app:
```sh
fox uninstall dev.foxclean.app --confirm
```

## 🏗️ Build Instructions

To build the FoxClean app and CLI from source:

```sh
# Install dependencies using Homebrew
brew bundle

# Generate the Xcode project
xcodegen generate

# Build the macOS application
xcodebuild -scheme FoxCleanApp -destination 'platform=macOS' build

# Run Swift tests
swift test

# Verify the CLI tool
swift run fox --version
```

## 📜 License & Privacy

- **No Telemetry**: FoxClean does not track you, collect data, or send any information to remote servers.
- **No Subscription**: 100% free forever.
- **MIT Licensed**: Open source and community-driven. See the [LICENSE](LICENSE) file for more details.

---

*Keep your Mac running like new with FoxClean!*
