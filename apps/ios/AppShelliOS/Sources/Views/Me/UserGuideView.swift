import SwiftUI

struct UserGuideView: View {
    private let guides: [String] = [
        "使用 Passkey 登录钱包",
        "如何发起转账",
        "如何创建收款码",
        "如何查看账单与统计"
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
        .navigationTitle("用户指南")
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
