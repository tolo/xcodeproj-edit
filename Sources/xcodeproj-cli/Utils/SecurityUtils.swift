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

  /// Sanitize path using PathUtils validation (avoiding circular imports)
  private static func sanitizePath(_ path: String) -> String? {
    // Basic path traversal check (subset of PathUtils logic to avoid circular import)
    if path.contains("../") || path.contains("..\\") || path.hasPrefix("../") {
      return nil
    }
    return path
  }
}
