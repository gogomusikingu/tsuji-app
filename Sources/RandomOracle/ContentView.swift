import SwiftUI

struct ContentView: View {
    @AppStorage("language") private var language: AppLanguage = .ja
    @StateObject private var journal = Journal()
    @AppStorage("guideSeen") private var guideSeen = false
    @State private var showGuide = false
    private let bible = Bible.bundled()

    var body: some View {
        let l = L10n(lang: language)
        TabView {
            DrawView(bible: bible, journal: journal, lang: language)
                .tabItem { Text(l.tabDraw) }
            RecordsView(journal: journal, lang: language)
                .tabItem { Text(l.tabRecords) }
        }
        .padding()
        .onAppear { if !guideSeen { showGuide = true } }
        .sheet(isPresented: $showGuide) {
            GuideView(lang: language) { guideSeen = true; showGuide = false }
        }
        .toolbar {
            Button { showGuide = true } label: { Image(systemName: "questionmark.circle") }
            Picker("", selection: $language) {
                ForEach(AppLanguage.allCases) { Text($0.label).tag($0) }
            }
            .pickerStyle(.segmented)
        }
    }
}

/// First-run guide: shows that "bending" an unrelated verse to your own dilemma is the whole point.
struct GuideView: View {
    let lang: AppLanguage
    let onClose: () -> Void

    var body: some View {
        let l = L10n(lang: lang)
        VStack(alignment: .leading, spacing: 16) {
            Text(l.guideTitle).font(.title2.weight(.semibold))
            Text(l.guideBody).lineSpacing(5)
            Text(l.guideExamples).font(.headline).padding(.top, 4)
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(FixedExamples.all(lang), id: \.ref) { item in
                        ExampleCard(example: item.example, lang: lang, verse: "\(item.verse)（\(item.ref)）")
                    }
                }
            }
            HStack { Spacer(); Button(l.guideStart, action: onClose).buttonStyle(.borderedProminent).controlSize(.large) }
        }
        .padding(28)
        .frame(width: 560, height: 640)
    }
}
