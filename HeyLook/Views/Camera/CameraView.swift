//
//  CameraView.swift
//  HeyLook
//
//  Created on December 22, 2025.
//

import SwiftUI

struct CameraView: View {
    @Environment(CameraManager.self) private var manager
    @Environment(AudioManager.self) private var audioManager
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        ZStack {
            // Bottom layer: Live camera preview
            if manager.capturedPhoto == nil {
                CameraPreviewView(
                    session: manager.getCaptureSession(),
                    currentDevice: manager.currentDevice
                )
                .ignoresSafeArea()
            }
            
            // Photo review overlay (when photo is captured)
            if let photo = manager.capturedPhoto {
                Image(uiImage: photo)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
            }
            
            // Top overlays (only visible when photo is captured)
            if manager.capturedPhoto != nil {
                VStack {
                    HStack {
                        // Retake button (top left)
                        Button {
                            manager.retakePhoto()
                        } label: {
                            Text("Retake")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.black.opacity(0.6))
                                .cornerRadius(8)
                        }
                        .padding(.leading, 20)
                        
                        Spacer()
                        
                        // Save button (top right)
                        Button {
                            Task {
                                try? await manager.savePhoto()
                            }
                        } label: {
                            Text("Save")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.blue)
                                .cornerRadius(8)
                        }
                        .padding(.trailing, 20)
                    }
                    .padding(.top, 50)
                    
                    Spacer()
                }
            }
            
            // Bottom controls (only visible when NOT reviewing photo)
            if manager.capturedPhoto == nil {
                VStack {
                    Spacer()
                                
                    // Controls container
                    VStack(spacing: 30) {
                                    
                        // 1. Sound Carousel (Real Component)
                        SoundCarouselView()
                            .frame(height: 80)
                            .disabled(manager.captureState.isCapturing)
                            .opacity(manager.captureState.isCapturing ? 0.5 : 1.0)
                                    
                        HStack(alignment: .center, spacing: 40) {
                                        
                            // 2. Timer Wheel (Real Component)
                            TimerWheelView()
                                .disabled(manager.captureState.isCapturing)
                                .opacity(manager.captureState.isCapturing ? 0.5 : 1.0)
                                        
                            // 3. Shutter Button (Your Custom Component)
                            CaptureButton(
                                isEnabled: !manager.captureState.isCapturing,
                                action: {
                                    Task {
                                        await manager.startCapture()
                                    }
                                }
                            )
                                        
                            // Spacer to balance the layout visually (since Timer is on left)
                            Spacer()
                                .frame(width: 60)
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .task {
            await manager.setupCamera()
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            // Abort capture if app backgrounds
            if newPhase == .background {
                manager.abortCapture()
            }
        }
    }
}

#Preview {
    CameraView()
        .environment(CameraManager(audioManager: AudioManager()))
        .environment(AudioManager())
}
