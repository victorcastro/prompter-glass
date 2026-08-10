import AppKit
import SwiftUI

struct HeroGlass: View {
    var accent: Color
    var sideTilt: Double = 18
    var imageWidth: CGFloat = 320
    var pulse: Int = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var pulseAmount: Double = 0
    @State private var hoverTilt: Double = 0
    @State private var isAppActive = true

    private enum Cycle {
        static let float: Double = 8
        static let shine: Double = 5
        static let breath: Double = 3.2
    }

    var body: some View {
        Group {
            if reduceMotion || !isAppActive {
                hero(time: nil)
            } else {
                TimelineView(.animation) { context in
                    hero(time: context.date.timeIntervalSinceReferenceDate)
                }
            }
        }
        .onChange(of: pulse) { _, _ in firePulse() }
        .onContinuousHover(coordinateSpace: .local) { phase in
            switch phase {
            case let .active(location):
                let normalized = Double((location.x - imageWidth / 2) / (imageWidth / 2))
                hoverTilt = normalized.clamped(to: -1 ... 1) * 6
            case .ended:
                hoverTilt = 0
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: hoverTilt)
        .onReceive(
            NotificationCenter.default.publisher(for: NSApplication.didResignActiveNotification)
        ) { _ in isAppActive = false }
        .onReceive(
            NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)
        ) { _ in isAppActive = true }
    }

    private func hero(time: TimeInterval?) -> some View {
        ZStack {
            halo(breath: breathScale(time))
            panel(microYaw: microYaw(time), time: time)
        }
    }

    private func microYaw(_ time: TimeInterval?) -> Double {
        guard let time else { return 0 }
        return sin(2 * Double.pi * time / Cycle.float + Double.pi / 3)
    }

    private func breathScale(_ time: TimeInterval?) -> Double {
        guard let time else { return 1.03 }
        return 1.03 + 0.03 * sin(2 * Double.pi * time / Cycle.breath)
    }

    private func halo(breath: Double) -> some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [accent.opacity(0.45 + 0.45 * pulseAmount), .clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: imageWidth * 0.55
                )
            )
            .frame(width: imageWidth * 1.1, height: imageWidth * 1.1)
            .blur(radius: 24)
            .scaleEffect(breath * (1 + 0.12 * pulseAmount))
            .allowsHitTesting(false)
    }

    private func panel(microYaw: Double, time: TimeInterval?) -> some View {
        panelImage
            .overlay(
                shine(time: time)
                    .blendMode(.plusLighter)
                    .mask(panelImage)
            )
            .rotation3DEffect(
                .degrees(sideTilt + microYaw + hoverTilt),
                axis: (x: 0, y: 1, z: 0),
                perspective: 0.6
            )
            .rotation3DEffect(.degrees(-6 - 6 * pulseAmount), axis: (x: 1, y: 0, z: 0))
            .rotationEffect(.degrees(-8))
            .shadow(color: .black.opacity(0.45), radius: 30, y: 24)
    }

    private var panelImage: some View {
        Image(decorative: "prompter")
            .resizable()
            .scaledToFit()
            .frame(width: imageWidth)
    }

    @ViewBuilder
    private func shine(time: TimeInterval?) -> some View {
        let progress = time.map { $0.truncatingRemainder(dividingBy: Cycle.shine) / Cycle.shine }
        if let progress, progress < 0.3 {
            let travel = progress / 0.3
            LinearGradient(
                colors: [.clear, .white.opacity(0.7), .clear],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: 200, height: imageWidth * 1.6)
            .rotationEffect(.degrees(24))
            .offset(x: -imageWidth + travel * imageWidth * 2)
        } else {
            Color.clear
        }
    }

    private func firePulse() {
        withAnimation(.spring(response: 0.28, dampingFraction: 0.55)) {
            pulseAmount = 1
        }
        Task {
            try? await Task.sleep(for: .milliseconds(300))
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                pulseAmount = 0
            }
        }
    }
}

#Preview {
    HeroGlass(accent: Theme.Mood.forest.glow)
        .frame(width: 560, height: 440)
        .background(MoodBackground(mood: .forest))
}
