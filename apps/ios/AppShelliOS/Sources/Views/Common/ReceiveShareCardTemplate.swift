import SwiftUI

struct ShareCardRenderModel: Equatable {
    let chainName: String
    let address: String
    let chainColorHex: String
    let title: String
    let subtitle: String
    let modeTitle: String
    let minimumDepositText: String
}

struct ReceiveShareCardTemplate: View {
    let model: ShareCardRenderModel
    var qrSide: CGFloat = 188

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(hex: model.chainColorHex, fallback: ThemeTokens.cpGold))

            VStack(spacing: 14) {
                HStack {
                    Spacer()
                    Text(model.title)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(Color.white)
                    Spacer()
                }
                .padding(.top, 8)

                VStack(spacing: 14) {
                    HStack(spacing: 10) {
                        Image(systemName: "square.grid.2x2")
                            .font(.system(size: 24, weight: .regular))
                            .foregroundStyle(ThemeTokens.title)
                            .frame(width: 30, height: 30)
                        Text(model.modeTitle)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(ThemeTokens.title)
                        Spacer()
                        Image(systemName: "chevron.up")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(ThemeTokens.tertiary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 54)

                    Divider()

                    Text(model.subtitle)
                        .font(.system(size: 15))
                        .foregroundStyle(ThemeTokens.secondary)
                        .multilineTextAlignment(.center)

                    QRCodeView(value: model.address, side: qrSide)
                        .padding(12)
                        .background(ThemeTokens.qrBackground, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color.black.opacity(0.12), lineWidth: 1)
                        )

                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Text("Address")
                                .font(.system(size: 13))
                                .foregroundStyle(ThemeTokens.secondary)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(ThemeTokens.tertiary)
                        }
                        Text(model.address)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(ThemeTokens.title)
                            .lineLimit(3)
                            .minimumScaleFactor(0.85)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(ThemeTokens.softSurface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                    HStack(spacing: 12) {
                        actionPill("Share")
                        actionPill("Copy")
                    }

                    HStack {
                        Text("Minimum deposit")
                            .font(.system(size: 15))
                            .foregroundStyle(ThemeTokens.title)
                        Spacer()
                        Text(model.minimumDepositText)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(ThemeTokens.title)
                    }

                    Divider()

                    HStack(spacing: 10) {
                        Image("me_bill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                        Text("Transaction records")
                            .font(.system(size: 16))
                            .foregroundStyle(ThemeTokens.title)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(ThemeTokens.tertiary)
                    }
                }
                .padding(16)
                .background(ThemeTokens.cardBackground, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 18)
        }
    }

    private func actionPill(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(ThemeTokens.title)
            .frame(maxWidth: .infinity, minHeight: 44)
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(ThemeTokens.divider, lineWidth: 1)
            )
    }
}
