//
//  SoundCarouselView.swift
//  HeyLook
//
//  Created on December 22, 2025.
//

import SwiftUI

struct SoundCarouselView: View {
    @Environment(AudioManager.self) private var audioManager
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 20) {
                ForEach(Sound.attentionSounds) { sound in
                    SoundBubble(
                        sound: sound,
                        isSelected: sound == audioManager.selectedSound
                    )
                    .onTapGesture {
                        withAnimation(.bouncy) {
                            audioManager.selectSound(sound)
                        }
                        audioManager.previewSound(sound)
                    }
                }
            }
            .padding(.horizontal, 30)
        }
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
                .frame(width: 60, height: 60)
            
            // Selected state border
            if isSelected {
                Circle()
                    .stroke(Color.white, lineWidth: 3)
                    .frame(width: 60, height: 60)
            }
            
            // EMOJI (Replaces the First Letter)
            Text(emojiFor(name: sound.name))
                .font(.system(size: 30)) // Increased size for emoji
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
        .background(Color.black)
}
