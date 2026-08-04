import Foundation

struct CommandResult: Sendable {
    let output: String
    let errorOutput: String
    let exitCode: Int32
}

enum SnapshotServiceError: LocalizedError {
    case commandFailed(String)
    case invalidSnapshotName
    case authorizationCancelled

    var errorDescription: String? {
        switch self {
        case .commandFailed(let message):
            return message.isEmpty ? "명령을 실행하지 못했습니다." : message
        case .invalidSnapshotName:
            return "안전하지 않은 스냅샷 이름이 감지되어 삭제를 중단했습니다."
        case .authorizationCancelled:
            return "관리자 인증이 취소되었습니다."
        }
    }
}

struct SnapshotService: Sendable {
    func listSnapshots() async throws -> [LocalSnapshot] {
        let result = try await run(
            executable: "/usr/bin/tmutil",
            arguments: ["listlocalsnapshots", "/"]
        )
        guard result.exitCode == 0 else {
            throw SnapshotServiceError.commandFailed(result.errorOutput)
        }
        return SnapshotParser.parse(result.output)
    }

    func delete(_ snapshots: [LocalSnapshot]) async throws {
        let tokens = snapshots.map(\.deletionToken)
        guard !tokens.isEmpty else { return }
        guard tokens.allSatisfy(SnapshotParser.isValidDeletionToken) else {
            throw SnapshotServiceError.invalidSnapshotName
        }

        let scriptLines = [
            "on run argv",
            "set shellCommand to \"\"",
            "repeat with snapshotID in argv",
            "set shellCommand to shellCommand & \"/usr/bin/tmutil deletelocalsnapshots \" & quoted form of (contents of snapshotID) & \"; \"",
            "end repeat",
            "do shell script shellCommand with administrator privileges",
            "end run"
        ]

        var arguments: [String] = []
        for line in scriptLines {
            arguments.append(contentsOf: ["-e", line])
        }
        arguments.append(contentsOf: tokens)

        let result = try await run(executable: "/usr/bin/osascript", arguments: arguments)
        guard result.exitCode == 0 else {
            if result.errorOutput.contains("(-128)") || result.errorOutput.localizedCaseInsensitiveContains("canceled") {
                throw SnapshotServiceError.authorizationCancelled
            }
            throw SnapshotServiceError.commandFailed(result.errorOutput)
        }
    }

    private func run(executable: String, arguments: [String]) async throws -> CommandResult {
        try await Task.detached(priority: .userInitiated) {
            let process = Process()
            let outputPipe = Pipe()
            let errorPipe = Pipe()

            process.executableURL = URL(fileURLWithPath: executable)
            process.arguments = arguments
            process.standardOutput = outputPipe
            process.standardError = errorPipe

            try process.run()
            process.waitUntilExit()

            let output = String(
                data: outputPipe.fileHandleForReading.readDataToEndOfFile(),
                encoding: .utf8
            ) ?? ""
            let errorOutput = String(
                data: errorPipe.fileHandleForReading.readDataToEndOfFile(),
                encoding: .utf8
            ) ?? ""
            return CommandResult(
                output: output,
                errorOutput: errorOutput,
                exitCode: process.terminationStatus
            )
        }.value
    }
}
