import SwiftUI

struct HelpView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text(String(localized: "Help"))
                    .font(.headline)
                Spacer()
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    tunnelManagement
                    tunnelTypes
                    authentication
                    sshConfig
                    shareImport
                    menuBar
                    keyboardShortcuts
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            HStack {
                Spacer()
                Button(String(localized: "Close")) { dismiss() }
                    .keyboardShortcut(.cancelAction)
            }
        }
        .padding()
        .frame(width: 500, height: 450)
    }

    // MARK: - Sections

    private var tunnelManagement: some View {
        HelpSectionView(title: String(localized: "Tunnel Management"), items: [
            ("plus", String(localized: "Add a new tunnel with the + button in the toolbar.")),
            ("play.fill", String(localized: "Click Connect/Disconnect to toggle the connection.")),
            ("pencil", String(localized: "Edit tunnel settings in the detail pane.")),
            ("trash", String(localized: "Right-click a tunnel to delete it.")),
        ])
    }

    private var tunnelTypes: some View {
        HelpSectionView(title: String(localized: "Tunnel Types"), items: [
            ("arrow.right", String(localized: "Local (-L): Forward a local port to a remote destination.")),
            ("arrow.left", String(localized: "Remote (-R): Forward a remote port to a local destination.")),
            ("globe", String(localized: "Dynamic (-D): SOCKS proxy through the SSH server.")),
        ])
    }

    private var authentication: some View {
        HelpSectionView(title: String(localized: "Authentication"), items: [
            ("key", String(localized: "Identity File: Select an SSH private key file.")),
            ("lock", String(localized: "Password: Stored securely in the macOS Keychain.")),
        ])
    }

    private var sshConfig: some View {
        HelpSectionView(title: String(localized: "SSH Config"), items: [
            ("doc.text", String(localized: "Browse and edit hosts in the SSH Config tab.")),
            ("square.and.pencil", String(localized: "Open config files in an external editor.")),
            ("doc.plaintext", String(localized: "Use text editing mode for raw config editing.")),
            ("list.bullet.rectangle", String(localized: "Load SSH Config hosts into a tunnel.")),
        ])
    }

    private var shareImport: some View {
        HelpSectionView(title: String(localized: "Share & Import"), items: [
            ("doc.on.doc", String(localized: "Copy Share String to share configs as sshtunnel:// URLs.")),
            ("square.and.arrow.down", String(localized: "Import configs from a share string or URL.")),
            ("terminal", String(localized: "Copy CLI Command to get the equivalent ssh command.")),
        ])
    }

    private var menuBar: some View {
        HelpSectionView(title: String(localized: "Menu Bar"), items: [
            ("menubar.rectangle", String(localized: "Quick connect/disconnect tunnels from the menu bar.")),
            ("arrow.clockwise", String(localized: "Auto-connect on launch and disconnect on quit per tunnel.")),
            ("terminal", String(localized: "Monitor running SSH processes from the toolbar.")),
        ])
    }

    private var keyboardShortcuts: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(String(localized: "Keyboard Shortcuts"))
                .font(.subheadline)
                .fontWeight(.semibold)

            Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 4) {
                shortcutRow("⌘I", String(localized: "Import from share string"))
                shortcutRow("⌘V", String(localized: "Paste share string to import"))
                shortcutRow("⌘M", String(localized: "Open Manager from menu bar"))
                shortcutRow("⌘Q", String(localized: "Quit application"))
                shortcutRow("Esc", String(localized: "Close dialog"))
            }
        }
    }

    private func shortcutRow(_ shortcut: String, _ description: String) -> some View {
        GridRow {
            Text(shortcut)
                .font(.system(.caption, design: .monospaced))
                .fontWeight(.medium)
                .frame(width: 40, alignment: .trailing)
            Text(description)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Section Helper

private struct HelpSectionView: View {
    let title: String
    let items: [(icon: String, text: String)]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)

            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                Label(item.text, systemImage: item.icon)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
