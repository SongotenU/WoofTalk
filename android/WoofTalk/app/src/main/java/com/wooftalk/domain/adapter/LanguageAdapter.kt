package com.wooftalk.domain.adapter

interface LanguageAdapter {
    val languageName: String
    val simpleSounds: List<String>

    fun translateToAnimal(humanText: String): Pair<String, Double>
    fun translateToHuman(animalText: String): Pair<String, Double>
    fun generateSimpleTranslation(wordCount: Int): String
}
