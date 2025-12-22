//
//  CameraManager.swift
//  HeyLook
//
//  Created on December 22, 2025.
//

import Foundation
import AVFoundation
import SwiftUI
import Observation

/// Manages camera capture, state machine, and coordinates with AudioManager for the capture sequence.
@Observable
@MainActor
final class CameraManager {
    
    // MARK: - Published State
    
    private(set) var captureState: CaptureState = .idle
    private(set) var capturedPhoto: UIImage?
    private(set) var cameraPosition: AVCaptureDevice.Position = .back
    private(set) var flashMode: AVCaptureDevice.FlashMode = .off
    
    // MARK: - Private Properties
    
    private let captureSession = AVCaptureSession()
    private var photoOutput = AVCapturePhotoOutput()
    private var currentCameraInput: AVCaptureDeviceInput?
    
    /// Active photo capture delegate (must be retained to prevent deallocation before capture completes)
    private var activePhotoDelegate: PhotoCaptureDelegate?
    
    /// Timer for countdown delay (0.5s - 3.0s)
    private var countdownTask: Task<Void, Never>?
    
    /// Reference to AudioManager (injected)
    private let audioManager: AudioManager
    
    /// Current timer delay setting (in seconds)
    var timerDelay: TimeInterval = 1.0
    
    /// Visual countdown enabled flag
    var visualCountdownEnabled: Bool = true
    
    // MARK: - Public Properties (Read-Only)
    
    /// Current active camera device (needed for RotationCoordinator in preview view)
    var currentDevice: AVCaptureDevice? {
        return currentCameraInput?.device
    }
    
    // MARK: - Initialization
    
    init(audioManager: AudioManager) {
        self.audioManager = audioManager
        
        // Set up audio callback for state transitions
        audioManager.onSoundFinished = { [weak self] in
            Task { @MainActor in
                await self?.transitionToCountdown()
            }
        }
    }
    
    // MARK: - Camera Setup
    
    /// Configures the camera capture session
    func setupCamera() async {
        // 1. Check & Request Permission
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        if status == .notDetermined {
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            if !granted {
                print("❌ Camera permission denied")
                return
            }
            // If granted, we continue to setup
        } else if status != .authorized {
            print("❌ Camera permission not granted")
            return
        }
        
        // 2. Configure Session
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .photo
        
        // Add camera input
        await addCameraInput(position: cameraPosition)
        
        // Add photo output
        if captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
        }
        
        captureSession.commitConfiguration()
        
        // 3. Start Running
        // Capture session reference on Main Actor before entering background task
        let session = self.captureSession
        
        // Start session on background thread (no self access needed)
        Task.detached {
            session.startRunning()
        }
    }
    
    /// Adds camera input for specified position
    private func addCameraInput(position: AVCaptureDevice.Position) async {
        // Remove existing input
        if let currentInput = currentCameraInput {
            captureSession.removeInput(currentInput)
        }
        
        // Get camera for position
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position),
              let input = try? AVCaptureDeviceInput(device: camera) else {
            print("❌ Failed to create camera input for position: \(position)")
            return
        }
        
        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
            currentCameraInput = input
        }
    }
    
    // MARK: - Camera Controls
    
    /// Flips between front and rear camera
    func flipCamera() async {
        let newPosition: AVCaptureDevice.Position = cameraPosition == .back ? .front : .back
        
        captureSession.beginConfiguration()
        await addCameraInput(position: newPosition)
        captureSession.commitConfiguration()
        
        cameraPosition = newPosition
    }
    
    /// Cycles flash mode (off → auto → on → off)
    func toggleFlashMode() {
        switch flashMode {
        case .off:
            flashMode = .auto
        case .auto:
            flashMode = .on
        case .on:
            flashMode = .off
        @unknown default:
            flashMode = .off
        }
    }
    
    /// Returns the capture session for preview layer
    func getCaptureSession() -> AVCaptureSession {
        return captureSession
    }
    
    // MARK: - Capture Flow
    
    /// Starts the capture sequence (only allowed from .idle state)
    func startCapture() async {
        guard captureState.canStartCapture else {
            print("⚠️ Cannot start capture - current state: \(captureState)")
            return
        }
        
        // Transition to playingSound
        captureState = .playingSound
        
        // Play selected attention sound (AudioManager will call onSoundFinished when complete)
        audioManager.playSelectedSound()
    }
    
    /// Transitions to countdown state (called by AudioManager callback)
    private func transitionToCountdown() async {
        guard captureState == .playingSound else { return }
        
        captureState = .countingDown
        
        // Start countdown timer
        countdownTask = Task {
            try? await Task.sleep(for: .seconds(timerDelay))
            
            // Check if task was cancelled (abort scenario)
            guard !Task.isCancelled else { return }
            
            await capturePhoto()
        }
    }
    
    /// Captures the photo
    private func capturePhoto() async {
        guard captureState == .countingDown else { return }
        
        captureState = .capturing
        
        // Play shutter sound
        audioManager.playShutterSound()
        
        // Configure photo settings
        let settings = AVCapturePhotoSettings()
        settings.flashMode = flashMode
        
        // Create and RETAIN delegate to prevent deallocation before capture completes
        activePhotoDelegate = PhotoCaptureDelegate { [weak self] image in
            Task { @MainActor in
                await self?.processPhoto(image)
                // Clear delegate after processing
                self?.activePhotoDelegate = nil
            }
        }
        
        // Capture photo
        photoOutput.capturePhoto(with: settings, delegate: activePhotoDelegate!)
    }
    
    /// Processes captured photo and transitions to review
    private func processPhoto(_ image: UIImage?) async {
        captureState = .processing
        
        // Store photo in memory (not saved to library yet)
        capturedPhoto = image
        
        // Transition back to idle (review screen will be shown by UI)
        captureState = .idle
    }
    
    // MARK: - Photo Actions
    
    /// Saves the captured photo to Photos library
    func savePhoto() async throws {
        guard capturedPhoto != nil else {
            throw CameraError.noPhotoToSave
        }
        
        // Request Photos permission if needed
        // (This will be handled by PhotoStorageManager in future)
        // For now, just clear the photo
        capturedPhoto = nil
    }
    
    /// Discards the captured photo and returns to camera
    func retakePhoto() {
        capturedPhoto = nil
        captureState = .idle
    }
    
    // MARK: - Abort Handling
    
    /// Aborts current capture sequence (called when app backgrounds or is interrupted)
    func abortCapture() {
        // Cancel countdown timer
        countdownTask?.cancel()
        countdownTask = nil
        
        // Stop audio
        audioManager.stopAllSounds()
        
        // Transition to aborted, then idle
        captureState = .aborted
        
        // Clean transition back to idle
        Task {
            try? await Task.sleep(for: .milliseconds(100))
            captureState = .idle
        }
    }
}

// MARK: - Photo Capture Delegate

/// Handles photo capture completion
private class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    private let completion: (UIImage?) -> Void
    
    init(completion: @escaping (UIImage?) -> Void) {
        self.completion = completion
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard error == nil,
              let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            completion(nil)
            return
        }
        
        completion(image)
    }
}

// MARK: - Errors

enum CameraError: Error {
    case noPhotoToSave
    case permissionDenied
    case captureSessionFailed
}
