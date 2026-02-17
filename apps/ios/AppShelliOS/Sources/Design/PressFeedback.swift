import SwiftUI

struct PressFeedbackStyle: ButtonStyle {
    var pressedScale: CGFloat = 0.98
    var pressedOpacity: Double = 0.86

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? pressedScale : 1)
            .opacity(configuration.isPressed ? pressedOpacity : 1)
            .animation(.easeOut(duration: 0.14), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PressFeedbackStyle {
    static var pressFeedback: PressFeedbackStyle {
        PressFeedbackStyle()
    }
}
