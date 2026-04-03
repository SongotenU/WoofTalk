import Foundation

struct BarkClassification: Identifiable, Codable {
    let id = UUID()
    let timestamp: Date
    let className: String  // "bark", "howl", "whine", "silence"
    let confidence: Float

    var isDogSound: Bool {
        className != "silence" && confidence > 0.7
    }
}
