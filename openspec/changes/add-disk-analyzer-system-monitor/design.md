# Design: Disk Analyzer and System Monitor

The analyzer scans a selected path into a tree of sized nodes and exposes a
largest-child view in SwiftUI and JSON output in the CLI. The monitor gathers
host, memory, disk, process, and health metrics through core APIs and displays
them in cards plus an AppKit `NSStatusItem` popover. The menu bar surface uses
AppKit for the status item and a small SwiftUI popover for metrics/actions to
avoid the SwiftUI `MenuBarExtra` update loop that previously made the app
unresponsive.
