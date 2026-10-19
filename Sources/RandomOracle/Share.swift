import SwiftUI

/// The image people share: the verse, optionally their own reading, and the app's name.
/// Colours are set explicitly because ImageRenderer does not inherit the app's environment.
struct ShareCard: View {
    let entry: JournalEntry
    let lang: AppLanguage
    var includeReading = true

    var body: some View {
        let l = L10n(lang: lang)
        VStack(alignment: .leading, spacing: 22) {
            Text(entry.verse.text(lang))
                .font(Theme.mincho(20))
                .lineSpacing(10)
                .fixedSize(horizontal: false, vertical: true)
            Text(entry.verse.reference(lang))
                .font(Theme.mincho(11))
                .foregroundStyle(Theme.inkFaint)
                .frame(maxWidth: .infinity, alignment: .trailing)
            if includeReading && entry.hasReading {
                VStack(alignment: .leading, spacing: 10) {
                    if !entry.keyword.isEmpty { row(l.exWords, entry.keyword) }
                    if !entry.interpretation.isEmpty { row(l.exReading, entry.interpretation) }
                    if !entry.action.isEmpty { row(l.exAction, entry.action) }
                    // Only filled in later from the journal, so it appears when sharing from there.
                    if !entry.outcome.isEmpty { row(l.exOutcome, entry.outcome) }
                }
                .padding(.leading, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .overlay(alignment: .leading) { Rectangle().fill(Theme.shu).frame(width: 2) }
            }
            HStack(spacing: 8) {
                TsujiMark().frame(width: 18, height: 18)
                Text("\(l.tagline)｜\(l.appName)").font(Theme.mincho(10)).foregroundStyle(Theme.inkFaint)
            }
            .padding(.top, 6)
        }
        .padding(.horizontal, 32)
        .padding(.top, 52)
        .padding(.bottom, 24)
        .frame(width: 360)
        .background(Theme.paper)
        .overlay(alignment: .topTrailing) {
            Rectangle().fill(Theme.shu).frame(width: 6, height: 44).padding(.trailing, 28)
        }
        .foregroundStyle(Theme.ink)
    }

    private func row(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label).font(Theme.mincho(10)).foregroundStyle(Theme.shu)
            Text(value).font(Theme.mincho(13)).lineSpacing(4).fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @MainActor
    static func image(_ entry: JournalEntry, lang: AppLanguage, includeReading: Bool) -> Image? {
        let renderer = ImageRenderer(content: ShareCard(entry: entry, lang: lang, includeReading: includeReading))
        renderer.scale = 3
        #if os(iOS)
        return renderer.uiImage.map { Image(uiImage: $0) }
        #else
        return renderer.nsImage.map { Image(nsImage: $0) }
        #endif
    }
}

/// Shows the card before sharing so the user sees exactly what leaves the device,
/// and lets them leave their own reading out.
struct ShareSheet: View {
    let entry: JournalEntry
    let lang: AppLanguage
    @State private var includeReading = true
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let l = L10n(lang: lang)
        let image = ShareCard.image(entry, lang: lang, includeReading: includeReading)
        VStack(spacing: 18) {
            Text(l.shareTitle).font(Theme.mincho(16, bold: true))
            if let image {
                image.resizable().scaledToFit()
                    .shadow(color: Theme.ink.opacity(0.15), radius: 6, y: 2)
                    .frame(maxHeight: 460)
            }
            if entry.hasReading {
                Toggle(l.shareIncludeReading, isOn: $includeReading).font(Theme.mincho(13))
            }
            HStack {
                Button(l.cancel) { dismiss() }.buttonStyle(InkButtonStyle())
                Spacer()
                if let image {
                    ShareLink(item: image, preview: SharePreview(l.appName, image: image)) {
                        Label(l.share, systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(InkButtonStyle(filled: true))
                }
            }
        }
        .padding(28)
        #if os(macOS)
        .frame(width: 440)
        #endif
        .background(Theme.paper)
        .foregroundStyle(Theme.ink)
        .tint(Theme.shu)
        .preferredColorScheme(.light)
    }
}
