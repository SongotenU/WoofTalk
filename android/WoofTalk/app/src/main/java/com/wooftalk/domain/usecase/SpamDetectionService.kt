package com.wooftalk.domain.usecase

import android.content.Context

class SpamDetectionService(context: Context) {
    private val spamPatterns = listOf(
        Regex("(.)\\1{4,}"),
        Regex("(http|https|www)://\\S+"),
        Regex("\\b(spam|buy|cheap|free|click|win)\\b", RegexOption.IGNORE_CASE)
    )

    private val submissionTimestamps = mutableMapOf<String, MutableList<Long>>()

    data class SpamResult(
        val isSpam: Boolean,
        val confidence: Double,
        val reasons: List<String>
    )

    fun analyze(text: String, userId: String): SpamResult {
        val reasons = mutableListOf<String>()
        var spamScore = 0.0

        spamPatterns.forEach { pattern ->
            if (pattern.containsMatchIn(text)) {
                spamScore += 0.3
                reasons.add("Pattern match: ${pattern.pattern.take(20)}...")
            }
        }

        if (text.length > 500) {
            spamScore += 0.2
            reasons.add("Text too long (${text.length} chars)")
        }

        if (text.split(" ").toSet().size < text.split(" ").size / 2) {
            spamScore += 0.3
            reasons.add("High word repetition")
        }

        val now = System.currentTimeMillis()
        val userSubmissions = submissionTimestamps.getOrPut(userId) { mutableListOf() }
        userSubmissions.add(now)
        val recentSubmissions = userSubmissions.filter { now - it < 60000 }
        if (recentSubmissions.size > 5) {
            spamScore += 0.4
            reasons.add("Too many submissions (${recentSubmissions.size}/min)")
        }

        return SpamResult(
            isSpam = spamScore >= 0.5,
            confidence = spamScore.coerceIn(0.0, 1.0),
            reasons = reasons
        )
    }

    fun clearOldData() {
        val now = System.currentTimeMillis()
        submissionTimestamps.forEach { (userId, timestamps) ->
            submissionTimestamps[userId] = timestamps.filter { now - it < 3600000 }.toMutableList()
        }
    }
}
