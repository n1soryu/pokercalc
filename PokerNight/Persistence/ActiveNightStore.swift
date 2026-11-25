import Foundation
import PokerCore

struct ActiveNightStore {
    let url: URL

    init(url: URL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("PokerNight", isDirectory: true).appendingPathComponent("active-night.json")) {
        self.url = url
    }

    var exists: Bool { FileManager.default.fileExists(atPath: url.path) }

    func write(_ session: TableSession) throws {
        guard session.isPointConserved else { throw ActiveNightError.invalidSession }
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try JSONEncoder().encode(session).write(to: url, options: .atomic)
    }

    func load() throws -> TableSession {
        // Read errors are not corruption and must not offer destructive recovery.
        let data = try Data(contentsOf: url)
        do {
            let session = try JSONDecoder().decode(TableSession.self, from: data)
            guard session.isPointConserved else { throw ActiveNightError.corrupt }
            return session
        } catch is DecodingError {
            throw ActiveNightError.corrupt
        }
    }

    func remove() throws {
        if exists { try FileManager.default.removeItem(at: url) }
    }

    func removeCorruptFile() throws {
        guard exists else { return }
        do { _ = try load() }
        catch ActiveNightError.corrupt { try remove(); return }
        throw ActiveNightError.fileChanged
    }
}

enum ActiveNightError: LocalizedError {
    case corrupt, fileChanged, alreadyActive, invalidSession

    var errorDescription: String? {
        switch self {
        case .corrupt: return "The saved night could not be decoded. Cancel to keep it, or delete only this active-night file. Your players and past nights will stay saved."
        case .fileChanged: return "The saved night is now readable. Resume it instead of deleting it."
        case .alreadyActive: return "Resume and end the existing night before starting another."
        case .invalidSession: return "The night’s points no longer balance, so it was not saved. Undo the last action or restart the hand."
        }
    }
}
