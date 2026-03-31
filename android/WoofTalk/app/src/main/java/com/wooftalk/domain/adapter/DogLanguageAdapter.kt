package com.wooftalk.domain.adapter

class DogLanguageAdapter : LanguageAdapter {
    override val languageName = "Dog"
    override val simpleSounds = listOf("woof", "bark", "arf", "ruff", "bow-wow")

    private val humanToDog = mapOf(
        "hello" to "woof woof",
        "hi" to "woof",
        "goodbye" to "arf arf arf",
        "bye" to "arf arf",
        "i love you" to "woof woof woof",
        "love" to "woof woof",
        "food" to "bark bark",
        "hungry" to "bark bark bark",
        "eat" to "bark",
        "play" to "woof arf woof",
        "walk" to "woof woof arf",
        "good boy" to "woof woof woof",
        "bad" to "grrr",
        "stop" to "grrr grrr",
        "sit" to "arf",
        "stay" to "ruff ruff",
        "come" to "woof arf",
        "yes" to "woof",
        "no" to "grr",
        "thank you" to "woof woof arf",
        "please" to "woof arf",
        "friend" to "woof woof woof",
        "happy" to "woof woof arf arf",
        "sad" to "whine whine",
        "help" to "bark bark bark",
        "water" to "arf woof",
        "sleep" to "ruff",
        "outside" to "woof woof bark",
        "inside" to "arf ruff",
        "treat" to "bark bark woof"
    )

    private val dogToHuman = humanToDog.entries.associate { (k, v) -> v to k }

    override fun translateToAnimal(humanText: String): Pair<String, Double> {
        val normalized = humanText.lowercase().trim()
        humanToDog[normalized]?.let { return it to 1.0 }
        val words = normalized.split(" ")
        val translated = words.map { humanToDog[it] ?: generateDogSound() }.joinToString(" ")
        val confidence = words.count { humanToDog.containsKey(it) }.toDouble() / words.size
        return translated to confidence
    }

    override fun translateToHuman(animalText: String): Pair<String, Double> {
        val normalized = animalText.lowercase().trim()
        dogToHuman[normalized]?.let { return it to 1.0 }
        val sounds = normalized.split(" ")
        val translated = sounds.map { dogToHuman[it] ?: "?" }.joinToString(" ")
        val confidence = sounds.count { dogToHuman.containsKey(it) }.toDouble() / sounds.size
        return translated to confidence
    }

    override fun generateSimpleTranslation(wordCount: Int): String =
        (1..wordCount).map { simpleSounds.random() }.joinToString(" ")

    private fun generateDogSound(): String = simpleSounds.random()
}
