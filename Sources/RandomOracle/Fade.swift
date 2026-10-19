import SwiftUI

/// Every change of scene in this app is a slow dissolve, never a slide: it should feel like
/// turning to a page in a book, not like using a phone.
enum Fade {
    static let duration = 0.7
    static let animation = Animation.easeInOut(duration: duration)
}

extension View {
    /// Shows `content` over the whole screen on a veil of paper, fading in and out.
    /// Used instead of sliding sheets.
    func fadeCover<C: View>(isPresented: Binding<Bool>, @ViewBuilder content: @escaping () -> C) -> some View {
        modifier(FadeCover(isPresented: isPresented, cover: content))
    }
}

private struct FadeCover<C: View>: ViewModifier {
    @Binding var isPresented: Bool
    let cover: () -> C
    /// Whether the cover is mounted; it stays mounted while fading out.
    @State private var mounted = false
    @State private var visible = false

    func body(content: Content) -> some View {
        content
            #if os(iOS)
            .fullScreenCover(isPresented: $mounted) {
                layer.presentationBackground(.clear)
            }
            #else
            .overlay { if mounted { layer } }
            #endif
            .onChange(of: isPresented) { _, show in show ? fadeIn() : fadeOut() }
    }

    private var layer: some View {
        ZStack {
            Theme.paper.opacity(0.94).ignoresSafeArea()
            cover()
        }
        .opacity(visible ? 1 : 0)
        .preferredColorScheme(.light)
    }

    private func fadeIn() {
        // Mount without the system's slide, then dissolve in.
        var t = Transaction(); t.disablesAnimations = true
        withTransaction(t) { mounted = true }
        DispatchQueue.main.async { withAnimation(Fade.animation) { visible = true } }
    }

    private func fadeOut() {
        withAnimation(Fade.animation) { visible = false } completion: {
            var t = Transaction(); t.disablesAnimations = true
            withTransaction(t) { mounted = false }
        }
    }
}
