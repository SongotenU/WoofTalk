package com.wooftalk.domain.adapter

class CatLanguageAdapter : LanguageAdapter {
    override val languageName = "Cat"
    override val simpleSounds = listOf("meow", "purr", "mew", "hiss", "mrrp")

    private val humanToCat = mapOf(
        "hello" to "meow",
        "hi" to "mew",
        "goodbye" to "meow meow",
        "i love you" to "purr purr",
        "love" to "purr",
        "food" to "meow meow meow",
        "hungry" to "meow meow",
        "eat" to "meow",
        "play" to "mew mew",
        "good" to "purr purr purr",
        "bad" to "hiss",
        "stop" to "hiss hiss",
        "come" to "mrrp",
        "yes" to "meow",
        "no" to "hiss",
        "happy" to "purr purr meow",
        "sad" to "mew mew",
        "sleep" to "purr",
        "friend" to "mrrp mrrp",
        "water" to "meow mew",
        "treat" to "meow meow purr"
    )

    private val catToHuman = humanToCat.entries.associate { (k, v) -> v to k }

    override fun translateToAnimal(humanText: String): Pair<String, Double> {
        val normalized = humanText.lowercase().trim()
        humanToCat[normalized]?.let { return it to 1.0 }
        val words = normalized.split(" ")
        val translated = words.map { humanToCat[it] ?: generateCatSound() }.joinToString(" ")
        val confidence = words.count { humanToCat.containsKey(it) }.toDouble() / words.size
        return translated to confidence
    }

    override fun translateToHuman(animalText: String): Pair<String, Double> {
        val normalized = animalText.lowercase().trim()
        catToHuman[normalized]?.let { return it to 1.0 }
        val sounds = normalized.split(" ")
        val translated = sounds.map { catToHuman[it] ?: "?" }.joinToString(" ")
        val confidence = sounds.count { catToHuman.containsKey(it) }.toDouble() / sounds.size
        return translated to confidence
    }

    override fun generateSimpleTranslation(wordCount: Int): String =
        (1..wordCount).map { simpleSounds.random() }.joinToString(" ")

    private fun generateCatSound(): String = simpleSounds.random()
}
