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
      count: 1,
      usage: "add-target-file requires: <file-path> --targets <target1,target2>"
    )

    let filePath = try PathUtils.validatePath(arguments.positional[0])
    
    let targetsStr = try arguments.requireFlag(
      "--targets", "-t",
      error: "add-target-file requires --targets or -t flag"
    )
    
    let targets = parseTargets(from: targetsStr)

    // Validate targets exist
    try validateTargets(targets, in: utility)

    // Execute the command for each target
    for targetName in targets {
      try utility.addFileToTarget(path: filePath, targetName: targetName)
    }
  }

  nonisolated static func printUsage() {
    print(
      """
      add-target-file <file-path> --targets <target1,target2>
        Add an existing file to target build phases
        
        Arguments:
          <file-path>           Path to the file (must already exist in project)
          --targets, -t <list>  Comma-separated list of target names
        
        Examples:
          add-target-file Sources/Model.swift --targets MyApp
          add-target-file Helper.swift --targets MyAppTests,MyFrameworkTests
          add-target-file Utils.swift -t MyApp,MyWidget
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
  
  private static func parseTargets(from targetsString: String) -> [String] {
    return BaseCommand.parseTargets(from: targetsString)
  }

  @MainActor
  private static func validateTargets(_ targetNames: [String], in utility: XcodeProjUtility) throws
  {
    try BaseCommand.validateTargets(targetNames, in: utility)
  }
}