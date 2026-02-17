import SwiftUI

enum NetworkLogoResolver {
    static func resolvedURL(baseURL: URL, raw: String?) -> URL? {
        guard let raw, !raw.isEmpty else { return nil }
        if let absolute = URL(string: raw), absolute.scheme != nil {
            return absolute
        }
        let trimmed = raw.hasPrefix("/") ? String(raw.dropFirst()) : raw
        return baseURL.appendingPathComponent(trimmed)
    }

    static func isRasterURL(_ url: URL) -> Bool {
        let ext = url.pathExtension.lowercased()
        return ["png", "jpg", "jpeg", "webp", "gif", "heic", "heif"].contains(ext)
    }

    static func localAsset(networkName: String, rawLogo: String?) -> String? {
        let name = normalize(networkName)
        let logo = normalize(rawLogo ?? "")
        let key = "\(name) \(logo)"

        if key.contains("cpcash") || key.contains("appchannel") || key.contains("inapp") {
            return "chain_cp"
        }
        if key.contains("tron") || key.contains("trx") {
            return "chain_tron"
        }
        if key.contains("bsc") || key.contains("bnb") {
            return "chain_bsc"
        }
        if key.contains("btt") || key.contains("bittorrent") {
            return "settings_network_btt"
        }
        if key.contains("eth") || key.contains("evm") {
            return "chain_evm"
        }
        return nil
    }

    private static func normalize(_ raw: String) -> String {
        raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}

struct NetworkLogoView: View {
    let networkName: String
    let logoURL: String?
    let baseURL: URL
    let isNormalChannel: Bool

    var body: some View {
        Group {
            if isNormalChannel {
                ZStack {
                    Circle().fill(ThemeTokens.cpPrimary.opacity(0.1))
                    Image("chain_cp")
                        .resizable()
                        .scaledToFit()
                        .padding(6)
                }
            } else if let url = NetworkLogoResolver.resolvedURL(baseURL: baseURL, raw: logoURL),
                      NetworkLogoResolver.isRasterURL(url)
            {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case let .success(image):
                        image
                            .resizable()
                            .scaledToFit()
                            .clipShape(Circle())
                    default:
                        fallback
                    }
                }
            } else {
                fallback
            }
        }
    }

    @ViewBuilder
    private var fallback: some View {
        if let local = NetworkLogoResolver.localAsset(networkName: networkName, rawLogo: logoURL) {
            Image(local)
                .resizable()
                .scaledToFit()
                .clipShape(Circle())
        } else if isNormalChannel {
            Image("chain_cp")
                .resizable()
                .scaledToFit()
                .clipShape(Circle())
        } else {
            Image("chain_evm")
                .resizable()
                .scaledToFit()
                .clipShape(Circle())
        }
    }
}
