//
// ProjectError.swift
// xcodeproj-cli
//
// Error types for xcodeproj-cli operations
//

import Foundation

/// Comprehensive error types for xcodeproj-cli operations
enum ProjectError: Error, CustomStringConvertible {
  case fileAlreadyExists(String)
  case groupNotFound(String)
  case targetNotFound(String)
  case invalidArguments(String)
  case operationFailed(String)

  var description: String {
    switch self {
    case .fileAlreadyExists(let path): return "File already exists: \(path)"
    case .groupNotFound(let name): return "Group not found: \(name)"
    case .targetNotFound(let name): return "Target not found: \(name)"
    case .invalidArguments(let msg): return "Invalid arguments: \(msg)"
    case .operationFailed(let msg): return "Operation failed: \(msg)"
    }
  }
}