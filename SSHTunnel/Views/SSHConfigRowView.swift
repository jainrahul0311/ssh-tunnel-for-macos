import SwiftUI

struct SSHConfigRowView: View {
    let entry: SSHConfigEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(entry.host)
                .fontWeight(.medium)
                .strikethrough(entry.commented)
                .foregroundStyle(entry.commented ? .secondary : .primary)
            let hostname = entry.value(for: "HostName")
            let user = entry.value(for: "User")
            if !hostname.isEmpty || !user.isEmpty {
                Text(verbatim: "\(user.isEmpty ? "" : "\(user)@")\(hostname)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
        .opacity(entry.commented ? 0.6 : 1.0)
    }
}
