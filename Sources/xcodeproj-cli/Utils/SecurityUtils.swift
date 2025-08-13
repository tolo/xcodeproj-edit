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
    // Comprehensive shell metacharacter escaping
    let charactersToEscape = [
      "$", "`", "\\", "\"", "'", "\n", "\r", "\t",
      ";", "&", "|", "(", ")", "{", "}", "[", "]",
      "<", ">", "*", "?", "~", "#", "%", "^",
      "!", "@", "+", "=", " "
    ]
    
    var escaped = command
    
    // First escape backslashes to prevent double-escaping
    escaped = escaped.replacingOccurrences(of: "\\", with: "\\\\")
    
    // Then escape all other metacharacters except backslash
    for char in charactersToEscape where char != "\\" {
      escaped = escaped.replacingOccurrences(of: char, with: "\\\(char)")
    }
    
    return escaped
  }
}