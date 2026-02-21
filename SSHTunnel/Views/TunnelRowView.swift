import SwiftUI

struct TunnelRowView: View {
    let config: SSHTunnelConfig
    let state: ConnectionState

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(state.color)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(config.name.isEmpty ? config.host : config.name)
                    .fontWeight(.medium)

                Text(verbatim: "\(config.username)@\(config.host):\(config.port)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("\(config.tunnels.count)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(.quaternary, in: Capsule())
        }
        .padding(.vertical, 2)
    }
}
