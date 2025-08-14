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
    // Use single quotes to prevent shell expansion and escape embedded single quotes
    // This handles the tricky case of embedded single quotes in shell commands
    let escaped = command.replacingOccurrences(of: "'", with: "'\"'\"'")
    return "'\(escaped)'"
  }

  /// Validate shell script for dangerous patterns instead of using restrictive whitelist
  static func validateShellScript(_ script: String) -> Bool {
    // Check for dangerous patterns that could lead to code injection
    let dangerousPatterns = [
      "$(",  // Command substitution
      "`",  // Command substitution (backticks)
      "${",  // Variable expansion that could be dangerous
      "eval ",  // Direct code evaluation
      "exec ",  // Process replacement
      " | sh",  // Piping to shell
      " | bash",  // Piping to bash
      " | zsh",  // Piping to zsh
      ";",  // Command separator
      "&&",  // Command chaining
      "||",  // Command chaining OR
      " > ",  // File redirection output
      " >> ",  // File redirection append
      " < ",  // File redirection input
      "../",  // Path traversal
      "~",  // Home directory expansion can be risky
      "\n",  // Newlines for command injection
      "\r",  // Carriage returns
    ]

    let scriptLower = script.lowercased()
    for pattern in dangerousPatterns {
      if scriptLower.contains(pattern.lowercased()) {
        return false
      }
    }

    return true
  }

  /// Safe shell script sanitization - reject rather than filter for security
  static func safeShellScript(_ script: String) -> String? {
    guard validateShellScript(script) else {
      return nil  // Reject dangerous scripts entirely
    }
    return script  // Return original if safe
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
      "HEADER_SEARCH_PATHS",
      "GCC_PREPROCESSOR_DEFINITIONS",
      "SWIFT_ACTIVE_COMPILATION_CONDITIONS",
      "RUN_CLANG_STATIC_ANALYZER",
      "PREBINDING",
    ]

    // Check if this is a dangerous setting that needs validation
    if dangerousSettings.contains(key) {
      // Look for suspicious patterns that could indicate code injection
      let suspiciousPatterns = [
        "$(",  // Command substitution
        "`",  // Command substitution (backticks)
        "${",  // Variable expansion
        ";",  // Command separator
        "&&",  // Command chaining
        "||",  // Command chaining OR
        "|",  // Pipe
        ">",  // File redirection
        "<",  // File input redirection
        "eval ",  // Code evaluation
        "exec ",  // Process execution
        "\n",  // Newlines for injection
        "\r",  // Carriage returns
        "../",  // Path traversal attempts
        "~",  // Home directory expansion
      ]

      let valueLower = value.lowercased()
      for pattern in suspiciousPatterns {
        if valueLower.contains(pattern.lowercased()) {
          return false  // Reject suspicious values
        }
      }

      // Additional validation for specific dangerous settings
      if key == "OTHER_LDFLAGS" {
        // Check for dangerous linker flags
        let dangerousLdFlags = [
          "-execute",  // Allow execution
          "-dylib_file",  // Dynamic library file substitution
          "-reexport",  // Re-export symbols
        ]

        for flag in dangerousLdFlags {
          if valueLower.contains(flag) {
            return false
          }
        }
      }
    }

    // Validate paths in path-related settings don't allow traversal
    let pathSettings = ["FRAMEWORK_SEARCH_PATHS", "LIBRARY_SEARCH_PATHS", "HEADER_SEARCH_PATHS"]
    if pathSettings.contains(key) {
      // Use our existing path validation for path-based settings
      let pathComponents = value.components(separatedBy: " ")
      for component in pathComponents {
        if !component.isEmpty && sanitizePath(component) == nil {
          return false
        }
      }
    }

    return true
  }

  /// Sanitize and validate a user-provided path for security
  static func sanitizePath(_ path: String) -> String? {
    // Limit path length to prevent resource exhaustion
    guard path.count <= 1024 else {
      return nil  // Path too long
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

    // Simple depth-based path traversal prevention
    // Check if any ".." sequence would take us above the project root
    let components = normalizedPath.components(separatedBy: "/")
    var depth = 0
    for component in components {
      if component == ".." {
        depth -= 1
        if depth < 0 {  // Never allow going above project root
          return nil
        }
      } else if !component.isEmpty && component != "." {
        depth += 1
      }
    }

    // For absolute paths, block critical system directories and sensitive locations
    if normalizedPath.hasPrefix("/") {
      let criticalDirs = [
        "/System/", "/usr/", "/bin/", "/sbin/", "/var/", "/tmp/", "/etc/",
        "/proc/", "/dev/", "/boot/", "/root/", "/Library/System/", "/private/",
      ]
      for dir in criticalDirs {
        if normalizedPath.hasPrefix(dir) {
          return nil
        }
      }
    }

    // Additional checks for suspicious patterns
    let suspiciousPatterns = [
      "\\x", "\\u", "%2e%2e", "%2f", "%5c",  // Encoded traversal attempts
      "//", "\\\\",  // Double slashes
      "\r", "\n", "\t",  // Control characters
    ]

    for pattern in suspiciousPatterns {
      if normalizedPath.lowercased().contains(pattern.lowercased()) {
        return nil
      }
    }

    return normalizedPath
  }

  /// Sanitize and validate a user-provided string (names, identifiers, etc.)
  static func sanitizeString(_ input: String) -> String? {
    // Limit string length to prevent resource exhaustion
    guard input.count <= 256 else {
      return nil  // String too long
    }

    // Check for null bytes
    if input.contains("\0") {
      return nil
    }

    // Check for dangerous patterns that could indicate injection attempts
    let dangerousPatterns = [
      "$(",  // Command substitution
      "`",  // Command substitution (backticks)
      "${",  // Variable expansion
      ";",  // Command separator
      "&&",  // Command chaining
      "||",  // Command chaining OR
      "|",  // Pipe
      ">",  // File redirection
      "<",  // File input redirection
      "eval ",  // Code evaluation
      "exec ",  // Process execution
      "\n",  // Newlines for injection
      "\r",  // Carriage returns
      "../",  // Path traversal attempts
      "~",  // Home directory expansion
      "\\x", "\\u",  // Encoded sequences
      "%2e", "%2f", "%5c",  // URL-encoded dangerous chars
    ]

    let inputLower = input.lowercased()
    for pattern in dangerousPatterns {
      if inputLower.contains(pattern.lowercased()) {
        return nil  // Reject dangerous input
      }
    }

    return input
  }

  /// Validate a user-provided path and throw appropriate error if invalid
  static func validatePath(_ path: String) throws -> String {
    guard let validPath = sanitizePath(path) else {
      throw ProjectError.invalidArguments("Invalid or potentially unsafe path: \(path)")
    }
    return validPath
  }

  /// Validate a user-provided string and throw appropriate error if invalid
  static func validateString(_ input: String) throws -> String {
    guard let validString = sanitizeString(input) else {
      throw ProjectError.invalidArguments("Invalid or potentially unsafe string: \(input)")
    }
    return validString
  }

  /// Sanitize path using PathUtils validation (avoiding circular imports) - DEPRECATED
  private static func deprecatedSanitizePath(_ path: String) -> String? {
    // Basic path traversal check (subset of PathUtils logic to avoid circular import)
    if path.contains("../") || path.contains("..\\") || path.hasPrefix("../") {
      return nil
    }
    return path
  }
}
