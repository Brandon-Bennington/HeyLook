//
//  AudioManager.swift
//  HeyLook
//
//  Created on December 22, 2025.
//

import Foundation
import AVFoundation
import Observation

/// Manages audio playback for attention sounds and shutter sound.
/// Inherits from NSObject to conform to AVAudioPlayerDelegate (Objective-C protocol requirement).
@Observable
@MainActor
final class AudioManager: NSObject, AVAudioPlayerDelegate {
    
    // MARK: - Published State
    
    private(set) var selectedSound: Sound = Sound.attentionSounds[0]
    private(set) var isPlaying: Bool = false
    
    // MARK: - Private Properties
    
    /// Pre-loaded audio players for each attention sound (eliminates playback lag)
    private var soundPlayers: [String: AVAudioPlayer] = [:]
    
    /// Player for shutter sound
    private var shutterPlayer: AVAudioPlayer?
    
    /// Currently active player (used for delegate callbacks)
    private var activePlayer: AVAudioPlayer?
    
    /// Callback to trigger when sound finishes playing (state transition to .countingDown)
    var onSoundFinished: (() -> Void)?
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        configureAudioSession()
        preloadSounds()
    }
    
    // MARK: - Audio Session Configuration
    
    /// Configures AVAudioSession to override silent switch and duck other audio
    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            // .playback overrides silent switch (critical for app functionality)
            // .duckOthers lowers background audio (podcasts/music) during playback
            try session.setCategory(.playback, mode: .default, options: .duckOthers)
            try session.setActive(true)
        } catch {
            print("❌ AudioSession configuration failed: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Sound Loading
    
    /// Pre-loads all attention sounds into memory buffers for instant playback
    private func preloadSounds() {
        // Load attention sounds
        for sound in Sound.attentionSounds {
            guard let url = Bundle.main.url(forResource: sound.id, withExtension: Sound.fileExtension) else {
                print("⚠️ Sound file not found: \(sound.filename)")
                continue
            }
            
            do {
                let player = try AVAudioPlayer(contentsOf: url)
                player.prepareToPlay() // Pre-buffer audio data
                player.delegate = self
                soundPlayers[sound.id] = player
            } catch {
                print("❌ Failed to load sound \(sound.name): \(error.localizedDescription)")
            }
        }
        
        // Load shutter sound
        if let url = Bundle.main.url(forResource: Sound.shutter.id, withExtension: Sound.fileExtension) {
            do {
                shutterPlayer = try AVAudioPlayer(contentsOf: url)
                shutterPlayer?.prepareToPlay()
            } catch {
                print("❌ Failed to load shutter sound: \(error.localizedDescription)")
            }
        }
        
        print("✅ Loaded \(soundPlayers.count) attention sounds + shutter")
    }
    
    // MARK: - Public Methods
    
    /// Selects a sound for the next capture (updates UI binding)
    func selectSound(_ sound: Sound) {
        selectedSound = sound
    }
    
    /// Plays a preview of the sound (for carousel interaction, no state transition)
    func previewSound(_ sound: Sound) {
        guard let player = soundPlayers[sound.id] else { return }
        
        // Stop any currently playing sound
        activePlayer?.stop()
        
        player.currentTime = 0
        player.play()
        activePlayer = player
        isPlaying = true
    }
    
    /// Plays the selected sound during capture sequence (triggers state transition when complete)
    func playSelectedSound() {
        guard let player = soundPlayers[selectedSound.id] else {
            // Sound missing - immediately trigger callback to continue capture flow
            onSoundFinished?()
            return
        }
        
        player.currentTime = 0
        player.play()
        activePlayer = player
        isPlaying = true
    }
    
    /// Plays shutter sound when photo is captured
    func playShutterSound() {
        shutterPlayer?.currentTime = 0
        shutterPlayer?.play()
    }
    
    /// Stops any currently playing sound (used for abort scenarios)
    func stopAllSounds() {
        activePlayer?.stop()
        activePlayer = nil
        isPlaying = false
    }
    
    // MARK: - AVAudioPlayerDelegate
    
    /// Called when sound finishes playing - triggers state transition to .countingDown
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            isPlaying = false
            activePlayer = nil
            
            // Trigger state transition in CameraManager (only for capture sounds, not previews)
            if flag {
                onSoundFinished?()
            }
        }
    }
    
    nonisolated func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        Task { @MainActor in
            print("❌ Audio decode error: \(error?.localizedDescription ?? "unknown")")
            isPlaying = false
            activePlayer = nil
        }
    }
}
