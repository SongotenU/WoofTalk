package com.wooftalk.domain.usecase

import android.content.Context
import android.content.Intent
import com.wooftalk.domain.model.TranslationResult

class ShareManager(private val context: Context) {
    fun shareTranslation(result: TranslationResult) {
        val shareText = buildString {
            append("\"${result.inputText}\" → ")
            append("\"${result.outputText}\"")
            append("\n\nTranslated with WoofTalk 🐾")
        }
        val intent = Intent(Intent.ACTION_SEND).apply {
            type = "text/plain"
            putExtra(Intent.EXTRA_TEXT, shareText)
        }
        context.startActivity(Intent.createChooser(intent, "Share translation"))
    }

    fun sharePhrase(phraseText: String, language: String) {
        val shareText = "\"$phraseText\" ($language)\n\nShared from WoofTalk 🐾"
        val intent = Intent(Intent.ACTION_SEND).apply {
            type = "text/plain"
            putExtra(Intent.EXTRA_TEXT, shareText)
        }
        context.startActivity(Intent.createChooser(intent, "Share phrase"))
    }
}
