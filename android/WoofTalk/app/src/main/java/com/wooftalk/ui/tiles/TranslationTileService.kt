package com.wooftalk.ui.tiles

import android.service.quicksettings.Tile
import android.service.quicksettings.TileService
import com.wooftalk.R
import com.wooftalk.voice.service.VoiceTranslationService

class TranslationTileService : TileService() {

    private var isListening = false

    override fun onStartListening() {
        super.onStartListening()
        updateTileState()
    }

    override fun onClick() {
        super.onClick()
        if (isListening) {
            stopTranslation()
        } else {
            startTranslation()
        }
        isListening = !isListening
        updateTileState()
    }

    override fun onStopListening() {
        super.onStopListening()
    }

    private fun startTranslation() {
        val intent = VoiceTranslationService.createStartIntent(this).apply {
            action = VoiceTranslationService.ACTION_START
        }
        startForegroundService(intent)
    }

    private fun stopTranslation() {
        val intent = VoiceTranslationService.createStartIntent(this).apply {
            action = VoiceTranslationService.ACTION_STOP
        }
        startService(intent)
    }

    private fun updateTileState() {
        qsTile?.apply {
            if (isListening) {
                state = Tile.STATE_ACTIVE
                label = getString(R.string.tile_stop_translation)
                icon
            } else {
                state = Tile.STATE_INACTIVE
                label = getString(R.string.tile_start_translation)
            }
            updateTile()
        }
    }
}
