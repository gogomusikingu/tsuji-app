import SwiftUI

/// Short timestamps shown beside each handwritten line.
enum NoteTime {
    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "M/d HH:mm"
        return f
    }()
    static func short(_ date: Date) -> String { formatter.string(from: date) }
    static func clock(_ date: Date) -> String {
        let f = DateFormatter(); f.locale = Locale(identifier: "en_US_POSIX"); f.dateFormat = "HH:mm"
        return f.string(from: date)
    }
}

extension NoteKind {
    func question(_ l: L10n) -> String {
        switch self {
        case .keyword: "一　\(l.step1)"
        case .interpretation: "二　\(l.step2)"
        case .action: "三　\(l.step3)"
        case .outcome: l.stepOutcome
        }
    }
}

/// "Writings (n) ▾": folded by default so the page stays quiet; opens to the full notes.
struct NotesDisclosure: View {
    let entryID: UUID
    @ObservedObject var journal: Journal
    let lang: AppLanguage
    var kinds: [NoteKind] = NoteKind.allCases
    @State private var expanded = false

    var body: some View {
        let l = L10n(lang: lang)
        let entry = journal.entry(entryID)
        VStack(alignment: .leading, spacing: 14) {
            Button {
                withAnimation(Fade.animation) { expanded.toggle() }
            } label: {
                HStack(spacing: 6) {
                    Text(l.writings(entry?.noteCount ?? 0)).font(Theme.mincho(14))
                    Image(systemName: expanded ? "chevron.up" : "chevron.down").font(.system(size: 10))
                }
                .foregroundStyle(Theme.shu)
            }
            .buttonStyle(.plain)
            if expanded {
                NotesSection(entryID: entryID, journal: journal, lang: lang, kinds: kinds)
                    .transition(.opacity)
            } else if let last = entry?.lastWritten {
                Text(l.lastWritten(NoteTime.short(last))).font(Theme.mincho(11)).foregroundStyle(Theme.inkFaint)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// The questions with everything written under each. Lines can be added at any time and
/// struck through (or restored) by tapping them, but never edited or removed.
struct NotesSection: View {
    let entryID: UUID
    @ObservedObject var journal: Journal
    let lang: AppLanguage
    var kinds: [NoteKind] = NoteKind.allCases
    /// Opens the first question's input right away (used straight after opening the book).
    var openFirst = false

    @State private var writing: NoteKind?
    @State private var draft = ""
    /// The line whose strike-through is being asked about.
    @State private var striking: StrikeTarget?
    @FocusState private var focused: Bool

    var body: some View {
        let l = L10n(lang: lang)
        let entry = journal.entry(entryID)
        VStack(alignment: .leading, spacing: 18) {
            if entry?.noteCount ?? 0 > 0 {
                Text(l.strikeHint).font(Theme.mincho(10)).foregroundStyle(Theme.inkFaint)
            }
            ForEach(kinds, id: \.self) { kind in
                VStack(alignment: .leading, spacing: 8) {
                    Text(kind.question(l)).font(Theme.mincho(14))
                    ForEach(entry?.notes(kind) ?? []) { note in
                        NoteRow(note: note, lang: lang)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                guard striking == nil else { return }
                                striking = StrikeTarget(note: note, kind: kind)
                            }
                    }
                    if writing == kind {
                        HStack(alignment: .bottom, spacing: 8) {
                            TextField(l.writePlaceholder, text: $draft, axis: .vertical)
                                .textFieldStyle(.roundedBorder)
                                .font(Theme.mincho(13))
                                .focused($focused)
                            Button(l.keep) { save(kind) }
                                .buttonStyle(InkButtonStyle())
                                .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                        .padding(.leading, 14)
                    } else {
                        Button(l.write) { open(kind) }
                            .buttonStyle(.plain)
                            .font(Theme.mincho(12))
                            .foregroundStyle(Theme.shu)
                            .padding(.leading, 14)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        // The first question is open from the start, but the keyboard waits for a tap: it must not
        // rise over the verse the moment the page turns.
        .onAppear { if openFirst, writing == nil, let first = kinds.first { open(first, focus: false) } }
        // When the next question appears, open it for writing straight away.
        .onChange(of: kinds) { old, new in if openFirst, new.count > old.count, let last = new.last { open(last) } }
        .fadeCover(item: $striking) { target in
            StrikeSheet(note: target.note, lang: lang) {
                striking = nil
                // Let the question fade away before the line changes underneath it.
                DispatchQueue.main.asyncAfter(deadline: .now() + Fade.duration) {
                    withAnimation(.easeInOut(duration: 1.0)) {
                        journal.toggleStrike(target.note.id, in: target.kind, of: entryID)
                    }
                }
            } onCancel: { striking = nil }
        }
    }

    private func open(_ kind: NoteKind, focus: Bool = true) {
        if let writing, writing != kind, !draft.isEmpty { save(writing) }
        draft = ""
        withAnimation(Fade.animation) { writing = kind }
        if focus { focused = true }
    }

    private func save(_ kind: NoteKind) {
        journal.write(draft, to: kind, of: entryID)
        draft = ""
        withAnimation(Fade.animation) { writing = nil }
    }
}

/// A line picked for striking through or restoring, handed to the confirmation cover.
struct StrikeTarget: Identifiable {
    let note: Note
    let kind: NoteKind
    var id: UUID { note.id }
}

/// One line as it would look in a notebook: struck lines stay readable, and a line that has been
/// struck and restored again and again fades, blurs and sits on a worn, smudged patch of paper.
struct NoteRow: View {
    let note: Note
    let lang: AppLanguage

    /// Strikes and restores it takes for a line to wear away completely.
    static let wearLimit = 50.0

    var body: some View {
        // 0 when freshly written, 1 when worn through. Early changes show a little; the last ones blur it away.
        let f = min(Double(note.wear) / Self.wearLimit, 1)
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(note.text)
                .font(Theme.mincho(13))
                .foregroundStyle(Theme.ink.opacity(1 - 0.9 * pow(f, 0.8)))
                .blur(radius: 4 * pow(f, 1.4))
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
                // The line through it is drawn fresh, so it stays sharp however worn the words are.
                .overlay { if note.isStruck { StrikeLine(text: note.text, seed: note.id, stroke: note.wear) } }
                // The worn patch sits under the words only, not the whole row.
                .background { if note.wear > 0 { Smudge(seed: note.id, amount: f) } }
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(NoteTime.short(note.date))
                .font(Theme.mincho(10).monospacedDigit())
                .foregroundStyle(Theme.inkFaint)
        }
        .padding(.leading, 14)
    }
}

/// A hand-drawn line through the words: unblurred, and never quite straight. Each new strike
/// (a different `stroke` count) lands at a slightly different angle and height, as a pen would.
struct StrikeLine: View {
    let text: String
    let seed: UUID
    let stroke: Int

    var body: some View {
        var rng = SeededRandom(seed, salt: UInt64(stroke))
        let angle = rng.next(-1.2, 1.2), dy = rng.next(-1.5, 1.5), dx = rng.next(-3, 3)
        // Same text with clear ink: only its system strike-through shows, wrapped exactly like the words.
        return Text(text)
            .font(Theme.mincho(13))
            .lineSpacing(3)
            .foregroundStyle(.clear)
            .strikethrough(true, color: Theme.ink.opacity(0.8))
            .fixedSize(horizontal: false, vertical: true)
            .rotationEffect(.degrees(angle))
            .offset(x: dx, y: dy)
            .allowsHitTesting(false)
    }
}

/// A soft, irregular worn patch. Its shape is fixed per line (seeded by the note's id)
/// and it grows darker with every strike or restore (amount 0...1).
struct Smudge: View {
    let seed: UUID
    let amount: Double

    var body: some View {
        Canvas { ctx, size in
            var rng = SeededRandom(seed)
            for _ in 0..<5 {
                let w = size.width * rng.next(0.25, 0.55), h = size.height * rng.next(0.9, 1.6)
                let x = size.width * rng.next(-0.05, 0.85) - w * 0.2, y = size.height * rng.next(-0.3, 0.1)
                ctx.fill(Path(ellipseIn: CGRect(x: x, y: y, width: w, height: h)),
                         with: .color(Color(red: 0.86, green: 0.82, blue: 0.75)))
            }
        }
        .blur(radius: 6)
        .opacity(0.15 + 0.8 * pow(amount, 0.6))
        .padding(.horizontal, -4)
        .allowsHitTesting(false)
    }
}

/// Deterministic random numbers from a UUID, so each smudge keeps its shape between launches.
struct SeededRandom {
    private var state: UInt64
    init(_ id: UUID, salt: UInt64 = 0) {
        let u = id.uuid
        state = ([u.0, u.1, u.2, u.3, u.4, u.5, u.6, u.7].reduce(0) { $0 << 8 | UInt64($1) } ^ (salt &* 0x9E3779B97F4A7C15)) | 1
    }
    mutating func next(_ lo: CGFloat, _ hi: CGFloat) -> CGFloat {
        state ^= state << 13; state ^= state >> 7; state ^= state << 17
        return lo + (hi - lo) * CGFloat(state % 10_000) / 10_000
    }
}

/// The question asked before a line is struck through, or restored.
struct StrikeSheet: View {
    let note: Note
    let lang: AppLanguage
    let onConfirm: () -> Void
    let onCancel: () -> Void

    var body: some View {
        let l = L10n(lang: lang)
        let restoring = note.isStruck
        VStack(alignment: .leading, spacing: 16) {
            Text(restoring ? l.restoreTitle : l.strikeTitle).font(Theme.mincho(17, bold: true))
            Text("「\(note.text)」").font(Theme.mincho(14)).lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
            Text(restoring ? l.restoreBody : l.strikeBody)
                .font(Theme.mincho(12)).foregroundStyle(Theme.inkFaint).lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 12) {
                Button(l.leaveAsIs, action: onCancel).buttonStyle(InkButtonStyle())
                Button(restoring ? l.restore : l.strike, action: onConfirm).buttonStyle(InkButtonStyle(filled: true))
            }
            .padding(.top, 6)
        }
        .padding(28)
        .frame(maxWidth: 420, alignment: .leading)
        .background(Rectangle().fill(Theme.paper).shadow(color: Theme.ink.opacity(0.12), radius: 10, y: 2))
        .padding(24)
        .foregroundStyle(Theme.ink)
    }
}
