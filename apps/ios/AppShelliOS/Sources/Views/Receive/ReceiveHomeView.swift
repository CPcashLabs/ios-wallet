import BackendAPI
import SwiftUI
import UIKit

struct ReceiveHomeView: View {
    @ObservedObject var receiveStore: ReceiveStore
    @ObservedObject var uiStore: UIStore
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
                if !receiveStore.receiveDomainState.selectedIsNormalChannel {
                    Button("地址有效期设置") {
                        onNavigate(.expiry)
                    }
                    if let orderSN = receiveStore.receiveDomainState.individualOrderSN, !orderSN.isEmpty {
                        Button("编辑个人收款地址") {
                            receiveStore.setReceiveActiveTab(.individuals)
                            expandedDrawer = .individuals
                            onNavigate(.editAddress(orderSN: orderSN))
                        }
                        Button("个人收款记录") {
                            receiveStore.setReceiveActiveTab(.individuals)
                            expandedDrawer = .individuals
                            onNavigate(.txLogs(orderSN: orderSN))
                        }
                    }
                    if let orderSN = receiveStore.receiveDomainState.businessOrderSN, !orderSN.isEmpty {
                        Button("编辑经营收款地址") {
                            receiveStore.setReceiveActiveTab(.business)
                            expandedDrawer = .business
                            onNavigate(.editAddress(orderSN: orderSN))
                        }
                        Button("经营收款记录") {
                            receiveStore.setReceiveActiveTab(.business)
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
                if receiveStore.receiveSelectedNetworkId == nil {
                    await receiveStore.loadReceiveSelectNetwork()
                }
                syncExpandedDrawer()
                await receiveStore.loadReceiveHome()
                syncExpandedDrawer()
            }
            .onChange(of: receiveStore.receiveDomainState.activeTab) { _, newValue in
                expandedDrawer = newValue
            }
            .refreshable {
                await receiveStore.loadReceiveHome()
            }
            .sheet(isPresented: $normalShareSheetVisible) {
                ActivityShareSheet(activityItems: normalShareItems)
            }
        }
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(.hidden, for: .navigationBar)
        .modifier(iOS26TransparentNavBarModifier())
        .background(TransparentNavigationBar())
    }

