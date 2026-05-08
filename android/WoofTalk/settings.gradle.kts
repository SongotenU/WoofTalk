pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
    resolutionStrategy {
        eachPlugin {
            when (requested.id.id) {
                "com.android.application" -> useVersion("8.2.2")
                "org.jetbrains.kotlin.android" -> useVersion("2.0.21")
                "org.jetbrains.kotlin.plugin.compose" -> useVersion("2.0.21")
                "com.google.devtools.ksp" -> useVersion("2.0.21-1.0.28")
                "com.google.dagger.hilt.android" -> useVersion("2.48.1")
                "com.google.gms.google-services" -> useVersion("4.4.0")
                "com.google.firebase.crashlytics" -> useVersion("3.0.2")
            }
        }
    }
}

dependencyResolutionManagement {
    repositories {
        google()
        mavenCentral()
    }
}

plugins {
    id("com.google.gms.google-services") version "4.4.0" apply false
}

rootProject.name = "WoofTalk"
include(":app")
