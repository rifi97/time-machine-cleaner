import Foundation
import Testing
@testable import TimeMachineCleaner

struct SnapshotParserTests {
    @Test func parsesOnlyTimeMachineLocalSnapshots() {
        let output = """
        Snapshots for disk /:
        com.apple.TimeMachine.2026-07-30-083421.local
        com.apple.os.update-ABCDEF
        com.apple.TimeMachine.2026-07-30-111953.local
        """

        let snapshots = SnapshotParser.parse(output)

        #expect(snapshots.count == 2)
        #expect(Set(snapshots.map(\.deletionToken)) == [
            "2026-07-30-083421",
            "2026-07-30-111953"
        ])
    }

    @Test func rejectsMalformedDeletionTokens() {
        #expect(SnapshotParser.isValidDeletionToken("2026-07-30-083421"))
        #expect(!SnapshotParser.isValidDeletionToken("2026-07-30-083421; rm -rf /"))
        #expect(!SnapshotParser.isValidDeletionToken("com.apple.TimeMachine.2026-07-30-083421.local"))
    }

    @Test func supportsSnapshotNamesWithoutLocalSuffix() {
        let snapshots = SnapshotParser.parse("com.apple.TimeMachine.2026-08-04-123456")

        #expect(snapshots.count == 1)
        #expect(snapshots.first?.deletionToken == "2026-08-04-123456")
    }
}
