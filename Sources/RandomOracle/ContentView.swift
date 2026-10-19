import SwiftUI

struct ContentView: View {
    @AppStorage("language") private var language: AppLanguage = .ja
    @AppStorage("guideSeen") private var guideSeen = false
    @StateObject private var journal = Journal()
    @State private var showGuide = false
    @State private var tab: Tab = .draw
    @State private var showSplash = true
    @State private var skipSplash = false
    /// Loaded off the main thread while the splash is up, so launch does not stall on 31k verses.
    @State private var bible: Bible?
    /// Full window size, so the mark can sit at the exact screen centre wherever it is drawn.
    @State private var windowSize: CGSize = .zero

    enum Tab { case draw, records }

    var body: some View {
        let l = L10n(lang: language)
        VStack(spacing: 0) {
            header(l)
            Rectangle().fill(Theme.ink.opacity(0.15)).frame(height: 1)
            // Pages dissolve into each other instead of switching instantly.
            ZStack {
                if tab == .draw { page(.draw).transition(.opacity) }
                if tab == .records { page(.records).transition(.opacity) }
            }
            #if os(iOS)
            tabBar(l)
            #endif
        }
        .background(Theme.paper)
        .foregroundStyle(Theme.ink)
        .tint(Theme.shu)
        .preferredColorScheme(.light)
        .background(GeometryReader { g in
            Color.clear
                .onAppear { windowSize = g.size }
                .onChange(of: g.size) { _, size in windowSize = size }
        }.ignoresSafeArea())
        .overlay {
            if showSplash {
                SplashView(lang: language).transition(.opacity)
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture { skipSplash = true }
            }
        }
        #if DEBUG
        // Screenshot automation: TSUJI_TAB=records starts on the journal.
        .onAppear { if ProcessInfo.processInfo.environment["TSUJI_TAB"] == "records" { tab = .records } }
        #endif
        .task {
            // Show the name and mark for a moment while the text loads, then reveal the app
            // (and the guide on first run).
            async let loaded = Task.detached(priority: .userInitiated) { Bible.shared }.value
            // About 4.5 s: longer than the usual 2-3 s guidance on purpose, as a pause before the
            // day's verse. A tap skips it.
            for _ in 0..<45 where !skipSplash { try? await Task.sleep(for: .milliseconds(100)) }
            bible = await loaded
            withAnimation(.easeInOut(duration: 1.0)) { showSplash = false }
            if !guideSeen {
                try? await Task.sleep(for: .seconds(1.0))
                showGuide = true
            }
        }
        .fadeCover(isPresented: $showGuide) {
            GuideView(lang: language) { guideSeen = true; showGuide = false }
        }
        .environment(\.windowSize, windowSize)
    }

    private func page(_ target: Tab) -> some View {
        // A ZStack with a clear layer keeps the page full-size even while it has nothing to show yet
        // (the text is still loading); an empty Group would collapse the whole window around it.
        ZStack {
            Color.clear
            switch target {
            case .draw: if let bible { DrawView(bible: bible, journal: journal, lang: language) }
            case .records: RecordsView(journal: journal, lang: language, bible: bible)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.paper)
    }

    /// A quiet two-item bar in the book's type, instead of the system tab bar.
    private func tabBar(_ l: L10n) -> some View {
        HStack {
            barItem(l.tabDraw, .draw) { Image(systemName: "book").font(.system(size: 18, weight: .light)) }
            barItem(l.tabRecords, .records) { KoyomiIcon().frame(width: 22, height: 22) }
        }
        .padding(.top, 10)
        .padding(.bottom, 4)
        .overlay(alignment: .top) { Rectangle().fill(Theme.ink.opacity(0.12)).frame(height: 1) }
        .background(Theme.paper)
    }

    private func barItem(_ title: String, _ target: Tab, @ViewBuilder icon: () -> some View) -> some View {
        Button { withAnimation(Fade.animation) { tab = target } } label: {
            VStack(spacing: 4) {
                icon().frame(height: 22)
                Text(title).font(Theme.mincho(10))
            }
            .frame(maxWidth: .infinity)
            .foregroundStyle(tab == target ? Theme.shu : Theme.inkFaint)
        }
        .buttonStyle(.plain)
    }

    private func header(_ l: L10n) -> some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                // The tagline leads: it says what the app does; the name alone would not.
                Text(l.tagline).font(Theme.mincho(15, bold: true)).lineLimit(1).minimumScaleFactor(0.8)
                Text(l.appName).font(Theme.mincho(11)).foregroundStyle(Theme.inkFaint)
            }
            Spacer()
            #if os(macOS)
            tabButton(l.tabDraw, .draw)
            tabButton(l.tabRecords, .records)
            Divider().frame(height: 16)
            #endif
            Button(language == .ja ? "EN" : "日本語") { language = language == .ja ? .en : .ja }
                .buttonStyle(.plain).font(Theme.mincho(12)).foregroundStyle(Theme.inkFaint)
            Button { showGuide = true } label: { Image(systemName: "questionmark.circle") }
                .buttonStyle(.plain).foregroundStyle(Theme.inkFaint)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
    }

    private func tabButton(_ title: String, _ target: Tab) -> some View {
        Button(title) { withAnimation(Fade.animation) { tab = target } }
            .buttonStyle(.plain)
            .font(Theme.mincho(14, bold: tab == target))
            .foregroundStyle(tab == target ? Theme.shu : Theme.inkFaint)
    }
}