    /// iOS 26+ Liquid Glass navigation bar fix
    private struct iOS26TransparentNavBarModifier: ViewModifier {
        func body(content: Content) -> some View {
            if #available(iOS 26, *) {
                content
                    .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
            } else {
                content
            }
        }
    }

    // Helper to force transparent navigation bar via UIKit
    private struct TransparentNavigationBar: UIViewControllerRepresentable {
        func makeUIViewController(context: Context) -> UIViewController {
            return TransparentNavigationController()
        }

        func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}

        class TransparentNavigationController: UIViewController {
            override func viewDidLoad() {
                super.viewDidLoad()
                applyTransparentAppearance()
            }

            override func viewWillAppear(_ animated: Bool) {
                super.viewWillAppear(animated)
                applyTransparentAppearance()
            }
            
            override func didMove(toParent parent: UIViewController?) {
                super.didMove(toParent: parent)
                applyTransparentAppearance()
            }
            
            private func applyTransparentAppearance() {
                let appearance = UINavigationBarAppearance()
                appearance.configureWithTransparentBackground()
                appearance.backgroundColor = .clear
                appearance.shadowColor = .clear
                
                // Traverse up to find the hosting controller(s) and apply appearance
                var candidate: UIViewController? = self.parent
                while let current = candidate {
                    current.navigationItem.standardAppearance = appearance
                    current.navigationItem.scrollEdgeAppearance = appearance
                    current.navigationItem.compactAppearance = appearance
                    current.navigationItem.scrollEdgeAppearance = appearance

                    // iOS 26+: Suppress Liquid Glass effect on navigation bar
                    if #available(iOS 26, *) {
                        if let navBar = current.navigationController?.navigationBar {
                            navBar.isTranslucent = true
                            navBar.setBackgroundImage(UIImage(), for: .default)
                            navBar.shadowImage = UIImage()
                        }
                    }
                    
                    // Also try to help the transition coordinator if active
                    if let coordinator = current.transitionCoordinator {
                        coordinator.animate(alongsideTransition: { _ in
                            current.navigationController?.navigationBar.setNeedsLayout()
                        }, completion: nil)
                    }
                    
                    candidate = current.parent
                }
            }
        }
    }

    private var receiveTopColor: Color {
        let hex = receiveStore.receiveDomainState.selectedChainColor
        if hex.isEmpty {
            return Color.clear
        }
        let base = Color(hex: hex, fallback: ThemeTokens.cpGold)
        if colorScheme == .dark {
            return base.opacity(0.76)
        }
        return base.opacity(0.92)
    }

    private func cardSection(widthClass: DeviceWidthClass) -> some View {
        VStack(spacing: 10) {
            if receiveStore.receiveDomainState.isPolling {
                HStack(spacing: 8) {
                    ProgressView()
                    Text("地址生成中...")
                        .font(.system(size: widthClass.footnoteSize, weight: .medium))
                        .foregroundStyle(ThemeTokens.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }

            if receiveStore.receiveDomainState.selectedIsNormalChannel {
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
                            order: receiveStore.individualTraceOrder,
                            traceDetail: receiveStore.individualTraceDetail,
                            payChain: receiveStore.receiveDomainState.selectedPayChain,
                            sendCoinName: receiveStore.receiveDomainState.selectedSendCoinName,
                            minAmount: receiveStore.receiveDomainState.receiveMinAmount,
                            maxAmount: receiveStore.receiveDomainState.receiveMaxAmount,
                            qrSide: receiveCardQRSide(widthClass),
                            isPolling: receiveStore.receiveDomainState.isPolling,
                            onGenerate: {
                                receiveStore.setReceiveActiveTab(.individuals)
                                expandedDrawer = .individuals
                                Task { await receiveStore.createShortTraceOrder() }
                            },
                            onShare: {
                                if let orderSN = receiveStore.receiveDomainState.individualOrderSN {
                                    receiveStore.setReceiveActiveTab(.individuals)
                                    expandedDrawer = .individuals
                                    onNavigate(.share(orderSN: orderSN))
                                }
                            },
                            onTxLogs: {
                                if let orderSN = receiveStore.receiveDomainState.individualOrderSN {
                                    receiveStore.setReceiveActiveTab(.individuals)
                                    expandedDrawer = .individuals
                                    onNavigate(.txLogs(orderSN: orderSN))
                                }
                            },
                            onCopyAddress: {
                                uiStore.showInfoToast("地址已复制")
                            },
                            addressTapA11yID: A11yID.Receive.cardAddressTapIndividuals,
                            onAddressTap: {
                                receiveStore.setReceiveActiveTab(.individuals)
                                expandedDrawer = .individuals
                                onNavigate(.addAddress)
                            }
                        )
                    }

                    drawerSection(
                        title: "For Business",
                        icon: "storefront",
                        mode: .business,
                        widthClass: widthClass
                    ) {
                        if receiveStore.businessTraceOrder == nil {
                            ReceiveBusinessStartView {
                                receiveStore.setReceiveActiveTab(.business)
                                expandedDrawer = .business
                                Task { await receiveStore.createLongTraceOrder() }
                            }
                        } else {
                            ReceiveCardView(
                                order: receiveStore.businessTraceOrder,
                                traceDetail: receiveStore.businessTraceDetail,
                                payChain: receiveStore.receiveDomainState.selectedPayChain,
                                sendCoinName: receiveStore.receiveDomainState.selectedSendCoinName,
                                minAmount: receiveStore.receiveDomainState.receiveMinAmount,
                                maxAmount: receiveStore.receiveDomainState.receiveMaxAmount,
                                qrSide: receiveCardQRSide(widthClass),
                                isPolling: receiveStore.receiveDomainState.isPolling,
                                onGenerate: {
                                    receiveStore.setReceiveActiveTab(.business)
                                    expandedDrawer = .business
                                    Task { await receiveStore.createLongTraceOrder() }
                                },
                                onShare: {
                                    if let orderSN = receiveStore.receiveDomainState.businessOrderSN {
                                        receiveStore.setReceiveActiveTab(.business)
                                        expandedDrawer = .business
                                        onNavigate(.share(orderSN: orderSN))
                                    }
                                },
                                onTxLogs: {
                                    if let orderSN = receiveStore.receiveDomainState.businessOrderSN {
                                        receiveStore.setReceiveActiveTab(.business)
                                        expandedDrawer = .business
                                        onNavigate(.txLogs(orderSN: orderSN))
                                    }
                                },
                                onCopyAddress: {
                                    uiStore.showInfoToast("地址已复制")
                                },
                                addressTapA11yID: A11yID.Receive.cardAddressTapBusiness,
                                onAddressTap: {
                                    receiveStore.setReceiveActiveTab(.business)
                                    expandedDrawer = .business
                                    onNavigate(.addAddress)
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
                receiveStore.setReceiveActiveTab(mode)
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
            .accessibilityIdentifier(mode == .individuals ? A11yID.Receive.drawerIndividuals : A11yID.Receive.drawerBusiness)

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
            QRCodeView(value: receiveStore.activeAddress, side: receiveCardQRSide(widthClass))
                .padding(8)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.black.opacity(0.12), lineWidth: 1)
                )

            Button {
                onNavigate(.addAddress)
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Address")
                            .font(.system(size: 14))
                            .foregroundStyle(ThemeTokens.secondary)
                        Text(shortAddress(receiveStore.activeAddress))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(ThemeTokens.title)
                            .lineLimit(2)
                            .truncationMode(.middle)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(ThemeTokens.tertiary)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(ThemeTokens.softSurface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier(A11yID.Receive.cardAddressTap)

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
                    UIPasteboard.general.string = receiveStore.activeAddress
                    uiStore.showInfoToast("地址已复制")
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
            uiStore.showInfoToast("分享图片生成失败")
            return
        }

        normalShareImage = image
        normalShareSheetVisible = true
    }

    private func normalShareCaptureCard(widthClass: DeviceWidthClass) -> some View {
        ReceiveShareCardTemplate(
            model: ShareCardRenderModel(
                chainName: receiveStore.receiveDomainState.selectedPayChain,
                address: shareAddress,
                chainColorHex: receiveStore.receiveDomainState.selectedChainColor,
                title: "Receive",
                subtitle: "Only supports \(receiveStore.receiveDomainState.selectedPayChain) network assets",
                modeTitle: "For individuals",
                minimumDepositText: minimumDepositText
            ),
            qrSide: min(190, receiveCardQRSide(widthClass) + 8)
        )
    }

    private func syncExpandedDrawer() {
        if receiveStore.receiveDomainState.activeTab == .business {
            expandedDrawer = .business
            return
        }
        if receiveStore.businessTraceOrder != nil, receiveStore.individualTraceOrder == nil {
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
        let trimmed = receiveStore.activeAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty || trimmed == "-" {
            return "0x0000000000000000000000000000000000000000"
        }
        return trimmed
    }

    private var minimumDepositText: String {
        let value = receiveStore.receiveDomainState.receiveMinAmount
        if value > 0 {
            let formatted = value.rounded() == value ? String(format: "%.0f", value) : String(format: "%.2f", value)
            return "\(formatted) \(receiveStore.receiveDomainState.selectedSendCoinName)"
        }
        return "-- \(receiveStore.receiveDomainState.selectedSendCoinName)"
    }
}

#Preview("ReceiveHomeView") {
    let appState = AppState()
    NavigationStack {
        ReceiveHomeView(receiveStore: ReceiveStore(appState: appState), uiStore: UIStore(appState: appState)) { _ in }
    }
}
