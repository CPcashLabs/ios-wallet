import BackendAPI
import SwiftUI

private enum AssetSegment: String, CaseIterable {
    case usdt = "USDT"
    case crypto = "Crypto"
}

struct TotalAssetsView: View {
    @ObservedObject var sessionStore: SessionStore
    @ObservedObject var homeStore: HomeStore
    @ObservedObject var meStore: MeStore

    private static let balanceFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 6
        formatter.minimumFractionDigits = 0
        return formatter
    }()

    private static let fractionalBalanceFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 6
        formatter.minimumFractionDigits = 2
        return formatter
    }()

    @AppStorage("wallet.showBalance") private var showBalance = true
    @State private var selectedSegment: AssetSegment = .usdt
    @State private var refreshing = false

    var body: some View {
        AdaptiveReader { widthClass in
            FullscreenScaffold(backgroundStyle: .globalImage) {
                ScrollView {
                    VStack(spacing: 14) {
                        totalCard(widthClass: widthClass)
                        segmentBar
                        if filteredCoins.isEmpty {
                            EmptyStateView(asset: "bill_no_data", title: "No assets")
                                .padding(.vertical, 40)
                        } else {
                            VStack(spacing: 0) {
                                ForEach(coinRows) { row in
                                    coinRow(row.coin, widthClass: widthClass)
                                    if row.index < coinRows.count - 1 {
                                        Divider()
                                            .padding(.leading, 54)
                                    }
                                }
                            }
                            .background(ThemeTokens.cardBackground, in: RoundedRectangle(cornerRadius: widthClass.metrics.cardCornerRadius, style: .continuous))
                        }
                    }
                    .padding(.horizontal, widthClass.horizontalPadding)
                    .padding(.vertical, 12)
                }
            }
            .background(LinearGradient(
                colors: [ThemeTokens.homeTopGradient, ThemeTokens.groupBackground],
                startPoint: .top,
                endPoint: .center
            ))
            .navigationTitle("Total Assets")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await refreshAssets(withHaptic: true) }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 14, weight: .semibold))
                            .rotationEffect(.degrees(refreshing ? 360 : 0))
                            .animation(
                                refreshing ? .linear(duration: 0.8).repeatForever(autoreverses: false) : .default,
                                value: refreshing
                            )
                    }
                    .buttonStyle(.pressFeedback)
                }
            }
            .refreshable {
                await refreshAssets(withHaptic: true)
            }
            .task {
                await refreshAssets(withHaptic: false)
            }
        }
    }

    private func totalCard(widthClass: DeviceWidthClass) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text("Wallet Balance")
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
                .font(.system(size: 30, weight: .medium))
                .foregroundStyle(.white)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(ThemeTokens.cpPrimary, in: RoundedRectangle(cornerRadius: widthClass.metrics.cardCornerRadius))
    }

    private var segmentBar: some View {
        HStack(spacing: 8) {
            ForEach(AssetSegment.allCases, id: \.self) { segment in
                Button {
                    selectedSegment = segment
                } label: {
                    Text(segment.rawValue)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(selectedSegment == segment ? ThemeTokens.cpPrimary : ThemeTokens.title)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(ThemeTokens.cardBackground, in: Capsule())
                }
                .buttonStyle(.pressFeedback)
            }
            Spacer()
        }
    }

    private func coinRow(_ coin: CoinItem, widthClass: DeviceWidthClass) -> some View {
        HStack(spacing: 12) {
            coinIcon(coin)
            VStack(alignment: .leading, spacing: 2) {
                Text(displayCoinTitle(coin))
                    .font(.system(size: widthClass.titleSize - 1, weight: .semibold))
                    .foregroundStyle(ThemeTokens.title)
                if let price = coin.coinPrice {
                    Text("\(currencySymbol) \(String(format: "%.2f", price * currencyRate))")
                        .font(.system(size: widthClass.footnoteSize))
                        .foregroundStyle(ThemeTokens.secondary)
                        .lineLimit(1)
                } else {
                    Text("--")
                        .font(.system(size: widthClass.footnoteSize))
                        .foregroundStyle(ThemeTokens.secondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(showBalance ? formatBalance(coinBalance(coin)) : "***")
                    .font(.system(size: widthClass.titleSize, weight: .semibold))
                    .foregroundStyle(ThemeTokens.title)
                if let fiatValue = coinFiatValue(coin), showBalance {
                    Text(String(format: "\(currencySymbol) %.2f", fiatValue))
                        .font(.system(size: widthClass.footnoteSize))
                        .foregroundStyle(ThemeTokens.secondary)
                } else {
                    Text(showBalance ? "--" : "***")
                        .font(.system(size: widthClass.footnoteSize))
                        .foregroundStyle(ThemeTokens.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: 74)
        .padding(.horizontal, 14)
        .contentShape(Rectangle())
    }

    private func displayCoinTitle(_ coin: CoinItem) -> String {
        if let name = coin.coinName, !name.isEmpty {
            if name.uppercased().contains("USDT") {
                return "USDT"
            }
            return name
        }
        if let symbol = coin.coinSymbol, !symbol.isEmpty {
            return symbol
        }
        return coin.code ?? "-"
    }

    @ViewBuilder
    private func coinIcon(_ coin: CoinItem) -> some View {
        RemoteImageView(
            rawURL: coin.coinLogo,
            baseURL: sessionStore.environment.baseURL,
            contentMode: .fill
        ) {
            coinFallbackIcon(coin)
        }
        .frame(width: 34, height: 34)
        .clipShape(Circle())
    }

    private func coinFallbackIcon(_ coin: CoinItem) -> some View {
        Circle()
            .fill(ThemeTokens.cpPrimary.opacity(0.12))
            .frame(width: 34, height: 34)
            .overlay(
                Text(String(displayCoinTitle(coin).prefix(1)).uppercased())
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(ThemeTokens.cpPrimary)
            )
    }

    private var filteredCoins: [CoinItem] {
        let source = homeStore.allCoins.filter { coin in
            let name = displayCoinTitle(coin).uppercased()
            switch selectedSegment {
            case .usdt:
                return name.contains("USDT")
            case .crypto:
                return !name.contains("USDT")
            }
        }
        return source.sorted { coinBalance($0) > coinBalance($1) }
    }

    private var coinRows: [AssetCoinRow] {
        let seeds = filteredCoins.map { coin in
            StableRowID.make(
                coin.coinCode,
                coin.code,
                coin.coinSymbol,
                coin.chainName,
                fallback: "coin-row"
            )
        }
        let ids = StableRowID.uniqued(seeds)
        return Array(zip(filteredCoins, ids).enumerated()).map { index, pair in
            AssetCoinRow(id: pair.1, index: index, coin: pair.0)
        }
    }

    private var currencyRate: Double {
        if meStore.selectedCurrency.uppercased() == "USD" {
            return 1
        }
        guard let item = meStore.exchangeRates.first(where: { ($0.currency ?? "").uppercased() == meStore.selectedCurrency.uppercased() }),
              let text = item.value,
              let rate = Double(text),
              rate > 0
        else {
            return 1
        }
        return rate
    }

    private var currencySymbol: String {
        if let item = meStore.exchangeRates.first(where: { ($0.currency ?? "").uppercased() == meStore.selectedCurrency.uppercased() }),
           let symbol = item.symbol,
           !symbol.isEmpty
        {
            return symbol
        }
        return "$"
    }

    private var formattedTotalBalance: String {
        let totalUSD = homeStore.allCoins.reduce(0.0) { partial, coin in
            partial + ((coin.coinPrice ?? 0) * coinBalance(coin))
        }
        let total = totalUSD * currencyRate
        if total > 0 {
            return String(format: "\(currencySymbol) %.2f", total)
        }
        return "\(currencySymbol) --.--"
    }

    private func coinBalance(_ coin: CoinItem) -> Double {
        if let text = coin.balance?.stringValue, let parsed = Double(text) {
            return normalizedBalance(raw: parsed, rawText: text, precision: coin.precision)
        }
        if let value = coin.balance?.doubleValue {
            return normalizedBalance(raw: value, rawText: coin.balance?.description ?? "", precision: coin.precision)
        }
        return 0
    }

    private func coinFiatValue(_ coin: CoinItem) -> Double? {
        guard let price = coin.coinPrice else { return nil }
        return price * coinBalance(coin) * currencyRate
    }

    private func formatBalance(_ value: Double) -> String {
        if value == 0 { return "0" }
        let formatter = value < 1 ? Self.fractionalBalanceFormatter : Self.balanceFormatter
        return formatter.string(from: NSNumber(value: value)) ?? String(value)
    }

    private func refreshAssets(withHaptic: Bool) async {
        refreshing = true
        await meStore.loadExchangeRates()
        await homeStore.refreshHomeData()
        refreshing = false
        if withHaptic {
            Haptics.lightImpact()
        }
    }

    private func normalizedBalance(raw: Double, rawText: String, precision: Int?) -> Double {
        guard let precision, precision > 0 else { return raw }
        let clean = rawText
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: "")
        guard !clean.isEmpty, !clean.contains(".") else { return raw }
        let sign = clean.hasPrefix("-") ? -1.0 : 1.0
        let digits = clean.replacingOccurrences(of: "-", with: "")
        guard digits.count > precision, let integer = Double(digits) else {
            return raw
        }
        return sign * integer / pow(10, Double(precision))
    }
}

private struct AssetCoinRow: Identifiable {
    let id: String
    let index: Int
    let coin: CoinItem
}
