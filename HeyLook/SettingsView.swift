//
//  SettingsView.swift
//  HeyLook
//
//  Created on January 26, 2026.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(SettingsManager.self) private var settings
    @Environment(AudioManager.self) private var audioManager
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 30) {
                        // Photo Ratio Section
                        PhotoRatioSection()
                        
                        Divider()
                            .background(Color.white.opacity(0.3))
                        
                        // Favorite Sounds Section
                        FavoriteSoundsSection()
                    }
                    .padding()
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

// MARK: - Photo Ratio Section

private struct PhotoRatioSection: View {
    @Environment(SettingsManager.self) private var settings
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Photo Ratio")
                .font(.headline)
                .foregroundColor(.white)
            
            Text("Choose the aspect ratio for your photos and camera viewfinder")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
            
            VStack(spacing: 12) {
                ForEach(SettingsManager.PhotoRatio.allCases) { ratio in
                    PhotoRatioButton(ratio: ratio)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct PhotoRatioButton: View {
    @Environment(SettingsManager.self) private var settings
    let ratio: SettingsManager.PhotoRatio
    
    private var isSelected: Bool {
        settings.selectedPhotoRatio == ratio
    }
    
    var body: some View {
        Button {
            withAnimation(.bouncy) {
                settings.setPhotoRatio(ratio)
            }
        } label: {
            HStack {
                // Visual representation of ratio
                RatioPreview(ratio: ratio)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(ratio.displayName)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    
                    Text(ratioDescription(for: ratio))
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title3)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue.opacity(0.2) : Color.white.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
    }
    
    private func ratioDescription(for ratio: SettingsManager.PhotoRatio) -> String {
        switch ratio {
        case .ratio_3_4: return "Portrait • Standard"
        case .ratio_4_3: return "Landscape • Classic"
        case .ratio_16_9: return "Wide • Cinematic"
        case .ratio_1_1: return "Square • Instagram"
        }
    }
}

private struct RatioPreview: View {
    let ratio: SettingsManager.PhotoRatio
    
    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(Color.white.opacity(0.8))
            .aspectRatio(ratio.aspectRatio, contentMode: .fit)
            .frame(width: ratio == .ratio_16_9 || ratio == .ratio_4_3 ? 50 : nil,
                   height: ratio == .ratio_3_4 || ratio == .ratio_1_1 ? 50 : nil)
    }
}

// MARK: - Favorite Sounds Section

private struct FavoriteSoundsSection: View {
    @Environment(SettingsManager.self) private var settings
    @Environment(AudioManager.self) private var audioManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Favorite Sounds")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("Select up to 5 sounds that will appear in the camera view. Tap and hold to reorder.")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            // Selected favorites (reorderable)
            if !settings.favoriteSounds.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your Favorites (\(settings.favoriteSounds.count)/5)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white.opacity(0.9))
                    
                    FavoritesList()
                }
            }
            
            // All sounds selection grid
            VStack(alignment: .leading, spacing: 8) {
                Text("All Sounds")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white.opacity(0.9))
                
                AllSoundsGrid()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct FavoritesList: View {
    @Environment(SettingsManager.self) private var settings
    @Environment(AudioManager.self) private var audioManager
    @Environment(\.editMode) private var editMode
    @State private var isEditMode: Bool = false
    
    var body: some View {
        List {
            ForEach(settings.favoriteSounds) { sound in
                HStack {
                    Text(emojiFor(sound: sound))
                        .font(.title2)
                    
                    Text(sound.name)
                        .font(.body)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button {
                        audioManager.previewSound(sound)
                    } label: {
                        Image(systemName: "play.circle.fill")
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(.plain)
                    
                    Button {
                        withAnimation {
                            settings.toggleFavoriteSound(sound)
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.vertical, 8)
                .listRowBackground(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.blue.opacity(0.2))
                )
            }
            .onMove { source, destination in
                settings.moveFavoriteSound(from: source, to: destination)
            }
        }
        .environment(\.editMode, .constant(.active))
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .scrollDisabled(true)
        .frame(height: CGFloat(settings.favoriteSounds.count) * 72)
    }
}

private struct AllSoundsGrid: View {
    @Environment(SettingsManager.self) private var settings
    @Environment(AudioManager.self) private var audioManager
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(Sound.attentionSounds) { sound in
                SoundGridItem(sound: sound)
            }
        }
    }
}

private struct SoundGridItem: View {
    @Environment(SettingsManager.self) private var settings
    @Environment(AudioManager.self) private var audioManager
    
    let sound: Sound
    
    private var isFavorited: Bool {
        settings.isFavorite(sound)
    }
    
    private var canAddMore: Bool {
        settings.favoriteSounds.count < 5
    }
    
    var body: some View {
        Button {
            if isFavorited || canAddMore {
                withAnimation(.bouncy) {
                    settings.toggleFavoriteSound(sound)
                }
            }
        } label: {
            VStack(spacing: 8) {
                ZStack(alignment: .topTrailing) {
                    Circle()
                        .fill(isFavorited ? Color.blue.opacity(0.8) : Color.white.opacity(0.2))
                        .frame(width: 70, height: 70)
                    
                    Text(emojiFor(sound: sound))
                        .font(.system(size: 32))
                        .frame(width: 70, height: 70)
                    
                    if isFavorited {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .background(Circle().fill(Color.black))
                            .offset(x: 4, y: -4)
                    }
                }
                
                Text(sound.name)
                    .font(.caption)
                    .foregroundColor(.white)
            }
        }
        .disabled(!isFavorited && !canAddMore)
        .opacity(!isFavorited && !canAddMore ? 0.5 : 1.0)
        .onTapGesture(count: 2) {
            // Double tap to preview
            audioManager.previewSound(sound)
        }
    }
}

// MARK: - Helper Functions

private func emojiFor(sound: Sound) -> String {
    switch sound.name.lowercased() {
    case "duck": return "🦆"
    case "cow": return "🐮"
    case "dog": return "🐶"
    case "cat": return "🐱"
    case "boing": return "🌀"
    case "whistle": return "😗"
    case "pop": return "💥"
    case "bell": return "🔔"
    case "chime": return "✨"
    case "shutter": return "📸"
    default: return "🎵"
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
        .environment(SettingsManager())
        .environment(AudioManager())
}
