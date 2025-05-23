//
//  SyncStatus.swift
//  ptchampion
//
//  Created to resolve SyncStatus ambiguity across multiple files
//

import Foundation

/// Enum to track synchronization state of workout records
public enum SyncStatus: String, Codable {
    case synced           // Successfully synced with server
    case pendingUpload    // New local record that needs to be uploaded
    case pendingUpdate    // Local changes that need to be synced
    case pendingDeletion  // Marked for deletion, needs to be synced
    case conflicted       // Conflict detected between server and local version
    
    /// Map iOS granular status to backend's simpler model if needed
    var backendValue: String {
        switch self {
        case .synced:
            return "synced"
        case .pendingUpload, .pendingUpdate, .pendingDeletion:
            return "pending"
        case .conflicted:
            return "conflict"
        }
    }
    
    /// Initialize from backend value
    init(backendValue: String) {
        switch backendValue {
        case "synced":
            self = .synced
        case "pending":
            self = .pendingUpload  // Default to upload for generic pending
        case "conflict":
            self = .conflicted
        default:
            self = .pendingUpload  // Safe default
        }
    }
} 