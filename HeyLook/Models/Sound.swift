//
//  Sound.swift
//  HeyLook
//
//  Created on December 22, 2025.
//

import Foundation

/// Represents a sound file that can be played during the capture sequence.
struct Sound: Identifiable, Equatable, Sendable {
    let id: String
    let name: String
    
    // MARK: - Configuration
    /// The single file extension used for all sounds in the app.
    /// Change this here if you convert your assets (e.g., to "wav" or "m4a").
    static let fileExtension = "mp3"
    
    /// Computed filename helper
    var filename: String {
        return "\(id).\(Sound.fileExtension)"
    }
    
    init(id: String, name: String) {
        self.id = id
        self.name = name
    }
}

// MARK: - Predefined Sounds

extension Sound {
    /// The 8 attention-grabbing sounds available in the carousel
    static let attentionSounds: [Sound] = [
        Sound(id: "duck", name: "Duck"),
        Sound(id: "cow", name: "Cow"),
        Sound(id: "dog", name: "Dog"),
        Sound(id: "boing", name: "Boing"),
        Sound(id: "whistle", name: "Whistle"),
        Sound(id: "pop", name: "Pop"),
        Sound(id: "bell", name: "Bell"),
        Sound(id: "chime", name: "Chime")
    ]
    
    /// Shutter sound played when photo is captured
    static let shutter = Sound(id: "shutter", name: "Shutter")
}
