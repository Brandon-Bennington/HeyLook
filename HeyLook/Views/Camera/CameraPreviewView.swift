//
//  CameraPreviewView.swift
//  HeyLook
//
//  Created on December 22, 2025.
//

import SwiftUI
import AVFoundation

/// SwiftUI wrapper for AVCaptureVideoPreviewLayer with automatic rotation handling via iOS 26 RotationCoordinator
struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession
    let currentDevice: AVCaptureDevice?
    
    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }
    
    func updateUIView(_ uiView: PreviewView, context: Context) {
        if uiView.previewLayer.session !== session {
            uiView.previewLayer.session = session
        }
        
        // Mirror the preview for front camera
        if let device = currentDevice {
            let isFrontCamera = device.position == .front
            if let connection = uiView.previewLayer.connection {
                connection.automaticallyAdjustsVideoMirroring = false
                connection.isVideoMirrored = isFrontCamera
            }
        }
        
        // Pass the device AND the layer to the coordinator
        if let device = currentDevice {
            context.coordinator.setupRotation(for: uiView, device: device)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    // MARK: - Coordinator
    
    class Coordinator: NSObject {
        // Keep strong reference to the coordinator so it doesn't deallocate
        private var rotationCoordinator: AVCaptureDevice.RotationCoordinator?
        private var observation: NSKeyValueObservation?
        private weak var currentDevice: AVCaptureDevice?
        
        func setupRotation(for view: PreviewView, device: AVCaptureDevice) {
            // Optimization: Don't reconstruct if device hasn't changed
            guard device != currentDevice else { return }
            currentDevice = device
            
            // Clean up previous
            observation?.invalidate()
            
            // Correct Initializer (Requires device AND previewLayer)
            let coordinator = AVCaptureDevice.RotationCoordinator(device: device, previewLayer: view.previewLayer)
            self.rotationCoordinator = coordinator // Retain it!
            
            // Observe rotation angle changes
            observation = coordinator.observe(\.videoRotationAngleForHorizonLevelPreview, options: [.new, .initial]) { [weak view] _, change in
                guard let connection = view?.previewLayer.connection,
                      let angle = change.newValue else { return }
                
                // Update the layer
                connection.videoRotationAngle = angle
            }
        }
    }
    
    // MARK: - PreviewView
    
    class PreviewView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
    }
}
