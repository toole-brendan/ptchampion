package com.example.ptchampion

import android.app.Application
import dagger.hilt.android.HiltAndroidApp

@HiltAndroidApp
class PTChampionApp : Application() {
    override fun onCreate() {
        super.onCreate()
        // Initialization logic can go here
    }
}