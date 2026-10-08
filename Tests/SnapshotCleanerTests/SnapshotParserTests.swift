import Foundation
import Testing
@testable import TimeMachineCleaner

struct SnapshotParserTests {
    @Test func calculatesDiskUsageAndFormatsCapacity() {
        let capacity = DiskCapacity(totalBytes: 2_000_000_000, availableBytes: 750_000_000)

        #expect(capacity.usedBytes == 1_250_000_000)
        #expect(capacity.usedFraction == 0.625)
        #expect(DiskCapacity.formatted(bytes: 1_000_000_000).contains("GB"))
    }

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

    @Test func parsesDatalessSnapshotAnnotation() {
        let snapshots = SnapshotParser.parse(
            "com.apple.TimeMachine.2026-08-04-120336.local (dataless)"
        )

        #expect(snapshots.count == 1)
        #expect(snapshots.first?.name == "com.apple.TimeMachine.2026-08-04-120336.local")
        #expect(snapshots.first?.deletionToken == "2026-08-04-120336")
        #expect(snapshots.first?.isDataless == true)
    }
}
