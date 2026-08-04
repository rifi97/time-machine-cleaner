import Foundation

struct LocalSnapshot: Identifiable, Hashable, Sendable {
    static let namePrefix = "com.apple.TimeMachine."

    let name: String
    let deletionToken: String
    let date: Date
    let isDataless: Bool

    var id: String { name }

    var formattedDate: String {
        date.formatted(
            .dateTime
                .year()
                .month(.wide)
                .day()
                .weekday(.wide)
                .hour()
                .minute()
                .second()
                .locale(Locale(identifier: "ko_KR"))
        )
    }
}

enum SnapshotParser {
    static func parse(_ output: String, calendar: Calendar = .current) -> [LocalSnapshot] {
        output
            .split(whereSeparator: \.isNewline)
            .compactMap { parseLine(String($0), calendar: calendar) }
            .sorted { $0.date > $1.date }
    }

    static func isValidDeletionToken(_ token: String) -> Bool {
        let parts = token.split(separator: "-", omittingEmptySubsequences: false)
        let expectedLengths = [4, 2, 2, 6]
        guard parts.count == expectedLengths.count else { return false }
        return zip(parts, expectedLengths).allSatisfy { part, expectedLength in
            part.count == expectedLength && part.utf8.allSatisfy { byte in
                byte >= 48 && byte <= 57
            }
        }
    }

    private static func parseLine(_ rawLine: String, calendar: Calendar) -> LocalSnapshot? {
        let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let firstComponent = line.split(whereSeparator: \.isWhitespace).first else { return nil }
        let snapshotName = String(firstComponent)
        guard snapshotName.hasPrefix(LocalSnapshot.namePrefix) else { return nil }

        var token = String(snapshotName.dropFirst(LocalSnapshot.namePrefix.count))
        if token.hasSuffix(".local") {
            token.removeLast(".local".count)
        }
        guard isValidDeletionToken(token) else { return nil }

        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "yyyy-MM-dd-HHmmss"
        guard let date = formatter.date(from: token) else { return nil }

        return LocalSnapshot(
            name: snapshotName,
            deletionToken: token,
            date: date,
            isDataless: line.hasSuffix("(dataless)")
        )
    }
}
