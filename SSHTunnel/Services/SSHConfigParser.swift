import Foundation

struct SSHConfigHost: Identifiable, Hashable {
    let id = UUID()
    let name: String        // Host alias
    let hostname: String    // HostName (actual address)
    let port: UInt16
    let user: String
    let identityFile: String
}

enum SSHConfigParser {
    static func parse() -> [SSHConfigHost] {
        let home = FileManager.default.homeDirectoryForCurrentUser
        var hosts: [SSHConfigHost] = []

        // Parse main config
        let mainConfig = home.appendingPathComponent(".ssh/config")
        if let content = try? String(contentsOf: mainConfig, encoding: .utf8) {
            hosts.append(contentsOf: parseContent(content))
        }

        // Parse config.d/ directory
        let configDir = home.appendingPathComponent(".ssh/config.d")
        if let files = try? FileManager.default.contentsOfDirectory(at: configDir, includingPropertiesForKeys: nil) {
            for file in files.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) {
                guard !file.lastPathComponent.hasPrefix(".") else { continue }
                if let content = try? String(contentsOf: file, encoding: .utf8) {
                    hosts.append(contentsOf: parseContent(content))
                }
            }
        }

        return hosts
    }

    // MARK: - Full-fidelity parser for SSH Config editor

    static func parseAll() -> [SSHConfigEntry] {
        let home = FileManager.default.homeDirectoryForCurrentUser
        var entries: [SSHConfigEntry] = []

        let mainConfig = home.appendingPathComponent(".ssh/config")
        if let content = try? String(contentsOf: mainConfig, encoding: .utf8) {
            entries.append(contentsOf: parseFullContent(content, sourceFile: mainConfig))
        }

        let configDir = home.appendingPathComponent(".ssh/config.d")
        if let files = try? FileManager.default.contentsOfDirectory(at: configDir, includingPropertiesForKeys: nil) {
            for file in files.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) {
                guard !file.lastPathComponent.hasPrefix(".") else { continue }
                if let content = try? String(contentsOf: file, encoding: .utf8) {
                    entries.append(contentsOf: parseFullContent(content, sourceFile: file))
                }
            }
        }

        return entries
    }

    static func configFiles() -> [URL] {
        let home = FileManager.default.homeDirectoryForCurrentUser
        var files: [URL] = []
        let mainConfig = home.appendingPathComponent(".ssh/config")
        if FileManager.default.fileExists(atPath: mainConfig.path) {
            files.append(mainConfig)
        }
        let configDir = home.appendingPathComponent(".ssh/config.d")
        if let dirFiles = try? FileManager.default.contentsOfDirectory(at: configDir, includingPropertiesForKeys: nil) {
            for f in dirFiles.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) {
                guard !f.lastPathComponent.hasPrefix(".") else { continue }
                files.append(f)
            }
        }
        return files
    }

    static func serialize(_ entries: [SSHConfigEntry]) -> String {
        var lines: [String] = []
        for (index, entry) in entries.enumerated() {
            if index > 0 { lines.append("") }
            if !entry.comment.isEmpty {
                lines.append(entry.comment)
            }
            let prefix = entry.commented ? "# " : ""
            lines.append("\(prefix)Host \(entry.host)")
            for directive in entry.directives {
                lines.append("\(prefix)    \(directive.key) \(directive.value)")
            }
        }
        lines.append("")
        return lines.joined(separator: "\n")
    }

    static func parseFullContent(_ content: String, sourceFile: URL) -> [SSHConfigEntry] {
        var entries: [SSHConfigEntry] = []
        var currentHost: String?
        var currentCommented = false
        var currentDirectives: [SSHConfigDirective] = []
        var commentBuffer: [String] = []

        func flush() {
            if let host = currentHost, host != "*" {
                entries.append(SSHConfigEntry(
                    host: host,
                    directives: currentDirectives,
                    sourceFile: sourceFile,
                    comment: commentBuffer.joined(separator: "\n"),
                    commented: currentCommented
                ))
            }
            currentDirectives = []
            commentBuffer = []
            currentCommented = false
        }

        for line in content.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.isEmpty {
                if currentHost == nil { commentBuffer = [] }
                continue
            }

            // Check for commented-out Host line: "# Host xxx" or "#Host xxx"
            if trimmed.hasPrefix("#") {
                let uncommented = trimmed.drop(while: { $0 == "#" || $0 == " " })
                let uParts = uncommented.split(separator: " ", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
                if uParts.count == 2 && uParts[0].lowercased() == "host" {
                    flush()
                    currentHost = uParts[1]
                    currentCommented = true
                    continue
                }

                // If inside a commented host block, parse commented directives
                if currentHost != nil && currentCommented {
                    let dParts = uncommented.split(separator: " ", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
                    if dParts.count == 2 {
                        let key = dParts[0]
                        if key.lowercased() != "include" && key.lowercased() != "match" {
                            currentDirectives.append(SSHConfigDirective(key: String(key), value: dParts[1]))
                        }
                    }
                    continue
                }

                // Regular comment before any host block
                if currentHost == nil { commentBuffer.append(trimmed) }
                continue
            }

            // If we were in a commented block and hit an uncommented line, flush
            if currentCommented && currentHost != nil {
                flush()
            }

            let parts = trimmed.split(separator: " ", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
            guard parts.count == 2 else { continue }

            let key = parts[0]
            let value = parts[1]

            if key.lowercased() == "host" {
                flush()
                currentHost = value
            } else if key.lowercased() == "include" || key.lowercased() == "match" {
                continue
            } else if currentHost != nil {
                currentDirectives.append(SSHConfigDirective(key: key, value: value))
            }
        }
        flush()

        return entries
    }

    // MARK: - Legacy parser for SSHConfigPickerView

    private static func parseContent(_ content: String) -> [SSHConfigHost] {
        var hosts: [SSHConfigHost] = []
        var currentName: String?
        var hostname = ""
        var port: UInt16 = 22
        var user = ""
        var identityFile = ""

        func flush() {
            if let name = currentName, name != "*" {
                hosts.append(SSHConfigHost(
                    name: name,
                    hostname: hostname.isEmpty ? name : hostname,
                    port: port,
                    user: user,
                    identityFile: identityFile
                ))
            }
            hostname = ""
            port = 22
            user = ""
            identityFile = ""
        }

        for line in content.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty, !trimmed.hasPrefix("#") else { continue }

            let parts = trimmed.split(separator: " ", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
            guard parts.count == 2 else { continue }

            let key = parts[0].lowercased()
            let value = parts[1]

            switch key {
            case "host":
                flush()
                currentName = value
            case "hostname":
                hostname = value
            case "port":
                port = UInt16(value) ?? 22
            case "user":
                user = value
            case "identityfile":
                identityFile = (value as NSString).expandingTildeInPath
            default:
                break
            }
        }
        flush()

        return hosts
    }
}
