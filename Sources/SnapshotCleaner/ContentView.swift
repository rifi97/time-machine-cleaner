import SwiftUI

struct ContentView: View {
    @StateObject private var model = SnapshotViewModel()
    @State private var showingDeleteConfirmation = false

    var body: some View {
        VStack(spacing: 0) {
            header
            capacitySummary
            Divider()
            content
            Divider()
            footer
        }
        .frame(minWidth: 620, minHeight: 430)
        .task { await model.load() }
        .alert("오류", isPresented: errorAlertBinding) {
            Button("확인", role: .cancel) {}
        } message: {
            Text(model.alertMessage ?? "알 수 없는 오류가 발생했습니다.")
        }
        .confirmationDialog(
            "선택한 로컬 스냅샷을 삭제할까요?",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("\(model.selectedSnapshots.count)개 삭제", role: .destructive) {
                Task { await model.deleteSelected() }
            }
            Button("취소", role: .cancel) {}
        } message: {
            Text("삭제한 로컬 스냅샷은 복구할 수 없습니다. 외장 Time Machine 백업은 삭제되지 않습니다.")
        }
    }

    @ViewBuilder
    private var capacitySummary: some View {
        if let capacity = model.diskCapacity {
            VStack(spacing: 8) {
                HStack {
                    Label("내장 SSD", systemImage: "internaldrive")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Text("\(DiskCapacity.formatted(bytes: capacity.availableBytes)) 사용 가능")
                        .font(.subheadline.weight(.medium))
                }
                ProgressView(value: capacity.usedFraction)
                HStack {
                    Text("\(DiskCapacity.formatted(bytes: capacity.usedBytes)) 사용")
                    Spacer()
                    Text("전체 \(DiskCapacity.formatted(bytes: capacity.totalBytes))")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
    }

    private var header: some View {
        HStack(spacing: 14) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 30, weight: .medium))
                .foregroundStyle(.tint)
            VStack(alignment: .leading, spacing: 3) {
                Text("Time Machine 로컬 스냅샷")
                    .font(.title2.weight(.semibold))
                Text("맥 내부에 임시 저장된 스냅샷만 표시합니다.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                Task { await model.load() }
            } label: {
                Label("새로고침", systemImage: "arrow.clockwise")
            }
            .disabled(model.isWorking)
        }
        .padding(20)
    }

    @ViewBuilder
    private var content: some View {
        if model.isWorking && model.snapshots.isEmpty {
            VStack(spacing: 12) {
                ProgressView()
                Text("스냅샷을 확인하는 중…")
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if model.snapshots.isEmpty {
            VStack(spacing: 12) {
                Image(systemName: "checkmark.circle")
                    .font(.system(size: 42))
                    .foregroundStyle(.secondary)
                Text("로컬 스냅샷 없음")
                    .font(.title3.weight(.semibold))
                Text("현재 삭제할 Time Machine 로컬 스냅샷이 없습니다.")
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List(model.snapshots) { snapshot in
                Button {
                    model.toggleSelection(for: snapshot)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: model.selectedIDs.contains(snapshot.id) ? "checkmark.square.fill" : "square")
                            .font(.title3)
                            .foregroundStyle(model.selectedIDs.contains(snapshot.id) ? Color.accentColor : .secondary)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(snapshot.formattedDate)
                                .foregroundStyle(.primary)
                            HStack(spacing: 6) {
                                Text(snapshot.name)
                                    .font(.caption.monospaced())
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                                if snapshot.isDataless {
                                    Text("dataless")
                                        .font(.caption2.weight(.medium))
                                        .foregroundStyle(.secondary)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(.secondary.opacity(0.12), in: Capsule())
                                }
                            }
                        }
                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .listStyle(.inset)
        }
    }

    private var footer: some View {
        HStack {
            Button(model.allSelected ? "전체 선택 해제" : "전체 선택") {
                model.toggleSelectAll()
            }
            .disabled(model.snapshots.isEmpty || model.isWorking)

            Text("총 \(model.snapshots.count)개 · \(model.selectedSnapshots.count)개 선택")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if let summary = model.lastDeletionSummary {
                Label(summary, systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.green)
            }

            Spacer()

            if model.isWorking && !model.snapshots.isEmpty {
                ProgressView()
                    .controlSize(.small)
            }

            Button("선택 항목 삭제", role: .destructive) {
                showingDeleteConfirmation = true
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
            .disabled(model.selectedSnapshots.isEmpty || model.isWorking)
        }
        .padding(16)
        .overlay(alignment: .top) {
            Text("APFS 공유 블록 특성상 삭제 전 스냅샷별 크기는 macOS에서 제공하지 않습니다.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .offset(y: -20)
        }
    }

    private var errorAlertBinding: Binding<Bool> {
        Binding(
            get: { model.alertMessage != nil },
            set: { if !$0 { model.alertMessage = nil } }
        )
    }
}
