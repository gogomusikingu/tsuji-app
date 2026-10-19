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
        VStack(spacing: 20) {
            if let verse = entry?.verse {
                VStack(spacing: 16) {
                    Text(verse.text(lang))
                        .font(.system(.title2, design: .serif))
                        .multilineTextAlignment(.center)
                        .lineSpacing(8)
                        .textSelection(.enabled)
                    Text(verse.reference(lang))
                        .font(.system(.callout, design: .serif))
                        .foregroundStyle(.secondary)
                }
                .padding(28)
                .frame(maxWidth: .infinity)
                .background(RoundedRectangle(cornerRadius: 6).fill(Color(nsColor: .textBackgroundColor)).shadow(radius: 3))
                .rotation3DEffect(.degrees(pageAngle), axis: (x: 0, y: 1, z: 0), anchor: .leading, perspective: 0.4)
                .opacity(pageAngle > 80 ? 0 : 1)

                Text(l.prompt)
                    .font(.callout)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)

                Form {
                    TextField(l.interpretation, text: binding(\.interpretation), axis: .vertical)
                    TextField(l.action, text: binding(\.action), axis: .vertical)
                }
                .formStyle(.grouped)

                Button(l.done, action: finish).controlSize(.large)
            }
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
