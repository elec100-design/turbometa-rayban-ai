import Foundation

struct StoredChatMessage: Codable, Identifiable {
    let id: UUID
    let role: String
    let text: String
    let timestamp: Date
}

struct OpenClawSession: Codable, Identifiable {
    let id: UUID
    let startedAt: Date
    var messages: [StoredChatMessage]

    var title: String {
        messages.first(where: { $0.role == "user" })?.text
            .prefix(30)
            .description ?? "대화"
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        if calendar.isDateInToday(startedAt) {
            formatter.dateFormat = "HH:mm"
            return "오늘 " + formatter.string(from: startedAt)
        } else if calendar.isDateInYesterday(startedAt) {
            formatter.dateFormat = "HH:mm"
            return "어제 " + formatter.string(from: startedAt)
        } else {
            formatter.dateFormat = "MM/dd HH:mm"
            return formatter.string(from: startedAt)
        }
    }
}

final class OpenClawSessionStorage {
    static let shared = OpenClawSessionStorage()
    private let key = "openClawSessions"
    private let maxSessions = 50

    private init() {}

    func saveSession(messages: [OpenClawChatMessage]) {
        guard !messages.isEmpty else { return }
        let stored = messages.map {
            StoredChatMessage(id: $0.id, role: $0.role, text: $0.text, timestamp: $0.timestamp)
        }
        let session = OpenClawSession(
            id: UUID(),
            startedAt: stored.first?.timestamp ?? Date(),
            messages: stored
        )
        var sessions = loadSessions()
        sessions.insert(session, at: 0)
        if sessions.count > maxSessions { sessions = Array(sessions.prefix(maxSessions)) }
        if let encoded = try? JSONEncoder().encode(sessions) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }

    func loadSessions() -> [OpenClawSession] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let sessions = try? JSONDecoder().decode([OpenClawSession].self, from: data)
        else { return [] }
        return sessions
    }

    func deleteSession(_ id: UUID) {
        var sessions = loadSessions()
        sessions.removeAll { $0.id == id }
        if let encoded = try? JSONEncoder().encode(sessions) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }
}
