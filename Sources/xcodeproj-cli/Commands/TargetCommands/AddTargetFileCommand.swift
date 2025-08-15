//
// AddTargetFileCommand.swift
// xcodeproj-cli
//
// Command for adding an existing file to a target's compile sources
//

import Foundation
@preconcurrency import XcodeProj

/// Command for adding an existing file to a target's compile sources or resources

struct AddTargetFileCommand: Command {
  static let commandName = "add-target-file"

  static let description = "Add an existing file to a target's compile sources or resources"

  static func execute(with arguments: ParsedArguments, utility: XcodeProjUtility) throws {
    // Validate required arguments
    try requirePositionalArguments(
      arguments,
      count: 2,
      usage: "add-target-file requires: <file-path> <target-name>"
    )

    let filePath = try PathUtils.validatePath(arguments.positional[0])
    let targetName = arguments.positional[1]

    // Validate target exists
    try validateTargets([targetName], in: utility)

    // Execute the command
    try utility.addFileToTarget(path: filePath, targetName: targetName)
  }

  nonisolated static func printUsage() {
    print(
      """
      add-target-file <file-path> <target-name>
        Add an existing file to a target's build phases
        
        Arguments:
          <file-path>       Path to the file (must already exist in project)
          <target-name>     Name of the target to add file to
        
        Examples:
          add-target-file Sources/Model.swift MyApp
          add-target-file Helper.swift MyAppTests
      """)
  }
}

// MARK: - BaseCommand conformance
extension AddTargetFileCommand {
  private static func requirePositionalArguments(
    _ arguments: ParsedArguments, count: Int, usage: String
  ) throws {
    try BaseCommand.requirePositionalArguments(arguments, count: count, usage: usage)
  }

  @MainActor
  private static func validateTargets(_ targetNames: [String], in utility: XcodeProjUtility) throws
  {
    try BaseCommand.validateTargets(targetNames, in: utility)
  }
}