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
    /// Whether the cover is in the view tree; it stays there while fading out.
    @State private var mounted = false
    /// The cover has actually appeared on screen (the system presentation has finished).
    @State private var ready = false
    @State private var visible = false
    /// Touches are accepted only once fully faded in, so a quick double tap cannot hit a button
    /// that is still invisible, or close the cover while it is still being presented.
    @State private var interactive = false

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
            // Tapping the paper around the content closes it, so the cover can never trap the user.
            Theme.paper.opacity(0.94).ignoresSafeArea()
                .onTapGesture { isPresented = false }
            cover()
        }
        .opacity(visible ? 1 : 0)
        .allowsHitTesting(interactive)
        .preferredColorScheme(.light)
        .onAppear {
            ready = true
            if isPresented { reveal() } else { unmount() }
        }
        .onDisappear { ready = false; visible = false; interactive = false }
    }

    private func fadeIn() {
        if mounted, ready { reveal(); return }
        // Mount without the system's slide; onAppear then dissolves it in.
        var t = Transaction(); t.disablesAnimations = true
        withTransaction(t) { mounted = true }
    }

    private func reveal() {
        withAnimation(Fade.animation) { visible = true } completion: {
            if isPresented { interactive = true }
        }
    }

    private func fadeOut() {
        interactive = false
        // Still being presented: onAppear will see isPresented == false and unmount.
        guard ready else { return }
        withAnimation(Fade.animation) { visible = false } completion: {
            if !isPresented { unmount() }
        }
    }

    private func unmount() {
        var t = Transaction(); t.disablesAnimations = true
        withTransaction(t) { mounted = false }
    }
}
