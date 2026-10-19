import SwiftUI

struct ContentView: View {
    @AppStorage("language") private var language: AppLanguage = .ja
    @AppStorage("guideSeen") private var guideSeen = false
    @StateObject private var journal = Journal()
    @State private var showGuide = false
    @State private var tab: Tab = .draw
    @State private var showSplash = true
    private let bible = Bible.bundled()

    enum Tab { case draw, menu, records }

    var body: some View {
        let l = L10n(lang: language)
        VStack(spacing: 0) {
            header(l)
            Rectangle().fill(Theme.ink.opacity(0.15)).frame(height: 1)
            #if os(iOS)
            // iPhone: the familiar bottom tab bar.
            TabView(selection: $tab) {
                page(.draw).tabItem { Label(l.tabDraw, systemImage: "book") }.tag(Tab.draw)
                page(.menu).tabItem { Label(l.tabMenu, systemImage: "menucard") }.tag(Tab.menu)
                page(.records).tabItem { Label(l.tabRecords, systemImage: "list.bullet") }.tag(Tab.records)
            }
            #else
            page(tab)
            #endif
        }
        .background(Theme.paper)
        .foregroundStyle(Theme.ink)
        .tint(Theme.shu)
        .preferredColorScheme(.light)
        .overlay {
            if showSplash {
                SplashView(lang: language).transition(.opacity)
            }
        }
        .onAppear {
            // Show the name and mark briefly, then reveal the app (and the guide on first run).
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                withAnimation(.easeOut(duration: 0.6)) { showSplash = false }
                if !guideSeen {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { showGuide = true }
                }
            }
        }
        .sheet(isPresented: $showGuide) {
            GuideView(lang: language) { guideSeen = true; showGuide = false }
        }
    }

    private func page(_ target: Tab) -> some View {
        Group {
            switch target {
            case .draw: DrawView(bible: bible, journal: journal, lang: language)
            case .menu: MenuView(lang: language)
            case .records: RecordsView(journal: journal, lang: language)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.paper)
        #if os(iOS)
        .toolbarBackground(Theme.paper, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        #endif
    }

    private func header(_ l: L10n) -> some View {
        HStack(spacing: 14) {
            TsujiMark().frame(width: 30, height: 30)
            VStack(alignment: .leading, spacing: 2) {
                // The tagline leads: it says what the app does; the name alone would not.
                Text(l.tagline).font(Theme.mincho(15, bold: true)).lineLimit(1).minimumScaleFactor(0.8)
                Text(l.appName).font(Theme.mincho(11)).foregroundStyle(Theme.inkFaint)
            }
            Spacer()
            #if os(macOS)
            tabButton(l.tabDraw, .draw)
            tabButton(l.tabMenu, .menu)
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
        Button(title) { tab = target }
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
struct SplashView: View {
    let lang: AppLanguage

    var body: some View {
        let l = L10n(lang: lang)
        VStack(spacing: 28) {
            Spacer()
            TsujiMark().frame(width: 132, height: 132)
            Text(l.tagline).font(Theme.mincho(lang == .ja ? 24 : 22, bold: true))
            Text(l.appName).font(Theme.mincho(18)).foregroundStyle(Theme.inkFaint)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.paper)
        .foregroundStyle(Theme.ink)
    }
}
