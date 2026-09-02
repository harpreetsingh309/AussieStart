import SwiftUI

/// A vector Australian outback scene used behind the onboarding welcome.
///
/// Drawn rather than photographed so it stays sharp at every device size and
/// aspect ratio, carries no image licensing, and composes correctly in
/// portrait — a landscape photo has to be cropped hard on a phone screen.
struct AustralianHorizonView: View {
    /// 0 = pre-dawn, 1 = full golden hour. Animated in on appear.
    var warmth: Double = 1

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let horizon = h * 0.52

            ZStack(alignment: .topLeading) {
                sky
                sun(width: w, horizon: horizon)
                ridge(width: w, baseline: horizon, amplitude: h * 0.030, phase: 0.0)
                    .fill(Color(hex: "8C4A2F").opacity(0.55))
                ridge(width: w, baseline: horizon + h * 0.038, amplitude: h * 0.022, phase: 1.7)
                    .fill(Color(hex: "6B3524").opacity(0.75))

                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "5A2C1D"), Color(hex: "3A1B12")],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: max(0, h - (horizon + h * 0.08)))
                    .offset(y: horizon + h * 0.08)

                KangarooShape()
                    .fill(Color(hex: "2A120B"))
                    .frame(width: w * 0.30, height: w * 0.30)
                    .offset(x: w * 0.56, y: horizon + h * 0.08 - w * 0.30 + 2)

                gumTree(height: h * 0.20)
                    .fill(Color(hex: "2A120B").opacity(0.9))
                    .frame(width: w * 0.22, height: h * 0.20)
                    .offset(x: -w * 0.02, y: horizon + h * 0.08 - h * 0.20 + 2)

                LinearGradient(
                    colors: [.black.opacity(0.10), .black.opacity(0.05), .black.opacity(0.55), .black.opacity(0.85)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .frame(width: w, height: h)
        }
        .drawingGroup()
    }

    private var sky: some View {
        LinearGradient(
            colors: [
                Color(hex: "10243F"),
                Color(hex: "3D3A63"),
                Color(hex: "B85C38").opacity(0.35 + 0.65 * warmth),
                Color(hex: "E8A15D").opacity(0.35 + 0.65 * warmth)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private func sun(width: CGFloat, horizon: CGFloat) -> some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [Color(hex: "FFE9A8"), Color(hex: "F7B267").opacity(0.85), Color(hex: "F7B267").opacity(0)],
                    center: .center,
                    startRadius: 0,
                    endRadius: width * 0.22
                )
            )
            .frame(width: width * 0.44, height: width * 0.44)
            .offset(x: width * 0.10, y: horizon - width * 0.30)
            .opacity(0.55 + 0.45 * warmth)
    }

    /// A soft, irregular ridge line built from a few sine terms.
    private func ridge(width: CGFloat, baseline: CGFloat, amplitude: CGFloat, phase: Double) -> Path {
        Path { p in
            p.move(to: CGPoint(x: 0, y: baseline))
            let steps = 48
            for i in 0...steps {
                let t = Double(i) / Double(steps)
                let x = width * CGFloat(t)
                let y = baseline
                    - amplitude * CGFloat(sin(t * 5.1 + phase))
                    - amplitude * 0.55 * CGFloat(sin(t * 11.3 + phase * 1.9))
                p.addLine(to: CGPoint(x: x, y: y))
            }
            p.addLine(to: CGPoint(x: width, y: baseline + amplitude * 8))
            p.addLine(to: CGPoint(x: 0, y: baseline + amplitude * 8))
            p.closeSubpath()
        }
    }

    /// A spare eucalypt silhouette — trunk plus a few forked limbs.
    private func gumTree(height: CGFloat) -> Path {
        Path { p in
            func pt(_ x: Double, _ y: Double) -> CGPoint {
                CGPoint(x: height * CGFloat(x), y: height * CGFloat(y))
            }
            p.move(to: pt(0.46, 1.00))
            p.addCurve(to: pt(0.50, 0.42), control1: pt(0.46, 0.80), control2: pt(0.47, 0.58))
            p.addCurve(to: pt(0.30, 0.14), control1: pt(0.44, 0.32), control2: pt(0.36, 0.22))
            p.addLine(to: pt(0.34, 0.11))
            p.addCurve(to: pt(0.54, 0.34), control1: pt(0.42, 0.20), control2: pt(0.50, 0.27))
            p.addCurve(to: pt(0.74, 0.10), control1: pt(0.58, 0.24), control2: pt(0.66, 0.16))
            p.addLine(to: pt(0.78, 0.13))
            p.addCurve(to: pt(0.56, 0.46), control1: pt(0.70, 0.22), control2: pt(0.60, 0.33))
            p.addCurve(to: pt(0.58, 1.00), control1: pt(0.57, 0.62), control2: pt(0.57, 0.82))
            p.closeSubpath()
        }
    }
}

