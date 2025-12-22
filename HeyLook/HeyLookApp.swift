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
    
    // MARK: - Initialization
    
    init() {
        // 1. Create the Audio Manager first (it has no dependencies)
        let audio = AudioManager()
        
        // 2. Inject Audio Manager into Camera Manager
        let camera = CameraManager(audioManager: audio)
        
        // 3. Store them in State
        _audioManager = State(initialValue: audio)
        _cameraManager = State(initialValue: camera)
    }
    
    var body: some Scene {
        WindowGroup {
            CameraView()
                // Inject dependencies into the View Hierarchy
                .environment(audioManager)
                .environment(cameraManager)
                // Camera apps usually look best in Dark Mode
                .preferredColorScheme(.dark)
                .task {
                    // Optional: Pre-warm the camera permissions check here if desired
                }
        }
    }
}
