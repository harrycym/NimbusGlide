import AppKit

class AppTracker {
    /// Returns the name of the currently frontmost application.
    func frontmostAppName() -> String {
        return NSWorkspace.shared.frontmostApplication?.localizedName ?? "Unknown"
    }

    /// Returns the bundle identifier of the currently frontmost application.
    func frontmostAppBundleId() -> String? {
        return NSWorkspace.shared.frontmostApplication?.bundleIdentifier
    }
}
