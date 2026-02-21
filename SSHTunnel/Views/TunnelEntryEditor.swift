import SwiftUI

struct TunnelEntryHeader: View {
    var body: some View {
        HStack(spacing: 8) {
            Text(String(localized: "Type"))
                .frame(width: 110)
            Text(String(localized: "Local Port"))
                .frame(width: 60, alignment: .trailing)
            Image(systemName: "arrow.right")
                .hidden()
            Text(String(localized: "Remote Host"))
                .frame(maxWidth: .infinity, alignment: .trailing)
            Text(String(localized: "Remote Port"))
                .frame(width: 60, alignment: .trailing)
            Image(systemName: "minus.circle.fill")
                .hidden()
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }
}

struct TunnelEntryEditor: View {
    @Binding var entry: TunnelEntry
    let onDelete: () -> Void

    @State private var localPortText: String = ""
    @State private var remotePortText: String = ""

    var body: some View {
        HStack(spacing: 8) {
            Picker("", selection: $entry.type) {
                ForEach(TunnelType.allCases) { type in
                    Text(type.displayName).tag(type)
                }
            }
            .labelsHidden()
            .frame(width: 110)

            TextField("", text: $localPortText)
                .multilineTextAlignment(.trailing)
                .frame(width: 60)
                .onChange(of: localPortText) { _, newValue in
                    entry.localPort = UInt16(newValue) ?? 0
                }

            Image(systemName: "arrow.right")
                .foregroundStyle(.secondary)

            if entry.type != .dynamic {
                TextField("", text: $entry.remoteHost)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: .infinity)

                TextField("", text: $remotePortText)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 60)
                    .onChange(of: remotePortText) { _, newValue in
                        entry.remotePort = UInt16(newValue) ?? 0
                    }
            } else {
                Spacer()
                    .frame(maxWidth: .infinity)
                Spacer()
                    .frame(width: 60)
            }

            Button(role: .destructive) {
                onDelete()
            } label: {
                Image(systemName: "minus.circle.fill")
            }
            .buttonStyle(.plain)
            .foregroundStyle(.red)
        }
        .onAppear {
            localPortText = entry.localPort == 0 ? "" : "\(entry.localPort)"
            remotePortText = entry.remotePort == 0 ? "" : "\(entry.remotePort)"
        }
    }
}
