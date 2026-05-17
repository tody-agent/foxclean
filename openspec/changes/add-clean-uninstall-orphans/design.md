# Design: Clean, Uninstall, and Orphans

Cleanup UI follows a master-detail shape: category or app lists on the left,
candidate files and safety details on the right, and destructive actions behind
confirmation. The app layer presents selections and progress; `FoxCleanCore`
owns scanning, protected-app filtering, operation logging, and file movement.
