# Delta: CLI

## ADDED Requirements

### Requirement: Command Surface
The `fox` executable MUST expose scan, clean, uninstall, log, analyze, status,
purge, installer, optimize, completion, open, and touchid commands.

### Requirement: Shell Completion
FoxClean SHALL generate completion scripts for bash, zsh, and fish.

### Requirement: GUI Launch from CLI
`fox open` SHOULD open the GUI or a requested view through the registered URL
scheme when installed.

### Requirement: Quick Launchers
FoxClean SHOULD provide Raycast script commands for common actions.
