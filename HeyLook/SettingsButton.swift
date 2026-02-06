//
//  SettingsButton.swift
//  HeyLook
//
//  Created on January 26, 2026.
//

import SwiftUI

/// A styled settings button that matches the FlipCameraButton design.
struct SettingsButton: View {
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.black.opacity(0.6))
                    .frame(width: 60, height: 60)

                Image(systemName: "gearshape.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
            }
        }
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1.0 : 0.5)
        .accessibilityLabel("Settings")
    }
}

#Preview {
    SettingsButton(isEnabled: true) { }
        .padding()
        .background(Color.black)
}
