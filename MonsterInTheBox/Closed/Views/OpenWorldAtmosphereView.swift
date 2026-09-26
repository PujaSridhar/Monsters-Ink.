import SwiftUI

/// An atmospheric, open-world backdrop for the closed phone experience.
/// Features a dynamic sky reflecting focus progression (dawn → day → sunset → starry night),
/// slow-drifting pixel clouds, and distant mountain silhouettes behind the city diorama.
struct OpenWorldAtmosphereView: View {
    @Environment(KaijuEngine.self) private var engine
    @State private var cloudOffset: CGFloat = -30

    var body: some View {
        ZStack {
            // Dynamic Sky Gradient
            skyGradient
                .ignoresSafeArea()

            // Twinkling stars during deep focus / night
            if isNight {
                StarField()
                    .ignoresSafeArea()
                    .transition(.opacity)
            }

            // Drifting Clouds in the sky
            VStack {
                HStack(spacing: 50) {
                    PixelCloud(width: 84, height: 26)
                    PixelCloud(width: 112, height: 32)
                    PixelCloud(width: 72, height: 22)
                }
                .offset(x: cloudOffset)
                .opacity(isNight ? 0.35 : 0.8)
                .padding(.top, 45)

                Spacer()
            }
            .ignoresSafeArea()

            // Distant Mountain Silhouette Horizon
            VStack {
                Spacer()
                MountainRange()
                    .frame(height: 120)
                    .opacity(0.45)
            }
            .ignoresSafeArea()
        }
        .onAppear {
            withAnimation(.linear(duration: 35).repeatForever(autoreverses: true)) {
                cloudOffset = 40
            }
        }
        .animation(.smooth(duration: 2), value: timeOfDayPhase)
    }

    private var timeOfDayPhase: Int {
        let s = engine.focusSeconds
        if s < 60 { return 0 } // Dawn
        if s < 180 { return 1 } // Midday
        if s < 300 { return 2 } // Sunset
        return 3 // Night
    }

    private var isNight: Bool { timeOfDayPhase == 3 }

    private var skyGradient: LinearGradient {
        switch timeOfDayPhase {
        case 0:
            // Dawn: soft sunrise peach & cyan into verdant pine
            LinearGradient(
                colors: [
                    Color(red: 0.32, green: 0.52, blue: 0.70),
                    Color(red: 0.65, green: 0.58, blue: 0.50),
                    Color(red: 0.16, green: 0.36, blue: 0.22)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        case 1:
            // Midday: clear crisp blue sky into lush green
            LinearGradient(
                colors: [
                    Color(red: 0.20, green: 0.56, blue: 0.84),
                    Color(red: 0.32, green: 0.65, blue: 0.60),
                    Color(red: 0.13, green: 0.38, blue: 0.20)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        case 2:
            // Sunset: warm lavender, coral, into dusky forest
            LinearGradient(
                colors: [
                    Color(red: 0.38, green: 0.24, blue: 0.52),
                    Color(red: 0.80, green: 0.44, blue: 0.38),
                    Color(red: 0.18, green: 0.32, blue: 0.22)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        default:
            // Starry Night: deep midnight indigo into dark forest
            LinearGradient(
                colors: [
                    Color(red: 0.07, green: 0.08, blue: 0.20),
                    Color(red: 0.10, green: 0.16, blue: 0.28),
                    Color(red: 0.08, green: 0.20, blue: 0.15)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
}

/// A pixel-art stylized cloud shape.
struct PixelCloud: View {
    var width: CGFloat
    var height: CGFloat

    var body: some View {
        ZStack {
            Capsule()
                .fill(Color.white.opacity(0.85))
                .frame(width: width, height: height * 0.65)
            Circle()
                .fill(Color.white.opacity(0.9))
                .frame(width: height, height: height)
                .offset(x: -width * 0.18, y: -height * 0.22)
            Circle()
                .fill(Color.white.opacity(0.9))
                .frame(width: height * 0.85, height: height * 0.85)
                .offset(x: width * 0.16, y: -height * 0.18)
        }
        .compositingGroup()
        .shadow(color: .white.opacity(0.2), radius: 4, x: 0, y: 1)
    }
}

/// Distant mountain and hill silhouette.
struct MountainRange: View {
    var body: some View {
        Canvas { context, size in
            // Back mountain peak
            var backPath = Path()
            backPath.move(to: CGPoint(x: 0, y: size.height))
            backPath.addLine(to: CGPoint(x: size.width * 0.2, y: size.height * 0.35))
            backPath.addLine(to: CGPoint(x: size.width * 0.45, y: size.height * 0.7))
            backPath.addLine(to: CGPoint(x: size.width * 0.75, y: size.height * 0.25))
            backPath.addLine(to: CGPoint(x: size.width, y: size.height * 0.6))
            backPath.addLine(to: CGPoint(x: size.width, y: size.height))
            backPath.closeSubpath()
            context.fill(backPath, with: .color(Color(red: 0.10, green: 0.25, blue: 0.22).opacity(0.6)))

            // Front rolling hills
            var frontPath = Path()
            frontPath.move(to: CGPoint(x: 0, y: size.height))
            frontPath.addCurve(
                to: CGPoint(x: size.width * 0.5, y: size.height * 0.55),
                control1: CGPoint(x: size.width * 0.2, y: size.height * 0.5),
                control2: CGPoint(x: size.width * 0.35, y: size.height * 0.6)
            )
            frontPath.addCurve(
                to: CGPoint(x: size.width, y: size.height * 0.65),
                control1: CGPoint(x: size.width * 0.65, y: size.height * 0.5),
                control2: CGPoint(x: size.width * 0.85, y: size.height * 0.7)
            )
            frontPath.addLine(to: CGPoint(x: size.width, y: size.height))
            frontPath.closeSubpath()
            context.fill(frontPath, with: .color(Color(red: 0.08, green: 0.22, blue: 0.18).opacity(0.85)))
        }
    }
}

/// Gentle stars in the night sky.
struct StarField: View {
    var body: some View {
        Canvas { context, size in
            let points: [(CGFloat, CGFloat, CGFloat)] = [
                (0.12, 0.08, 2.0), (0.28, 0.14, 1.5), (0.45, 0.06, 2.5),
                (0.65, 0.12, 1.8), (0.82, 0.09, 2.2), (0.92, 0.16, 1.4),
                (0.20, 0.22, 1.6), (0.52, 0.18, 2.0), (0.74, 0.24, 1.5)
            ]
            for (xRatio, yRatio, r) in points {
                let rect = CGRect(
                    x: size.width * xRatio - r,
                    y: size.height * yRatio - r,
                    width: r * 2,
                    height: r * 2
                )
                context.fill(Path(ellipseIn: rect), with: .color(.white.opacity(0.85)))
            }
        }
    }
}
