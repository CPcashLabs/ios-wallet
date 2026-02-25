import SwiftUI
import BackendAPI

struct MessageCenterView: View {
    @ObservedObject var meStore: MeStore
    @State private var loadMoreTask: Task<Void, Never>?
    @State private var paginationGate = PaginationGate()

    var body: some View {
        AdaptiveReader { widthClass in
            SafeAreaScreen(backgroundStyle: .globalImage) {
                Group {
                    if meStore.isLoading(.meMessageList) && meStore.messageList.isEmpty {
                        ProgressView("LoadingMessages...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if meStore.messageList.isEmpty {
                        EmptyStateView(asset: "message_no_data", title: "No messages")
                            .padding(.horizontal, widthClass.horizontalPadding)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 0) {
                                ForEach(messageRows) { row in
                                    messageRow(row.item)
                                        .onAppear {
                                            if row.index == messageRows.count - 1,
                                               !meStore.messageLastPage,
                                               !meStore.isLoading(.meMessageList)
                                            {
                                                triggerLoadMoreIfNeeded()
                                            }
                                        }
                                    Divider()
                                }

                                if meStore.isLoading(.meMessageList) {
                                    ProgressView()
                                        .padding(.vertical, 12)
                                } else if meStore.messageLastPage {
                                    Text("No more data")
                                        .font(.system(size: 12))
                                        .foregroundStyle(ThemeTokens.tertiary)
                                        .padding(.vertical, 12)
                                }
                            }
                            .padding(.horizontal, widthClass.horizontalPadding)
                            .padding(.top, 8)
                        }
                    }
                }
            }
            .navigationTitle("Messages")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Mark all as read") {
                        Task { await meStore.markAllMessagesRead() }
                    }
                    .font(.system(size: 14))
                    .accessibilityIdentifier(A11yID.Me.messageAllReadButton)
                }
            }
            .task {
                paginationGate.reset()
                await meStore.loadMessages(page: 1, append: false)
            }
            .onDisappear {
                loadMoreTask?.cancel()
                loadMoreTask = nil
                paginationGate.reset()
            }
        }
    }

    private var messageRows: [MessageRow] {
        let seeds = meStore.messageList.map { item in
            StableRowID.make(
                item.id.map(String.init),
                item.createdAt.map(String.init),
                item.title,
                fallback: "message-row"
            )
        }
        let ids = StableRowID.uniqued(seeds)
        return Array(zip(meStore.messageList, ids).enumerated()).map { index, pair in
            MessageRow(id: pair.1, index: index, item: pair.0)
        }
    }

    private func triggerLoadMoreIfNeeded() {
        guard !meStore.messageLastPage else { return }
        guard !meStore.isLoading(.meMessageList) else { return }
        let nextPage = max(1, meStore.messagePage + 1)
        let token = "message.page.\(nextPage)"
        guard paginationGate.begin(token: token) else { return }
        guard loadMoreTask == nil else {
            paginationGate.end(token: token)
            return
        }
        loadMoreTask = Task { @MainActor in
            defer {
                paginationGate.end(token: token)
                loadMoreTask = nil
            }
            await meStore.loadMessages(page: nextPage, append: true)
        }
    }

    private func messageRow(_ item: MessageItem) -> some View {
        Button {
            if let id = item.id {
                Task { await meStore.markMessageRead(id: String(id)) }
            }
        } label: {
            HStack(alignment: .top, spacing: 10) {
                Circle()
                    .fill((item.isRead ?? false) ? ThemeTokens.divider : ThemeTokens.cpPrimary)
                    .frame(width: 8, height: 8)
                    .padding(.top, 6)

                VStack(alignment: .leading, spacing: 6) {
                    Text(item.title ?? titleByType(item.type))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(ThemeTokens.title)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(item.content ?? "")
                        .font(.system(size: 13))
                        .foregroundStyle(ThemeTokens.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .lineLimit(2)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(ThemeTokens.tertiary)
                    .padding(.top, 4)
            }
            .frame(minHeight: 58)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func titleByType(_ value: String?) -> String {
        switch value {
        case "RE_ALLOCATE":
            return "Multisig Reassignment Notification"
        case "OWNER_REMOVED":
            return "Multisig Member Change Notification"
        default:
            return "System Messages"
        }
    }
}

private struct MessageRow: Identifiable {
    let id: String
    let index: Int
    let item: MessageItem
}
