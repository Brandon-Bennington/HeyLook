//
//  TimerWheelView.swift
//  HeyLook
//
//  Created on December 22, 2025.
//

import SwiftUI

struct TimerWheelView: View {
    @Environment(CameraManager.self) private var manager
    
    // Available timer delays (0.5s - 3.0s in 0.5s increments)
    private let timerOptions: [TimeInterval] = [0.5, 1.0, 1.5, 2.0, 2.5, 3.0]
    
    var body: some View {
        Picker("Timer Delay", selection: Binding(
            get: { manager.timerDelay },
            set: { manager.timerDelay = $0 }
        )) {
            ForEach(timerOptions, id: \.self) { delay in
                Text("\(String(format: "%.1f", delay))s")
                    .foregroundColor(.white)
                    .tag(delay)
            }
        }
        .pickerStyle(.wheel)
        .frame(width: 60, height: 80)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.black.opacity(0.6))
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

#Preview {
    TimerWheelView()
        .environment(CameraManager(audioManager: AudioManager(), settingsManager: SettingsManager()))
        .background(Color.gray)
}
