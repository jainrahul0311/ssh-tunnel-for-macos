import Foundation

@Observable
final class SSHConfigStore {
    private(set) var entries: [SSHConfigEntry] = []
    private(set) var configFiles: [URL] = []

    init() {
        load()
    }

    func load() {
        entries = SSHConfigParser.parseAll()
        configFiles = SSHConfigParser.configFiles()
    }

    func update(_ entry: SSHConfigEntry) {
        guard let index = entries.firstIndex(where: { $0.id == entry.id }) else { return }
        let oldFile = entries[index].sourceFile
        entries[index] = entry
        saveFile(for: entry.sourceFile)
        if oldFile != entry.sourceFile {
            saveFile(for: oldFile)
        }
    }

    func add(_ entry: SSHConfigEntry) {
        entries.append(entry)
        saveFile(for: entry.sourceFile)
    }

    func delete(_ id: UUID) {
        guard let entry = entries.first(where: { $0.id == id }) else { return }
        let file = entry.sourceFile
        entries.removeAll { $0.id == id }
        saveFile(for: file)
    }

    func toggleComment(_ id: UUID) {
        guard let index = entries.firstIndex(where: { $0.id == id }) else { return }
        entries[index].commented.toggle()
        saveFile(for: entries[index].sourceFile)
    }

    func moveEntry(_ id: UUID, direction: Int) {
        guard let index = entries.firstIndex(where: { $0.id == id }) else { return }
        let file = entries[index].sourceFile
        // Find entries in the same file to determine file-local ordering
        let fileIndices = entries.indices.filter { entries[$0].sourceFile == file }
        guard let localPos = fileIndices.firstIndex(of: index) else { return }
        let targetLocalPos = localPos + direction
        guard fileIndices.indices.contains(targetLocalPos) else { return }
        let targetIndex = fileIndices[targetLocalPos]
        entries.swapAt(index, targetIndex)
        saveFile(for: file)
    }

    func moveEntries(_ ids: Set<UUID>, to targetFile: URL) {
        var affectedFiles: Set<URL> = [targetFile]
        for id in ids {
            guard let index = entries.firstIndex(where: { $0.id == id }) else { continue }
            affectedFiles.insert(entries[index].sourceFile)
            entries[index].sourceFile = targetFile
        }
        for file in affectedFiles {
            saveFile(for: file)
        }
    }

    private func saveFile(for fileURL: URL) {
        let fileEntries = entries.filter { $0.sourceFile == fileURL }

        let home = FileManager.default.homeDirectoryForCurrentUser
        let mainConfig = home.appendingPathComponent(".ssh/config")

        if fileURL == mainConfig {
            let header = preserveMainConfigHeader(fileURL)
            let body = SSHConfigParser.serialize(fileEntries)
            try? (header + body).write(to: fileURL, atomically: true, encoding: .utf8)
        } else {
            let content = SSHConfigParser.serialize(fileEntries)
            try? content.write(to: fileURL, atomically: true, encoding: .utf8)
        }
    }

    private func preserveMainConfigHeader(_ fileURL: URL) -> String {
        guard let existing = try? String(contentsOf: fileURL, encoding: .utf8) else { return "" }
        var headerLines: [String] = []
        for line in existing.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.lowercased().hasPrefix("host ") { break }
            headerLines.append(line)
        }
        if !headerLines.isEmpty && !(headerLines.last?.isEmpty ?? true) {
            headerLines.append("")
        }
        return headerLines.joined(separator: "\n")
    }
}
