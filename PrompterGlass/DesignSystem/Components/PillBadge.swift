import SwiftUI

struct PillBadge: View {
    enum Leading {
        case dot
        case icon(String)
        case none
    }

    let text: String
    var leading: Leading = .none
    var tint: Color?

    var body: some View {
        HStack(spacing: 6) {
            leadingView
            Text(text)
                .font(.system(size: 12, weight: .semibold))
        }
        .foregroundStyle(tint ?? Theme.Palette.textSecondary)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background((tint ?? .white).opacity(tint == nil ? 0.10 : 0.16))
        .clipShape(Capsule())
    }

    @ViewBuilder
    private var leadingView: some View {
        switch leading {
        case .dot:
            Circle()
                .fill((tint ?? Theme.Palette.textSecondary).opacity(0.7))
                .frame(width: 6, height: 6)
        case let .icon(systemImage):
            Image(systemName: systemImage)
                .font(.system(size: 10, weight: .bold))
        case .none:
            EmptyView()
        }
    }
}
