//
//  CameraView.swift
//  HeyLook
//
//  Created on December 22, 2025.
//

import SwiftUI
import UIKit
import Observation

struct CameraView: View {
    @Environment(CameraManager.self) private var manager
    @Environment(AudioManager.self) private var audioManager
    @Environment(SettingsManager.self) private var settings
    @Environment(\.scenePhase) private var scenePhase

    // Flash animation
    @State private var showFlash: Bool = false
    @State private var reviewDragOffset: CGFloat = 0
    @State private var showReviewHints: Bool = true
    @State private var showSaveBanner: Bool = false
    @State private var showLaunchOverlay: Bool = true
    @State private var showSettings: Bool = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Black background
                Color.black.ignoresSafeArea()
                
                // Viewfinder centered in the top 2/3 area
                VStack(spacing: 0) {
                    ZStack {
                        Color.black
                        ViewfinderSection(
                            geometryWidth: geometry.size.width,
                            aspectRatio: settings.selectedPhotoRatio.aspectRatio,
                            showFlash: $showFlash,
                            reviewDragOffset: $reviewDragOffset,
                            showReviewHints: $showReviewHints,
                            showSaveBanner: $showSaveBanner
                        )
                    }
                    .frame(height: (geometry.size.height - geometry.safeAreaInsets.top) * 2 / 3)
                    .padding(.top, geometry.safeAreaInsets.top)
                    
                    Spacer()
                }
                
                // Controls positioned at bottom third
                VStack {
                    Spacer()
                    ControlsSection(
                        reviewMode: manager.capturedPhoto != nil,
                        isCapturing: manager.captureState.isCapturing,
                        onRetake: { manager.retakePhoto() },
                        onSave: { Task { try? await manager.savePhoto() } },
                        onStartCapture: { Task { await manager.startCapture() } },
                        onFlipCamera: { await manager.flipCamera() },
                        onShowSettings: { showSettings = true }
                    )
                    .frame(height: (geometry.size.height - geometry.safeAreaInsets.top) / 3)
                }
                .padding(.top, geometry.safeAreaInsets.top)
                
                if showLaunchOverlay {
                    LaunchOverlay()
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .ignoresSafeArea(.all, edges: .top)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .task {
            await manager.setupCamera()
            withAnimation(.easeOut(duration: 0.35)) { showLaunchOverlay = false }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                if showLaunchOverlay {
                    withAnimation(.easeOut(duration: 0.35)) { showLaunchOverlay = false }
                }
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background { manager.abortCapture() }
        }
        .onChange(of: manager.capturedPhoto) { _, newPhoto in
            if newPhoto != nil {
                withAnimation(.linear(duration: 0.1)) { showFlash = true }
                withAnimation(.linear(duration: 0.5).delay(0.1)) { showFlash = false }
            }
        }
    }
}

private struct TopSafeArea: View {
    let color: Color
    let height: CGFloat
    var body: some View {
        color.frame(height: height)
    }
}

private struct ViewfinderSection: View {
    @Environment(CameraManager.self) private var manager

    let geometryWidth: CGFloat
    let aspectRatio: CGFloat
    @Binding var showFlash: Bool
    @Binding var reviewDragOffset: CGFloat
    @Binding var showReviewHints: Bool
    @Binding var showSaveBanner: Bool

    var body: some View {
        ZStack {
            if manager.capturedPhoto == nil {
                CameraPreviewView(
                    session: manager.getCaptureSession(),
                    currentDevice: manager.currentDevice
                )
            }

            if let photo = manager.capturedPhoto {
                Image(uiImage: photo)
                    .resizable()
                    .scaledToFill()
                    .offset(x: reviewDragOffset)
                    .rotationEffect(.degrees(Double(reviewDragOffset / 12)))
                    .scaleEffect(1 - min(abs(reviewDragOffset) / 4000, 0.02))
                    .animation(.interactiveSpring(response: 0.25, dampingFraction: 0.85), value: reviewDragOffset)
                    .clipped()
            }

            if showFlash { Color.white }

            if manager.capturedPhoto != nil {
                ReviewDragOverlay(
                    reviewDragOffset: $reviewDragOffset,
                    showReviewHints: $showReviewHints,
                    showSaveBanner: $showSaveBanner
                )
            }
        }
        .aspectRatio(aspectRatio, contentMode: .fit)
        .frame(width: geometryWidth)
        .clipped()
        .background(Color.black)
    }
}

