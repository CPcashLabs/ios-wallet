import BackendAPI
import SwiftUI

enum HomeShortcut: CaseIterable {
    case transfer
    case receive
    case statistics

    var title: String {
        switch self {
        case .transfer:
            return "Transfer"
        case .receive:
            return "Receive"
        case .statistics:
            return "Statistics"
        }
    }

    var imageName: String {
        switch self {
        case .transfer:
            return "home_send"
        case .receive:
            return "home_receive"
        case .statistics:
            return "home_bill"
        }
    }
}

struct HomeView: View {
    @ObservedObject var sessionStore: SessionStore
    @ObservedObject var homeStore: HomeStore
    let onShortcutTap: (HomeShortcut) -> Void
    let onBannerTap: () -> Void
    let onRecentMessageTap: () -> Void

    @AppStorage("wallet.showBalance") private var showBalance = true
    @AppStorage("home.latestMessageId") private var latestMessageId = ""
    @Environment(\.scenePhase) private var scenePhase
    @State private var selectedBanner = 0

    private let banners = ["home_banner_1", "home_banner_2", "home_banner_3"]

    var body: some View {
        AdaptiveReader { widthClass in
            TopSafeAreaHeaderScaffold(
                backgroundStyle: .globalImage,
                headerBackground: ThemeTokens.groupBackground.opacity(0.94)
            ) {
                topBrandHeader(widthClass: widthClass)
            } content: {
                ZStack(alignment: .top) {
                    LinearGradient(
                        colors: [ThemeTokens.homeTopGradient.opacity(0.72), Color.clear],
                        startPoint: .top,
                        endPoint: .center
                    )
                    .frame(height: 260)
                    .frame(maxWidth: .infinity)

                    ScrollView {
                        VStack(spacing: sectionSpacing(for: widthClass)) {
                            balanceCard(widthClass: widthClass)
                            quickEntryRow(widthClass: widthClass)
                            bannerSection(widthClass: widthClass)
                            recentMessageSection(widthClass: widthClass)
                        }
                        .padding(.horizontal, widthClass.horizontalPadding)
                        .padding(.top, 12)
                        .padding(.bottom, widthClass == .max ? 36 : 24)
                    }
                    .refreshable {
                        await refreshHomeData(withHaptic: true)
                    }
                    .task {
                        if homeStore.homeRecentMessages.isEmpty {
                            await refreshHomeData(withHaptic: false)
                        }
                    }
                }
            }
        }
        .onAppear {
            homeStore.startHeartbeat()
        }
        .onDisappear {
            homeStore.stopHeartbeat()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                homeStore.startHeartbeat()
            } else {
                homeStore.stopHeartbeat()
            }
        }
    }

    private func topBrandHeader(widthClass: DeviceWidthClass) -> some View {
        HStack {
            HStack(spacing: 8) {
                Image("home_logo_mark")
                    .resizable()
                    .scaledToFit()
                    .frame(width: widthClass == .max ? 24 : 20, height: widthClass == .max ? 24 : 20)
                Image("home_logo_text")
                    .resizable()
                    .scaledToFit()
                    .frame(height: widthClass == .max ? 22 : 20)
            }
            Spacer()
            HStack(spacing: 8) {
                Text("\(sessionStore.selectedChainName) · \(shortAddress(sessionStore.activeAddress))")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(ThemeTokens.secondary)
                    .lineLimit(1)
                Button {
                    Task { await refreshHomeData(withHaptic: true) }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(ThemeTokens.title)
                        .frame(width: 28, height: 28)
                        .background(ThemeTokens.cardBackground, in: Circle())
                }
                .buttonStyle(.pressFeedback)
            }
        }
    }

    private func refreshHomeData(withHaptic: Bool) async {
        await homeStore.refreshHomeData()
        guard withHaptic else { return }
        Haptics.lightImpact()
    }

    private func balanceCard(widthClass: DeviceWidthClass) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text("钱包余额")
                    .font(.system(size: widthClass.bodySize))
                    .foregroundStyle(Color.white.opacity(0.92))
                Button {
                    showBalance.toggle()
                } label: {
                    Image(systemName: showBalance ? "eye" : "eye.slash")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
            }

            Text(showBalance ? formattedTotalBalance : "*****")
                .font(.system(size: balanceAmountSize(for: widthClass), weight: .medium))
                .foregroundStyle(.white)
                .lineLimit(1)

            Text("单链单币：BTT + USDT")
                .font(.system(size: 12))
                .foregroundStyle(Color.white.opacity(0.84))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(ThemeTokens.cpPrimary, in: RoundedRectangle(cornerRadius: widthClass.metrics.cardCornerRadius))
    }

    private func quickEntryRow(widthClass: DeviceWidthClass) -> some View {
        HStack(spacing: 8) {
            ForEach(HomeShortcut.allCases, id: \.title) { shortcut in
                Button {
                    Haptics.lightImpact()
                    onShortcutTap(shortcut)
                } label: {
                    VStack(spacing: 8) {
                        Image(shortcut.imageName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: shortcutIconSize(for: widthClass), height: shortcutIconSize(for: widthClass))
                        Text(shortcut.title)
                            .font(.system(size: widthClass == .max ? 13 : 12))
                            .foregroundStyle(ThemeTokens.title)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, shortcutVerticalPadding(for: widthClass))
                }
                .buttonStyle(.pressFeedback)
                .accessibilityIdentifier(shortcutIdentifier(shortcut))
            }
        }
    }

    private func bannerSection(widthClass: DeviceWidthClass) -> some View {
        TabView(selection: $selectedBanner) {
            ForEach(Array(banners.indices), id: \.self) { index in
                bannerCard(asset: banners[index])
                    .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .automatic))
        .frame(height: bannerHeight(for: widthClass))
    }

    private func bannerCard(asset: String) -> some View {
        Button {
            Haptics.lightImpact()
            onBannerTap()
        } label: {
            Image(asset)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                .background(
                    Image("home_banner_fallback")
                        .resizable()
                        .scaledToFill()
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.pressFeedback)
    }

    private func recentMessageSection(widthClass: DeviceWidthClass) -> some View {
        Button {
            guard !homeStore.homeRecentMessages.isEmpty else { return }
            if let firstID = homeStore.homeRecentMessages.first?.id {
                latestMessageId = String(firstID)
            }
            Haptics.lightImpact()
            onRecentMessageTap()
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("最近消息")
                        .font(.system(size: 14))
                        .foregroundStyle(ThemeTokens.title)
                    Spacer()
                    if !homeStore.homeRecentMessages.isEmpty {
                        HStack(spacing: 6) {
                            if hasNewMessage {
                                Text("New")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(ThemeTokens.secondary)
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 8, height: 8)
                            }
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(ThemeTokens.tertiary)
                        }
                    }
                }

                if homeStore.homeRecentMessages.isEmpty {
                    VStack(spacing: 8) {
                        Image("home_no_data")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 96, height: 72)
                        Text("暂无数据")
                            .font(.system(size: 13))
                            .foregroundStyle(ThemeTokens.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: emptyMessageHeight(for: widthClass))
                } else {
                    VStack(spacing: 10) {
                        ForEach(recentMessageRows) { row in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(messageTitle(row.item))
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(ThemeTokens.title)
                                    .lineLimit(1)
                                Text(messageContent(row.item))
                                    .font(.system(size: 12))
                                    .foregroundStyle(ThemeTokens.secondary)
                                    .lineLimit(2)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            if row.index < recentMessageRows.count - 1 {
                                Divider()
                            }
                        }
                    }
                }
            }
            .frame(minHeight: recentSectionMinHeight(for: widthClass), alignment: .top)
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(ThemeTokens.cardBackground, in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.pressFeedback)
        .accessibilityIdentifier(A11yID.Home.recentMessageButton)
    }

    private var hasNewMessage: Bool {
        guard let first = homeStore.homeRecentMessages.first?.id else { return false }
        return String(first) != latestMessageId
    }

    private var recentMessageRows: [RecentMessageRow] {
        let seeds = homeStore.homeRecentMessages.map { item in
            StableRowID.make(
                item.id.map(String.init),
                item.createdAt.map(String.init),
                item.title,
                fallback: "home-message-row"
            )
        }
        let ids = StableRowID.uniqued(seeds)
        return Array(zip(homeStore.homeRecentMessages, ids).enumerated()).map { index, pair in
            RecentMessageRow(id: pair.1, index: index, item: pair.0)
        }
    }

    private var formattedTotalBalance: String {
        let total = homeStore.coins.reduce(0.0) { partial, coin in
            partial + coinBalance(coin)
        }
        return String(format: "$ %.2f", total)
    }

    private func coinBalance(_ coin: CoinItem) -> Double {
        if let value = coin.balance?.doubleValue {
            return value
        }
        if let text = coin.balance?.stringValue, let value = Double(text) {
            return value
        }
        return 0
    }

    private func messageTitle(_ item: MessageItem) -> String {
        let title = item.title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return title.isEmpty ? "消息通知" : title
    }

    private func messageContent(_ item: MessageItem) -> String {
        let content = item.content?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return content.isEmpty ? "-" : content
    }

    private func shortAddress(_ value: String) -> String {
        AddressFormatter.shortened(value, leading: 6, trailing: 4, threshold: 12)
    }

    private func sectionSpacing(for widthClass: DeviceWidthClass) -> CGFloat {
        switch widthClass {
        case .compact:
            return 14
        case .regular:
            return 16
        case .plus:
            return 18
        case .max:
            return 22
        }
    }

    private func shortcutIdentifier(_ shortcut: HomeShortcut) -> String {
        switch shortcut {
        case .transfer:
            return A11yID.Home.shortcutTransfer
        case .receive:
            return A11yID.Home.shortcutReceive
        case .statistics:
            return A11yID.Home.shortcutStatistics
        }
    }

    private func balanceAmountSize(for widthClass: DeviceWidthClass) -> CGFloat {
        switch widthClass {
        case .compact:
            return 30
        case .regular:
            return 32
        case .plus:
            return 34
        case .max:
            return 38
        }
    }

    private func shortcutIconSize(for widthClass: DeviceWidthClass) -> CGFloat {
        switch widthClass {
        case .compact:
            return 36
        case .regular:
            return 40
        case .plus:
            return 42
        case .max:
            return 46
        }
    }

    private func shortcutVerticalPadding(for widthClass: DeviceWidthClass) -> CGFloat {
        switch widthClass {
        case .compact:
            return 8
        case .regular:
            return 10
        case .plus:
            return 11
        case .max:
            return 12
        }
    }

    private func bannerHeight(for widthClass: DeviceWidthClass) -> CGFloat {
        switch widthClass {
        case .compact:
            return 150
        case .regular:
            return 160
        case .plus:
            return 172
        case .max:
            return 188
        }
    }

    private func recentSectionMinHeight(for widthClass: DeviceWidthClass) -> CGFloat {
        switch widthClass {
        case .compact:
            return 200
        case .regular:
            return 220
        case .plus:
            return 240
        case .max:
            return 268
        }
    }

    private func emptyMessageHeight(for widthClass: DeviceWidthClass) -> CGFloat {
        switch widthClass {
        case .compact:
            return 110
        case .regular:
            return 128
        case .plus:
            return 148
        case .max:
            return 172
        }
    }
}

private struct RecentMessageRow: Identifiable {
    let id: String
    let index: Int
    let item: MessageItem
}

#Preview("HomeView") {
    let appState = AppState()
    HomeView(
        sessionStore: SessionStore(appState: appState),
        homeStore: HomeStore(appState: appState),
        onShortcutTap: { _ in },
        onBannerTap: {},
        onRecentMessageTap: {}
    )
}
