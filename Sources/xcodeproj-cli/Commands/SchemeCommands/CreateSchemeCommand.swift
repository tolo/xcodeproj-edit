//
// CreateSchemeCommand.swift
// xcodeproj-cli
//
// Command for creating Xcode schemes
//

import Foundation
@preconcurrency import PathKit
import XcodeProj


struct CreateSchemeCommand: Command {
  static let commandName = "create-scheme"
  static let description = "Create a new scheme for a target"

  let schemeName: String
  let targetName: String
  let shared: Bool
  let verbose: Bool

  init(arguments: ParsedArguments) throws {
    guard let name = arguments.positional.first else {
      throw ProjectError.invalidArguments("Scheme name is required")
    }

    self.schemeName = name
    self.targetName = arguments.getFlag("--target", "target") ?? name  // Default to scheme name if no target specified
    self.shared =
      arguments.boolFlags.contains("--shared") || !arguments.boolFlags.contains("--user")
    self.verbose = arguments.boolFlags.contains("--verbose")
  }

  func execute(with xcodeproj: XcodeProj, projectPath: Path) throws {
    let schemeManager = SchemeManager(xcodeproj: xcodeproj, projectPath: projectPath)

    // Check if scheme already exists
    let existingSchemes = try schemeManager.listSchemes(shared: shared)
    if existingSchemes.contains(schemeName) {
      throw ProjectError.operationFailed("Scheme '\(schemeName)' already exists")
    }

    // Create the scheme
    _ = try schemeManager.createScheme(
      name: schemeName,
      targetName: targetName,
      shared: shared
    )

    print("✅ Created scheme '\(schemeName)' for target '\(targetName)'")

    if verbose {
      print("  Location: \(shared ? "Shared" : "User")")
      print("  Target: \(targetName)")
    }
  }

  static func execute(with arguments: ParsedArguments, utility: XcodeProjUtility) throws {
    let cmd = try CreateSchemeCommand(arguments: arguments)
    try cmd.execute(with: utility.xcodeproj, projectPath: utility.projectPath)
  }

  static func printUsage() {
    print(
      """
      Usage: create-scheme <name> [options]

      Arguments:
        name              Name of the scheme to create

      Options:
        --target <name>   Target to create scheme for (default: scheme name)
        --shared          Create as shared scheme (default)
        --user            Create as user-specific scheme
        --verbose         Show detailed output

      Examples:
        create-scheme MyApp --target MyApp
        create-scheme MyAppDev --target MyApp --shared
      """)
  }
}