private struct ReviewDragOverlay: View {
    @Environment(CameraManager.self) private var manager

    @Binding var reviewDragOffset: CGFloat
    @Binding var showReviewHints: Bool
    @Binding var showSaveBanner: Bool

    var body: some View {
        Color.clear
            .contentShape(Rectangle())
            .gesture(
                DragGesture()
                    .onChanged { value in
                        showReviewHints = false
                        reviewDragOffset = value.translation.width
                    }
                    .onEnded { value in
                        let width = value.translation.width
                        let predicted = value.predictedEndTranslation.width
                        let velocity = predicted - width
                        let commitDistance: CGFloat = 160
                        let flingVelocity: CGFloat = 260

                        func flyOutAndPerform(_ action: @escaping () -> Void, direction: CGFloat) {
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                                reviewDragOffset = direction * 1000
                            }
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.impactOccurred()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                                action()
                                reviewDragOffset = 0
                                showReviewHints = true
                            }
                        }

                        if width > commitDistance || velocity > flingVelocity {
                            flyOutAndPerform({ Task { try? await manager.savePhoto() } }, direction: 1)
                        } else if width < -commitDistance || velocity < -flingVelocity {
                            flyOutAndPerform({ manager.retakePhoto() }, direction: -1)
                        } else {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                reviewDragOffset = 0
                            }
                        }
                    }
            )
    }
}

private struct ControlsSection: View {
    @Environment(CameraManager.self) private var manager

    let reviewMode: Bool
    let isCapturing: Bool
    let onRetake: () -> Void
    let onSave: () -> Void
    let onStartCapture: () -> Void
    let onFlipCamera: () async -> Void
    let onShowSettings: () -> Void

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if reviewMode {
                VStack(spacing: 12) {
                    HStack(spacing: 60) {
                        Button(action: onRetake) {
                            ControlButton(icon: "xmark", color: .red, text: "Retake")
                        }
                        Button(action: onSave) {
                            ControlButton(icon: "checkmark", color: .green, text: "Save")
                        }
                    }
                    Text("Tip: Swipe left to retake, right to save")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.7))
                }
                .transition(.opacity)
            } else {
                VStack(spacing: 12) {
                    SoundCarouselView()
                        .disabled(isCapturing)
                        .opacity(isCapturing ? 0.5 : 1.0)
                    HStack(alignment: .center, spacing: 30) {
                        TimerWheelView()
                            .disabled(isCapturing)
                            .opacity(isCapturing ? 0.5 : 1.0)
                        CaptureButton(isEnabled: !isCapturing) {
                            onStartCapture()
                        }
                        VStack(spacing: 8) {
                            FlipCameraButton(isEnabled: !isCapturing) {
                                await onFlipCamera()
                            }
                            SettingsButton(isEnabled: !isCapturing) {
                                onShowSettings()
                            }
                        }
                    }
                }
                .padding(.bottom, 10)
            }
        }
    }
}

private struct LaunchOverlay: View {
    @State private var appear: Bool = false
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "camera.aperture")
                    .font(.system(size: 56, weight: .bold))
                    .foregroundStyle(.white)
                Text("HeyLook")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(.white)
                Text("Loading camera…")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.7))
            }
            .opacity(appear ? 1 : 0)
            .scaleEffect(appear ? 1 : 0.96)
            .animation(.easeOut(duration: 0.35), value: appear)
            .onAppear { appear = true }
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
        .environment(CameraManager(audioManager: AudioManager(), settingsManager: SettingsManager()))
        .environment(AudioManager())
        .environment(SettingsManager())
        .background(Color.black)
}

