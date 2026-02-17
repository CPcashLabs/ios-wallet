import CoreImage
import CoreImage.CIFilterBuiltins
import SwiftUI
import UIKit

struct QRCodeView: View {
    let value: String
    let side: CGFloat

    private let context = CIContext()
    private let filter = CIFilter.qrCodeGenerator()

    var body: some View {
        if let image = generateQRCode(from: value) {
            Image(uiImage: image)
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .frame(width: side, height: side)
        } else {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.08))
                .frame(width: side, height: side)
                .overlay(
                    Image(systemName: "qrcode")
                        .font(.system(size: side / 4, weight: .regular))
                        .foregroundStyle(ThemeTokens.secondary)
                )
        }
    }

    private func generateQRCode(from value: String) -> UIImage? {
        guard let data = value.data(using: .utf8) else { return nil }
        filter.setValue(data, forKey: "inputMessage")
        filter.correctionLevel = "M"

        guard let outputImage = filter.outputImage else { return nil }
        let transform = CGAffineTransform(scaleX: 12, y: 12)
        let scaled = outputImage.transformed(by: transform)
        guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}
