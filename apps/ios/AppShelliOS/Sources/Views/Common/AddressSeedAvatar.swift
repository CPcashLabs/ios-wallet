import SwiftUI

struct AddressSeedAvatar: View {
    let size: CGFloat
    let address: String
    let avatarURL: String?
    private let defaultAvatarBaseURL = URL(string: "https://charprotocol.dev")

    var body: some View {
        RemoteImageView(
            rawURL: avatarURL,
            baseURL: defaultAvatarBaseURL,
            contentMode: .fill
        ) {
            seededAvatar
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }

    private var seededAvatar: some View {
        let seed = avatarSeed(from: address)
        let palette = paletteForSeed(seed)
        let offsets = avatarOffsets(seed: seed, size: size)

        return ZStack {
            Circle()
                .fill(palette.0)
            Circle()
                .fill(palette.1)
                .frame(width: size * 0.78, height: size * 0.78)
                .offset(offsets.0)
            Circle()
                .fill(palette.2)
                .frame(width: size * 0.56, height: size * 0.56)
                .offset(offsets.1)
            Circle()
                .fill(palette.3)
                .frame(width: size * 0.38, height: size * 0.38)
                .offset(offsets.2)
            Circle()
                .fill(palette.4)
                .frame(width: size * 0.28, height: size * 0.28)
                .offset(offsets.3)
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }

    private func avatarSeed(from rawAddress: String) -> UInt64 {
        let address = rawAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        if address.hasPrefix("0x"), address.count >= 10 {
            let start = address.dropFirst(2).prefix(8)
            if let seed = UInt64(start, radix: 16) {
                return seed
            }
        }

        var hash: UInt64 = 2_166_136_261
        for byte in address.utf8 {
            hash ^= UInt64(byte)
            hash &*= 16_777_619
        }
        return hash
    }

    private func paletteForSeed(_ seed: UInt64) -> (Color, Color, Color, Color, Color) {
        let h1 = Double(seed % 360) / 360.0
        let h2 = Double((seed >> 9) % 360) / 360.0
        let h3 = Double((seed >> 18) % 360) / 360.0
        let h4 = Double((seed >> 27) % 360) / 360.0
        let h5 = Double((seed >> 36) % 360) / 360.0
        return (
            Color(hue: h1, saturation: 0.62, brightness: 0.90),
            Color(hue: h2, saturation: 0.72, brightness: 0.82),
            Color(hue: h3, saturation: 0.84, brightness: 0.72),
            Color(hue: h4, saturation: 0.52, brightness: 0.86),
            Color(hue: h5, saturation: 0.65, brightness: 0.74)
        )
    }

    private func avatarOffsets(seed: UInt64, size: CGFloat) -> (CGSize, CGSize, CGSize, CGSize) {
        let angle1 = CGFloat(Double((seed >> 5) % 360) * .pi / 180.0)
        let angle2 = CGFloat(Double((seed >> 13) % 360) * .pi / 180.0)
        let angle3 = CGFloat(Double((seed >> 21) % 360) * .pi / 180.0)
        let angle4 = CGFloat(Double((seed >> 29) % 360) * .pi / 180.0)
        let radius1 = size * 0.13
        let radius2 = size * 0.18
        let radius3 = size * 0.10
        let radius4 = size * 0.22

        let offset1 = CGSize(width: cos(angle1) * radius1, height: sin(angle1) * radius1)
        let offset2 = CGSize(width: cos(angle2) * radius2, height: sin(angle2) * radius2)
        let offset3 = CGSize(width: cos(angle3) * radius3, height: sin(angle3) * radius3)
        let offset4 = CGSize(width: cos(angle4) * radius4, height: sin(angle4) * radius4)
        return (offset1, offset2, offset3, offset4)
    }
}
