//
// DuplicateSchemeCommand.swift
// xcodeproj-cli
//
// Command for duplicating Xcode schemes
//

import Foundation
import PathKit
import XcodeProj

struct DuplicateSchemeCommand: Command {
  static var commandName = "duplicate-scheme"
  static let description = "Duplicate an existing scheme"

  let sourceName: String
  let destinationName: String
  let verbose: Bool

  init(arguments: ParsedArguments) throws {
    guard arguments.positional.count >= 2 else {
      throw ProjectError.invalidArguments("Source and destination scheme names are required")
    }

    self.sourceName = arguments.positional[0]
    self.destinationName = arguments.positional[1]
    self.verbose = arguments.boolFlags.contains("--verbose")
  }

  func execute(with xcodeproj: XcodeProj, projectPath: Path) throws {
    let schemeManager = SchemeManager(xcodeproj: xcodeproj, projectPath: projectPath)

    // Check if source scheme exists
    let existingSchemes = schemeManager.listSchemes(shared: true)
    if !existingSchemes.contains(sourceName) {
      throw ProjectError.operationFailed("Source scheme '\(sourceName)' not found")
    }

    // Check if destination scheme already exists
    if existingSchemes.contains(destinationName) {
      throw ProjectError.operationFailed("Destination scheme '\(destinationName)' already exists")
    }

    // Duplicate the scheme
    _ = try schemeManager.duplicateScheme(
      sourceName: sourceName,
      destinationName: destinationName
    )

    print("✅ Duplicated scheme '\(sourceName)' to '\(destinationName)'")

    if verbose {
      print("  Source: \(sourceName)")
      print("  Destination: \(destinationName)")
    }
  }

  static func execute(with arguments: ParsedArguments, utility: XcodeProjUtility) throws {
    let cmd = try DuplicateSchemeCommand(arguments: arguments)
    try cmd.execute(with: utility.xcodeproj, projectPath: utility.projectPath)
  }

  static func printUsage() {
    print(
      """
      Usage: duplicate-scheme <source> <destination> [options]

      Arguments:
        source            Name of the scheme to duplicate
        destination       Name for the new scheme

      Options:
        --verbose         Show detailed output

      Examples:
        duplicate-scheme MyApp MyAppDev
        duplicate-scheme Production Staging
      """)
  }
}
