import BackendAPI
import SwiftUI
import UIKit

struct ReceiveCardView: View {
    let order: TraceOrderItem?
    let traceDetail: TraceShowDetail?
    let payChain: String
    let sendCoinName: String
    let minAmount: Double
    let maxAmount: Double
    let qrSide: CGFloat
    let isPolling: Bool
    let onGenerate: () -> Void
    let onShare: () -> Void
    let onTxLogs: () -> Void
    let onCopyAddress: () -> Void
    let addressTapA11yID: String
    var onAddressTap: (() -> Void)? = nil

    init(
        order: TraceOrderItem?,
        traceDetail: TraceShowDetail?,
        payChain: String,
        sendCoinName: String,
        minAmount: Double,
        maxAmount: Double,
        qrSide: CGFloat,
        isPolling: Bool,
        onGenerate: @escaping () -> Void,
        onShare: @escaping () -> Void,
        onTxLogs: @escaping () -> Void,
        onCopyAddress: @escaping () -> Void,
        addressTapA11yID: String = A11yID.Receive.cardAddressTap,
        onAddressTap: (() -> Void)? = nil
    ) {
        self.order = order
        self.traceDetail = traceDetail
        self.payChain = payChain
        self.sendCoinName = sendCoinName
        self.minAmount = minAmount
        self.maxAmount = maxAmount
        self.qrSide = qrSide
        self.isPolling = isPolling
        self.onGenerate = onGenerate
        self.onShare = onShare
        self.onTxLogs = onTxLogs
        self.onCopyAddress = onCopyAddress
        self.addressTapA11yID = addressTapA11yID
        self.onAddressTap = onAddressTap
    }

    var body: some View {
        VStack(spacing: 12) {
            if showUpdateBanner {
                HStack(spacing: 8) {
                    Text("Address is about to expire")
                        .font(.system(size: 12))
                        .foregroundStyle(ThemeTokens.title)
                    Button("Generate Address") {
                        onGenerate()
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(ThemeTokens.cpPrimary)
                }
                .frame(maxWidth: .infinity, minHeight: 28)
                .background(ThemeTokens.softSurface, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            }

            if (qrAddress != nil && !qrAddress!.isEmpty) || isPolling {
                qrSection(address: qrAddress ?? "")
                addressSection(address: qrAddress ?? "")
                actionButtons(address: qrAddress ?? "")
                minimumSection
                txLogsSection
            } else {
                emptySection
            }
        }
        .padding(16)
        .background(ThemeTokens.cardBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func qrSection(address: String) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(ThemeTokens.qrBackground)
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.black.opacity(0.12), lineWidth: 1))
            
            if !address.isEmpty {
                QRCodeView(value: address, side: qrSide)
            }
            
            if isPolling {
                QRCodeLoadingView(side: qrSide)
            }
        }
        .frame(width: qrSide + 16, height: qrSide + 16)
    }

    private func addressSection(address: String) -> some View {
        Button {
            if let onAddressTap {
                onAddressTap()
                return
            }
            if !isPolling {
                UIPasteboard.general.string = address
                onCopyAddress()
            }
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text("Address")
                        .font(.system(size: 14))
                        .foregroundStyle(ThemeTokens.title)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(ThemeTokens.tertiary)
                }
                Text(isPolling ? "Generating..." : formatAddress(address))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(isPolling ? ThemeTokens.secondary : ThemeTokens.title)
                    .lineLimit(2)
                    .truncationMode(.middle)
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(ThemeTokens.softSurface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(isPolling && onAddressTap == nil)
        .accessibilityIdentifier(addressTapA11yID)
    }

    private func actionButtons(address: String) -> some View {
        HStack(spacing: 10) {
            button(title: "Share", action: onShare)
                .disabled(isPolling)
                .opacity(isPolling ? 0.6 : 1)
            
            button(title: "Copy") {
                UIPasteboard.general.string = address
                onCopyAddress()
            }
            .disabled(isPolling)
            .opacity(isPolling ? 0.6 : 1)
        }
    }

    private var minimumSection: some View {
        VStack(spacing: 8) {
            if let expiredAt = expiryTimestamp, isWithin30Days(expiredAt) {
                HStack {
                    Text("Validity Period")
                        .font(.system(size: 14))
                        .foregroundStyle(ThemeTokens.secondary)
                    Spacer()
                    ExpiryDisplayView(expiredAt: expiredAt)
                }
            }
            HStack {
                Text("Minimum Receive Amount")
                    .font(.system(size: 14))
                    .foregroundStyle(ThemeTokens.secondary)
                Spacer()
                Text("\(format(minAmount)) \(sendCoinName)")
                    .font(.system(size: 14))
                    .foregroundStyle(ThemeTokens.title)
            }
        }
    }

    private var txLogsSection: some View {
        Button {
            onTxLogs()
        } label: {
            HStack(spacing: 10) {
                Image("me_bill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22, height: 22)
                Text("Transaction records")
                    .font(.system(size: 16))
                    .foregroundStyle(ThemeTokens.title)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(ThemeTokens.tertiary)
            }
            .padding(.top, 10)
            .padding(.bottom, 2)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .overlay(alignment: .top) {
                Divider()
            }
        }
        .buttonStyle(.plain)
    }

    private struct QRCodeLoadingView: View {
        let side: CGFloat
        @State private var isAnimating = false
        
        var body: some View {
            ZStack {
                Color.white.opacity(0.9)
                
                // Scanning line animation
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [.clear, ThemeTokens.cpPrimary.opacity(0.4), .clear]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 60)
                    .offset(y: isAnimating ? side/2 : -side/2)
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .frame(width: side, height: side)
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    isAnimating = true
                }
            }
        }
    }
    
