import SwiftUI

struct GlassCard<Content: View>: View {
    var isHighlighted = false
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .background(isHighlighted ? Theme.Glass.fillHighlighted : Theme.Glass.fill)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Glass.cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Glass.cornerRadius, style: .continuous)
                    .strokeBorder(Theme.Glass.stroke, lineWidth: 1)
            )
    }
}
