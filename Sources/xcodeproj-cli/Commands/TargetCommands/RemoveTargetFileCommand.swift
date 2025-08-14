//
// RemoveTargetFileCommand.swift
// xcodeproj-cli
//
// Command for removing a file from a target's compile sources
//

import Foundation
@preconcurrency import XcodeProj

/// Command for removing a file from a target's compile sources or resources without removing it from the project

struct RemoveTargetFileCommand: Command {
  static let commandName = "remove-target-file"

  static let description = "Remove a file from a target's compile sources or resources without removing it from the project"

  static func execute(with arguments: ParsedArguments, utility: XcodeProjUtility) throws {
    // Validate required arguments
    try requirePositionalArguments(
      arguments,
      count: 2,
      usage: "remove-target-file requires: <file-path> <target-name>"
    )

    let filePath = try PathUtils.validatePath(arguments.positional[0])
    let targetName = arguments.positional[1]

    // Validate target exists
    try validateTargets([targetName], in: utility)

    // Execute the command - uses the new utility method
    try utility.removeFileFromTargets(path: filePath, targets: [targetName])
  }

  nonisolated static func printUsage() {
    print(
      """
      remove-target-file <file-path> <target-name>
        Remove a file from a target's build phases without removing it from the project
        
        Arguments:
          <file-path>       Path to the file
          <target-name>     Name of the target to remove file from
        
        Examples:
          remove-target-file Sources/Model.swift MyAppTests
          remove-target-file Helper.swift MyApp
      """)
  }
}

// MARK: - BaseCommand conformance
extension RemoveTargetFileCommand {
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