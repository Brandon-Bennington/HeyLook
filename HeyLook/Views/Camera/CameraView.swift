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

    // Flash animation
    @State private var showFlash: Bool = false

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {

                // --------------------------------------------------------
                // SECTION 1: Top Bar (Safe Area Padding)
                // --------------------------------------------------------
                Color.black
                    .frame(height: geometry.safeAreaInsets.top)

                // --------------------------------------------------------
                // SECTION 2: Viewfinder (4:3 Aspect Ratio)
                // --------------------------------------------------------
                ZStack {

                    // A. Live Camera Feed
                    if manager.capturedPhoto == nil {
                        CameraPreviewView(
                            session: manager.getCaptureSession(),
                            currentDevice: manager.currentDevice
                        )
                    }

                    // B. Photo Review
                    if let photo = manager.capturedPhoto {
                        Image(uiImage: photo)
                            .resizable()
                            .scaledToFill()
                    }

                    // C. Flash Overlay
                    if showFlash {
                        Color.white
                    }
                }
                .aspectRatio(3 / 4, contentMode: .fit)
                .frame(width: geometry.size.width)
                .clipped()
                .background(Color.black)

                // --------------------------------------------------------
                // SECTION 3: Controls Area
                // --------------------------------------------------------
                ZStack {
                    Color.black.ignoresSafeArea()

                    // ----------------------------------------------------
                    // A. REVIEW MODE CONTROLS
                    // ----------------------------------------------------
                    if manager.capturedPhoto != nil {
                        HStack(spacing: 60) {

                            // Retake
                            Button {
                                manager.retakePhoto()
                            } label: {
                                ControlButton(
                                    icon: "xmark",
                                    color: .red,
                                    text: "Retake"
                                )
                            }

                            // Save
                            Button {
                                Task {
                                    try? await manager.savePhoto()
                                }
                            } label: {
                                ControlButton(
                                    icon: "checkmark",
                                    color: .green,
                                    text: "Save"
                                )
                            }
                        }
                    }

                    // ----------------------------------------------------
                    // B. LIVE CAMERA CONTROLS
                    // ----------------------------------------------------
                    if manager.capturedPhoto == nil {
                        VStack(spacing: 20) {

                            // 1. Sound Carousel
                            SoundCarouselView()
                                .frame(height: 80)
                                .disabled(manager.captureState.isCapturing)
                                .opacity(manager.captureState.isCapturing ? 0.5 : 1.0)

                            // 2. Main Controls Row
                            HStack(alignment: .center, spacing: 30) {

                                // Timer Wheel (Left)
                                TimerWheelView()
                                    .disabled(manager.captureState.isCapturing)
                                    .opacity(manager.captureState.isCapturing ? 0.5 : 1.0)

                                // Shutter Button (Center)
                                CaptureButton(
                                    isEnabled: !manager.captureState.isCapturing,
                                    action: {
                                        Task {
                                            await manager.startCapture()
                                        }
                                    }
                                )

                                // Flip Camera Button (Right)
                                FlipCameraButton(isEnabled: !manager.captureState.isCapturing) {
                                    await manager.flipCamera()
                                }
                            }
                        }
                        .padding(.bottom, 20)
                    }
                }
            }
            .ignoresSafeArea(.all, edges: .top)
        }
        .task {
            await manager.setupCamera()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background {
                manager.abortCapture()
            }
        }
        .onChange(of: manager.capturedPhoto) { _, newPhoto in
            if newPhoto != nil {
                withAnimation(.linear(duration: 0.1)) {
                    showFlash = true
                }
                withAnimation(.linear(duration: 0.5).delay(0.1)) {
                    showFlash = false
                }
            }
        }
    }
}

// ------------------------------------------------------------
// MARK: - Helper Views
// ------------------------------------------------------------

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

// ------------------------------------------------------------
// MARK: - Preview
// ------------------------------------------------------------

#Preview {
    CameraView()
        .environment(CameraManager(audioManager: AudioManager()))
        .environment(AudioManager())
        .background(Color.black)
}
