import BackendAPI
import SwiftUI

struct AddressBookListView: View {
    @ObservedObject var meStore: MeStore
    let navigate: (MeRoute) -> Void

    var body: some View {
        AdaptiveReader { widthClass in
            SafeAreaScreen(backgroundStyle: .globalImage) {
                Group {
                    if meStore.isLoading(.meAddressbookList) {
                        ProgressView("加载地址簿...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if meStore.addressBooks.isEmpty {
                        EmptyStateView(asset: "bill_no_data", title: "还未添加任何地址簿")
                            .padding(.horizontal, widthClass.horizontalPadding)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 10) {
                                ForEach(addressBookRows) { row in
                                    let item = row.item
                                    Button {
                                        navigate(.addressBookEdit(id: item.id.map(String.init)))
                                    } label: {
                                        HStack(spacing: 10) {
                                            Image(item.chainType == "TRON" ? "chain_tron" : "chain_evm")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 32, height: 32)
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(item.name ?? "-")
                                                    .font(.system(size: widthClass.bodySize + 1, weight: .semibold))
                                                    .foregroundStyle(ThemeTokens.title)
                                                Text(item.walletAddress ?? "-")
                                                    .font(.system(size: widthClass.footnoteSize))
                                                    .foregroundStyle(ThemeTokens.secondary)
                                                    .lineLimit(1)
                                                    .truncationMode(.middle)
                                            }
                                            Spacer()
                                            Image(systemName: "chevron.right")
                                                .font(.system(size: 11, weight: .semibold))
                                                .foregroundStyle(ThemeTokens.tertiary)
                                        }
                                        .frame(minHeight: widthClass.metrics.listRowMinHeight + 6)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(ThemeTokens.cardBackground, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    }
                                    .buttonStyle(.pressFeedback)
                                    .accessibilityIdentifier(A11yID.Me.addressBookRowPrefix + (item.id.map(String.init) ?? "unknown"))
                                }
                            }
                            .padding(.horizontal, widthClass.horizontalPadding)
                            .padding(.vertical, 12)
                        }
                    }
                }
            }
            .navigationTitle("地址簿")
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                Button {
                    navigate(.addressBookEdit(id: nil))
                } label: {
                    Text("添加地址")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(ThemeTokens.cpPrimary)
                        .frame(maxWidth: .infinity, minHeight: widthClass.metrics.buttonHeight)
                        .overlay(Capsule().stroke(ThemeTokens.cpPrimary, lineWidth: 1))
                        .padding(.horizontal, widthClass.horizontalPadding)
                        .padding(.top, 8)
                        .padding(.bottom, 6)
                        .background(ThemeTokens.groupBackground)
                }
                .buttonStyle(.pressFeedback)
                .accessibilityIdentifier(A11yID.Me.addressBookAddButton)
            }
            .task {
                await meStore.loadAddressBooks()
            }
        }
    }

    private var addressBookRows: [AddressBookRow] {
        let seeds = meStore.addressBooks.map { item in
            StableRowID.make(
                item.id.map(String.init),
                item.walletAddress,
                item.name,
                fallback: "address-book-row"
            )
        }
        let ids = StableRowID.uniqued(seeds)
        return Array(zip(meStore.addressBooks, ids)).map { pair in
            AddressBookRow(id: pair.1, item: pair.0)
        }
    }
}

private struct AddressBookRow: Identifiable {
    let id: String
    let item: AddressBookItem
}
