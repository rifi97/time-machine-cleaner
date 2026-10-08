import Combine
import Foundation

@MainActor
final class SnapshotViewModel: ObservableObject {
    @Published private(set) var snapshots: [LocalSnapshot] = []
    @Published private(set) var diskCapacity: DiskCapacity?
    @Published var selectedIDs: Set<LocalSnapshot.ID> = []
    @Published private(set) var isWorking = false
    @Published var alertMessage: String?
    @Published private(set) var lastDeletionSummary: String?

    private let service = SnapshotService()

    var selectedSnapshots: [LocalSnapshot] {
        snapshots.filter { selectedIDs.contains($0.id) }
    }

    var allSelected: Bool {
        !snapshots.isEmpty && selectedIDs.count == snapshots.count
    }

    func load() async {
        isWorking = true
        defer { isWorking = false }

        do {
            async let loadedSnapshots = service.listSnapshots()
            async let loadedCapacity = service.diskCapacity()
            snapshots = try await loadedSnapshots
            diskCapacity = try await loadedCapacity
            selectedIDs.formIntersection(Set(snapshots.map(\.id)))
        } catch {
            alertMessage = error.localizedDescription
        }
    }

    func toggleSelection(for snapshot: LocalSnapshot) {
        if selectedIDs.contains(snapshot.id) {
            selectedIDs.remove(snapshot.id)
        } else {
            selectedIDs.insert(snapshot.id)
        }
    }

    func toggleSelectAll() {
        selectedIDs = allSelected ? [] : Set(snapshots.map(\.id))
    }

    func deleteSelected() async {
        let targets = selectedSnapshots
        guard !targets.isEmpty else { return }

        isWorking = true
        defer { isWorking = false }

        do {
            let capacityBeforeDeletion = try? await service.diskCapacity()
            try await service.delete(targets)
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            let capacityAfterDeletion = try? await service.diskCapacity()
            selectedIDs.removeAll()
            snapshots = try await service.listSnapshots()
            diskCapacity = capacityAfterDeletion

            if let before = capacityBeforeDeletion, let after = capacityAfterDeletion {
                let reclaimedBytes = max(0, after.availableBytes - before.availableBytes)
                lastDeletionSummary = "\(targets.count)개 삭제 · 약 \(DiskCapacity.formatted(bytes: reclaimedBytes)) 확보"
            } else {
                lastDeletionSummary = "\(targets.count)개 스냅샷 삭제 완료"
            }
        } catch SnapshotServiceError.authorizationCancelled {
            return
        } catch {
            alertMessage = error.localizedDescription
        }
    }
}
