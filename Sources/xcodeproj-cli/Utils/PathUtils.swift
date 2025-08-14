//
// PathUtils.swift
// xcodeproj-cli
//
// Path manipulation and validation utilities
//

import Foundation

/// Path manipulation and security utilities
struct PathUtils {

  /// Sanitize and validate a file path for security
  /// Delegates to SecurityUtils for the actual implementation
  static func sanitizePath(_ path: String) -> String? {
    return SecurityUtils.sanitizePath(path)
  }

  /// Validate a file path and throw appropriate error if invalid
  static func validatePath(_ path: String) throws -> String {
    guard let validPath = sanitizePath(path) else {
      throw ProjectError.invalidArguments("Invalid file path: \(path)")
    }
    return validPath
  }

  /// Check if a file should be included based on filtering rules
  static func shouldIncludeFile(_ path: String) -> Bool {
    let filename = (path as NSString).lastPathComponent
    let excludedFiles = [".DS_Store", "Thumbs.db", ".git", ".gitignore", ".gitkeep"]
    let excludedExtensions = [".orig", ".bak", ".tmp", ".temp"]

    // Skip hidden files (starting with .)
    if filename.hasPrefix(".") && !filename.hasSuffix(".h") && !filename.hasSuffix(".m") {
      return false
    }

    // Skip excluded files
    if excludedFiles.contains(filename) {
      return false
    }

    // Skip excluded extensions
    for ext in excludedExtensions {
      if filename.hasSuffix(ext) {
        return false
      }
    }

    return true
  }

  /// Check if file should be added to compile sources
  static func isCompilableFile(_ path: String) -> Bool {
    let compilableExtensions = ["swift", "m", "mm", "cpp", "cc", "cxx", "c"]
    return compilableExtensions.contains((path as NSString).pathExtension.lowercased())
  }
}
