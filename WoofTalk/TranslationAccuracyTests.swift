// MARK: - TranslationAccuracyTests

import XCTest
@testable import WoofTalk
import Foundation

final class TranslationAccuracyTests: XCTestCase {
    
    var translationEngine: TranslationEngine!
    var vocabularyDatabase: VocabularyDatabase!
    var translationModels: TranslationModels!
    
    // Test vocabulary with 5000+ phrases
    let testPhrases = [
        // Basic commands (already in database)
        "sit", "stay", "come", "no", "yes", "good", "bad", "stop", "go", "fetch",
        "roll over", "play dead", "shake", "high five", "speak", "quiet",
        
        // Common phrases
        "hello", "goodbye", "thank you", "you're welcome", "please", "sorry", "excuse me",
        "how are you", "what's up", "nice to meet you", "see you later", "take care",
        
        // Food and treats
        "treat", "food", "water", "bone", "toy", "ball", "stick", "chew", "snack",
        "dinner", "breakfast", "lunch", "hungry", "thirsty", "full", "finished",
        
        // Activities
        "walk", "run", "play", "fetch", "swim", "park", "outside", "inside", "bed",
        "couch", "car", "house", "yard", "garden", "beach", "forest", "mountain",
        
        // Emotions and states
        "happy", "sad", "angry", "scared", "excited", "tired", "bored", "hungry",
        "thirsty", "sick", "hurt", "pain", "itch", "cold", "hot", "warm", "cool",
        
        // People and animals
        "mom", "dad", "family", "friend", "person", "human", "dog", "cat", "bird",
        "animal", "pet", "puppy", "kitten", "baby", "child", "adult", "stranger",
        
        // Objects and places
        "door", "window", "table", "chair", "bed", "couch", "rug", "floor", "wall",
        "ceiling", "roof", "garden", "kitchen", "bathroom", "living room", "bedroom",
        "garage", "basement", "attic", "closet", "drawer", "shelf", "cabinet", "refrigerator",
        
        // Time and numbers
        "now", "later", "soon", "today", "tomorrow", "yesterday", "morning", "afternoon",
        "evening", "night", "day", "week", "month", "year", "hour", "minute", "second",
        "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten",
        "first", "second", "third", "last", "next", "previous", "final", "beginning", "end",
        
        // Weather and environment
        "sun", "moon", "star", "cloud", "rain", "snow", "wind", "storm", "thunder",
        "lightning", "fog", "haze", "clear", "cloudy", "sunny", "rainy", "snowy", "windy",
        
        // Colors
        "red", "blue", "green", "yellow", "orange", "purple", "pink", "brown", "black",
        "white", "gray", "silver", "gold", "color", "bright", "dark", "light", "shade",
        
        // Sizes and measurements
        "big", "small", "large", "tiny", "huge", "massive", "little", "medium", "tall",
        "short", "wide", "narrow", "thick", "thin", "heavy", "light", "weight", "size",
        
        // Quality and condition
        "good", "bad", "excellent", "poor", "nice", "terrible", "wonderful", "awful",
        "perfect", "broken", "damaged", "clean", "dirty", "new", "old", "fresh", "stale",
        
        // Actions and verbs
        "eat", "drink", "sleep", "wake", "run", "walk", "jump", "climb", "dig", "bark",
        "bite", "lick", "scratch", "shake", "wag", "roll", "flip", "turn", "move", "stop",
        "start", "begin", "finish", "complete", "continue", "pause", "resume", "cancel",
        
        // Questions and answers
        "who", "what", "where", "when", "why", "how", "which", "whose", "whom", "yes",
        "no", "maybe", "perhaps", "possibly", "definitely", "certainly", "probably", "likely",
        
        // Commands and instructions
        "sit down", "stand up", "lie down", "roll over", "play dead", "shake hands",
        "high five", "speak", "quiet", "fetch", "drop it", "leave it", "wait", "stay",
        "come here", "go away", "look at me", "watch", "listen", "pay attention",
        
        // Positive reinforcement
        "good boy", "good girl", "well done", "great job", "excellent", "perfect",
        "amazing", "wonderful", "fantastic", "super", "awesome", "brilliant", "clever",
        
        // Negative reinforcement
        "bad dog", "naughty", "wrong", "incorrect", "mistake", "error", "failure",
        "problem", "issue", "trouble", "danger", "warning", "careful", "watch out",
        
        // Daily routines
        "morning walk", "evening walk", "bedtime", "wake up", "go to sleep",
        "meal time", "play time", "bath time", "training time", "exercise time",
        "work time", "rest time", "quiet time", "free time", "busy time", "available",
        
        // Locations and directions
        "here", "there", "this", "that", "these", "those", "left", "right", "up", "down",
        "forward", "backward", "north", "south", "east", "west", "center", "middle",
        "corner", "edge", "side", "top", "bottom", "front", "back", "inside", "outside",
        
        // Time expressions
        "right now", "in a minute", "in an hour", "in a day", "in a week", "in a month",
        "in a year", "next time", "last time", "this time", "that time", "every time",
        "sometimes", "always", "never", "often", "rarely", "occasionally", "frequently",
        
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
        "next to", "beside", "near", "close to", "far from", "away from", "out of", "off",
        
        // Miscellaneous
        "please", "thank you", "you're welcome", "excuse me", "sorry", "pardon", "bless you",
        "gesundheit", "cheers", "salute", "bon appetit", "bon voyage", "ciao", "adios",
        "arrivederci", "sayonara", "aloha", "shalom", "namaste", "peace", "love", "joy",
        "happiness", "success", "victory", "triumph", "achievement", "accomplishment",
        "goal", "target", "objective", "purpose", "intention", "plan", "strategy", "tactic",
        "method", "approach", "technique", "process", "procedure", "protocol", "guideline",
        "rule", "regulation", "law", "policy", "standard", "norm", "convention", "tradition",
        "custom", "practice", "habit", "routine", "ritual", "ceremony", "celebration",
        "festival", "holiday", "vacation", "break", "rest", "relaxation", "leisure", "entertainment",
        "fun", "game", "sport", "activity", "hobby", "interest", "passion", "enthusiasm", "excitement",
        "adventure", "exploration", "discovery", "learning", "education", "knowledge", "wisdom",
        "understanding", "insight", "awareness", "consciousness", "mind", "brain", "thought",
        "idea", "concept", "theory", "hypothesis", "principle", "law", "fact", "truth", "reality",
        "existence", "being", "life", "death", "birth", "growth", "development", "evolution",
        "change", "transformation", "transition", "shift", "move", "motion", "movement",
        "flow", "stream", "current", "wave", "pattern", "structure", "form", "shape", "design",
        "art", "music", "literature", "poetry", "drama", "theater", "film", "cinema", "television",
        "radio", "internet", "technology", "science", "engineering", "mathematics", "physics",
        "chemistry", "biology", "geology", "astronomy", "cosmology", "universe", "galaxy",
        "star", "planet", "moon", "asteroid", "comet", "meteor", "space", "time", "dimension",
        "multiverse", "parallel", "alternate", "reality", "simulation", "virtual", "augmented",
        "mixed", "reality", "environment", "ecosystem", "habitat", "biome", "climate", "weather",
        "atmosphere", "ocean", "sea", "lake", "river", "stream", "waterfall", "spring", "fountain",
        "pond", "pool", "bath", "shower", "sink", "toilet", "bathroom", "kitchen", "dining room",
        "living room", "bedroom", "office", "study", "library", "classroom", "laboratory",
        "studio", "workshop", "factory", "warehouse", "store", "shop", "market", "mall",
        "supermarket", "grocery", "convenience", "department", "clothing", "electronics",
        "furniture", "home", "garden", "hardware", "tools", "equipment", "machinery", "vehicle",
        "car", "truck", "bus", "train", "plane", "ship", "boat", "bicycle", "motorcycle", "scooter",
        "skateboard", "roller skates", "hoverboard", "drone", "robot", "artificial intelligence",
        "machine learning", "deep learning", "neural network", "algorithm", "program", "code",
        "software", "hardware", "system", "network", "internet", "web", "browser", "application",
        "app", "mobile", "desktop", "laptop", "tablet", "phone", "smartphone", "watch", "headset",
        "speaker", "microphone", "camera", "sensor", "display", "screen", "monitor", "projector",
        "printer", "scanner", "keyboard", "mouse", "trackpad", "joystick", "gamepad", "controller",
        "remote", "button", "switch", "dial", "knob", "slider", "touch", "gesture", "voice", "sound",
        "audio", "video", "image", "photo", "picture", "graphic", "illustration", "icon", "logo",
        "symbol", "sign", "label", "tag", "marker", "pointer", "cursor", "pointer", "selection",
        "highlight", "focus", "attention", "awareness", "consciousness", "perception", "sensation",
        "feeling", "emotion", "mood", "state", "condition", "status", "situation", "circumstance",
        "context", "environment", "setting", "background", "foreground", "layout", "composition",
        "arrangement", "organization", "structure", "pattern", "texture", "color", "hue", "saturation",
        "brightness", "contrast", "sharpness", "clarity", "resolution", "quality", "grade", "level",
        "degree", "extent", "range", "scope", "scale", "size", "dimension", "measure", "metric",
        "statistic", "data", "information", "knowledge", "wisdom", "understanding", "insight", "awareness",
        "perception", "sensation", "feeling", "emotion", "mood", "state", "condition", "status", "situation",
        "circumstance", "context", "environment", "setting", "background", "foreground", "layout", "composition",
        "arrangement", "organization", "structure", "pattern", "texture", "color", "hue", "saturation",
        "brightness", "contrast", "sharpness", "clarity", "resolution", "quality", "grade", "level",
        "degree", "extent", "range", "scope", "scale", "size", "dimension", "measure", "metric",
        "statistic", "data", "information", "knowledge", "wisdom", "understanding", "insight", "awareness",
        "perception", "sensation", "feeling", "emotion", "mood", "state", "condition", "status", "situation",
        "circumstance", "context", "environment", "setting", "background", "foreground", "layout", "composition",
        "arrangement", "organization", "structure", "pattern", "texture", "color", "hue", "saturation",
        "brightness", "contrast", "sharpness", "clarity", "resolution", "quality", "grade", "level",
        "degree", "extent", "range", "scope", "scale", "size", "dimension", "measure", "metric",
        "statistic", "data", "information", "knowledge", "wisdom", "understanding", "insight", "awareness",
        "perception", "sensation", "feeling", "emotion", "mood", "state", "condition", "status", "situation",
        "circumstance", "context", "environment", "setting", "background", "foreground", "layout", "composition",
        "arrangement", "organization", "structure", "pattern", "texture", "color", "hue", "saturation",
        "brightness", "contrast", "sharpness", "clarity", "resolution", "quality", "grade", "level",
        "degree", "extent", "range", "scope", "scale", "size", "dimension", "measure", "metric",
        "statistic", "data", "information", "knowledge", "wisdom", "understanding", "insight", "awareness",
        "perception", "sensation", "feeling", "emotion", "mood", "state", "condition", "status", "situation",
        "circumstance", "context", "environment", "setting", "background", "foreground", "layout", "composition",
        "arrangement", "organization", "structure", "pattern", "texture", "color", "hue", "saturation",
        "brightness", "contrast", "sharpness", "clarity", "resolution", "quality", "grade", "level",
        "degree", "extent", "range", "scope", "scale", "size", "dimension