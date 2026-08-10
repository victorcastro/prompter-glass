import SwiftUI

struct MoodBackground: View {
    let mood: Theme.Mood

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                LinearGradient(
                    stops: mood.baseStops,
                    startPoint: UnitPoint(x: 0.37, y: 0),
                    endPoint: UnitPoint(x: 0.63, y: 1)
                )
                ForEach(Array(mood.halos.enumerated()), id: \.offset) { _, halo in
                    haloView(halo, in: proxy.size)
                }
            }
        }
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 0.4), value: mood)
    }

    private func haloView(_ halo: Theme.MoodHalo, in size: CGSize) -> some View {
        let diameter = size.width * halo.width
        let verticalRatio = halo.width > 0 ? (size.height * halo.height) / diameter : 1

        return Circle()
            .fill(
                RadialGradient(
                    stops: [
                        .init(color: mood.glow.opacity(halo.opacity), location: 0),
                        .init(color: .clear, location: 0.68)
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: diameter / 2
                )
            )
            .frame(width: diameter, height: diameter)
            .scaleEffect(y: verticalRatio)
            .position(x: size.width * halo.centerX, y: size.height * halo.centerY)
            .allowsHitTesting(false)
    }
}
