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
    /// 0: silence, 1: "close your eyes…", 2: "the book opens."
    @State private var focusStage = 0
    @State private var breathe = false
    @State private var step = 0
    @State private var showContext = false
    @State private var showOthers = false
    @State private var now = Date()
    @State private var sharing: JournalEntry?
    @State private var showShare = false
    /// Today's verse stays folded away behind a button until the user chooses to open it again.
    @State private var showToday = false
    private let cooldown = Cooldown()
    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        let l = L10n(lang: lang)
        // Each stage dissolves into the next.
        ZStack {
            switch phase {
            case .idle: idle(l).transition(.opacity)
            case .focusing: focusing(l).transition(.opacity)
            case .revealed: revealed(l).transition(.opacity)
            }
        }
        .padding(Theme.screenPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onReceive(ticker) { now = $0 }
        .fadeCover(isPresented: $showShare) {
            if let sharing { ShareSheet(entry: sharing, lang: lang) { showShare = false } }
        }
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
        ZStack {
            if remaining > 0, let today = journal.entries.first {
                if showToday {
                    todayPage(today, remaining: remaining, l).transition(.opacity)
                } else {
                    closedHome(remaining: remaining, l).transition(.opacity)
                }
            } else {
                intro(l, remaining: remaining).transition(.opacity)
            }
        }
    }

    /// The book is closed for today; today's verse can be opened again from here.
    private func closedHome(remaining: TimeInterval, _ l: L10n) -> some View {
        VStack(spacing: 36) {
            Spacer()
            TsujiMark(tight: true).frame(width: 150, height: 150)
            Text(l.todayAlreadyOpen)
                .font(Theme.mincho(16))
                .multilineTextAlignment(.center)
                .lineSpacing(10)
            Button(l.openToday) { withAnimation(Fade.animation) { showToday = true } }
                .buttonStyle(InkButtonStyle())
            Text(l.nextDraw(Cooldown.format(remaining)))
                .font(Theme.mincho(13).monospacedDigit())
                .foregroundStyle(Theme.inkFaint)
            Spacer()
            Text(l.disclaimer).font(Theme.mincho(11)).foregroundStyle(Theme.inkFaint)
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
                    Button { share(journal.entry(today.id)) } label: { Label(l.share, systemImage: "square.and.arrow.up") }
                        .buttonStyle(.plain).font(Theme.mincho(13)).foregroundStyle(Theme.shu)
                    Spacer()
                    Button(l.done) { withAnimation(Fade.animation) { showToday = false } }
                        .buttonStyle(InkButtonStyle())
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
            TsujiMark(tight: true).frame(width: 150, height: 150)
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
            // The mark breathes slowly while the user holds the dilemma in mind.
            TsujiMark(tight: true).frame(width: 110, height: 110)
                .opacity(breathe ? 0.75 : 0.35)
                .scaleEffect(breathe ? 1.04 : 0.96)
                .animation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true), value: breathe)
                .onAppear { breathe = true }
                .onDisappear { breathe = false }
            ZStack {
                Text(l.focusing).opacity(focusStage == 1 ? 1 : 0)
                Text(l.focusingOpen).opacity(focusStage == 2 ? 1 : 0)
            }
            .font(Theme.mincho(15)).foregroundStyle(Theme.inkFaint)
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
                Button { share(entry) } label: { Label(l.share, systemImage: "square.and.arrow.up") }
                    .buttonStyle(.plain).font(Theme.mincho(13)).foregroundStyle(Theme.shu)
                Spacer()
                if step < steps.count - 1 {
                    Button(l.next) { withAnimation(Fade.animation) { step += 1 } }.buttonStyle(InkButtonStyle())
                }
                Button(l.done, action: finish).buttonStyle(InkButtonStyle(filled: true))
            }
            if step == steps.count - 1 {
                Text(l.disclaimer).font(Theme.mincho(11)).foregroundStyle(Theme.inkFaint)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }

    private func share(_ e: JournalEntry?) {
        guard let e else { return }
        sharing = e
        showShare = true
    }

    private func begin() {
        guard cooldown.remaining() == 0 else { return }
        // Commit the draw before revealing it, so quitting mid-way cannot be used to redraw.
        let drawn = JournalEntry(verse: bible.draw())
        cooldown.markDrawn()
        journal.upsert(drawn)
        entryID = drawn.id
        focusStage = 0
        withAnimation(Fade.animation) { phase = .focusing }
        // About six seconds of quiet before the page turns: words surface one at a time.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { withAnimation(.easeInOut(duration: 1.2)) { focusStage = 1 } }
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) { withAnimation(.easeInOut(duration: 1.2)) { focusStage = 2 } }
        DispatchQueue.main.asyncAfter(deadline: .now() + 6.5) {
            pageAngle = 90
            step = 0
            showContext = false
            showOthers = false
            withAnimation(Fade.animation) { phase = .revealed }
            Platform.haptic()
            withAnimation(.easeOut(duration: 1.2).delay(0.3)) { pageAngle = 0 }
        }
    }

    private func finish() {
        if let entry { Followup.schedule(for: entry, lang: lang) }
        entryID = nil
        showContext = false
        showToday = false
        now = Date()
        withAnimation(Fade.animation) { phase = .idle }
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
