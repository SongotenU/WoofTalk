package com.wooftalk.domain.adapter

class BirdLanguageAdapter : LanguageAdapter {
    override val languageName = "Bird"
    override val simpleSounds = listOf("chirp", "tweet", "whistle", "squawk", "trill")

    private val humanToBird = mapOf(
        "hello" to "chirp chirp",
        "hi" to "tweet",
        "goodbye" to "chirp tweet",
        "i love you" to "whistle whistle",
        "love" to "whistle",
        "food" to "chirp chirp chirp",
        "hungry" to "squawk squawk",
        "eat" to "chirp",
        "play" to "tweet tweet",
        "good" to "trill trill",
        "bad" to "squawk",
        "happy" to "chirp tweet trill",
        "sad" to "tweet mew",
        "sleep" to "trill",
        "friend" to "chirp chirp tweet",
        "water" to "tweet chirp",
        "fly" to "chirp tweet chirp",
        "sing" to "whistle trill whistle",
        "morning" to "chirp chirp chirp",
        "night" to "trill trill"
    )

    private val birdToHuman = humanToBird.entries.associate { (k, v) -> v to k }

    override fun translateToAnimal(humanText: String): Pair<String, Double> {
        val normalized = humanText.lowercase().trim()
        humanToBird[normalized]?.let { return it to 1.0 }
        val words = normalized.split(" ")
        val translated = words.map { humanToBird[it] ?: generateBirdSound() }.joinToString(" ")
        val confidence = words.count { humanToBird.containsKey(it) }.toDouble() / words.size
        return translated to confidence
    }

    override fun translateToHuman(animalText: String): Pair<String, Double> {
        val normalized = animalText.lowercase().trim()
        birdToHuman[normalized]?.let { return it to 1.0 }
        val sounds = normalized.split(" ")
        val translated = sounds.map { birdToHuman[it] ?: "?" }.joinToString(" ")
        val confidence = sounds.count { birdToHuman.containsKey(it) }.toDouble() / sounds.size
        return translated to confidence
    }

    override fun generateSimpleTranslation(wordCount: Int): String =
        (1..wordCount).map { simpleSounds.random() }.joinToString(" ")

    private fun generateBirdSound(): String = simpleSounds.random()
}
