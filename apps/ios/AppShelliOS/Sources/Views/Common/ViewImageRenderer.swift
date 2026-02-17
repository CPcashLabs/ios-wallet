import SwiftUI
import UIKit

enum ViewImageRenderer {
    @MainActor
    static func render<Content: View>(_ view: Content, size: CGSize? = nil) -> UIImage? {
        let renderer = ImageRenderer(content: view)
        renderer.scale = UIScreen.main.scale
        if let size {
            renderer.proposedSize = ProposedViewSize(size)
        }
        if let image = renderer.uiImage {
            return image
        }

        let hosting = UIHostingController(rootView: view)
        let targetSize = size ?? hosting.sizeThatFits(in: UIScreen.main.bounds.size)
        guard targetSize.width > 0, targetSize.height > 0 else {
            return nil
        }

        hosting.view.bounds = CGRect(origin: .zero, size: targetSize)
        hosting.view.backgroundColor = .clear
        hosting.view.setNeedsLayout()
        hosting.view.layoutIfNeeded()

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = UIScreen.main.scale
        let fallbackRenderer = UIGraphicsImageRenderer(size: targetSize, format: format)
        return fallbackRenderer.image { _ in
            hosting.view.drawHierarchy(in: hosting.view.bounds, afterScreenUpdates: true)
        }
    }
}
