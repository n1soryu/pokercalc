import Foundation
import PokerCore

enum ActiveNightStore {
    private static var url: URL {
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("PokerNight", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent("active-night.json")
    }

    static var exists: Bool {
        FileManager.default.fileExists(atPath: url.path)
    }

    static func save(_ session: TableSession) {
        guard let data = try? JSONEncoder().encode(session) else { return }
        try? data.write(to: url, options: .atomic)
    }

    static func load() throws -> TableSession {
        try JSONDecoder().decode(TableSession.self, from: Data(contentsOf: url))
    }

    static func remove() {
        try? FileManager.default.removeItem(at: url)
    }
}
