import CoreGraphics
import Foundation
import Vision

/// Menu feature: read the text on a photo of a menu, keep the lines that look like dishes,
/// and pick one at random. Everything runs on-device.
enum MenuPicker {
    /// Recognises text lines in the image, top to bottom.
    static func recognizeLines(in image: CGImage) async throws -> [String] {
        try await withCheckedThrowingContinuation { cont in
            let request = VNRecognizeTextRequest { req, error in
                if let error { cont.resume(throwing: error); return }
                let lines = (req.results as? [VNRecognizedTextObservation] ?? [])
                    .compactMap { $0.topCandidates(1).first?.string }
                cont.resume(returning: lines)
            }
            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["ja-JP", "en-US"]
            request.usesLanguageCorrection = true
            do {
                try VNImageRequestHandler(cgImage: image).perform([request])
            } catch {
                cont.resume(throwing: error)
            }
        }
    }

    /// Turns raw OCR lines into dish candidates: prices and noise removed, duplicates dropped.
    static func candidates(from lines: [String]) -> [String] {
        var seen = Set<String>()
        return lines.compactMap { raw in
            var line = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            // Strip prices such as "¥980", "980円", "1,200 yen", "$12.50", "（税込）".
            for pattern in [#"[¥￥$]\s*[\d,.]+"#, #"[\d,.]+\s*(円|yen|YEN)"#, #"[（(]\s*税[込抜別][^）)]*[）)]"#] {
                line = line.replacingOccurrences(of: pattern, with: "", options: .regularExpression)
            }
            // Trim leftover separators but keep brackets, e.g. "餃子（6個）".
            line = line.trimmingCharacters(in: CharacterSet.whitespaces.union(CharacterSet(charactersIn: "・.…‥:：-—–_*※/|,、。")))
            // Drop what is left of leader dots and bare numbers.
            line = line.replacingOccurrences(of: #"[・.…‥]{2,}.*$"#, with: "", options: .regularExpression)
                .trimmingCharacters(in: .whitespaces)
            guard line.count >= 2, line.count <= 30,
                  line.contains(where: { $0.isLetter }),
                  !seen.contains(line) else { return nil }
            seen.insert(line)
            return line
        }
    }

    static func pick(from items: [String]) -> String? {
        var rng = SystemRandomNumberGenerator()
        return items.randomElement(using: &rng)
    }
}
