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
    var timerDelay: TimeInterval = 0.5 // Default to 0.5s for quick reactions
    
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
        let session = self.captureSession
        Task.detached {
            session.startRunning()
        }
    }
    
    /// Adds camera input for specified position
    private func addCameraInput(position: AVCaptureDevice.Position) async {
        if let currentInput = currentCameraInput {
            captureSession.removeInput(currentInput)
        }
        
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
    
    func flipCamera() async {
        let newPosition: AVCaptureDevice.Position = cameraPosition == .back ? .front : .back
        
        captureSession.beginConfiguration()
        await addCameraInput(position: newPosition)
        captureSession.commitConfiguration()
        
        cameraPosition = newPosition
    }
    
    func toggleFlashMode() {
        switch flashMode {
        case .off: flashMode = .auto
        case .auto: flashMode = .on
        case .on: flashMode = .off
        @unknown default: flashMode = .off
        }
    }
    
    func getCaptureSession() -> AVCaptureSession {
        return captureSession
    }
    
    // MARK: - Capture Flow
    
    /// Starts the capture sequence: Sound + Timer run in parallel
    func startCapture() async {
        guard !captureState.isCapturing else { return }
        
        // 1. Lock the UI
        captureState = .capturing
        
        // 2. Start the Sound (Fire & Forget)
        audioManager.playSelectedSound()
        
        // 3. Start the Timer (In parallel with the sound)
        // This ensures we snap the photo while the animal is still looking
        try? await Task.sleep(nanoseconds: UInt64(timerDelay * 1_000_000_000))
        
        // 4. Snap the Photo
        capturePhoto()
    }
    
    /// Captures the photo
    private func capturePhoto() {
        // 1. STOP the animal sound immediately (The "Cut-off")
        audioManager.stopAllSounds()
        
        // 2. Play shutter sound (The "Click")
        audioManager.playShutterSound()
        
        let settings = AVCapturePhotoSettings()
        settings.flashMode = flashMode
        
        // Create and RETAIN delegate
        activePhotoDelegate = PhotoCaptureDelegate { [weak self] image in
            Task { @MainActor in
                await self?.processPhoto(image)
                self?.activePhotoDelegate = nil
            }
        }
        
        photoOutput.capturePhoto(with: settings, delegate: activePhotoDelegate!)
    }
    
    /// Processes captured photo and transitions to review
    private func processPhoto(_ image: UIImage?) async {
        captureState = .processing
        capturedPhoto = image
        captureState = .idle
    }
    
    // MARK: - Photo Actions
    
    func savePhoto() async throws {
        guard let photo = capturedPhoto else {
            throw CameraError.noPhotoToSave
        }
        
        // Simple save to Camera Roll
        UIImageWriteToSavedPhotosAlbum(photo, nil, nil, nil)
        
        // Close review screen
        capturedPhoto = nil
    }
    
    func retakePhoto() {
        capturedPhoto = nil
        captureState = .idle
    }
    
    // MARK: - Abort Handling
    
    func abortCapture() {
        countdownTask?.cancel()
        countdownTask = nil
        audioManager.stopAllSounds()
        captureState = .aborted
        
        Task {
            try? await Task.sleep(for: .milliseconds(100))
            captureState = .idle
        }
    }
}

// MARK: - Photo Capture Delegate

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

enum CameraError: Error {
    case noPhotoToSave
}
