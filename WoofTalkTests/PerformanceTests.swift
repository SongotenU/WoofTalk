// MARK: - PerformanceTests

import XCTest
@testable import WoofTalk
import Foundation

final class PerformanceTests: XCTestCase {
    
    var translationEngine: TranslationEngine!
    var testPhrases: [String] = []
    var startTime: CFAbsoluteTime = 0
    var latencyResults: [Double] = []
    var batteryUsage: Double = 0
    
    override func setUpWithError() throws {
        translationEngine = TranslationEngine()
        setupTestVocabulary()
        startTime = CFAbsoluteTimeGetCurrent()
        latencyResults.removeAll()
        batteryUsage = 0
    }
    
    override func tearDownWithError() throws {
        translationEngine = nil
        let endTime = CFAbsoluteTimeGetCurrent()
        let totalDuration = endTime - startTime
        
        print("\n=== Performance Test Results ===")
        print("Total test duration: \(String(format: "%.2f", totalDuration)) seconds")
        print("Number of translation requests: \(latencyResults.count)")
        
        if !latencyResults.isEmpty {
            let avgLatency = latencyResults.reduce(0, +) / Double(latencyResults.count)
            let maxLatency = latencyResults.max() ?? 0
            let minLatency = latencyResults.min() ?? 0
            
            print("Average latency: \(String(format: "%.2f", avgLatency)) seconds")
            print("Max latency: \(String(format: "%.2f", maxLatency)) seconds")
            print("Min latency: \(String(format: "%.2f", minLatency)) seconds")
            print("Latency >2s: \(latencyResults.filter { $0 > 2.0 }.count) requests")
            print("Latency >1s: \(latencyResults.filter { $0 > 1.0 }.count) requests")
            print("Latency <0.5s: \(latencyResults.filter { $0 < 0.5 }.count) requests")
        }
        
        print("Estimated battery usage: \(String(format: "%.1f", batteryUsage))%")
        print("Battery usage per hour: \(String(format: "%.1f", batteryUsage / (totalDuration / 3600)))%")
        print("=============================\n")
    }
    
    // MARK: - Test Vocabulary Setup
    
