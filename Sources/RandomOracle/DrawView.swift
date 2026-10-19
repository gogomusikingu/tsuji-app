import AppKit
import Combine
import SwiftUI

struct DrawView: View {
    let bible: Bible
    @ObservedObject var journal: Journal
    let lang: AppLanguage

    private enum Phase { case idle, focusing, revealed }

    @State private var phase: Phase = .idle
    @State private var entry: JournalEntry?
    @State private var pageAngle: Double = 90
    @State private var step = 0
    @State private var now = Date()
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
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onReceive(ticker) { now = $0 }
    }

    private func idle(_ l: L10n) -> some View {
        let remaining = cooldown.remaining(now: now)
        return VStack(spacing: 32) {
            Spacer()
            Image(systemName: "book.closed")
                .font(.system(size: 72, weight: .ultraLight))
            Text(l.intro)
                .multilineTextAlignment(.center)
                .lineSpacing(6)
            if remaining > 0 {
                Text(l.nextDraw(Cooldown.format(remaining)))
                    .font(.callout.monospacedDigit())
                    .foregroundStyle(.secondary)
            } else {
                Button(l.openButton, action: begin)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
            }
            Spacer()
            Text(l.disclaimer).font(.footnote).foregroundStyle(.secondary)
        }
    }

    private func focusing(_ l: L10n) -> some View {
        VStack(spacing: 24) {
            Spacer()
            ProgressView()
            Text(l.focusing).foregroundStyle(.secondary)
            Spacer()
        }
    }

    private func revealed(_ l: L10n) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                if let verse = entry?.verse {
                    page(verse)
                        .rotation3DEffect(.degrees(pageAngle), axis: (x: 0, y: 1, z: 0), anchor: .leading, perspective: 0.4)
                        .opacity(pageAngle > 80 ? 0 : 1)
                    if pageAngle == 0 { guide(l) }
                }
            }
            .padding(.horizontal, 4)
        }
    }

    /// The drawn verse, with the surrounding verses shown faintly for context.
    private func page(_ verse: Verse) -> some View {
        let context = bible.context(of: verse, radius: 2)
        return VStack(alignment: .leading, spacing: 10) {
            ForEach(context, id: \.self) { v in
                let isDrawn = v == verse
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("\(v.verse)")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                    Text(v.text(lang))
                        .font(.system(isDrawn ? .title3 : .callout, design: .serif))
                        .fontWeight(isDrawn ? .semibold : .regular)
                        .foregroundStyle(isDrawn ? .primary : .tertiary)
                        .lineSpacing(isDrawn ? 6 : 3)
                        .textSelection(.enabled)
                }
            }
            Text(verse.reference(lang))
                .font(.system(.callout, design: .serif))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 6).fill(Color(nsColor: .textBackgroundColor)).shadow(radius: 3))
    }

    /// Questions shown one at a time. They help the user read meaning in, but never interpret for them.
    private func guide(_ l: L10n) -> some View {
        let steps: [(String, WritableKeyPath<JournalEntry, String>)] = [
            (l.step1, \.keyword), (l.step2, \.interpretation), (l.step3, \.action),
        ]
        return VStack(alignment: .leading, spacing: 14) {
            ForEach(0...step, id: \.self) { i in
                VStack(alignment: .leading, spacing: 6) {
                    Text("\(i + 1). \(steps[i].0)").font(.callout.weight(.medium))
                    TextField(l.optional, text: binding(steps[i].1), axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                }
                .transition(.opacity)
            }
            HStack {
                Spacer()
                if step < steps.count - 1 {
                    Button(l.next) { withAnimation { step += 1 } }
                } else {
                    Text(l.disclaimer).font(.footnote).foregroundStyle(.secondary)
                }
                Button(l.done, action: finish)
            }
            .controlSize(.large)
        }
    }

    private func binding(_ key: WritableKeyPath<JournalEntry, String>) -> Binding<String> {
        Binding(get: { entry?[keyPath: key] ?? "" },
                set: { entry?[keyPath: key] = $0 })
    }

    private func begin() {
        guard cooldown.remaining() == 0 else { return }
        // Commit the draw before revealing it, so quitting mid-way cannot be used to redraw.
        let drawn = JournalEntry(verse: bible.draw())
        cooldown.markDrawn()
        journal.upsert(drawn)
        entry = drawn
        phase = .focusing
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            pageAngle = 90
            step = 0
            phase = .revealed
            NSHapticFeedbackManager.defaultPerformer.perform(.levelChange, performanceTime: .now)
            withAnimation(.easeOut(duration: 1.2)) { pageAngle = 0 }
        }
    }

    private func finish() {
        if let entry { journal.upsert(entry) }
        entry = nil
        now = Date()
        phase = .idle
    }
}
