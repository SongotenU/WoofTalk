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
                "com.google.devtools.ksp" -> useVersion("2.0.0-1.0.22")
                "com.google.dagger.hilt.android" -> useVersion("2.50")
                "com.google.gms.google-services" -> useVersion("4.3.0")
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
    id("com.google.gms.google-services") version "4.4.2" apply false
}

rootProject.name = "WoofTalk"
include(":app")
