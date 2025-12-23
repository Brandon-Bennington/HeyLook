//
//  FlipCameraButton.swift
//  HeyLook
//
//  Created on December 22, 2025.
//

import SwiftUI

/// A styled flip-camera control that matches the TimerWheelView's dark rounded background.
struct FlipCameraButton: View {
    let isEnabled: Bool
    let action: () async -> Void

    var body: some View {
        Button {
            Task {
                await action()
            }
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.black.opacity(0.6))
                    .frame(width: 60, height: 60)

                Image(systemName: "arrow.triangle.2.circlepath.camera")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
            }
        }
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1.0 : 0.5)
        .accessibilityLabel("Flip camera")
    }
}

#Preview {
    FlipCameraButton(isEnabled: true) { }
        .padding()
        .background(Color.black)
}
