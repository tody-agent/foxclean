# Design: Project Purge, Installer Cleanup, and Optimize

Project purge uses marker-aware artifact discovery so folders such as
`node_modules` or `.build` are only reported when they belong to a recognized
project. Installer cleanup scans common installer locations and labels each
candidate by source. Optimize tasks are modular and default to dry-run style
reporting unless a future privileged implementation is explicitly confirmed.
