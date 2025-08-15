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
      count: 1,
      usage: "remove-target-file requires: <file-path> --targets <target1,target2>"
    )

    let filePath = try PathUtils.validatePath(arguments.positional[0])
    
    let targetsStr = try arguments.requireFlag(
      "--targets", "-t",
      error: "remove-target-file requires --targets or -t flag"
    )
    
    let targets = parseTargets(from: targetsStr)

    // Validate targets exist
    try validateTargets(targets, in: utility)

    // Execute the command for each target
    for targetName in targets {
      try utility.removeFileFromTarget(path: filePath, targetName: targetName)
    }
  }

  nonisolated static func printUsage() {
    print(
      """
      remove-target-file <file-path> --targets <target1,target2>
        Remove a file from target build phases without removing it from the project
        
        Arguments:
          <file-path>           Path to the file in the project
                                Can be: filename only (Model.swift),
                                partial path (Sources/Model.swift),
                                or full project path
          --targets, -t <list>  Comma-separated list of target names
        
        Examples:
          remove-target-file Sources/Model.swift --targets MyAppTests
          remove-target-file Helper.swift --targets MyApp,MyWidget
          remove-target-file Utils.swift -t MyFramework
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
  
  private static func parseTargets(from targetsString: String) -> [String] {
    return BaseCommand.parseTargets(from: targetsString)
  }

  @MainActor
  private static func validateTargets(_ targetNames: [String], in utility: XcodeProjUtility) throws
  {
    try BaseCommand.validateTargets(targetNames, in: utility)
  }
}