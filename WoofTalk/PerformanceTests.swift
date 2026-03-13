// MARK: - PerformanceTests

import XCTest
@testable import WoofTalk
import Foundation
import AVFoundation

final class PerformanceTests: XCTestCase {
    
    var translationEngine: TranslationEngine!
    var synthesizer: DogVocalizationSynthesizer!
    var audioEngine: AudioEngine!
    var testPhrases: [String] = []
    
    // Performance benchmarks
    let latencyThreshold: TimeInterval = 2.0 // 2 seconds
    let batteryUsageThreshold: Double = 5.0 // 5% per hour
    
    override func setUp() {
        super.setUp()
        translationEngine = TranslationEngine()
        synthesizer = DogVocalizationSynthesizer()
        audioEngine = AudioEngine()
        
        // Load test phrases
        loadTestPhrases()
    }
    
    override func tearDown() {
        translationEngine = nil
        synthesizer = nil
        audioEngine = nil
        super.tearDown()
    }
    
    // MARK: - Test Data Loading
    
    func loadTestPhrases() {
        // Common phrases (subset for performance testing)
        testPhrases = [
            // Basic commands
            "sit", "stay", "come", "no", "yes", "good", "bad", "stop", "go", "fetch",
            
            // Common phrases
            "hello", "goodbye", "thank you", "you're welcome", "please", "sorry", "excuse me",
            "how are you", "what's up", "nice to meet you", "see you later", "take care",
            
            // Food and treats
            "treat", "food", "water", "bone", "toy", "ball", "stick", "chew", "snack",
            
            // Activities
            "walk", "run", "play", "fetch", "swim", "park", "outside", "inside", "bed",
            
            // Emotions
            "happy", "sad", "angry", "scared", "excited", "tired", "bored", "hungry",
            
            // People
            "mom", "dad", "family", "friend", "person", "human", "dog", "cat", "baby",
            
            // Objects
            "door", "window", "table", "chair", "bed", "couch", "rug", "floor", "wall",
            
            // Time
            "now", "later", "soon", "today", "tomorrow", "yesterday", "morning", "afternoon",
            
            // Weather
            "sun", "moon", "star", "cloud", "rain", "snow", "wind", "storm", "thunder",
            
            // Colors
            "red", "blue", "green", "yellow", "orange", "purple", "pink", "brown", "black",
            
            // Actions
            "eat", "drink", "sleep", "wake", "run", "walk", "jump", "climb", "dig", "bark",
            
            // Questions
            "who", "what", "where", "when", "why", "how", "which", "yes", "no", "maybe",
            
            // Commands
            "sit down", "stand up", "lie down", "roll over", "play dead", "shake hands",
            "high five", "speak", "quiet", "fetch", "drop it", "leave it", "wait", "stay",
            
            // Positive reinforcement
            "good boy", "good girl", "well done", "great job", "excellent", "perfect",
            "amazing", "wonderful", "fantastic", "super", "awesome", "brilliant", "clever",
            
            // Negative reinforcement
            "bad dog", "naughty", "wrong", "incorrect", "mistake", "error", "failure",
            "problem", "issue", "trouble", "danger", "warning", "careful", "watch out",
            
            // Daily routines
            "morning walk", "evening walk", "bedtime", "wake up", "go to sleep",
            "meal time", "play time", "bath time", "training time", "exercise time",
            
            // Locations
            "here", "there", "this", "that", "left", "right", "up", "down", "forward",
            "backward", "inside", "outside", "home", "park", "yard", "garden", "beach",
            
            // Time expressions
            "right now", "in a minute", "in an hour", "in a day", "in a week", "in a month",
            "in a year", "next time", "last time", "this time", "that time", "every time",
            
            // Conditional phrases
            "if", "then", "else", "when", "while", "until", "unless", "because", "since",
            "although", "though", "even if", "as if", "as though", "provided that", "assuming",
            
            // Comparative phrases
            "more", "less", "better", "worse", "faster", "slower", "stronger", "weaker",
            "higher", "lower", "bigger", "smaller", "older", "younger", "taller", "shorter",
            "wider", "narrower", "thicker", "thinner", "heavier", "lighter", "hotter", "colder",
            
            // Superlative phrases
            "best", "worst", "fastest", "slowest", "strongest", "weakest", "highest", "lowest",
            "biggest", "smallest", "oldest", "youngest", "tallest", "shortest", "widest", "narrowest",
            "thickest", "thinnest", "heaviest", "lightest", "hottest", "coldest", "largest", "smallest",
            
            // Quantifiers
            "all", "some", "many", "few", "several", "numerous", "plenty", "enough", "sufficient",
            "insufficient", "too much", "too little", "too many", "too few", "most", "least",
            "majority", "minority", "whole", "part", "portion", "share", "amount", "quantity",
            
            // Logical connectors
            "and", "or", "but", "nor", "for", "so", "yet", "however", "therefore", "thus",
            "consequently", "moreover", "furthermore", "additionally", "besides", "nevertheless",
            "nonetheless", "instead", "alternatively", "otherwise", "meanwhile", "simultaneously",
            
            // Prepositions
            "in", "on", "at", "by", "with", "from", "to", "into", "onto", "through", "across",
            "over", "under", "above", "below", "between", "among", "around", "about", "during",
            "before", "after", "since", "until", "toward", "against", "along", "behind", "in front of",
            "next to", "beside", "near", "close to", "far from", "away from", "out of", "off"
        ]
        
        // Add some longer phrases
        testPhrases.append("let's go for a walk in the park")
        testPhrases.append("do you want to play with your ball")
        testPhrases.append("it's time for dinner, come eat")
        testPhrases.append("good morning, how did you sleep")
        testPhrases.append("I need to go to work now, be a good dog")
        testPhrases.append("who's a good boy, you are, yes you are")
        testPhrases.append("stop barking, it's okay, there's nothing to worry about")
        testPhrases.append("let's play fetch, go get the ball and bring it back")
        testPhrases.append("it's bath time, let's get you cleaned up and smelling fresh")
        testPhrases.append("I love you so much, you're the best dog in the whole world")
    }
    
    // MARK: - Translation Latency Tests
    
    func testTranslationLatency() throws {
        measure(metrics: [XCTClockMetric(), XCTCPUMetric(), XCTMemoryMetric()]) {
            for phrase in testPhrases.shuffled().prefix(100) {
                let startTime = CFAbsoluteTimeGetCurrent()
                
                do {
                    _ = try translationEngine.translateHumanToDog(speechText: phrase)
                    let endTime = CFAbsoluteTimeGetCurrent()
                    let latency = endTime - startTime
                    
                    XCTAssertLessThan(latency, latencyThreshold, 
                                     "Translation latency for '