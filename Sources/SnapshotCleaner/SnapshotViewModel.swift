import Combine
import Foundation

@MainActor
final class SnapshotViewModel: ObservableObject {
    @Published private(set) var snapshots: [LocalSnapshot] = []
    @Published var selectedIDs: Set<LocalSnapshot.ID> = []
    @Published private(set) var isWorking = false
    @Published var alertMessage: String?

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
            snapshots = try await service.listSnapshots()
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
            try await service.delete(targets)
            selectedIDs.removeAll()
            snapshots = try await service.listSnapshots()
        } catch SnapshotServiceError.authorizationCancelled {
            return
        } catch {
            alertMessage = error.localizedDescription
        }
    }
}
