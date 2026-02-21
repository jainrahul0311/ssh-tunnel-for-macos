import Foundation

struct SSHConfigDirective: Identifiable, Hashable {
    let id = UUID()
    var key: String
    var value: String
}

struct SSHConfigEntry: Identifiable, Hashable {
    let id: UUID
    var host: String
    var directives: [SSHConfigDirective]
    var sourceFile: URL
    var comment: String
    var commented: Bool

    init(id: UUID = UUID(), host: String = "", directives: [SSHConfigDirective] = [], sourceFile: URL, comment: String = "", commented: Bool = false) {
        self.id = id
        self.host = host
        self.directives = directives
        self.sourceFile = sourceFile
        self.comment = comment
        self.commented = commented
    }

    static let commonKeys = [
        "HostName", "User", "Port", "IdentityFile",
        "ProxyCommand", "ProxyJump", "ForwardAgent",
        "ServerAliveInterval", "ServerAliveCountMax"
    ]

    func value(for key: String) -> String {
        let lower = key.lowercased()
        return directives.first { $0.key.lowercased() == lower }?.value ?? ""
    }

    mutating func setValue(_ value: String, for key: String) {
        let lower = key.lowercased()
        if let idx = directives.firstIndex(where: { $0.key.lowercased() == lower }) {
            if value.isEmpty {
                directives.remove(at: idx)
            } else {
                directives[idx].value = value
            }
        } else if !value.isEmpty {
            directives.append(SSHConfigDirective(key: key, value: value))
        }
    }

    var otherDirectives: [SSHConfigDirective] {
        let commonLower = Set(Self.commonKeys.map { $0.lowercased() })
        return directives
            .filter { !commonLower.contains($0.key.lowercased()) }
            .sorted { $0.key.lowercased() < $1.key.lowercased() }
    }
}