/// Kangaroo silhouette, facing left, normalised to a unit square.
struct KangarooShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + rect.width * x, y: rect.minY + rect.height * y)
        }
        p.move(to: pt(0.318, 0.150))
        p.addCurve(to: pt(0.346, 0.040), control1: pt(0.300, 0.070), control2: pt(0.316, 0.024))
        p.addCurve(to: pt(0.372, 0.156), control1: pt(0.370, 0.054), control2: pt(0.376, 0.110))
        p.addCurve(to: pt(0.428, 0.150), control1: pt(0.392, 0.146), control2: pt(0.412, 0.144))
        p.addCurve(to: pt(0.474, 0.056), control1: pt(0.428, 0.092), control2: pt(0.446, 0.046))
        p.addCurve(to: pt(0.466, 0.184), control1: pt(0.500, 0.070), control2: pt(0.488, 0.136))
        p.addCurve(to: pt(0.470, 0.278), control1: pt(0.482, 0.216), control2: pt(0.482, 0.250))
        p.addCurve(to: pt(0.548, 0.446), control1: pt(0.506, 0.330), control2: pt(0.532, 0.386))
        p.addCurve(to: pt(0.706, 0.612), control1: pt(0.612, 0.482), control2: pt(0.674, 0.534))
        p.addCurve(to: pt(0.936, 0.812), control1: pt(0.776, 0.638), control2: pt(0.862, 0.712))
        p.addCurve(to: pt(0.980, 0.922), control1: pt(0.970, 0.856), control2: pt(0.988, 0.896))
        p.addCurve(to: pt(0.798, 0.828), control1: pt(0.942, 0.918), control2: pt(0.868, 0.880))
        p.addCurve(to: pt(0.678, 0.730), control1: pt(0.748, 0.790), control2: pt(0.706, 0.756))
        p.addCurve(to: pt(0.626, 0.868), control1: pt(0.678, 0.786), control2: pt(0.660, 0.836))
        p.addCurve(to: pt(0.512, 0.912), control1: pt(0.590, 0.900), control2: pt(0.548, 0.912))
        p.addCurve(to: pt(0.492, 0.952), control1: pt(0.500, 0.930), control2: pt(0.494, 0.944))
        p.addLine(to: pt(0.236, 0.952))
        p.addCurve(to: pt(0.234, 0.914), control1: pt(0.214, 0.952), control2: pt(0.212, 0.918))
        p.addCurve(to: pt(0.452, 0.856), control1: pt(0.330, 0.906), control2: pt(0.408, 0.886))
        p.addCurve(to: pt(0.484, 0.790), control1: pt(0.474, 0.840), control2: pt(0.482, 0.816))
        p.addCurve(to: pt(0.398, 0.700), control1: pt(0.448, 0.762), control2: pt(0.416, 0.736))
        p.addCurve(to: pt(0.386, 0.602), control1: pt(0.378, 0.664), control2: pt(0.374, 0.630))
        p.addCurve(to: pt(0.338, 0.534), control1: pt(0.362, 0.586), control2: pt(0.344, 0.560))
        p.addCurve(to: pt(0.318, 0.500), control1: pt(0.330, 0.520), control2: pt(0.322, 0.508))
        p.addCurve(to: pt(0.252, 0.502), control1: pt(0.296, 0.516), control2: pt(0.268, 0.518))
        p.addCurve(to: pt(0.272, 0.470), control1: pt(0.236, 0.484), control2: pt(0.250, 0.462))
        p.addCurve(to: pt(0.314, 0.472), control1: pt(0.290, 0.478), control2: pt(0.304, 0.480))
        p.addCurve(to: pt(0.322, 0.332), control1: pt(0.312, 0.424), control2: pt(0.314, 0.372))
        p.addCurve(to: pt(0.304, 0.270), control1: pt(0.312, 0.310), control2: pt(0.306, 0.288))
        p.addCurve(to: pt(0.242, 0.260), control1: pt(0.282, 0.272), control2: pt(0.258, 0.268))
        p.addCurve(to: pt(0.222, 0.224), control1: pt(0.224, 0.252), control2: pt(0.216, 0.238))
        p.addCurve(to: pt(0.288, 0.176), control1: pt(0.232, 0.208), control2: pt(0.264, 0.190))
        p.addCurve(to: pt(0.318, 0.150), control1: pt(0.304, 0.166), control2: pt(0.314, 0.158))
        p.closeSubpath()
        return p
    }
}

#Preview {
    AustralianHorizonView()
        .ignoresSafeArea()
}
