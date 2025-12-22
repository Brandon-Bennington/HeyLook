//
//  CaptureState.swift
//  HeyLook
//
//  Created by Brandon Bennington on 22/12/25.
//

import Foundation

/// Represents the strict lifecycle of a single capture sequence.
enum CaptureState: String, Sendable {
    /// Ready to begin. UI is unlocked.
    case idle
    
    /// Sound is playing. Inputs locked.
    case playingSound
    
    /// Visual countdown active. Inputs locked.
    case countingDown
    
    /// Shutter triggering.
    case capturing
    
    /// Processing/Saving data.
    case processing
    
    /// Interrupted sequence (backgrounding/lock).
    case aborted
}

// MARK: - UI Helpers
extension CaptureState {
    /// Helper to clean up SwiftUI logic (Disable buttons when true)
    var isCapturing: Bool {
        switch self {
        case .idle, .aborted:
            return false
        case .playingSound, .countingDown, .capturing, .processing:
            return true
        }
    }
    
    /// Helper to prevent double-triggering
    var canStartCapture: Bool {
        self == .idle
    }
}
