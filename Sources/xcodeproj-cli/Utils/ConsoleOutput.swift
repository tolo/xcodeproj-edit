//
// ConsoleOutput.swift
// xcodeproj-cli
//
// Console output utilities for consistent messaging
//

import Foundation

/// Utility for consistent console output formatting
struct ConsoleOutput {

  /// Print an error message to stderr
  static func error(_ message: String) {
    fputs("Error: \(message)\n", stderr)
  }

  /// Print a warning message to stderr
  static func warning(_ message: String) {
    fputs("Warning: \(message)\n", stderr)
  }

  /// Print an info message to stdout
  static func info(_ message: String) {
    print("Info: \(message)")
  }

  /// Print a success message to stdout
  static func success(_ message: String) {
    print("Success: \(message)")
  }

  /// Print a verbose message if verbose mode is enabled
  static func verbose(_ message: String, enabled: Bool) {
    if enabled {
      print("Verbose: \(message)")
    }
  }
}
