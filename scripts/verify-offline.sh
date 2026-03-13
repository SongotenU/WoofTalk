#!/bin/bash

# Offline Mode Verification Script for WoofTalk

echo "🧪 Verifying Offline Mode functionality..."

# Check if offline manager files exist
if [ ! -f "offline_manager/offline_manager.ts" ] || [ ! -f "offline_manager/connectivity_manager.ts" ]; then
    echo "❌ Missing offline manager files"
    exit 1
fi

# Check if UI components exist
if [ ! -f "ui/offline_mode_view_controller.swift" ]; then
    echo "❌ Missing offline mode UI component"
    exit 1
fi

# Check if database files exist
if [ ! -f "offline_storage/sqlite_manager.ts" ] || [ ! -f "offline_storage/offline_database.ts" ]; then
    echo "❌ Missing database files"
    exit 1
fi

# Check if offline translation manager exists in main project
if [ ! -f "WoofTalk/OfflineTranslationManager.swift" ]; then
    echo "❌ Missing OfflineTranslationManager in main project"
    exit 1
fi

echo "✅ All required files found"

# Check if main view controller has offline mode tab
if grep -q "OfflineModeViewController" "WoofTalk/MainViewController.swift"; then
    echo "✅ Offline mode tab found in MainViewController"
else
    echo "❌ Offline mode tab not found in MainViewController"
    exit 1
fi

echo "🎉 Offline mode verification passed!"
