import Combine
import SwiftUI

struct DrawView: View {
    let bible: Bible
    @ObservedObject var journal: Journal
    let lang: AppLanguage

    private enum Phase { case idle, focusing, revealed }

    @State private var phase: Phase = .idle
    @State private var entryID: UUID?
    @State private var pageAngle: Double = 90
    @State private var step = 0
    @State private var showContext = false
    @State private var showOthers = false
    @State private var now = Date()
    @State private var sharing: JournalEntry?
    private let cooldown = Cooldown()
    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        let l = L10n(lang: lang)
        VStack(spacing: 24) {
            switch phase {
            case .idle: idle(l)
            case .focusing: focusing(l)
            case .revealed: revealed(l)
            }
        }
        .padding(Theme.screenPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onReceive(ticker) { now = $0 }
        .sheet(item: $sharing) { ShareSheet(entry: $0, lang: lang) }
        #if DEBUG
        // Screenshot automation: TSUJI_AUTODRAW=1 opens the book right after launch.
        .onAppear {
            if ProcessInfo.processInfo.environment["TSUJI_AUTODRAW"] == "1", phase == .idle {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { begin() }
            }
        }
        #endif
    }

    /// The entry being written about: the one just drawn, read live from the journal.
    private var entry: JournalEntry? { entryID.flatMap(journal.entry) }

    @ViewBuilder
    private func idle(_ l: L10n) -> some View {
        let remaining = cooldown.remaining(now: now)
        if remaining > 0, let today = journal.entries.first {
            todayPage(today, remaining: remaining, l)
        } else {
            intro(l, remaining: remaining)
        }
    }

    /// While the book is closed for the day: today's verse stays open for going back over it.
    private func todayPage(_ today: JournalEntry, remaining: TimeInterval, _ l: L10n) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text(l.todayVerse(NoteTime.short(today.date)))
                    .font(Theme.mincho(11)).foregroundStyle(Theme.inkFaint)
                VersePage(bible: bible, verse: today.verse, lang: lang, showContext: $showContext)
                NotesDisclosure(entryID: today.id, journal: journal, lang: lang)
                HStack {
                    Button { sharing = journal.entry(today.id) } label: { Label(l.share, systemImage: "square.and.arrow.up") }
                        .buttonStyle(.plain).font(Theme.mincho(13)).foregroundStyle(Theme.shu)
                    Spacer()
                }
                Text(l.nextDraw(Cooldown.format(remaining)))
                    .font(Theme.mincho(12).monospacedDigit())
                    .foregroundStyle(Theme.inkFaint)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 12)
            }
            .padding(8)
        }
        .scrollContentBackground(.hidden)
    }

    private func intro(_ l: L10n, remaining: TimeInterval) -> some View {
        VStack(spacing: 36) {
            Spacer()
            TsujiMark().frame(width: 120, height: 120)
            Text(l.intro)
                .font(Theme.mincho(16))
                .multilineTextAlignment(.center)
                .lineSpacing(10)
            if remaining > 0 {
                Text(l.nextDraw(Cooldown.format(remaining)))
                    .font(Theme.mincho(13).monospacedDigit())
                    .foregroundStyle(Theme.inkFaint)
            } else {
                Button(l.openButton, action: begin).buttonStyle(InkButtonStyle(filled: true))
            }
            Spacer()
            Text(l.disclaimer).font(Theme.mincho(11)).foregroundStyle(Theme.inkFaint)
        }
    }

    private func focusing(_ l: L10n) -> some View {
        VStack(spacing: 28) {
            Spacer()
            TsujiMark().frame(width: 80, height: 80).opacity(0.5)
            Text(l.focusing).font(Theme.mincho(15)).foregroundStyle(Theme.inkFaint)
            Spacer()
        }
    }

    private func revealed(_ l: L10n) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                if let verse = entry?.verse {
                    VersePage(bible: bible, verse: verse, lang: lang, showContext: $showContext)
                        .rotation3DEffect(.degrees(pageAngle), axis: (x: 0, y: 1, z: 0), anchor: .leading, perspective: 0.4)
                        .opacity(pageAngle > 80 ? 0 : 1)
                    if pageAngle == 0 {
                        guide(l)
                            Rectangle().fill(Theme.ink.opacity(0.12)).frame(height: 1)
                        others(l)
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
        }
        .scrollContentBackground(.hidden)
    }

    /// Sample readings of other verses, shown only when the user asks for them.
    private func others(_ l: L10n) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if showOthers {
                Text(l.othersCaption).font(Theme.mincho(11)).foregroundStyle(Theme.inkFaint)
                ForEach(FixedExamples.all(lang), id: \.ref) { item in
                    ExampleCard(example: item.example, lang: lang, verse: FixedExamples.caption(item, lang))
                }
            } else {
                Button(l.showOthers) { withAnimation { showOthers = true } }
                    .buttonStyle(.plain).font(Theme.mincho(13)).foregroundStyle(Theme.shu)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Questions shown one at a time. They help the user read meaning in, but never interpret for them.
    /// Each can be written under as often as wanted, now or later in the day.
    private func guide(_ l: L10n) -> some View {
        let steps: [NoteKind] = [.keyword, .interpretation, .action]
        return VStack(alignment: .leading, spacing: 14) {
            if let entryID {
                NotesSection(entryID: entryID, journal: journal, lang: lang,
                             kinds: Array(steps.prefix(step + 1)), openFirst: true)
            }
            HStack {
                Button { sharing = entry } label: { Label(l.share, systemImage: "square.and.arrow.up") }
                    .buttonStyle(.plain).font(Theme.mincho(13)).foregroundStyle(Theme.shu)
                Spacer()
                if step < steps.count - 1 {
                    Button(l.next) { withAnimation { step += 1 } }.buttonStyle(InkButtonStyle())
                }
                Button(l.done, action: finish).buttonStyle(InkButtonStyle(filled: true))
            }
            if step == steps.count - 1 {
                Text(l.disclaimer).font(Theme.mincho(11)).foregroundStyle(Theme.inkFaint)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }

    private func begin() {
        guard cooldown.remaining() == 0 else { return }
        // Commit the draw before revealing it, so quitting mid-way cannot be used to redraw.
        let drawn = JournalEntry(verse: bible.draw())
        cooldown.markDrawn()
        journal.upsert(drawn)
        entryID = drawn.id
        phase = .focusing
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            pageAngle = 90
            step = 0
            showContext = false
            showOthers = false
            phase = .revealed
            Platform.haptic()
            withAnimation(.easeOut(duration: 1.2)) { pageAngle = 0 }
        }
    }

    private func finish() {
        if let entry { Followup.schedule(for: entry, lang: lang) }
        entryID = nil
        showContext = false
        now = Date()
        phase = .idle
    }
}

struct ExampleCard: View {
    let example: ReadingExample
    let lang: AppLanguage
    var verse: String? = nil

    var body: some View {
        let l = L10n(lang: lang)
        VStack(alignment: .leading, spacing: 6) {
            if let verse { Text(verse).font(Theme.verse(13)).lineSpacing(4).fixedSize(horizontal: false, vertical: true).padding(.bottom, 4) }
            row(l.exWorry, example.worry)
            row(l.exWords, example.words)
            row(l.exReading, example.reading)
            row(l.exAction, example.action)
        }
        .font(Theme.mincho(12))
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Rectangle().fill(Theme.paperDeep.opacity(0.6)))
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label).foregroundStyle(Theme.shu).frame(width: 100, alignment: .leading)
            Text(value).lineSpacing(3).fixedSize(horizontal: false, vertical: true).textSelection(.enabled)
        }
    }
}

