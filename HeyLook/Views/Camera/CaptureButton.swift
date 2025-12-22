//
//  CaptureButton.swift
//  HeyLook
//
//  Created on December 22, 2025.
//

import SwiftUI

struct CaptureButton: View {
    let isEnabled: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // Outer ring
                Circle()
                    .stroke(Color.white, lineWidth: 3)
                    .frame(width: 80, height: 80)
                
                // Inner circle
                Circle()
                    .fill(Color.white)
                    .frame(width: 70, height: 70)
            }
        }
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1.0 : 0.5)
        .animation(.easeInOut(duration: 0.2), value: isEnabled)
    }
}

#Preview {
    VStack(spacing: 40) {
        CaptureButton(isEnabled: true, action: {})
        CaptureButton(isEnabled: false, action: {})
    }
    .padding()
    .background(Color.black)
}
