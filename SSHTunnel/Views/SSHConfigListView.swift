import SwiftUI

struct SSHConfigListView: View {
    let store: SSHConfigStore
    @Binding var selection: UUID?
    @State private var searchText = ""

    private var filtered: [SSHConfigEntry] {
        if searchText.isEmpty { return store.entries }
        let query = searchText.lowercased()
        return store.entries.filter {
            $0.host.lowercased().contains(query) ||
            $0.value(for: "HostName").lowercased().contains(query) ||
            $0.value(for: "User").lowercased().contains(query)
        }
    }

    private var grouped: [(file: URL, entries: [SSHConfigEntry])] {
        Dictionary(grouping: filtered, by: \.sourceFile)
            .sorted { $0.key.lastPathComponent < $1.key.lastPathComponent }
            .map { (file: $0.key, entries: $0.value) }
    }

    var body: some View {
        VStack(spacing: 0) {
            TextField(String(localized: "Search"), text: $searchText)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)

            List(selection: $selection) {
                ForEach(grouped, id: \.file) { group in
                    Section(group.file.lastPathComponent) {
                        ForEach(group.entries) { entry in
                            SSHConfigRowView(entry: entry)
                                .tag(entry.id)
                                .contextMenu {
                                    Button(entry.commented
                                           ? String(localized: "Enable")
                                           : String(localized: "Disable")) {
                                        store.toggleComment(entry.id)
                                    }
                                    Divider()
                                    Button(String(localized: "Move Up")) {
                                        store.moveEntry(entry.id, direction: -1)
                                    }
                                    Button(String(localized: "Move Down")) {
                                        store.moveEntry(entry.id, direction: 1)
                                    }
                                    Divider()
                                    Menu(String(localized: "Move to...")) {
                                        ForEach(store.configFiles, id: \.self) { file in
                                            if file != entry.sourceFile {
                                                Button(file.lastPathComponent) {
                                                    store.moveEntries([entry.id], to: file)
                                                }
                                            }
                                        }
                                    }
                                    Divider()
                                    Button(String(localized: "Delete"), role: .destructive) {
                                        if selection == entry.id { selection = nil }
                                        store.delete(entry.id)
                                    }
                                }
                        }
                    }
                }
            }
            .overlay {
                if store.entries.isEmpty {
                    ContentUnavailableView {
                        Label {
                            Text(String(localized: "No SSH Hosts"))
                        } icon: {
                            Image(systemName: "apple.terminal.circle")
                                .resizable()
                                .frame(width: 36, height: 36)
                                .foregroundStyle(.secondary)
                        }
                    } description: {
                        Text(String(localized: "No hosts found in ~/.ssh/config"))
                    }
                } else if filtered.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                }
            }
        }
    }
}
