//
// ParsedArguments.swift
// xcodeproj-cli
//
// Command-line argument parsing structure
//

import Foundation

/// Structure for managing parsed command-line arguments
struct ParsedArguments: Sendable {
  var positional: [String] = []
  var flags: [String: String] = [:]
  var boolFlags: Set<String> = []

  func flag(_ names: String...) -> String? {
    return getFlagFromArray(names)
  }

  func getFlag(_ names: String...) -> String? {
    return getFlagFromArray(names)
  }

  func getFlagFromArray(_ names: [String]) -> String? {
    for name in names {
      if let value = flags[name] {
        return value
      }
    }
    return nil
  }

  func hasFlag(_ names: String...) -> Bool {
    return hasFlagFromArray(names)
  }

  func hasFlagFromArray(_ names: [String]) -> Bool {
    for name in names {
      if boolFlags.contains(name) {
        return true
      }
    }
    return false
  }

  func requireFlag(_ names: String..., error: String) throws -> String {
    guard let value = getFlagFromArray(names) else {
      throw ProjectError.invalidArguments(error)
    }
    return value
  }
}
