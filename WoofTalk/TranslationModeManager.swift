// MARK: - TranslationModeManager

import Foundation

/// Manages translation mode switching between AI and rule-based translation
final class TranslationModeManager: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Current translation mode
    @Published private(set) var currentMode: TranslationMode = .ruleBased
    
    /// Whether AI model is loaded and ready
    @Published private(set) var isAIReady: Bool = false
    
    /// Last error that occurred
    @Published private(set) var lastError: Error?
    
    // MARK: - Dependencies
    
    private let aiService: AITranslationServiceProtocol
    
    // MARK: - Initialization
    
    init(aiService: AITranslationServiceProtocol = AITranslationService.shared) {
        self.aiService = aiService
    }
    
    // MARK: - Public Methods
    
    /// Switch to AI translation mode
    func enableAIMode() async {
        do {
            if !aiService.isModelAvailable {
                try await aiService.loadModel()
            }
            await MainActor.run {
                self.currentMode = .ai
                self.isAIReady = true
                self.lastError = nil
            }
        } catch {
            await MainActor.run {
                self.lastError = error
                self.isAIReady = false
                // Fall back to rule-based on error
                self.currentMode = .ruleBased
            }
        }
    }
    
    /// Switch to rule-based translation mode
    func enableRuleBasedMode() {
        currentMode = .ruleBased
        lastError = nil
    }
    
    /// Toggle between translation modes
    func toggleMode() async {
        if currentMode == .ai {
            enableRuleBasedMode()
        } else {
            await enableAIMode()
        }
    }
    
    /// Translate using the current mode
    func translate(input: String, direction: TranslationDirection) async throws -> TranslationResult {
        switch currentMode {
        case .ai:
            let result = try await aiService.translate(input: input, direction: direction)
            return TranslationResult(
                text: result.translatedText,
                mode: .ai,
                qualityScore: result.qualityScore,
                inferenceTime: result.inferenceTime
            )
            
        case .ruleBased:
            let fallbackText = aiService.fallbackTranslate(input: input, direction: direction)
            return TranslationResult(
                text: fallbackText,
                mode: .ruleBased,
                qualityScore: nil,
                inferenceTime: nil
            )
        }
    }
    
    func initialize() async {
        if currentMode == .ai {
            await enableAIMode()
        }
    }
}

enum TranslationMode: String, CaseIterable {
    case ai = "AI"
    case ruleBased = "Rule-Based"
    case auto = "Auto"
    
    var displayName: String {
        switch self {
        case .ai: return "AI Translation"
        case .ruleBased: return "Rule-Based"
        case .auto: return "Auto"
        }
    }
    
    var description: String {
        switch self {
        case .ai: return "Contextual translations using AI"
        case .ruleBased: return "Traditional translation engine"
        case .auto: return "Automatic mode selection"
        }
    }
}

struct TranslationResult {
    let text: String
    let mode: TranslationMode
    let qualityScore: TranslationQualityScore?
    let inferenceTime: TimeInterval?
    
    var hasQualityScore: Bool {
        qualityScore != nil
    }
}