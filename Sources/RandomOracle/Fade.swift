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
        let token = Binding<FadeToken?>(
            get: { isPresented.wrappedValue ? FadeToken() : nil },
            set: { isPresented.wrappedValue = $0 != nil }
        )
        return modifier(FadeCover(item: token) { _ in content() })
    }

    /// Shows `content` for `item` while it is non-nil, fading in and out. The item is handed to
    /// `content` directly: on iOS a presented cover cannot be trusted to read state that the
    /// presenting view set in the same tap (it saw nil and showed an empty veil).
    func fadeCover<Item: Identifiable, C: View>(item: Binding<Item?>, @ViewBuilder content: @escaping (Item) -> C) -> some View {
        modifier(FadeCover(item: item, cover: content))
    }
}

private struct FadeToken: Identifiable { var id: Int { 0 } }

private struct FadeCover<Item: Identifiable, C: View>: ViewModifier {
    @Binding var item: Item?
    let cover: (Item) -> C
    /// The item on screen; it stays while the cover fades out.
    @State private var mounted: Item?
    /// The cover has actually appeared on screen (the system presentation has finished).
    @State private var ready = false
    @State private var visible = false
    /// Touches are accepted only once fully faded in, so a quick double tap cannot hit a button
    /// that is still invisible, or close the cover while it is still being presented.
    @State private var interactive = false

    func body(content: Content) -> some View {
        content
            #if os(iOS)
            .fullScreenCover(item: $mounted) { layer($0).presentationBackground(.clear) }
            #else
            .overlay { if let mounted { layer(mounted) } }
            #endif
            .onChange(of: item?.id) { _, id in id != nil ? fadeIn() : fadeOut() }
    }

    private func layer(_ shown: Item) -> some View {
        ZStack {
            // Tapping the paper around the content closes it, so the cover can never trap the user.
            Theme.paper.opacity(0.94).ignoresSafeArea()
                .onTapGesture { item = nil }
            cover(shown)
        }
        .opacity(visible ? 1 : 0)
        .allowsHitTesting(interactive)
        .preferredColorScheme(.light)
        .onAppear {
            ready = true
            if item != nil { reveal() } else { unmount() }
        }
        .onDisappear { ready = false; visible = false; interactive = false }
    }

    private func fadeIn() {
        guard let item else { return }
        if ready, mounted?.id == item.id { reveal(); return }
        // Mount without the system's slide; onAppear then dissolves it in.
        var t = Transaction(); t.disablesAnimations = true
        withTransaction(t) { mounted = item }
    }

    private func reveal() {
        withAnimation(Fade.animation) { visible = true } completion: {
            if item != nil { interactive = true }
        }
    }

    private func fadeOut() {
        interactive = false
        // Still being presented: onAppear will see item == nil and unmount.
        guard ready else { return }
        withAnimation(Fade.animation) { visible = false } completion: {
            if item == nil { unmount() }
        }
    }

    private func unmount() {
        var t = Transaction(); t.disablesAnimations = true
        withTransaction(t) { mounted = nil }
    }
}