/// First-run guide: the 辻占 tradition, then why "bending" an unrelated verse is the whole point.
struct GuideView: View {
    let lang: AppLanguage
    let onClose: () -> Void

    var body: some View {
        let l = L10n(lang: lang)
        VStack(alignment: .leading, spacing: 18) {
            ScrollView { GuideContent(lang: lang).padding(.trailing, 8) }
            HStack { Spacer(); Button(l.guideStart, action: onClose).buttonStyle(InkButtonStyle(filled: true)) }
        }
        .padding(32)
        #if os(macOS)
        .frame(width: 580, height: 680)
        #endif
        .background(Theme.paper)
        .foregroundStyle(Theme.ink)
        .preferredColorScheme(.light)
    }
}

/// The guide's scrollable body, split out so it can also be rendered to an image for review.
struct GuideContent: View {
    let lang: AppLanguage

    var body: some View {
        let l = L10n(lang: lang)
        VStack(alignment: .leading, spacing: 18) {
            Text(l.guideTitle).font(Theme.mincho(22, bold: true))
            VStack(alignment: .leading, spacing: 10) {
                Text("言霊の　八十の衢に　夕占問ふ\n占正に告る　妹相寄らむ")
                    .font(Theme.mincho(17))
                    .lineSpacing(8)
                .fixedSize(horizontal: false, vertical: true)
                Text(l.poemSource).font(Theme.mincho(11)).foregroundStyle(Theme.inkFaint)
                Text(l.poemMeaning).font(Theme.mincho(13)).lineSpacing(5).foregroundStyle(Theme.inkFaint)
                .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.leading, 14)
            .overlay(alignment: .leading) { Rectangle().fill(Theme.shu).frame(width: 2) }
            Text(l.guideHistory).font(Theme.mincho(14)).lineSpacing(6).fixedSize(horizontal: false, vertical: true)
            Text(l.guideBody).font(Theme.mincho(14)).lineSpacing(6).fixedSize(horizontal: false, vertical: true)
            Text(l.guideExamples).font(Theme.mincho(16, bold: true)).padding(.top, 4)
            ForEach(FixedExamples.all(lang), id: \.ref) { item in
                ExampleCard(example: item.example, lang: lang, verse: FixedExamples.caption(item, lang))
            }
        }
    }
}

/// Launch screen: the mark, the name and the tagline on plain paper, like a book's title page.
/// The mark sits exactly at the centre of the screen, where the system launch screen already shows
/// it, so the app's first moment and the splash are one continuous image. The tagline, then the
/// name, fade in below it: a breath before opening the book rather than a wait.
struct SplashView: View {
    let lang: AppLanguage
    var animated = true
    @State private var stage = 0

    var body: some View {
        let l = L10n(lang: lang)
        let shown = animated ? stage : 2
        // The book is not open yet: no verse line on the page.
        CenterStage(verse: 0) {
            VStack(spacing: 22) {
                Text(l.tagline).font(Theme.mincho(lang == .ja ? 24 : 22, bold: true)).opacity(shown >= 1 ? 1 : 0)
                Text(l.appName).font(Theme.mincho(18)).foregroundStyle(Theme.inkFaint).opacity(shown >= 2 ? 1 : 0)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.paper.ignoresSafeArea())
        .foregroundStyle(Theme.ink)
        .task {
            guard animated else { return }
            try? await Task.sleep(for: .seconds(0.6))
            for next in 1...2 {
                withAnimation(.easeInOut(duration: 1.2)) { stage = next }
                try? await Task.sleep(for: .seconds(1.1))
            }
        }
    }
}
