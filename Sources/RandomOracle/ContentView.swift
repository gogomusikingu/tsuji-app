import SwiftUI

struct ContentView: View {
    @AppStorage("language") private var language: AppLanguage = .ja
    @StateObject private var journal = Journal()
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
        .toolbar {
            Picker("", selection: $language) {
                ForEach(AppLanguage.allCases) { Text($0.label).tag($0) }
            }
            .pickerStyle(.segmented)
        }
    }
}
