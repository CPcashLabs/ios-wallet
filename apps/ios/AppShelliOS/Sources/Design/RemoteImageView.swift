import NukeUI
import SwiftUI

struct RemoteImageView<Placeholder: View>: View {
    let rawURL: String?
    let baseURL: URL?
    let contentMode: ContentMode
    @ViewBuilder let placeholder: () -> Placeholder

    init(
        rawURL: String?,
        baseURL: URL? = nil,
        contentMode: ContentMode = .fill,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.rawURL = rawURL
        self.baseURL = baseURL
        self.contentMode = contentMode
        self.placeholder = placeholder
    }

    var body: some View {
        Group {
            if let resolvedURL {
                LazyImage(url: resolvedURL) { state in
                    if let image = state.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: contentMode)
                    } else {
                        placeholder()
                    }
                }
            } else {
                placeholder()
            }
        }
    }

    private var resolvedURL: URL? {
        guard let rawURL else { return nil }
        let value = rawURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return nil }
        if let absolute = URL(string: value), absolute.scheme != nil {
            return absolute
        }
        guard let baseURL else { return nil }
        let trimmed = value.hasPrefix("/") ? String(value.dropFirst()) : value
        return baseURL.appendingPathComponent(trimmed)
    }
}
