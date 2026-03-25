import AppKit
import SwiftUI

class MenuBarManager: NSObject {
    private var statusItem: NSStatusItem!
    private let pipeline: FlowXPipeline
    private let settingsManager: SettingsManager
    private let profileManager: ProfileManager

    init(pipeline: FlowXPipeline, settingsManager: SettingsManager, profileManager: ProfileManager) {
        self.pipeline = pipeline
        self.settingsManager = settingsManager
        self.profileManager = profileManager
        super.init()
        setupMenuBar()
    }

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem.button {
            let config = NSImage.SymbolConfiguration(pointSize: 16, weight: .medium)
            button.image = NSImage(systemSymbolName: "waveform.circle.fill", accessibilityDescription: "FlowX")?.withSymbolConfiguration(config)
        }

        let menu = NSMenu()

        // Status item
        let statusMenuItem = NSMenuItem(title: "FlowX — Ready", action: nil, keyEquivalent: "")
        statusMenuItem.isEnabled = false
        menu.addItem(statusMenuItem)

        menu.addItem(NSMenuItem.separator())

        // Profile submenu
        let profileMenuItem = NSMenuItem(title: "Active Profile", action: nil, keyEquivalent: "")
        let profileSubmenu = NSMenu()
        buildProfileSubmenu(profileSubmenu)
        profileMenuItem.submenu = profileSubmenu
        menu.addItem(profileMenuItem)

        menu.addItem(NSMenuItem.separator())

        // Show Window
        let showWindowItem = NSMenuItem(title: "Show FlowX", action: #selector(showMainWindow), keyEquivalent: "o")
        showWindowItem.target = self
        menu.addItem(showWindowItem)

        // Settings
        let settingsItem = NSMenuItem(title: "Settings…", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        // About
        let aboutItem = NSMenuItem(title: "About FlowX", action: #selector(showAbout), keyEquivalent: "")
        aboutItem.target = self
        menu.addItem(aboutItem)

        menu.addItem(NSMenuItem.separator())

        // Quit
        let quitItem = NSMenuItem(title: "Quit FlowX", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    private func buildProfileSubmenu(_ menu: NSMenu) {
        let profiles = profileManager.profiles
        let activeId = profileManager.activeProfileId

        if profiles.isEmpty {
            let noProfiles = NSMenuItem(title: "No profiles configured", action: nil, keyEquivalent: "")
            noProfiles.isEnabled = false
            menu.addItem(noProfiles)
        } else {
            for profile in profiles {
                let item = NSMenuItem(title: profile.name, action: #selector(selectProfile(_:)), keyEquivalent: "")
                item.target = self
                item.representedObject = profile.id.uuidString
                if profile.id == activeId {
                    item.state = .on
                }
                menu.addItem(item)
            }
        }
    }

    @objc private func selectProfile(_ sender: NSMenuItem) {
        guard let idString = sender.representedObject as? String,
              let uuid = UUID(uuidString: idString) else { return }
        profileManager.activeProfileId = uuid
        // Rebuild menu to update checkmark
        setupMenuBar()
    }

    @objc private func showMainWindow() {
        if let window = NSApp.windows.first(where: { $0.title == "FlowX" }) {
            window.makeKeyAndOrderFront(nil)
        } else {
            // Open main window via SwiftUI scene
            if let url = URL(string: "flowx://main") {
                NSWorkspace.shared.open(url)
            }
        }
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func openSettings() {
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func showAbout() {
        let alert = NSAlert()
        alert.messageText = "FlowX"
        alert.informativeText = "Version 1.0\n\nAI-powered voice dictation for macOS.\n\nHold the Right Option (⌥) key to record.\nRelease to transcribe and paste.\n\nSay 'FlowX' as a wakeword for editing commands."
        alert.alertStyle = .informational
        alert.runModal()
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }

    func updateStatus(_ text: String) {
        if let menu = statusItem.menu, let firstItem = menu.items.first {
            firstItem.title = "FlowX — \(text)"
        }
    }

    func setRecordingIndicator(_ recording: Bool) {
        DispatchQueue.main.async {
            if let button = self.statusItem.button {
                let symbolName = recording ? "record.circle.fill" : "waveform.circle.fill"
                let config = NSImage.SymbolConfiguration(pointSize: 16, weight: .medium)
                button.image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "FlowX")?.withSymbolConfiguration(config)
            }
        }
    }
}
