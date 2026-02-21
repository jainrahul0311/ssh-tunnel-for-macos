import Foundation
import SwiftUI

enum ConnectionState: Equatable {
    case disconnected
    case connecting
    case connected
    case error(String)

    var isActive: Bool {
        switch self {
        case .connecting, .connected: true
        default: false
        }
    }

    var color: Color {
        switch self {
        case .disconnected: .gray
        case .connecting: .yellow
        case .connected: .green
        case .error: .red
        }
    }

    var label: String {
        switch self {
        case .disconnected: String(localized: "Disconnected")
        case .connecting: String(localized: "Connecting...")
        case .connected: String(localized: "Connected")
        case .error(let msg): String(localized: "Error: \(msg)")
        }
    }
}

@Observable
final class TunnelStatus {
    var states: [UUID: ConnectionState] = [:]

    func state(for id: UUID) -> ConnectionState {
        states[id] ?? .disconnected
    }
}