/// The drawn verse alone; surrounding verses appear faintly only when asked for.
/// A vermilion bookmark ribbon marks the page the book fell open at.
struct VersePage: View {
    let bible: Bible
    let verse: Verse
    let lang: AppLanguage
    @Binding var showContext: Bool

var body: some View {
    let l = L10n(lang: lang)
    let shown = showContext ? bible.context(of: verse, radius: 2) : [verse]
    return VStack(alignment: .leading, spacing: 14) {
        ForEach(shown, id: \.self) { v in
            let isDrawn = v == verse
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                if showContext {
                    Text("\(v.verse)").font(Theme.mincho(10)).foregroundStyle(Theme.inkFaint)
                }
                Text(v.text(lang))
                    .font(Theme.verse(isDrawn ? 21 : 13))
                    .foregroundStyle(isDrawn ? Theme.ink : Theme.inkFaint)
                    .lineSpacing(isDrawn ? 12 : 4)
                    .textSelection(.enabled)
            }
        }
        HStack {
            Button(showContext ? l.hideContext : l.showContext) { withAnimation { showContext.toggle() } }
                .buttonStyle(.plain)
                .font(Theme.mincho(11))
                .foregroundStyle(Theme.shu)
            Spacer()
            Text(verse.reference(lang)).font(Theme.mincho(12)).foregroundStyle(Theme.inkFaint)
        }
        .padding(.top, 6)
    }
    .padding(.horizontal, 40)
    .padding(.top, 48)
    .padding(.bottom, 28)
    .frame(maxWidth: .infinity)
    .background(
        Rectangle().fill(Color.white.opacity(0.55))
            .shadow(color: Theme.ink.opacity(0.12), radius: 6, y: 2)
    )
    .overlay(alignment: .topTrailing) {
        Rectangle().fill(Theme.shu).frame(width: 6, height: 54).padding(.trailing, 36).offset(y: -8)
    }
}
}
