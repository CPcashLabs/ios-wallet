import SwiftUI

struct ReceiveSelectNetworkView: View {
    @ObservedObject var state: AppState
    let onSelect: () -> Void
    @State private var selectingNetworkID: String?

    var body: some View {
        AdaptiveReader { widthClass in
            FullscreenScaffold(backgroundStyle: .globalImage) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        tipsCard(widthClass: widthClass)

                        sectionHeader(
                            title: "In-App Channel (Free)",
                            infoMessage: "Suitable for in-platform transfers with low friction and zero fee"
                        )
                        if state.isLoading(.receiveSelectNetwork), state.receiveNormalNetworks.isEmpty {
                            ProgressView()
                                .frame(maxWidth: .infinity, minHeight: 60)
                        } else {
                            VStack(spacing: 0) {
                                ForEach(state.receiveNormalNetworks) { item in
                                    networkRow(item, widthClass: widthClass)
                                }
                            }
                        }

                        sectionHeader(
                            title: "Proxy Settlement",
                            infoMessage: "Suitable for cross-network settlement routed by CPcash"
                        )
                        if state.isLoading(.receiveSelectNetwork), state.receiveProxyNetworks.isEmpty {
                            ProgressView()
                                .frame(maxWidth: .infinity, minHeight: 90)
                        } else if state.receiveProxyNetworks.isEmpty {
                            Text("No networks available")
                                .font(.system(size: widthClass.bodySize))
                                .foregroundStyle(ThemeTokens.secondary)
                                .padding(.top, 8)
                        } else {
                            VStack(spacing: 0) {
                                ForEach(state.receiveProxyNetworks) { item in
                                    networkRow(item, widthClass: widthClass)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, widthClass.horizontalPadding)
                    .padding(.top, 14)
                    .padding(.bottom, 24)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle("Select Network")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await state.loadReceiveSelectNetwork()
            }
            .refreshable {
                await state.loadReceiveSelectNetwork()
            }
        }
    }

    private func tipsCard(widthClass: DeviceWidthClass) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "info.circle")
                    .font(.system(size: 22))
                    .foregroundStyle(ThemeTokens.title)
                Text("TIPS")
                    .font(.system(size: widthClass.bodySize + 1, weight: .medium))
                    .foregroundStyle(ThemeTokens.title)
            }
            Text("To avoid asset loss, please make sure the selected network matches the recipient's or sender's platform")
                .font(.system(size: widthClass.bodySize + 2))
                .lineSpacing(2)
                .foregroundStyle(ThemeTokens.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ThemeTokens.cardBackground, in: RoundedRectangle(cornerRadius: widthClass.metrics.cardCornerRadius, style: .continuous))
    }

    private func sectionHeader(title: String, infoMessage: String) -> some View {
        Button {
            state.showInfoToast(infoMessage)
        } label: {
            HStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 18))
                    .foregroundStyle(ThemeTokens.secondary)
                Image(systemName: "info.circle")
                    .font(.system(size: 16))
                    .foregroundStyle(ThemeTokens.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.pressFeedback)
        .padding(.top, 4)
    }

    private func networkRow(_ item: ReceiveNetworkItem, widthClass: DeviceWidthClass) -> some View {
        let selected = state.receiveSelectedNetworkId == item.id
        let disabled = selectingNetworkID == item.id
        return Button {
            guard selectingNetworkID == nil else { return }
            selectingNetworkID = item.id
            Haptics.lightImpact()
            Task {
                await state.selectReceiveNetwork(item: item, preloadHome: false)
            }
            onSelect()
            Task {
                try? await Task.sleep(nanoseconds: 600_000_000)
                selectingNetworkID = nil
            }
        } label: {
            HStack(spacing: 14) {
                networkIcon(item)
                    .frame(width: 44, height: 44)
                Text(item.name)
                    .font(.system(size: widthClass.titleSize + 3, weight: .medium))
                    .foregroundStyle(ThemeTokens.title)
                Spacer()
                if selected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(ThemeTokens.cpPrimary)
                }
            }
            .frame(maxWidth: .infinity, minHeight: max(64, widthClass.metrics.listRowMinHeight + 10), alignment: .leading)
            .padding(.horizontal, 2)
            .opacity(disabled ? 0.6 : 1)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(selected ? ThemeTokens.cpPrimary.opacity(0.06) : .clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.pressFeedback)
        .disabled(disabled)
    }

    private func networkIcon(_ item: ReceiveNetworkItem) -> some View {
        NetworkLogoView(
            networkName: item.name,
            logoURL: item.logoURL,
            baseURL: state.environment.baseURL,
            isNormalChannel: item.isNormalChannel
        )
    }
}
