import SwiftUI

struct SectionCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ThemeTokens.cardBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

struct CellRow: View {
    let icon: String
    let title: String
    var note: String? = nil
    var showArrow: Bool = true

    var body: some View {
        HStack(spacing: 12) {
            Image(icon)
                .resizable()
                .scaledToFit()
                .frame(width: 22, height: 22)

            Text(title)
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(ThemeTokens.title)

            Spacer()

            if let note, !note.isEmpty {
                Text(note)
                    .font(.system(size: 13))
                    .foregroundStyle(ThemeTokens.secondary)
                    .lineLimit(1)
            }

            if showArrow {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(ThemeTokens.tertiary)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 58, alignment: .leading)
        .padding(.horizontal, 14)
        .contentShape(Rectangle())
    }
}
