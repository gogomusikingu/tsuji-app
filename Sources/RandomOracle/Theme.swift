import SwiftUI

/// "The look of a Japanese book": unbleached paper, sumi ink, Mincho type, one vermilion accent.
enum Theme {
    static let paper = Color(red: 0.961, green: 0.941, blue: 0.902)      // 生成り
    static let paperDeep = Color(red: 0.925, green: 0.898, blue: 0.847)  // cards, shadows
    static let ink = Color(red: 0.169, green: 0.161, blue: 0.153)        // 墨
    static let inkFaint = Color(red: 0.169, green: 0.161, blue: 0.153).opacity(0.55)
    static let shu = Color(red: 0.776, green: 0.278, blue: 0.188)        // 朱

    #if os(iOS)
    static let screenPadding: CGFloat = 18
    static let pagePadding: CGFloat = 26
    #else
    static let screenPadding: CGFloat = 32
    static let pagePadding: CGFloat = 40
    #endif

    /// Hiragino Mincho ships with both macOS and iOS and covers Latin text as well.
    static func mincho(_ size: CGFloat, bold: Bool = false) -> Font {
        .custom(bold ? "HiraMinProN-W6" : "HiraMinProN-W3", size: size)
    }
}

/// The 辻 mark: an open book whose gutter splits into a Y-shaped fork in the road.
struct TsujiMark: View {
    var ink: Color = Theme.ink
    var accent: Color = Theme.shu

    var body: some View {
        Canvas { ctx, size in
            let s = min(size.width, size.height) / 100
            func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x * s, y: y * s) }
            let line = StrokeStyle(lineWidth: 2.4 * s, lineCap: .round, lineJoin: .round)

            // Pages: each one follows a branch of the fork on its inner edge.
            var left = Path()
            left.move(to: p(46, 60))
            left.addLine(to: p(38, 24))
            left.addQuadCurve(to: p(8, 26), control: p(22, 18))
            left.addLine(to: p(8, 72))
            left.addQuadCurve(to: p(46, 74), control: p(28, 66))
            left.closeSubpath()
            var right = Path()
            right.move(to: p(54, 60))
            right.addLine(to: p(62, 24))
            right.addQuadCurve(to: p(92, 26), control: p(78, 18))
            right.addLine(to: p(92, 72))
            right.addQuadCurve(to: p(54, 74), control: p(72, 66))
            right.closeSubpath()
            ctx.stroke(left, with: .color(ink), style: line)
            ctx.stroke(right, with: .color(ink), style: line)

            // Lines of text on each page.
            for (i, y) in [36.0, 46, 56].enumerated() {
                var l = Path(); l.move(to: p(14, y)); l.addLine(to: p(36 - CGFloat(i) * 2 + 2, y - 1))
                var r = Path(); r.move(to: p(86, y)); r.addLine(to: p(64 + CGFloat(i) * 2 - 2, y - 1))
                ctx.stroke(l, with: .color(ink.opacity(0.35)), style: StrokeStyle(lineWidth: 1.4 * s, lineCap: .round))
                ctx.stroke(r, with: .color(ink.opacity(0.35)), style: StrokeStyle(lineWidth: 1.4 * s, lineCap: .round))
            }

            // The fork: a road comes up from below and splits along the gutter.
            var fork = Path()
            fork.move(to: p(50, 96))
            fork.addLine(to: p(50, 64))
            fork.addLine(to: p(42, 26))
            fork.move(to: p(50, 64))
            fork.addLine(to: p(58, 26))
            ctx.stroke(fork, with: .color(accent), style: StrokeStyle(lineWidth: 3.2 * s, lineCap: .round, lineJoin: .round))
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

/// A plain text button in the book style: Mincho label, vermilion underline-free outline.
struct InkButtonStyle: ButtonStyle {
    var filled = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.mincho(15))
            .padding(.horizontal, 22)
            .padding(.vertical, 10)
            .foregroundStyle(filled ? Theme.paper : Theme.shu)
            .background(
                RoundedRectangle(cornerRadius: 3)
                    .fill(filled ? Theme.shu : Color.clear)
                    .overlay(RoundedRectangle(cornerRadius: 3).stroke(Theme.shu, lineWidth: 1))
            )
            .opacity(configuration.isPressed ? 0.7 : 1)
            .contentShape(Rectangle())
    }
}
