//
//  SoundCarouselView.swift
//  HeyLook
//
//  Created on December 22, 2025.
//

import SwiftUI

struct SoundCarouselView: View {
    @Environment(AudioManager.self) private var audioManager
    @Environment(SettingsManager.self) private var settings
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 20) {
                ForEach(settings.favoriteSounds) { sound in
                    SoundBubble(
                        sound: sound,
                        isSelected: sound == audioManager.selectedSound
                    )
                    .onTapGesture(count: 2) {
                        // Double tap to preview sound
                        audioManager.previewSound(sound)
                    }
                    .onTapGesture(count: 1) {
                        // Single tap to select sound
                        withAnimation(.bouncy) {
                            audioManager.selectSound(sound)
                        }
                    }
                }
            }
            .padding(.horizontal, 30)
            .padding(.vertical, 10) // Add vertical padding to prevent clipping
        }
        .frame(height: 75) // Increase height to accommodate the scaled selected bubble
    }
}

// MARK: - Sound Bubble

struct SoundBubble: View {
    let sound: Sound
    let isSelected: Bool
    
    var body: some View {
        ZStack {
            // Background Circle
            Circle()
                .fill(Color.blue.opacity(0.8))
                .frame(width: 55, height: 55)
            
            // Selected state border
            if isSelected {
                Circle()
                    .stroke(Color.white, lineWidth: 3)
                    .frame(width: 55, height: 55)
            }
            
            // EMOJI (Replaces the First Letter)
            Text(emojiFor(name: sound.name))
                .font(.system(size: 28)) // Slightly reduced for smaller bubbles
                .shadow(radius: isSelected ? 0 : 2)
        }
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .opacity(isSelected ? 1.0 : 0.6)
        .animation(.bouncy, value: isSelected)
    }
    
    // Helper: Maps the Sound Name to an Emoji
    private func emojiFor(name: String) -> String {
        switch name.lowercased() {
        case "duck":    return "🦆"
        case "cow":     return "🐮"
        case "dog":     return "🐶"
        case "cat":     return "🐱"
        case "boing":   return "🌀"
        case "whistle": return "😗"
        case "pop":     return "💥"
        case "bell":    return "🔔"
        case "chime":   return "✨"
        case "shutter": return "📸"
        default:        return "🎵"
        }
    }
}

#Preview {
    SoundCarouselView()
        .environment(AudioManager())
        .environment(SettingsManager())
        .background(Color.black)
}