    func setupTestVocabulary() {
        // Common phrases for performance testing (subset of accuracy tests)
        testPhrases = [
            "hello", "sit", "stay", "come", "good boy", "good girl",
            "walk", "play", "treat", "ball", "outside", "inside",
            "bed", "car", "park", "vet", "food", "water", "bath",
            "groom", "leash", "crate", "quiet", "down", "up", "wait",
            "no", "yes", "okay", "hungry", "thirsty", "tired", "happy",
            "sad", "scared", "excited", "bored", "angry", "curious", "interested",
            "love", "friend", "family", "home", "safe", "danger", "help",
            "hurt", "sick", "healthy", "clean", "dirty", "hot", "cold",
            "warm", "cool", "wet", "dry", "soft", "hard", "smooth", "rough",
            "big", "small", "tall", "short", "fast", "slow", "loud", "quiet",
            "bright", "dark", "light", "heavy", "lightweight", "strong", "weak",
            "young", "old", "new", "fresh", "stale", "sweet", "sour", "bitter", "salty",
            "spicy", "bland", "delicious", "yucky", "tasty", "gross", "yummy", "icky",
            "run", "jump", "fetch", "roll", "bark", "howl", "whine", "growl", "pant", "sniff", "lick",
            "bite", "chew", "dig", "scratch", "shake", "wag", "tail", "ear", "nose", "eye", "mouth", "paw",
            "fur", "hair", "skin", "bone", "meat", "vegetable", "fruit", "grain", "dairy", "protein", "carb",
            "fat", "vitamin", "mineral", "nutrient", "calorie", "energy", "exercise", "rest", "sleep", "dream",
            "playtime", "training", "command", "trick", "behavior", "habit", "routine", "schedule", "time", "day", "night",
            "morning", "afternoon", "evening", "weekend", "weekday", "holiday", "birthday", "celebration", "party", "fun", "game",
            "sport", "activity", "hobby", "interest", "passion", "talent", "skill", "ability", "strength", "weakness", "challenge", "opportunity",
            "problem", "solution", "idea", "thought", "concept", "theory", "fact", "truth", "lie", "false", "true", "right", "wrong", "correct", "incorrect", "good", "bad", "better", "worse", "best", "worst", "first", "last", "next", "previous", "current", "past", "present", "future", "before", "after", "during", "while", "when", "where", "why", "how", "what", "who", "which", "whom", "whose", "this", "that", "these", "those", "here", "there", "everywhere", "somewhere", "anywhere", "nowhere", "all", "some", "none", "many", "few", "several", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten", "hundred", "thousand", "million", "billion", "trillion", "dozen", "score", "pair", "couple", "group", "team", "family", "community", "society", "world", "universe", "galaxy", "planet", "star", "moon", "sun", "earth", "ocean", "sea", "lake", "river", "stream", "pond", "waterfall", "wave", "tide", "current", "depth", "height", "width", "length", "area", "volume", "mass", "weight", "density", "temperature", "pressure", "speed", "velocity", "acceleration", "force", "energy", "power", "work", "heat", "light", "sound", "electricity", "magnetism", "gravity", "friction", "motion", "rest", "balance", "equilibrium", "stability", "change", "growth", "decay", "birth", "death", "life", "death", "alive", "dead", "living", "nonliving", "organic", "inorganic", "natural", "artificial", "synthetic", "real", "virtual", "physical", "digital", "analog", "digital", "binary", "decimal", "hexadecimal", "octal", "base", "number", "numeral", "digit", "integer", "float", "double", "boolean", "character", "string", "array", "list", "set", "map", "dictionary", "object", "class", "instance", "method", "function", "procedure", "routine", "subroutine", "macro", "script", "program", "software", "hardware", "firmware", "middleware", "database", "storage", "memory", "cache", "buffer", "queue", "stack", "heap", "tree", "graph", "network", "internet", "web", "browser", "server", "client", "host", "node", "endpoint", "gateway", "firewall", "router", "switch", "hub", "modem", "antenna", "cable", "fiber", "wireless", "radio", "microwave", "infrared", "ultraviolet", "xray", "gamma", "radiation", "particle", "wave", "field", "force", "energy", "matter", "antimatter", "dark", "light", "visible", "invisible", "transparent", "opaque", "reflective", "absorptive", "transmissive", "conductive", "insulative", "magnetic", "electric", "electronic", "mechanical", "thermal", "chemical", "biological", "physical", "chemical", "biological", "psychological", "sociological", "anthropological", "historical", "geographical", "astronomical", "geological", "meteorological", "oceanographic", "ecological", "environmental", "economic", "political", "social", "cultural", "religious", "philosophical", "ethical", "moral", "legal", "illegal", "right", "wrong", "good", "evil", "just", "unjust", "fair", "unfair", "equal", "unequal", "free", "unfree", "independent", "dependent", "autonomous", "heteronomous", "self", "other", "same", "different", "similar", "dissimilar", "like", "unlike", "equal", "unequal", "greater", "lesser", "more", "less", "most", "least", "best", "worst", "first", "last", "next", "previous", "current", "past", "present", "future", "before", "after", "during", "while", "when", "where", "why", "how", "what", "who", "which", "whom", "whose", "this", "that", "these", "those", "here", "there", "everywhere", "somewhere", "anywhere", "nowhere", "all", "some", "none", "many", "few", "several", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten", "hundred", "thousand", "million", "billion", "trillion", "dozen", "score", "pair", "couple", "group", "team", "family", "community", "society", "world", "universe", "galaxy", "planet", "star", "moon", "sun", "earth", "ocean", "sea", "lake", "river", "stream", "pond", "waterfall", "wave", "tide", "current", "depth", "height", "width", "length", "area", "volume", "mass", "weight", "density", "temperature", "pressure", "speed", "velocity", "acceleration", "force", "energy", "power", "work", "heat", "light", "sound", "electricity", "magnetism", "gravity", "friction", "motion", "rest", "balance", "equilibrium", "stability", "change", "growth", "decay", "birth", "death", "life", "death", "alive", "dead", "living", "nonliving", "organic", "inorganic", "natural", "artificial", "synthetic", "real", "virtual", "physical", "digital", "analog", "digital", "binary", "decimal", "hexadecimal", "octal", "base", "number", "numeral", "digit", "integer", "float", "double", "boolean", "character", "string", "array", "list", "set", "map", "dictionary", "object", "class", "instance", "method", "function", "procedure", "routine", "subroutine", "macro", "script", "program", "software", "hardware", "firmware", "middleware", "database", "storage", "memory", "cache", "buffer", "queue", "stack", "heap", "tree", "graph", "network", "internet", "web", "browser", "server", "client", "host", "node", "endpoint", "gateway", "firewall", "router", "switch", "hub", "modem", "antenna", "cable", "fiber", "wireless", "radio", "microwave", "infrared", "ultraviolet", "xray", "gamma", "radiation", "particle", "wave", "field", "force", "energy", "matter", "antimatter", "dark", "light", "visible", "invisible", "transparent", "opaque", "reflective", "absorptive", "transmissive", "conductive", "insulative", "magnetic", "electric", "electronic", "mechanical", "thermal", "chemical", "biological", "physical", "chemical", "biological", "psychological", "sociological", "anthropological", "historical", "geographical", "astronomical", "geological", "meteorological", "oceanographic", "ecological", "environmental", "economic", "political", "social", "cultural", "religious", "philosophical", "ethical", "moral", "legal", "illegal", "right", "wrong", "good", "evil", "just", "unjust", "fair", "unfair", "equal", "unequal", "free", "unfree", "independent", "dependent", "autonomous", "heteronomous", "self", "other", "same", "different", "similar", "dissimilar", "like", "unlike", "equal", "unequal", "greater", "lesser", "more", "less", "most", "least", "best", "worst", "first", "last", "next", "previous", "current", "past", "present", "future", "before", "after", "during", "while", "when", "where", "why", "how", "what", "who", "which", "whom", "whose", "this", "that", "these", "those", "here", "there", "everywhere", "somewhere", "anywhere", "nowhere", "all", "some", "none", "many", "few", "several", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten", "hundred", "thousand", "million", "billion", "trillion", "dozen", "score", "pair", "couple", "group", "team", "family", "community", "society", "world", "universe", "galaxy", "planet", "star", "moon", "sun", "earth", "ocean", "sea", "lake", "river", "stream", "pond", "waterfall", "wave", "tide", "current", "depth", "height", "width", "length", "area", "volume", "mass", "weight", "density", "temperature", "pressure", "speed", "velocity", "acceleration", "force", "energy", "power", "work", "heat", "light", "sound", "electricity", "magnetism", "gravity", "friction", "motion", "rest", "balance", "equilibrium", "stability", "change", "growth", "decay", "birth", "death", "life", "death", "alive", "dead", "living", "nonliving", "organic", "inorganic", "natural", "artificial", "synthetic", "real", "virtual", "physical", "digital", "analog", "digital", "binary", "decimal", "hexadecimal", "octal", "base", "number", "numeral", "digit", "integer", "float", "double", "boolean", "character", "string", "array", "list", "set", "map", "dictionary", "object", "class", "instance", "method", "function", "procedure", "routine", "subroutine", "macro", "script", "program", "software", "hardware", "firmware", "middleware", "database", "storage", "memory", "cache", "buffer", "queue", "stack", "heap", "tree", "graph", "network", "internet", "web", "browser", "server", "client", "host", "node", "endpoint", "gateway", "firewall", "router", "switch", "hub", "modem", "antenna", "cable", "fiber", "wireless", "radio", "microwave", "infrared", "ultraviolet", "xray", "gamma", "radiation", "particle", "wave", "field", "force", "energy", "matter", "antimatter", "dark", "light", "visible", "invisible", "transparent", "opaque", "reflective", "absorptive", "transmissive", "conductive", "insulative", "magnetic", "electric", "electronic", "mechanical", "thermal", "chemical", "biological", "physical", "chemical", "biological", "psychological", "sociological", "anthropological", "historical", "geographical", "astronomical", "geological", "meteorological", "oceanographic", "ecological", "environmental", "economic", "political", "social", "cultural", "religious", "philosophical", "ethical", "moral", "legal", "illegal", "right", "wrong", "good", "evil", "just", "unjust", "fair", "unfair", "equal", "unequal", "free", "unfree", "independent", "dependent", "autonomous", "heteronomous", "self", "other", "same", "different", "similar", "dissimilar", "like", "unlike", "equal", "unequal", "greater", "lesser", "more", "less", "most", "least", "best", "worst", "first", "last", "next", "previous", "current", "past", "present", "future", "before", "after", "during", "while", "when", "where", "why", "how", "what", "who", "which", "whom", "whose", "this", "that", "these", "those", "here", "there", "everywhere", "somewhere", "anywhere", "nowhere", "all", "some", "none", "many", "few", "several",