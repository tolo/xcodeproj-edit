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
  static func sanitizePath(_ path: String) -> String? {
    // Limit path length to prevent resource exhaustion
    guard path.count <= 1024 else {
      return nil // Path too long
    }
    
    // Check for null bytes
    if path.contains("\0") {
      return nil
    }
    
    // Decode URL-encoded sequences that could be used to bypass filters
    guard let decodedPath = path.removingPercentEncoding else {
      return nil
    }
    
    // Normalize path by resolving . and .. components
    let normalizedPath = (decodedPath as NSString).standardizingPath
    
    // Block path traversal attempts that try to escape project boundaries
    if normalizedPath.contains("../..") || normalizedPath.contains("..\\..") ||
       normalizedPath.contains("..\\..") || normalizedPath.hasPrefix("../") {
      // Allow single ../ only if it doesn't result in escaping the project root
      let components = normalizedPath.components(separatedBy: "/")
      var depth = 0
      for component in components {
        if component == ".." {
          depth -= 1
          if depth < -1 { // Allow one level up but not more
            return nil
          }
        } else if !component.isEmpty && component != "." {
          depth += 1
        }
      }
    }
    
    // For absolute paths, block critical system directories and sensitive locations
    if normalizedPath.hasPrefix("/") {
      let criticalDirs = [
        "/System/", "/usr/", "/bin/", "/sbin/", "/var/", "/tmp/", "/etc/",
        "/proc/", "/dev/", "/boot/", "/root/", "/Library/System/", "/private/"
      ]
      for dir in criticalDirs {
        if normalizedPath.hasPrefix(dir) {
          return nil
        }
      }
    }
    
    // Additional checks for suspicious patterns
    let suspiciousPatterns = [
      "\\x", "\\u", "%2e%2e", "%2f", "%5c", // Encoded traversal attempts
      "//", "\\\\", // Double slashes
      "\r", "\n", "\t" // Control characters
    ]
    
    for pattern in suspiciousPatterns {
      if normalizedPath.lowercased().contains(pattern.lowercased()) {
        return nil
      }
    }
    
    return normalizedPath
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