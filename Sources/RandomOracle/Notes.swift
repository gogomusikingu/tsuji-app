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
                withAnimation(.easeInOut(duration: 0.25)) { expanded.toggle() }
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
    @State private var striking: (note: Note, kind: NoteKind)?
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
                            .onTapGesture { striking = (note, kind) }
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
        .onAppear { if openFirst, writing == nil, let first = kinds.first { open(first) } }
        // When the next question appears, open it for writing straight away.
        .onChange(of: kinds) { old, new in if openFirst, new.count > old.count, let last = new.last { open(last) } }
        .sheet(isPresented: Binding(get: { striking != nil }, set: { if !$0 { striking = nil } })) {
            if let striking {
                StrikeSheet(note: striking.note, lang: lang) {
                    journal.toggleStrike(striking.note.id, in: striking.kind, of: entryID)
                    self.striking = nil
                } onCancel: { self.striking = nil }
            }
        }
    }

    private func open(_ kind: NoteKind) {
        if let writing, writing != kind, !draft.isEmpty { save(writing) }
        draft = ""
        withAnimation { writing = kind }
        focused = true
    }

    private func save(_ kind: NoteKind) {
        journal.write(draft, to: kind, of: entryID)
        draft = ""
        withAnimation { writing = nil }
    }
}

/// One line as it would look in a notebook: struck lines stay readable, and a line that has been
/// struck and restored again and again fades, blurs and sits on a worn, smudged patch of paper.
struct NoteRow: View {
    let note: Note
    let lang: AppLanguage

    var body: some View {
        let wear = CGFloat(note.wear)
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(note.text)
                .font(Theme.mincho(13))
                .strikethrough(note.isStruck, color: Theme.ink.opacity(0.7))
                .foregroundStyle(Theme.ink.opacity(max(1 - 0.09 * wear, 0.5)))
                .blur(radius: min(0.1 * wear, 0.5))
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background { if note.wear > 0 { Smudge(seed: note.id, wear: note.wear) } }
            VStack(alignment: .trailing, spacing: 2) {
                Text(NoteTime.short(note.date))
                if note.isStruck, let last = note.strikes.last {
                    Text(L10n(lang: lang).struckAt(NoteTime.short(last)))
                }
            }
            .font(Theme.mincho(10).monospacedDigit())
            .foregroundStyle(Theme.inkFaint)
        }
        .padding(.leading, 14)
    }
}

/// A soft, irregular worn patch. Its shape is fixed per line (seeded by the note's id)
/// and it grows darker with every strike or restore.
struct Smudge: View {
    let seed: UUID
    let wear: Int

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
        .blur(radius: 7)
        .opacity(min(0.22 * Double(wear), 0.95))
        .padding(.horizontal, -8)
        .allowsHitTesting(false)
    }
}

/// Deterministic random numbers from a UUID, so each smudge keeps its shape between launches.
struct SeededRandom {
    private var state: UInt64
    init(_ id: UUID) {
        let u = id.uuid
        state = [u.0, u.1, u.2, u.3, u.4, u.5, u.6, u.7].reduce(0) { $0 << 8 | UInt64($1) } | 1
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
        .frame(maxWidth: .infinity, alignment: .leading)
        #if os(iOS)
        .presentationDetents([.height(320)])
        #else
        .frame(width: 420)
        #endif
        .background(Theme.paper)
        .foregroundStyle(Theme.ink)
        .preferredColorScheme(.light)
    }
}
