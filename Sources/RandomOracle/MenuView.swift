import AppKit
import SwiftUI
import UniformTypeIdentifiers

/// "Can't choose from the menu": photograph it, and one dish is picked at random. No limit on redraws.
struct MenuView: View {
    let lang: AppLanguage

    private struct Candidate: Identifiable, Hashable {
        let id = UUID()
        var name: String
        var included = true
    }

    @State private var candidates: [Candidate] = []
    @State private var picked: String?
    @State private var reading = false
    @State private var importing = false
    @State private var error: String?
    @State private var newItem = ""

    var body: some View {
        let l = L10n(lang: lang)
        ScrollView {
            VStack(spacing: 24) {
                if let picked {
                    result(l, picked)
                } else if candidates.isEmpty {
                    empty(l)
                } else {
                    list(l)
                }
                if let error {
                    Text(error).font(Theme.mincho(12)).foregroundStyle(Theme.shu)
                }
            }
            .padding(32)
            .frame(maxWidth: .infinity)
        }
        .scrollContentBackground(.hidden)
        .fileImporter(isPresented: $importing, allowedContentTypes: [.image]) { result in
            if case .success(let url) = result { load(url) }
        }
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            _ = providers.first?.loadObject(ofClass: URL.self) { url, _ in
                if let url { DispatchQueue.main.async { load(url) } }
            }
            return true
        }
    }

    private func empty(_ l: L10n) -> some View {
        VStack(spacing: 28) {
            Spacer(minLength: 40)
            Image(systemName: "menucard").font(.system(size: 54, weight: .ultraLight)).foregroundStyle(Theme.ink)
            Text(l.menuIntro).font(Theme.mincho(15)).multilineTextAlignment(.center).lineSpacing(8)
            if reading {
                ProgressView().controlSize(.small)
                Text(l.menuReading).font(Theme.mincho(12)).foregroundStyle(Theme.inkFaint)
            } else {
                Button(l.menuChoosePhoto) { importing = true }.buttonStyle(InkButtonStyle(filled: true))
                Text(l.menuDropHint).font(Theme.mincho(11)).foregroundStyle(Theme.inkFaint)
            }
        }
    }

    private func list(_ l: L10n) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(l.menuCheck).font(Theme.mincho(14)).lineSpacing(5)
            VStack(alignment: .leading, spacing: 8) {
                ForEach($candidates) { $c in
                    Toggle(isOn: $c.included) {
                        Text(c.name).font(Theme.mincho(15)).foregroundStyle(c.included ? Theme.ink : Theme.inkFaint)
                            .strikethrough(!c.included, color: Theme.inkFaint)
                    }
                    .toggleStyle(.checkbox)
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Rectangle().fill(Color.white.opacity(0.55)))
            HStack {
                TextField(l.menuAdd, text: $newItem).textFieldStyle(.roundedBorder).font(Theme.mincho(13))
                    .onSubmit(addItem)
                Button(l.menuAddButton, action: addItem).buttonStyle(InkButtonStyle())
            }
            HStack {
                Button(l.menuStartOver) { reset() }.buttonStyle(.plain).font(Theme.mincho(12)).foregroundStyle(Theme.inkFaint)
                Spacer()
                Button(l.menuDecide, action: decide).buttonStyle(InkButtonStyle(filled: true))
                    .disabled(!candidates.contains { $0.included })
            }
        }
        .frame(maxWidth: 520)
    }

    private func result(_ l: L10n, _ dish: String) -> some View {
        VStack(spacing: 28) {
            Spacer(minLength: 40)
            Text(l.menuResultLead).font(Theme.mincho(13)).foregroundStyle(Theme.inkFaint)
            Text(dish)
                .font(Theme.mincho(30, bold: true))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40).padding(.vertical, 28)
                .background(Rectangle().fill(Color.white.opacity(0.55)).shadow(color: Theme.ink.opacity(0.12), radius: 6, y: 2))
                .overlay(alignment: .topTrailing) {
                    Rectangle().fill(Theme.shu).frame(width: 6, height: 40).padding(.trailing, 20).offset(y: -8)
                }
            HStack(spacing: 16) {
                Button(l.menuAgain, action: decide).buttonStyle(InkButtonStyle())
                Button(l.menuBack) { picked = nil }.buttonStyle(InkButtonStyle())
            }
        }
    }

    private func load(_ url: URL) {
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        guard let image = NSImage(contentsOf: url)?.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            error = L10n(lang: lang).menuLoadFailed; return
        }
        error = nil
        reading = true
        Task {
            let lines = (try? await MenuPicker.recognizeLines(in: image)) ?? []
            let names = MenuPicker.candidates(from: lines)
            reading = false
            if names.isEmpty { error = L10n(lang: lang).menuNoText }
            candidates = names.map { Candidate(name: $0) }
        }
    }

    private func addItem() {
        let name = newItem.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        candidates.append(Candidate(name: name))
        newItem = ""
    }

    private func decide() {
        picked = MenuPicker.pick(from: candidates.filter(\.included).map(\.name))
        NSHapticFeedbackManager.defaultPerformer.perform(.levelChange, performanceTime: .now)
    }

    private func reset() {
        candidates = []
        picked = nil
        error = nil
    }
}
