package com.wooftalk.domain.model

enum class TranslationDirection(val value: String) {
    HumanToDog("human_to_dog"),
    DogToHuman("dog_to_human"),
    HumanToCat("human_to_cat"),
    CatToHuman("cat_to_human"),
    HumanToBird("human_to_bird"),
    BirdToHuman("bird_to_human");

    companion object {
        fun fromStrings(source: String, target: String): TranslationDirection? =
            values().find { it.value == "${source}_to_$target" }
    }
}
