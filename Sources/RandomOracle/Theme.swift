import CoreText
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

    /// Quoted verses only: Shippori Mincho (bundled, SIL OFL 1.1), modelled on Meiji-era metal type,
    /// so the drawn verse looks like a page of an old book. Falls back to Hiragino if it fails to load.
    static func verse(_ size: CGFloat) -> Font {
        _ = registerVerseFont
        return .custom("ShipporiMincho-Regular", size: size)
    }

    private static let registerVerseFont: Void = {
        if let url = Platform.resourceBundle.url(forResource: "ShipporiMincho-Regular", withExtension: "ttf") {
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }()
}

/// The 辻 mark: a thick open book drawn only with straight lines and circular arcs, in two line
/// weights (a heavy silhouette, light inner divisions), with one vermilion line on the right page:
/// the verse the book fell open at. Geometry is on a 1024 grid.
struct TsujiMark: View {
    var ink: Color = Theme.ink
    var accent: Color = Theme.shu
    /// Drops the icon's built-in margin so the book fills the frame (for use beside text).
    /// The app icon and the launch screen keep the margin.
    var tight = false
    /// 0...1: how far the vermilion verse line has surfaced on the page.
    var verse: Double = 1

    var body: some View {
        Canvas { ctx, size in
            let k = min(size.width, size.height) / 1024
            ctx.translateBy(x: (size.width - 1024 * k) / 2, y: (size.height - 1024 * k) / 2)
            ctx.scaleBy(x: k, y: k)
            if tight {
                // The drawing spans roughly x 180...845, y 200...745; scale that up to the frame.
                ctx.translateBy(x: 512, y: 512)
                ctx.scaleBy(x: 1.45, y: 1.45)
                ctx.translateBy(x: -512, y: -472)
            }

            let farY: CGFloat = 240, nearY: CGFloat = 570, dip: CGFloat = 34, rise: CGFloat = 22, block: CGFloat = 120
            let wf: CGFloat = 284, wn: CGFloat = 315
            func p(_ dx: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: 512 + dx, y: y) }

            // Silhouette: the far page edges, straight sides, the bottom of the page block.
            var outline = Path()
            outline.move(to: p(-wf, farY))
            arc(&outline, p(-wf, farY), p(-wf / 2, farY - rise), p(0, farY + dip))
            arc(&outline, p(0, farY + dip), p(wf / 2, farY - rise), p(wf, farY))
            outline.addLine(to: p(wn, nearY + block))
            arc(&outline, p(wn, nearY + block), p(wn / 2, nearY - rise + block), p(0, nearY + dip + block))
            arc(&outline, p(0, nearY + dip + block), p(-wn / 2, nearY - rise + block), p(-wn, nearY + block))
            outline.closeSubpath()

            // Divisions: where the pages meet the block of page edges, and the gutter.
            var inner = Path()
            inner.move(to: p(-wn, nearY))
            arc(&inner, p(-wn, nearY), p(-wn / 2, nearY - rise), p(0, nearY + dip))
            arc(&inner, p(0, nearY + dip), p(wn / 2, nearY - rise), p(wn, nearY))
            inner.move(to: p(0, farY + dip))
            inner.addLine(to: p(0, nearY + dip + block))

            ctx.stroke(outline, with: .color(ink), style: StrokeStyle(lineWidth: 36, lineCap: .round, lineJoin: .round))
            ctx.stroke(inner, with: .color(ink), style: StrokeStyle(lineWidth: 10, lineCap: .round, lineJoin: .round))

            var verseLine = Path()
            verseLine.move(to: p(70, 395))
            verseLine.addLine(to: p(240, 395))
            ctx.stroke(verseLine, with: .color(accent.opacity(self.verse)), style: StrokeStyle(lineWidth: 22, lineCap: .round))
        }
        .aspectRatio(1, contentMode: .fit)
    }

    /// Adds the circular arc from a through b to c (the path is already at a), traced finely enough
    /// to be indistinguishable from a true arc at any size.
    private func arc(_ path: inout Path, _ a: CGPoint, _ b: CGPoint, _ c: CGPoint) {
        let d = 2 * (a.x * (b.y - c.y) + b.x * (c.y - a.y) + c.x * (a.y - b.y))
        let a2 = a.x * a.x + a.y * a.y, b2 = b.x * b.x + b.y * b.y, c2 = c.x * c.x + c.y * c.y
        let o = CGPoint(x: (a2 * (b.y - c.y) + b2 * (c.y - a.y) + c2 * (a.y - b.y)) / d,
                        y: (a2 * (c.x - b.x) + b2 * (a.x - c.x) + c2 * (b.x - a.x)) / d)
        let r = hypot(a.x - o.x, a.y - o.y)
        func angle(_ q: CGPoint) -> CGFloat { atan2(q.y - o.y, q.x - o.x) }
        func positive(_ x: CGFloat) -> CGFloat { let m = x.truncatingRemainder(dividingBy: 2 * .pi); return m < 0 ? m + 2 * .pi : m }
        let start = angle(a)
        // Go the way round that passes through b.
        let sweepPos = positive(angle(c) - start)
        let sweep = positive(angle(b) - start) < sweepPos ? sweepPos : sweepPos - 2 * .pi
        let steps = 48
        for i in 1...steps {
            let t = start + sweep * CGFloat(i) / CGFloat(steps)
            path.addLine(to: CGPoint(x: o.x + r * cos(t), y: o.y + r * sin(t)))
        }
    }
}

// Lets the verse line fade in smoothly when `verse` changes inside an animation.
extension TsujiMark: Animatable {
    var animatableData: Double {
        get { verse }
        set { verse = newValue }
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
