import Foundation

@Observable
final class ConfigStore {
    private(set) var configs: [SSHTunnelConfig] = []
    private let fileURL: URL

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("SSHTunnel", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        self.fileURL = dir.appendingPathComponent("tunnels.json")
        load()
    }

    func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        do {
            let data = try Data(contentsOf: fileURL)
            configs = try JSONDecoder().decode([SSHTunnelConfig].self, from: data)
        } catch {
            print("Failed to load configs: \(error)")
        }
    }

    func save() {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(configs)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("Failed to save configs: \(error)")
        }
    }

    func add(_ config: SSHTunnelConfig) {
        configs.append(config)
        save()
    }

    func update(_ config: SSHTunnelConfig) {
        guard let index = configs.firstIndex(where: { $0.id == config.id }) else { return }
        configs[index] = config
        save()
    }

    func delete(_ id: UUID) {
        configs.removeAll { $0.id == id }
        save()
    }
}
