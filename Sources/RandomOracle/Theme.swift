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

/// The 辻 mark: an open book lying on a road; the road runs on past it and forks into two,
/// each branch vanishing at its own point on the same (unseen) horizon. One white line on the page
/// is the verse the book fell open at. Geometry is on a 1024 grid, scaled to 95% so the tips clear
/// the iOS icon's rounded corners.
struct TsujiMark: View {
    var ink: Color = Theme.ink
    var accent: Color = Theme.shu
    var paper: Color = Theme.paper

    var body: some View {
        Canvas { ctx, size in
            let k = min(size.width, size.height) / 1024
            ctx.translateBy(x: (size.width - 1024 * k) / 2, y: (size.height - 1024 * k) / 2)
            ctx.scaleBy(x: k, y: k)
            ctx.translateBy(x: 512, y: 512)
            ctx.scaleBy(x: 0.95, y: 0.95)
            ctx.translateBy(x: -512, y: -512)

            let horizon: CGFloat = 110
            let vp = CGPoint(x: 512, y: horizon)
            // Point on the line from v through q at height y.
            func onRay(_ v: CGPoint, _ q: CGPoint, _ y: CGFloat) -> CGPoint {
                CGPoint(x: v.x + (q.x - v.x) * (y - v.y) / (q.y - v.y), y: y)
            }
            func shape(_ pts: [CGPoint]) -> Path {
                var p = Path(); p.addLines(pts); p.closeSubpath(); return p
            }

            // Road: the stem runs to the centre point; each branch to its own point, where it ends sharp.
            let sl = CGPoint(x: 322, y: 900), sr = CGPoint(x: 702, y: 900)
            let fl = onRay(vp, sl, 450), fr = onRay(vp, sr, 450)
            let crotch = CGPoint(x: 512, y: 450 - (fr.x - fl.x) * 0.35)
            // One outline, so no seam shows where the stem meets the branches.
            ctx.fill(shape([sl, fl, CGPoint(x: 72, y: horizon), crotch, CGPoint(x: 952, y: horizon), fr, sr]), with: .color(accent))

            // Book lying open on the road, its sides running to the same centre point.
            for s in [-1.0, 1.0] as [CGFloat] {
                let innerTop = CGPoint(x: 512 + s * 12, y: 620), outerTop = CGPoint(x: 512 + s * 260, y: 620)
                ctx.fill(shape([innerTop, outerTop, onRay(vp, outerTop, 820), onRay(vp, innerTop, 820)]), with: .color(ink))
            }

            // The verse: one line on the right page, following the page's perspective.
            let inner = onRay(vp, CGPoint(x: 524, y: 620), 720).x, outer = onRay(vp, CGPoint(x: 772, y: 620), 720).x
            var verse = Path()
            verse.move(to: CGPoint(x: inner + (outer - inner) * 0.14, y: 720))
            verse.addLine(to: CGPoint(x: inner + (outer - inner) * 0.82, y: 720))
            ctx.stroke(verse, with: .color(paper), style: StrokeStyle(lineWidth: 16, lineCap: .round))
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
