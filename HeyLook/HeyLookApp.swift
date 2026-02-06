//
//  HeyLookApp.swift
//  HeyLook
//
//  Created by Brandon Bennington on 22/12/25.
//

import SwiftUI
import AVFoundation

@main
struct HeyLookApp: App {
    
    // MARK: - App State
    
    /// We declare these as @State so they stay alive for the entire app lifecycle
    @State private var audioManager: AudioManager
    @State private var cameraManager: CameraManager
    @State private var settingsManager: SettingsManager
    
    // MARK: - Initialization
    
    init() {
        // 1. Create the Settings Manager first (stores user preferences)
        let settings = SettingsManager()
        
        // 2. Create the Audio Manager (it has no dependencies)
        let audio = AudioManager()
        
        // 3. Inject Audio Manager and Settings Manager into Camera Manager
        let camera = CameraManager(audioManager: audio, settingsManager: settings)
        
        // 4. Store them in State
        _settingsManager = State(initialValue: settings)
        _audioManager = State(initialValue: audio)
        _cameraManager = State(initialValue: camera)
    }
    
    var body: some Scene {
        WindowGroup {
            CameraView()
                // Inject dependencies into the View Hierarchy
                .environment(cameraManager)
                .environment(audioManager)
                .environment(settingsManager)
                // Camera apps usually look best in Dark Mode
                .preferredColorScheme(.dark)
                .task {
                    // Optional: Pre-warm the camera permissions check here if desired
                }
        }
    }
}
