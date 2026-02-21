import Foundation

/// Share format (plain text):
/// ```
/// sshtunnel://user@host:port/name
/// L:localPort:remoteHost:remotePort
/// R:localPort:remoteHost:remotePort
/// D:localPort
/// ```
enum ShareService {
    static func encode(_ config: SSHTunnelConfig) -> String {
        let name = config.name.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? config.name
        var lines: [String] = [
            "sshtunnel://\(config.username)@\(config.host):\(config.port)/\(name)"
        ]

        for entry in config.tunnels {
            switch entry.type {
            case .local:
                lines.append("L:\(entry.localPort):\(entry.remoteHost):\(entry.remotePort)")
            case .remote:
                lines.append("R:\(entry.localPort):\(entry.remoteHost):\(entry.remotePort)")
            case .dynamic:
                lines.append("D:\(entry.localPort)")
            }
        }

        return lines.joined(separator: "\n")
    }

    static func buildCLI(_ config: SSHTunnelConfig) -> String {
        var args = ["ssh", "-N"]

        if config.port != 22 {
            args += ["-p", "\(config.port)"]
        }

        switch config.authMethod {
        case .identityFile:
            if !config.identityFile.isEmpty {
                args += ["-i", config.identityFile]
            }
        case .password:
            args += ["-o", "PreferredAuthentications=password,keyboard-interactive"]
        }

        for entry in config.tunnels {
            args += [entry.type.flag, entry.sshArgument]
        }

        if !config.additionalArgs.isEmpty {
            args.append(config.additionalArgs)
        }

        args.append("\(config.username)@\(config.host)")
        return args.joined(separator: " ")
    }

    static func decode(_ input: String) -> SSHTunnelConfig? {
        let raw = input.trimmingCharacters(in: .whitespacesAndNewlines)

        // Support legacy base64 format
        if raw.hasPrefix("sshtunnel://") && !raw.contains("@") {
            return decodeLegacyBase64(raw)
        }

        let lines = raw.components(separatedBy: .newlines).map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        guard let header = lines.first, header.hasPrefix("sshtunnel://") else { return nil }

        // Parse: sshtunnel://user@host:port/name
        let uri = String(header.dropFirst("sshtunnel://".count))

        guard let atIndex = uri.firstIndex(of: "@") else { return nil }
        let user = String(uri[uri.startIndex..<atIndex])

        let afterAt = String(uri[uri.index(after: atIndex)...])

        // Split host:port/name
        var hostPart = afterAt
        var name = ""
        if let slashIndex = afterAt.firstIndex(of: "/") {
            hostPart = String(afterAt[afterAt.startIndex..<slashIndex])
            name = String(afterAt[afterAt.index(after: slashIndex)...])
                .removingPercentEncoding ?? ""
        }

        let hostComponents = hostPart.split(separator: ":", maxSplits: 1)
        let host = String(hostComponents[0])
        let port: UInt16 = hostComponents.count > 1 ? UInt16(hostComponents[1]) ?? 22 : 22

        // Parse tunnel entries
        var tunnels: [TunnelEntry] = []
        for line in lines.dropFirst() {
            if let entry = parseTunnelLine(line) {
                tunnels.append(entry)
            }
        }

        var config = SSHTunnelConfig()
        config.id = UUID()
        config.name = name
        config.host = host
        config.port = port
        config.username = user
        config.tunnels = tunnels
        return config
    }

    private static func parseTunnelLine(_ line: String) -> TunnelEntry? {
        let parts = line.split(separator: ":", maxSplits: 3).map(String.init)
        guard parts.count >= 2 else { return nil }

        let typeStr = parts[0].uppercased()
        var entry = TunnelEntry()

        switch typeStr {
        case "L":
            guard parts.count == 4,
                  let lp = UInt16(parts[1]),
                  let rp = UInt16(parts[3]) else { return nil }
            entry.type = .local
            entry.localPort = lp
            entry.remoteHost = parts[2]
            entry.remotePort = rp
        case "R":
            guard parts.count == 4,
                  let lp = UInt16(parts[1]),
                  let rp = UInt16(parts[3]) else { return nil }
            entry.type = .remote
            entry.localPort = lp
            entry.remoteHost = parts[2]
            entry.remotePort = rp
        case "D":
            guard let lp = UInt16(parts[1]) else { return nil }
            entry.type = .dynamic
            entry.localPort = lp
        default:
            return nil
        }
        return entry
    }

    // Support for old base64 format
    private static func decodeLegacyBase64(_ raw: String) -> SSHTunnelConfig? {
        let base64 = String(raw.dropFirst("sshtunnel://".count))
        guard let data = Data(base64Encoded: base64) else { return nil }
        var config = try? JSONDecoder().decode(SSHTunnelConfig.self, from: data)
        config?.id = UUID()
        return config
    }
}
