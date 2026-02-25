import SwiftUI

struct UserGuideView: View {
    private let guides: [String] = [
        "Use Passkey to sign in to wallet",
        "How to start a transfer",
        "How to create a receive QR code",
        "How to view bills and statistics"
    ]

    var body: some View {
        FullscreenScaffold(backgroundStyle: .globalImage) {
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(guideRows) { row in
                        HStack(spacing: 12) {
                            Circle()
                                .fill(ThemeTokens.cpPrimary.opacity(0.15))
                                .frame(width: 26, height: 26)
                                .overlay {
                                    Text("\(row.index + 1)")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(ThemeTokens.cpPrimary)
                                }
                            Text(row.title)
                                .font(.system(size: 15))
                                .foregroundStyle(ThemeTokens.title)
                            Spacer()
                        }
                        .padding(14)
                        .background(ThemeTokens.cardBackground, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
        .navigationTitle("User Guide")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var guideRows: [GuideRow] {
        Array(guides.enumerated()).map { index, title in
            GuideRow(id: "\(index)-\(title)", index: index, title: title)
        }
    }
}

private struct GuideRow: Identifiable {
    let id: String
    let index: Int
    let title: String
}
