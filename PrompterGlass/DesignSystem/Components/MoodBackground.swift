import SwiftUI

struct MoodBackground: View {
    let mood: Theme.Mood

    var body: some View {
        ZStack {
            mood.low
            RadialGradient(
                colors: [mood.high, mood.low],
                center: UnitPoint(x: 0.55, y: 0.2),
                startRadius: 0,
                endRadius: 1000
            )
            .opacity(0.9)
        }
        .ignoresSafeArea()
    }
}
