import SwiftUI
import UIKit

struct ReceiveShareView: View {
    @ObservedObject var sessionStore: SessionStore
    @ObservedObject var receiveStore: ReceiveStore
    @ObservedObject var uiStore: UIStore
    let orderSN: String
    @State private var shareSheetPresented = false
    @State private var shareImage: UIImage?
    @State private var shareBusy = false

    var body: some View {
        FullscreenScaffold(backgroundStyle: .globalImage) {
            ScrollView {
                VStack(spacing: 16) {
                    if receiveStore.isLoading(.receiveShare) {
                        ProgressView("Generating share card...")
                            .padding(.top, 30)
                    } else {
                        sharePreviewCard
                        actionButtons
                    }
                }
                .padding(16)
            }
        }
        .navigationTitle("Share")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $shareSheetPresented) {
            ActivityShareSheet(activityItems: shareItems)
        }
        .task {
            await receiveStore.loadReceiveShare(orderSN: orderSN)
        }
    }

    private var sharePreviewCard: some View {
        ReceiveShareCardTemplate(
            model: ShareCardRenderModel(
                chainName: shareChainName,
                address: shareAddress,
                chainColorHex: receiveStore.receiveDomainState.selectedChainColor,
                title: "Receive",
                subtitle: "Only supports \(shareChainName) network assets",
                modeTitle: "For individuals",
                minimumDepositText: minimumDepositText
            ),
            qrSide: 188
        )
        .frame(maxWidth: .infinity)
        .frame(height: 620)
    }

    private var actionButtons: some View {
        HStack(spacing: 10) {
            Button("Share Image") {
                shareCaptureCard()
            }
            .frame(maxWidth: .infinity, minHeight: 48)
            .foregroundStyle(.white)
            .background(ThemeTokens.cpPrimary, in: RoundedRectangle(cornerRadius: 24))
            .contentShape(Rectangle())
            .buttonStyle(.pressFeedback)
            .disabled(shareBusy || !canShareAddress)

            Button("Copy Address") {
                UIPasteboard.general.string = shareAddress
                uiStore.showInfoToast("Address copied")
            }
            .frame(maxWidth: .infinity, minHeight: 48)
            .foregroundStyle(ThemeTokens.cpPrimary)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(ThemeTokens.cpPrimary, lineWidth: 1)
            )
            .contentShape(Rectangle())
            .buttonStyle(.pressFeedback)
            .disabled(!canShareAddress)
        }
    }

    @MainActor
    private func shareCaptureCard() {
        guard !shareBusy else { return }
        guard canShareAddress else {
            uiStore.showInfoToast("Loading address data")
            return
        }
        shareBusy = true
        defer { shareBusy = false }
        let capture = sharePreviewCard
            .frame(width: 340, height: 620)
        guard let image = ViewImageRenderer.render(capture, size: CGSize(width: 340, height: 620)) else {
            uiStore.showInfoToast("Failed to generate share image")
            return
        }
        shareImage = image
        shareSheetPresented = true
    }

    private var shareItems: [Any] {
        if let shareImage {
            return [shareImage]
        }
        return []
    }

    private var shareAddress: String {
        let raw = receiveStore.receiveShareDetail?.depositAddress ??
            receiveStore.receiveShareDetail?.receiveAddress ??
            traceFallbackAddress ??
            sessionStore.activeAddress
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty || trimmed == "-" {
            return "0x0000000000000000000000000000000000000000"
        }
        return trimmed
    }

    private var traceFallbackAddress: String? {
        if receiveStore.receiveDomainState.individualOrderSN == orderSN {
            return receiveStore.individualTraceDetail?.depositAddress ??
                receiveStore.individualTraceDetail?.receiveAddress ??
                receiveStore.individualTraceOrder?.depositAddress ??
                receiveStore.individualTraceOrder?.receiveAddress
        }
        if receiveStore.receiveDomainState.businessOrderSN == orderSN {
            return receiveStore.businessTraceDetail?.depositAddress ??
                receiveStore.businessTraceDetail?.receiveAddress ??
                receiveStore.businessTraceOrder?.depositAddress ??
                receiveStore.businessTraceOrder?.receiveAddress
        }
        return nil
    }

    private var canShareAddress: Bool {
        let trimmed = shareAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty
    }

    private var shareChainName: String {
        let value = receiveStore.receiveDomainState.selectedPayChain.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? "BTT_TEST" : value
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
