# Design: GUI Shell, Onboarding, and Foxie

The SwiftUI app uses a `NavigationSplitView` shell, an app-wide `AppState`, and
feature views for dashboard, app cleanup, orphan cleanup, settings, and toolkit
sections. The first-run path uses onboarding and Full Disk Access affordances
inherited from the PureMac baseline.

Foxie is a reusable SwiftUI component with mood-specific visual states. The app
uses it in dashboard, toolbar, and empty-state contexts while honoring reduced
animation preferences where available.
