package com.andwati.castlei

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Taps never click. Sound belongs to piece moves, which play through
        // the audio player and are unaffected by this flag.
        window.decorView.isSoundEffectsEnabled = false
    }
}
