# Delta: Foundation

## ADDED Requirements

### Requirement: Repository Structure
FoxClean MUST provide separate GUI, core, and CLI targets.

#### Scenario: Fresh clone build
- GIVEN project dependencies are installed
- WHEN `xcodegen generate` and `xcodebuild -scheme FoxCleanApp -destination 'platform=macOS' build` are run
- THEN the app target builds successfully

#### Scenario: CLI binary runs
- WHEN `swift run fox --version` is run
- THEN the command prints the current FoxClean version

### Requirement: Licensing and Attribution
FoxClean MUST include MIT licensing and credits for PureMac and Mole.

### Requirement: Local Verification
FoxClean MUST provide a repeatable local verification script covering tests,
Xcode builds, CLI smoke checks, and optional app launch verification.
