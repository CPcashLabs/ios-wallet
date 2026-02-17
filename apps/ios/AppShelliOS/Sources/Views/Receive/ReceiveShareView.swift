import SwiftUI
import UIKit

struct ReceiveShareView: View {
    @ObservedObject var state: AppState
    let orderSN: String
    @State private var shareSheetPresented = false
    @State private var shareImage: UIImage?
    @State private var shareBusy = false

    var body: some View {
        FullscreenScaffold(backgroundStyle: .globalImage) {
            ScrollView {
                VStack(spacing: 16) {
                    if state.isLoading(.receiveShare) {
                        ProgressView("生成分享卡片...")
                            .padding(.top, 30)
                    } else {
                        sharePreviewCard
                        actionButtons
                    }
                }
                .padding(16)
            }
        }
        .navigationTitle("分享")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $shareSheetPresented) {
            ActivityShareSheet(activityItems: shareItems)
        }
        .task {
            await state.loadReceiveShare(orderSN: orderSN)
        }
    }

    private var sharePreviewCard: some View {
        ReceiveShareCardTemplate(
            model: ShareCardRenderModel(
                chainName: shareChainName,
                address: shareAddress,
                chainColorHex: state.receiveDomainState.selectedChainColor,
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
            Button("分享图片") {
                shareCaptureCard()
            }
            .frame(maxWidth: .infinity, minHeight: 48)
            .foregroundStyle(.white)
            .background(ThemeTokens.cpPrimary, in: RoundedRectangle(cornerRadius: 24))
            .contentShape(Rectangle())
            .buttonStyle(.pressFeedback)
            .disabled(shareBusy || !canShareAddress)

            Button("复制地址") {
                UIPasteboard.general.string = shareAddress
                state.showInfoToast("地址已复制")
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
            state.showInfoToast("地址数据加载中")
            return
        }
        shareBusy = true
        defer { shareBusy = false }
        let capture = sharePreviewCard
            .frame(width: 340, height: 620)
        guard let image = ViewImageRenderer.render(capture, size: CGSize(width: 340, height: 620)) else {
            state.showInfoToast("分享图片生成失败")
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
        let raw = state.receiveShareDetail?.depositAddress ??
            state.receiveShareDetail?.receiveAddress ??
            traceFallbackAddress ??
            state.activeAddress
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty || trimmed == "-" {
            return "0x0000000000000000000000000000000000000000"
        }
        return trimmed
    }

    private var traceFallbackAddress: String? {
        if state.receiveDomainState.individualOrderSN == orderSN {
            return state.individualTraceDetail?.depositAddress ??
                state.individualTraceDetail?.receiveAddress ??
                state.individualTraceOrder?.depositAddress ??
                state.individualTraceOrder?.receiveAddress
        }
        if state.receiveDomainState.businessOrderSN == orderSN {
            return state.businessTraceDetail?.depositAddress ??
                state.businessTraceDetail?.receiveAddress ??
                state.businessTraceOrder?.depositAddress ??
                state.businessTraceOrder?.receiveAddress
        }
        return nil
    }

    private var canShareAddress: Bool {
        let trimmed = shareAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty
    }

    private var shareChainName: String {
        let value = state.receiveDomainState.selectedPayChain.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? "BTT_TEST" : value
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
