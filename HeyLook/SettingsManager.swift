//
//  SettingsManager.swift
//  HeyLook
//
//  Created on January 26, 2026.
//

import Foundation
import Observation

/// Manages user preferences for the app
@Observable
@MainActor
final class SettingsManager {
    
    // MARK: - Photo Ratio Options
    
    enum PhotoRatio: String, CaseIterable, Identifiable {
        case ratio_3_4 = "3:4"
        case ratio_4_3 = "4:3"
        case ratio_16_9 = "16:9"
        case ratio_1_1 = "1:1"
        
        var id: String { rawValue }
        
        var aspectRatio: CGFloat {
            switch self {
            case .ratio_3_4: return 3.0 / 4.0
            case .ratio_4_3: return 4.0 / 3.0
            case .ratio_16_9: return 16.0 / 9.0
            case .ratio_1_1: return 1.0
            }
        }
        
        var displayName: String {
            rawValue
        }
    }
    
    // MARK: - Settings
    
    private(set) var selectedPhotoRatio: PhotoRatio = .ratio_4_3
    private(set) var favoriteSounds: [Sound] = []
    
    // MARK: - Keys for UserDefaults
    
    private let photoRatioKey = "selectedPhotoRatio"
    private let favoriteSoundsKey = "favoriteSounds"
    
    // MARK: - Initialization
    
    init() {
        loadSettings()
        
        // If no favorites are set, default to first 5 sounds
        if favoriteSounds.isEmpty {
            favoriteSounds = Array(Sound.attentionSounds.prefix(5))
        }
    }
    
    // MARK: - Public Methods
    
    func setPhotoRatio(_ ratio: PhotoRatio) {
        selectedPhotoRatio = ratio
        saveSettings()
    }
    
    func setFavoriteSounds(_ sounds: [Sound]) {
        // Ensure we have exactly 5 sounds
        favoriteSounds = Array(sounds.prefix(5))
        saveSettings()
    }
    
    func toggleFavoriteSound(_ sound: Sound) {
        if let index = favoriteSounds.firstIndex(where: { $0.id == sound.id }) {
            // Remove if already favorited
            favoriteSounds.remove(at: index)
        } else if favoriteSounds.count < 5 {
            // Add if under limit
            favoriteSounds.append(sound)
        }
        saveSettings()
    }
    
    func isFavorite(_ sound: Sound) -> Bool {
        favoriteSounds.contains(where: { $0.id == sound.id })
    }
    
    func moveFavoriteSound(from source: IndexSet, to destination: Int) {
        var updatedSounds = favoriteSounds
        let soundsToMove = source.map { updatedSounds[$0] }
        
        // Remove elements at the indices in the IndexSet (in reverse order to maintain indices)
        for index in source.sorted().reversed() {
            updatedSounds.remove(at: index)
        }
        
        let adjustedDestination = destination > source.first! ? destination - source.count : destination
        updatedSounds.insert(contentsOf: soundsToMove, at: adjustedDestination)
        
        favoriteSounds = updatedSounds
        saveSettings()
    }
    
    // MARK: - Persistence
    
    private func saveSettings() {
        UserDefaults.standard.set(selectedPhotoRatio.rawValue, forKey: photoRatioKey)
        
        let soundIds = favoriteSounds.map { $0.id }
        UserDefaults.standard.set(soundIds, forKey: favoriteSoundsKey)
    }
    
    private func loadSettings() {
        // Load photo ratio
        if let ratioString = UserDefaults.standard.string(forKey: photoRatioKey),
           let ratio = PhotoRatio(rawValue: ratioString) {
            selectedPhotoRatio = ratio
        }
        
        // Load favorite sounds
        if let soundIds = UserDefaults.standard.array(forKey: favoriteSoundsKey) as? [String] {
            favoriteSounds = soundIds.compactMap { id in
                Sound.attentionSounds.first(where: { $0.id == id })
            }
        }
    }
}
