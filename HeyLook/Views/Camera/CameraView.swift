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
    
    // For the flash animation
    @State private var showFlash: Bool = false
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                
                // --------------------------------------------------------
                // SECTION 1: Top Bar (Optional Black Space)
                // --------------------------------------------------------
                Color.black
                    .frame(height: geometry.safeAreaInsets.top)
                
                // --------------------------------------------------------
                // SECTION 2: The Viewfinder (Strict 4:3 Aspect Ratio)
                // --------------------------------------------------------
                ZStack {
                    // A. Live Camera Feed
                    if manager.capturedPhoto == nil {
                        CameraPreviewView(
                            session: manager.getCaptureSession(),
                            currentDevice: manager.currentDevice
                        )
                    }
                    
                    // B. Photo Review (Static Image)
                    if let photo = manager.capturedPhoto {
                        Image(uiImage: photo)
                            .resizable()
                            .scaledToFill() // Fill the 4:3 box
                    }
                    
                    // C. Flash Overlay
                    if showFlash {
                        Color.white
                    }
                }
                // FORCE 4:3 Aspect Ratio (Width / Height = 3 / 4)
                .aspectRatio(3/4, contentMode: .fit)
                .frame(width: geometry.size.width)
                .clipped()
                .background(Color.black)
                
                // --------------------------------------------------------
                // SECTION 3: Controls Area (Fills the bottom black space)
                // --------------------------------------------------------
                ZStack {
                    Color.black.ignoresSafeArea()
                    
                    // A. REVIEW MODE CONTROLS
                    if manager.capturedPhoto != nil {
                        HStack(spacing: 60) {
                            // Retake
                            Button {
                                manager.retakePhoto()
                            } label: {
                                ControlButton(icon: "xmark", color: .red, text: "Retake")
                            }
                            
                            // Save
                            Button {
                                Task {
                                    try? await manager.savePhoto()
                                }
                            } label: {
                                ControlButton(icon: "checkmark", color: .green, text: "Save")
                            }
                        }
                    }
                    
                    // B. LIVE CAMERA CONTROLS
                    if manager.capturedPhoto == nil {
                        VStack(spacing: 20) {
                            
                            // 1. Sound Carousel
                            SoundCarouselView()
                                .frame(height: 80)
                                .disabled(manager.captureState.isCapturing)
                                .opacity(manager.captureState.isCapturing ? 0.5 : 1.0)
                            
                            HStack(alignment: .center, spacing: 30) {
                                
                                // 2. Timer Wheel
                                TimerWheelView()
                                    .disabled(manager.captureState.isCapturing)
                                    .opacity(manager.captureState.isCapturing ? 0.5 : 1.0)
                                
                                // 3. Shutter Button
                                CaptureButton(
                                    isEnabled: !manager.captureState.isCapturing,
                                    action: {
                                        Task {
                                            await manager.startCapture()
                                        }
                                    }
                                )
                                
                                // Spacer to balance Timer
                                Spacer()
                                    .frame(width: 60)
                            }
                        }
                        .padding(.bottom, 20)
                    }
                }
            }
            .ignoresSafeArea(.all, edges: .top) // We handle top safe area manually
        }
        .task {
            await manager.setupCamera()
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .background {
                manager.abortCapture()
            }
        }
        .onChange(of: manager.capturedPhoto) { oldPhoto, newPhoto in
            if newPhoto != nil {
                withAnimation(.linear(duration: 0.1)) { showFlash = true }
                withAnimation(.linear(duration: 0.5).delay(0.1)) { showFlash = false }
            }
        }
    }
}

// Helper View for the Big Review Buttons
struct ControlButton: View {
    let icon: String
    let color: Color
    let text: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 60, height: 60)
                .background(color.opacity(0.8))
                .clipShape(Circle())
            
            Text(text)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
    }
}

#Preview {
    CameraView()
        .environment(CameraManager(audioManager: AudioManager()))
        .environment(AudioManager())
        .background(Color.black)
}
