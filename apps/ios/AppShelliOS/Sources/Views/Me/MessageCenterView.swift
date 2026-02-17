import SwiftUI
import BackendAPI

struct MessageCenterView: View {
    @ObservedObject var state: AppState

    var body: some View {
        AdaptiveReader { widthClass in
            SafeAreaScreen(backgroundStyle: .globalImage) {
                Group {
                    if state.isLoading(.meMessageList) && state.messageList.isEmpty {
                        ProgressView("正在加载消息...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if state.messageList.isEmpty {
                        EmptyStateView(asset: "message_no_data", title: "暂无消息")
                            .padding(.horizontal, widthClass.horizontalPadding)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 0) {
                                ForEach(messageRows) { row in
                                    messageRow(row.item)
                                        .onAppear {
                                            if row.index == messageRows.count - 1,
                                               !state.messageLastPage,
                                               !state.isLoading(.meMessageList)
                                            {
                                                Task {
                                                    await state.loadMessages(page: state.messagePage + 1, append: true)
                                                }
                                            }
                                        }
                                    Divider()
                                }

                                if state.isLoading(.meMessageList) {
                                    ProgressView()
                                        .padding(.vertical, 12)
                                } else if state.messageLastPage {
                                    Text("无更多数据")
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
            .navigationTitle("消息")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("全部已读") {
                        Task { await state.markAllMessagesRead() }
                    }
                    .font(.system(size: 14))
                }
            }
            .task {
                await state.loadMessages(page: 1, append: false)
            }
        }
    }

    private var messageRows: [MessageRow] {
        Array(state.messageList.enumerated()).map { index, item in
            let id = item.id.map(String.init) ?? "\(item.createdAt ?? 0)"
            return MessageRow(id: "\(id)-\(index)", index: index, item: item)
        }
    }

    private func messageRow(_ item: MessageItem) -> some View {
        Button {
            if let id = item.id {
                Task { await state.markMessageRead(id: String(id)) }
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
            return "多签重分配通知"
        case "OWNER_REMOVED":
            return "多签成员变更通知"
        default:
            return "系统消息"
        }
    }
}

private struct MessageRow: Identifiable {
    let id: String
    let index: Int
    let item: MessageItem
}
