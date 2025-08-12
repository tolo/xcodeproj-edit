//
// ArgumentParser.swift
// xcodeproj-cli
//
// Command-line argument parsing utilities
//

import Foundation

/// Utility for parsing command-line arguments
struct ArgumentParser {
  
  /// Parse command line arguments into a ParsedArguments structure
  static func parseArguments(_ args: [String]) -> ParsedArguments {
    var parsed = ParsedArguments()
    var i = 0

    while i < args.count {
      let arg = args[i]

      if arg.hasPrefix("--") || arg.hasPrefix("-") {
        let flagName = arg

        // Check if it's a boolean flag or has a value
        if i + 1 < args.count && !args[i + 1].hasPrefix("-") {
          // Flag with value
          parsed.flags[flagName] = args[i + 1]
          i += 2
        } else {
          // Boolean flag
          parsed.boolFlags.insert(flagName)
          i += 1
        }
      } else {
        // Positional argument
        parsed.positional.append(arg)
        i += 1
      }
    }

    return parsed
  }
}