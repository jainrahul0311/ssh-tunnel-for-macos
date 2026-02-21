import SwiftUI

struct SSHConfigDetailView: View {
    let store: SSHConfigStore
    var entryId: UUID

    @State private var draft = SSHConfigEntry(sourceFile: URL(fileURLWithPath: "/"))
    @State private var loaded = false
    @State private var showTextEditor = false

    var body: some View {
        SSHConfigFormView(draft: $draft, store: store)
            .onAppear { loadDraft() }
            .onChange(of: entryId) { _, _ in loadDraft() }
            .onChange(of: draft) { _, newValue in
                guard loaded else { return }
                store.update(newValue)
            }
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button {
                        showTextEditor = true
                    } label: {
                        Image(systemName: "doc.plaintext")
                    }
                    .help(String(localized: "Edit as Text"))
                }
            }
            .sheet(isPresented: $showTextEditor) {
                SSHConfigTextEditView(draft: $draft)
            }
    }

    private func loadDraft() {
        loaded = false
        if let entry = store.entries.first(where: { $0.id == entryId }) {
            draft = entry
        }
        loaded = true
    }
}

// MARK: - Text Edit Sheet

struct SSHConfigTextEditView: View {
    @Binding var draft: SSHConfigEntry
    @Environment(\.dismiss) private var dismiss
    @State private var text = ""

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text(String(localized: "Edit as Text"))
                    .font(.headline)
                Spacer()
            }

            TextEditor(text: $text)
                .font(.system(.body, design: .monospaced))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .border(Color(nsColor: .separatorColor), width: 0.5)

            HStack {
                Spacer()
                Button(String(localized: "Cancel")) { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button(String(localized: "Apply")) {
                    applyText()
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .frame(width: 550, height: 400)
        .onAppear {
            text = SSHConfigParser.serialize([draft])
        }
    }

    private func applyText() {
        let parsed = SSHConfigParser.parseFullContent(text, sourceFile: draft.sourceFile)
        guard let entry = parsed.first else { return }
        draft.host = entry.host
        draft.directives = entry.directives
        draft.comment = entry.comment
        draft.commented = entry.commented
    }
}

// MARK: - Form

struct SSHConfigFormView: View {
    @Binding var draft: SSHConfigEntry
    let store: SSHConfigStore
    @State private var newKey = ""
    @State private var newValue = ""

    var body: some View {
        Form {
            Section(String(localized: "Host")) {
                TextField("Host", text: $draft.host)
                LabeledContent(String(localized: "File")) {
                    Picker("", selection: $draft.sourceFile) {
                        ForEach(store.configFiles, id: \.self) { file in
                            Text(file.lastPathComponent).tag(file)
                        }
                    }
                    .labelsHidden()
                }
            }

            Section(String(localized: "Connection")) {
                commonField("HostName", label: "HostName")
                commonField("User", label: "User")
                commonField("Port", label: "Port")
                HStack {
                    commonField("IdentityFile", label: "IdentityFile")
                    Button(String(localized: "Browse...")) {
                        browseIdentityFile()
                    }
                }
            }

            Section(String(localized: "Proxy")) {
                commonField("ProxyCommand", label: "ProxyCommand")
                commonField("ProxyJump", label: "ProxyJump")
            }

            Section(String(localized: "Options")) {
                commonField("ForwardAgent", label: "ForwardAgent")
                commonField("ServerAliveInterval", label: "ServerAliveInterval")
                commonField("ServerAliveCountMax", label: "ServerAliveCountMax")
            }

            Section(String(localized: "Other Directives")) {
                let others = draft.otherDirectives
                ForEach(others) { directive in
                    HStack {
                        Text(directive.key)
                            .frame(width: 180, alignment: .leading)
                            .foregroundStyle(.secondary)
                        TextField("", text: directiveBinding(for: directive.id), prompt: Text("Value"))
                        Button(role: .destructive) {
                            draft.directives.removeAll { $0.id == directive.id }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .foregroundStyle(.red)
                        }
                        .buttonStyle(.plain)
                    }
                }

                HStack {
                    LeadingTextField(text: $newKey, placeholder: String(localized: "Key"))
                        .frame(width: 180)
                    TextField("", text: $newValue, prompt: Text("Value"))
                    Button {
                        guard !newKey.isEmpty else { return }
                        draft.directives.append(SSHConfigDirective(key: newKey, value: newValue))
                        newKey = ""
                        newValue = ""
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                    .buttonStyle(.plain)
                    .disabled(newKey.isEmpty)
                }
            }
        }
        .formStyle(.grouped)
    }

    @ViewBuilder
    private func commonField(_ key: String, label: String) -> some View {
        TextField(label, text: Binding(
            get: { draft.value(for: key) },
            set: { draft.setValue($0, for: key) }
        ))
    }

    private func directiveBinding(for id: UUID) -> Binding<String> {
        Binding(
            get: {
                draft.directives.first { $0.id == id }?.value ?? ""
            },
            set: { newValue in
                if let idx = draft.directives.firstIndex(where: { $0.id == id }) {
                    draft.directives[idx].value = newValue
                }
            }
        )
    }

    private func browseIdentityFile() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.directoryURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".ssh")
        if panel.runModal() == .OK, let url = panel.url {
            draft.setValue(url.path, for: "IdentityFile")
        }
    }
}

// MARK: - Leading-aligned TextField

struct LeadingTextField: NSViewRepresentable {
    @Binding var text: String
    var placeholder: String

    func makeNSView(context: Context) -> NSTextField {
        let field = NSTextField()
        field.placeholderString = placeholder
        field.focusRingType = .none
        field.alignment = .left
        field.isBordered = false
        field.isBezeled = false
        field.drawsBackground = false
        field.backgroundColor = .clear
        field.delegate = context.coordinator
        return field
    }

    func updateNSView(_ nsView: NSTextField, context: Context) {
        if nsView.stringValue != text {
            nsView.stringValue = text
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: LeadingTextField
        init(_ parent: LeadingTextField) { self.parent = parent }
        func controlTextDidChange(_ obj: Notification) {
            if let field = obj.object as? NSTextField {
                parent.text = field.stringValue
            }
        }
    }
}
