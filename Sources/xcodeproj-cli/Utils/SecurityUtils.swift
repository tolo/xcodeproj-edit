//
// SecurityUtils.swift
// xcodeproj-cli
//
// Security and shell command utilities
//

import Foundation

/// Security utilities for safe shell command execution
struct SecurityUtils {
  
  /// Escape shell command to prevent injection attacks
  static func escapeShellCommand(_ command: String) -> String {
    // Use single quotes to prevent most shell expansion, and escape single quotes
    // This is the safest approach for shell command escaping
    let escaped = command.replacingOccurrences(of: "'", with: "'\\''")
    return "'\(escaped)'"
  }
  
  /// Safe shell command using whitelist approach for scripts
  static func safeShellScript(_ script: String) -> String {
    // For build scripts, we need to be more permissive but still safe
    // Allow only alphanumerics and common safe characters
    let allowedCharacters = CharacterSet.alphanumerics.union(
      CharacterSet(charactersIn: " .-_/=:,@")
    )
    
    // Filter out any characters not in the whitelist
    let filtered = script.unicodeScalars
      .filter { allowedCharacters.contains($0) }
      .map { String($0) }
      .joined()
    
    return filtered
  }
  
  /// Validate build settings to prevent dangerous injections
  static func validateBuildSetting(key: String, value: String) -> Bool {
    // Dangerous build settings that could lead to code execution
    let dangerousSettings = [
      "OTHER_LDFLAGS",
      "OTHER_SWIFT_FLAGS", 
      "OTHER_CFLAGS",
      "OTHER_CPLUSPLUSFLAGS",
      "LD_RUNPATH_SEARCH_PATHS",
      "FRAMEWORK_SEARCH_PATHS",
      "LIBRARY_SEARCH_PATHS",
      "HEADER_SEARCH_PATHS"
    ]
    
    // Check if this is a dangerous setting
    if dangerousSettings.contains(key) {
      // Look for suspicious patterns that could indicate code injection
      let suspiciousPatterns = [
        "@executable_path",
        "@loader_path",
        "../",
        "$(", // Command substitution
        "`",  // Command substitution
        ";",  // Command separator
        "&&", // Command chaining
        "||", // Command chaining
        "|",  // Pipe
        ">",  // Redirect
        "<"   // Redirect
      ]
      
      for pattern in suspiciousPatterns {
        if value.contains(pattern) {
          return false // Reject suspicious values
        }
      }
    }
    
    return true
  }
}