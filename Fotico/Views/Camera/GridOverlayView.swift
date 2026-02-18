import SwiftUI

struct GridOverlayView: View {
    let mode: GridMode

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            switch mode {
            case .off:
                EmptyView()
            case .thirds:
                Path { path in
                    for i in 1...2 {
                        let x = size.width * CGFloat(i) / 3
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: size.height))
                        let y = size.height * CGFloat(i) / 3
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: size.width, y: y))
                    }
                }
                .stroke(Color.white.opacity(0.3), lineWidth: 0.5)
            case .center:
                Path { path in
                    let cx = size.width / 2, cy = size.height / 2
                    path.move(to: CGPoint(x: cx, y: cy - 10))
                    path.addLine(to: CGPoint(x: cx, y: cy + 10))
                    path.move(to: CGPoint(x: cx - 10, y: cy))
                    path.addLine(to: CGPoint(x: cx + 10, y: cy))
                }
                .stroke(Color.white.opacity(0.3), lineWidth: 0.5)
            case .golden:
                Path { path in
                    let phi: CGFloat = 1.618
                    let x1 = size.width / (1 + phi)
                    let x2 = size.width - x1
                    let y1 = size.height / (1 + phi)
                    let y2 = size.height - y1
                    for x in [x1, x2] {
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: size.height))
                    }
                    for y in [y1, y2] {
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: size.width, y: y))
                    }
                }
                .stroke(Color.white.opacity(0.25), lineWidth: 0.5)
            }
        }
        .allowsHitTesting(false)
    }
}
