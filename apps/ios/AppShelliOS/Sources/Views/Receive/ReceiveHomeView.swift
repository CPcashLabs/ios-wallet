import BackendAPI
import SwiftUI
import UIKit

struct ReceiveHomeView: View {
    @ObservedObject var state: AppState
    let onNavigate: (ReceiveRoute) -> Void

    @Environment(\.colorScheme) private var colorScheme
    @State private var optionMenuVisible = false
    @State private var normalShareSheetVisible = false
    @State private var normalShareImage: UIImage?
    @State private var normalShareBusy = false
    @State private var expandedDrawer: ReceiveTabMode = .individuals

    var body: some View {
        AdaptiveReader { widthClass in
            FullscreenScaffold(backgroundStyle: .globalImage) {
                ZStack(alignment: .top) {
                    Rectangle()
                        .fill(receiveTopColor)
                        .frame(height: 300)
                        .ignoresSafeArea(edges: .top)

                    ScrollView {
                        VStack(spacing: 12) {
                            cardSection(widthClass: widthClass)
                        }
                        .padding(.horizontal, widthClass.horizontalPadding)
                        .padding(.top, 12)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("Receive")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        optionMenuVisible = true
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(ThemeTokens.title)
                            .frame(minWidth: 44, minHeight: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.pressFeedback)
                }
            }
            .confirmationDialog("更多操作", isPresented: $optionMenuVisible, titleVisibility: .visible) {
                if !state.receiveDomainState.selectedIsNormalChannel {
                    Button("地址有效期设置") {
                        onNavigate(.expiry)
                    }
                    if let orderSN = state.receiveDomainState.individualOrderSN, !orderSN.isEmpty {
                        Button("编辑个人收款地址") {
                            state.setReceiveActiveTab(.individuals)
                            expandedDrawer = .individuals
                            onNavigate(.editAddress(orderSN: orderSN))
                        }
                        Button("个人收款记录") {
                            state.setReceiveActiveTab(.individuals)
                            expandedDrawer = .individuals
                            onNavigate(.txLogs(orderSN: orderSN))
                        }
                    }
                    if let orderSN = state.receiveDomainState.businessOrderSN, !orderSN.isEmpty {
                        Button("编辑经营收款地址") {
                            state.setReceiveActiveTab(.business)
                            expandedDrawer = .business
                            onNavigate(.editAddress(orderSN: orderSN))
                        }
                        Button("经营收款记录") {
                            state.setReceiveActiveTab(.business)
                            expandedDrawer = .business
                            onNavigate(.txLogs(orderSN: orderSN))
                        }
                    }
                    Button("有效地址") {
                        onNavigate(.addressList(validity: .valid))
                    }
                    Button("无效地址") {
                        onNavigate(.invalidAddress)
                    }
                    Button("删除地址") {
                        onNavigate(.deleteAddress)
                    }
                }
                Button("FAQ") {
                    onNavigate(.faq)
                }
            }
            .task {
                if state.receiveSelectedNetworkId == nil {
                    await state.loadReceiveSelectNetwork()
                }
                syncExpandedDrawer()
                await state.loadReceiveHome()
                syncExpandedDrawer()
            }
            .onChange(of: state.receiveDomainState.activeTab) { _, newValue in
                expandedDrawer = newValue
            }
            .refreshable {
                await state.loadReceiveHome()
            }
            .sheet(isPresented: $normalShareSheetVisible) {
                ActivityShareSheet(activityItems: normalShareItems)
            }
        }
    }

    private var receiveTopColor: Color {
        let base = Color(hex: state.receiveDomainState.selectedChainColor, fallback: ThemeTokens.cpGold)
        if colorScheme == .dark {
            return base.opacity(0.76)
        }
        return base.opacity(0.92)
    }

    private func cardSection(widthClass: DeviceWidthClass) -> some View {
        VStack(spacing: 10) {
            if state.receiveDomainState.isPolling {
                HStack(spacing: 8) {
                    ProgressView()
                    Text("地址生成中...")
                        .font(.system(size: widthClass.footnoteSize, weight: .medium))
                        .foregroundStyle(ThemeTokens.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }

            if state.receiveDomainState.selectedIsNormalChannel {
                normalReceiveCard(widthClass: widthClass)
            } else {
                VStack(spacing: 12) {
                    drawerSection(
                        title: "For individuals",
                        icon: "person.2",
                        mode: .individuals,
                        widthClass: widthClass
                    ) {
                        ReceiveCardView(
                            order: state.individualTraceOrder,
                            traceDetail: state.individualTraceDetail,
                            payChain: state.receiveDomainState.selectedPayChain,
                            sendCoinName: state.receiveDomainState.selectedSendCoinName,
                            minAmount: state.receiveDomainState.receiveMinAmount,
                            maxAmount: state.receiveDomainState.receiveMaxAmount,
                            qrSide: receiveCardQRSide(widthClass),
                            onGenerate: {
                                state.setReceiveActiveTab(.individuals)
                                expandedDrawer = .individuals
                                Task { await state.createShortTraceOrder() }
                            },
                            onShare: {
                                if let orderSN = state.receiveDomainState.individualOrderSN {
                                    state.setReceiveActiveTab(.individuals)
                                    expandedDrawer = .individuals
                                    onNavigate(.share(orderSN: orderSN))
                                }
                            },
                            onTxLogs: {
                                if let orderSN = state.receiveDomainState.individualOrderSN {
                                    state.setReceiveActiveTab(.individuals)
                                    expandedDrawer = .individuals
                                    onNavigate(.txLogs(orderSN: orderSN))
                                }
                            },
                            onCopyAddress: {
                                state.showInfoToast("地址已复制")
                            }
                        )
                    }

                    drawerSection(
                        title: "For Business",
                        icon: "storefront",
                        mode: .business,
                        widthClass: widthClass
                    ) {
                        if state.businessTraceOrder == nil {
                            ReceiveBusinessStartView {
                                state.setReceiveActiveTab(.business)
                                expandedDrawer = .business
                                Task { await state.createLongTraceOrder() }
                            }
                        } else {
                            ReceiveCardView(
                                order: state.businessTraceOrder,
                                traceDetail: state.businessTraceDetail,
                                payChain: state.receiveDomainState.selectedPayChain,
                                sendCoinName: state.receiveDomainState.selectedSendCoinName,
                                minAmount: state.receiveDomainState.receiveMinAmount,
                                maxAmount: state.receiveDomainState.receiveMaxAmount,
                                qrSide: receiveCardQRSide(widthClass),
                                onGenerate: {
                                    state.setReceiveActiveTab(.business)
                                    expandedDrawer = .business
                                    Task { await state.createLongTraceOrder() }
                                },
                                onShare: {
                                    if let orderSN = state.receiveDomainState.businessOrderSN {
                                        state.setReceiveActiveTab(.business)
                                        expandedDrawer = .business
                                        onNavigate(.share(orderSN: orderSN))
                                    }
                                },
                                onTxLogs: {
                                    if let orderSN = state.receiveDomainState.businessOrderSN {
                                        state.setReceiveActiveTab(.business)
                                        expandedDrawer = .business
                                        onNavigate(.txLogs(orderSN: orderSN))
                                    }
                                },
                                onCopyAddress: {
                                    state.showInfoToast("地址已复制")
                                }
                            )
                        }
                    }
                }
            }
        }
    }

    private func drawerSection<Content: View>(
        title: String,
        icon: String,
        mode: ReceiveTabMode,
        widthClass: DeviceWidthClass,
        @ViewBuilder content: () -> Content
    ) -> some View {
        let expanded = expandedDrawer == mode
        return VStack(spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.92)) {
                    expandedDrawer = mode
                }
                state.setReceiveActiveTab(mode)
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .regular))
                        .foregroundStyle(ThemeTokens.title)
                        .frame(width: 36, height: 36)
                    Text(title)
                        .font(.system(size: widthClass.titleSize + 3, weight: .medium))
                        .foregroundStyle(ThemeTokens.title)
                    Spacer()
                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(ThemeTokens.tertiary)
                }
                .frame(maxWidth: .infinity, minHeight: 70, alignment: .leading)
                .padding(.horizontal, 16)
                .contentShape(Rectangle())
            }
            .buttonStyle(.pressFeedback)

            if expanded {
                Divider()
                    .padding(.horizontal, 16)

                VStack(spacing: 12) {
                    content()
                }
                .padding(14)
            }
        }
        .background(ThemeTokens.elevatedCard, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.black.opacity(colorScheme == .dark ? 0.24 : 0.06), lineWidth: 1)
        )
    }

    private func normalReceiveCard(widthClass: DeviceWidthClass) -> some View {
        VStack(spacing: 12) {
            QRCodeView(value: state.activeAddress, side: receiveCardQRSide(widthClass))
                .padding(8)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.black.opacity(0.12), lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 6) {
                Text("Address")
                    .font(.system(size: 14))
                    .foregroundStyle(ThemeTokens.secondary)
                Text(shortAddress(state.activeAddress))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(ThemeTokens.title)
                    .lineLimit(2)
                    .truncationMode(.middle)
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(ThemeTokens.softSurface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            HStack(spacing: 10) {
                Button("分享") {
                    shareNormalQRCodeCard(widthClass: widthClass)
                }
                .frame(maxWidth: .infinity, minHeight: 48)
                .foregroundStyle(ThemeTokens.cpPrimary)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(ThemeTokens.cpPrimary.opacity(0.38), lineWidth: 1)
                )
                .buttonStyle(.pressFeedback)
                .contentShape(Rectangle())
                .disabled(normalShareBusy)

                Button("复制") {
                    UIPasteboard.general.string = state.activeAddress
                    state.showInfoToast("地址已复制")
                }
                .frame(maxWidth: .infinity)
                .frame(minHeight: 48)
                .foregroundStyle(ThemeTokens.cpPrimary)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(ThemeTokens.cpPrimary.opacity(0.38), lineWidth: 1)
                )
                .buttonStyle(.pressFeedback)
                .contentShape(Rectangle())
            }
        }
        .padding(16)
        .background(ThemeTokens.cardBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    @MainActor
    private func shareNormalQRCodeCard(widthClass: DeviceWidthClass) {
        guard !normalShareBusy else { return }
        normalShareBusy = true
        defer { normalShareBusy = false }

        let capture = normalShareCaptureCard(widthClass: widthClass)
            .frame(width: 340, height: 620)

        guard let image = ViewImageRenderer.render(capture, size: CGSize(width: 340, height: 620)) else {
            state.showInfoToast("分享图片生成失败")
            return
        }

        normalShareImage = image
        normalShareSheetVisible = true
    }

    private func normalShareCaptureCard(widthClass: DeviceWidthClass) -> some View {
        ReceiveShareCardTemplate(
            model: ShareCardRenderModel(
                chainName: state.receiveDomainState.selectedPayChain,
                address: shareAddress,
                chainColorHex: state.receiveDomainState.selectedChainColor,
                title: "Receive",
                subtitle: "Only supports \(state.receiveDomainState.selectedPayChain) network assets",
                modeTitle: "For individuals",
                minimumDepositText: minimumDepositText
            ),
            qrSide: min(190, receiveCardQRSide(widthClass) + 8)
        )
    }

    private func syncExpandedDrawer() {
        if state.receiveDomainState.activeTab == .business {
            expandedDrawer = .business
            return
        }
        if state.businessTraceOrder != nil, state.individualTraceOrder == nil {
            expandedDrawer = .business
            return
        }
        expandedDrawer = .individuals
    }

    private func shortAddress(_ value: String) -> String {
        AddressFormatter.shortened(value, leading: 8, trailing: 6, threshold: 14)
    }

    private func receiveCardQRSide(_ widthClass: DeviceWidthClass) -> CGFloat {
        let availableWidth = widthClass.metrics.maxContentWidth - (widthClass.horizontalPadding * 2) - 32
        let candidate = availableWidth * 0.52
        return min(max(candidate, 152), 196)
    }

    private var normalShareItems: [Any] {
        if let normalShareImage {
            return [normalShareImage]
        }
        return []
    }

    private var shareAddress: String {
        let trimmed = state.activeAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty || trimmed == "-" {
            return "0x0000000000000000000000000000000000000000"
        }
        return trimmed
    }

    private var minimumDepositText: String {
        let value = state.receiveDomainState.receiveMinAmount
        if value > 0 {
            let formatted = value.rounded() == value ? String(format: "%.0f", value) : String(format: "%.2f", value)
            return "\(formatted) \(state.receiveDomainState.selectedSendCoinName)"
        }
        return "-- \(state.receiveDomainState.selectedSendCoinName)"
    }
}

#Preview("ReceiveHomeView") {
    NavigationStack {
        ReceiveHomeView(state: AppState()) { _ in }
    }
}
