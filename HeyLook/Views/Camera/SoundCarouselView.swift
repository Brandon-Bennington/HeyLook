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
            Circle()
                .fill(Color.blue.opacity(0.8))
                .frame(width: 60, height: 60)
            
            // Selected state border
            if isSelected {
                Circle()
                    .stroke(Color.white, lineWidth: 3)
                    .frame(width: 60, height: 60)
            }
            
            // First letter of sound name
            Text(sound.name.prefix(1))
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .opacity(isSelected ? 1.0 : 0.6)
        .animation(.bouncy, value: isSelected)
    }
}

#Preview {
    SoundCarouselView()
        .environment(AudioManager())
        .background(Color.black)
}