    private struct ExpiryDisplayView: View {
        let expiredAt: Int64
        
        var body: some View {
            TimelineView(.periodic(from: .now, by: 1.0)) { context in
                if shouldShowCountdown(current: context.date) {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 14))
                        Text(countdownString(current: context.date))
                            .monospacedDigit()
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(ThemeTokens.title)
                } else {
                    Text(dateString)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(ThemeTokens.title)
                }
            }
        }
        
        private func shouldShowCountdown(current: Date) -> Bool {
            let expiryDate = Date(timeIntervalSince1970: TimeInterval(expiredAt) / 1000)
            let remaining = expiryDate.timeIntervalSince(current)
            // 30 days in seconds: 30 * 24 * 3600 = 2,592,000
            return remaining <= 2592000
        }
        
        private var dateString: String {
            DateTextFormatter.yearMonthDayMinute(fromTimestamp: Int(expiredAt), fallback: "-")
        }
        
        private func countdownString(current: Date) -> String {
            let expiryDate = Date(timeIntervalSince1970: TimeInterval(expiredAt) / 1000)
            let remaining = expiryDate.timeIntervalSince(current)
            
            if remaining <= 0 {
                return "00:00:00"
            }
            
            let days = Int(remaining) / 86400
            let hours = Int(remaining) / 3600 % 24
            let minutes = Int(remaining) / 60 % 60
            let seconds = Int(remaining) % 60
            
            if days > 0 {
                return String(format: "%d days %02d:%02d:%02d", days, hours, minutes, seconds)
            } else {
                return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
            }
        }
    }

    private var emptySection: some View {
        VStack(spacing: 12) {
            Text("No receive address")
                .font(.system(size: 14))
                .foregroundStyle(ThemeTokens.secondary)
            button(title: "Generate Address", action: onGenerate)
                .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 8)
    }

    private func button(title: String, action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .font(.system(size: 15, weight: .medium))
            .frame(maxWidth: .infinity, minHeight: 48)
            .foregroundStyle(ThemeTokens.cpPrimary)
            .overlay(
                RoundedRectangle(cornerRadius: 21, style: .continuous)
                    .stroke(ThemeTokens.cpPrimary.opacity(0.38), lineWidth: 1)
            )
            .contentShape(Rectangle())
            .buttonStyle(.pressFeedback)
    }

    private var qrAddress: String? {
        let address = traceDetail?.depositAddress
            ?? traceDetail?.receiveAddress
            ?? order?.depositAddress
            ?? order?.receiveAddress
            ?? order?.address
        if let address, !address.isEmpty {
            return address
        }
        return nil
    }

    private var showUpdateBanner: Bool {
        let expiredAt = traceDetail?.expiredAt ?? order?.expiredAt
        guard let expiredAt else { return false }
        let threshold: TimeInterval = 10 * 60 * 1000
        let nowMS = Date().timeIntervalSince1970 * 1000
        return Double(expiredAt) < (nowMS + threshold)
    }

    private var expiryTimestamp: Int64? {
        if let val = traceDetail?.expiredAt ?? order?.expiredAt {
            return Int64(val)
        }
        return nil
    }

    private func formatAddress(_ value: String) -> String {
        AddressFormatter.shortened(value, leading: 6, trailing: 6, threshold: 14)
    }

    private func format(_ value: Double) -> String {
        String(format: "%.2f", value)
    }

    private func isWithin30Days(_ expiredAt: Int64) -> Bool {
        let now = Date().timeIntervalSince1970
        let expiry = TimeInterval(expiredAt) / 1000
        let remaining = expiry - now
        // 30 days in seconds
        return remaining <= 30 * 24 * 3600
    }
}
