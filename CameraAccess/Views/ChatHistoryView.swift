import SwiftUI

struct ChatHistoryView: View {
    let onLoadSession: ([OpenClawChatMessage]) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var sessions: [OpenClawSession] = []
    @State private var showDeleteAllConfirm = false

    var body: some View {
        NavigationStack {
            Group {
                if sessions.isEmpty {
                    emptyState
                } else {
                    sessionList
                }
            }
            .navigationTitle("대화 기록")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("닫기") { dismiss() }
                }
                if !sessions.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("전체 삭제") { showDeleteAllConfirm = true }
                            .foregroundColor(.red)
                    }
                }
            }
            .confirmationDialog("모든 대화 기록을 삭제할까요?", isPresented: $showDeleteAllConfirm, titleVisibility: .visible) {
                Button("전체 삭제", role: .destructive) {
                    sessions.forEach { OpenClawSessionStorage.shared.deleteSession($0.id) }
                    sessions = []
                }
            }
        }
        .onAppear { sessions = OpenClawSessionStorage.shared.loadSessions() }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 56))
                .foregroundColor(.gray.opacity(0.4))
            Text("저장된 대화 기록이 없습니다")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
            Text("대화를 마치거나 새 대화를 시작하면\n자동으로 저장됩니다")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var sessionList: some View {
        List {
            ForEach(sessions) { session in
                Button {
                    let msgs = session.messages.map {
                        OpenClawChatMessage(role: $0.role, text: $0.text, image: nil)
                    }
                    onLoadSession(msgs)
                    dismiss()
                } label: {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(session.title)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        HStack {
                            Text(session.formattedDate)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(session.messages.count)개 메시지")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .onDelete { indexSet in
                indexSet.forEach { OpenClawSessionStorage.shared.deleteSession(sessions[$0].id) }
                sessions.remove(atOffsets: indexSet)
            }
        }
        .listStyle(.insetGrouped)
    }
}
