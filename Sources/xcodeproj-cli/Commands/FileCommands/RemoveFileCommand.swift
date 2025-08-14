//
// RemoveFileCommand.swift
// xcodeproj-cli
//
// Command for removing a file from the project
//

import Foundation
@preconcurrency import XcodeProj

/// Command for removing a file from the project

struct RemoveFileCommand: Command {
  static let commandName = "remove-file"

  static let description = "Remove a file from the project"

  static func execute(with arguments: ParsedArguments, utility: XcodeProjUtility) throws {
    // Validate required arguments
    try requirePositionalArguments(
      arguments,
      count: 1,
      usage: "remove-file requires: <file-path>"
    )

    let filePath = arguments.positional[0]
    
    // Check for optional flags
    let targetsStr = arguments.getFlag("--targets", "-t")
    
    if let targetsStr = targetsStr {
      // Mode: Remove from specific targets only
      let targets = parseTargets(from: targetsStr)
      try validateTargets(targets, in: utility)
      try utility.removeFileFromTargets(path: filePath, targets: targets)
    } else {
      // Mode: Remove from entire project
      try utility.removeFile(filePath)
    }
  }

  static func printUsage() {
    print(
      """
      remove-file <file-path> [--targets <target1,target2>]
        Remove a file from the project or from specific targets only
        
        Arguments:
          <file-path>           Path or name of the file to remove
          --targets, -t <list>  Optional: Remove from specific targets only
        
        Examples:
          remove-file Sources/OldFile.swift
          remove-file Helper.swift
          remove-file Sources/Model.swift --targets MyAppTests
          remove-file Utils.swift -t MyApp,MyFramework
          
        Note: Without --targets, removes the file reference from the entire project.
              With --targets, only removes from specified targets' build phases.
              This never deletes the actual file from the filesystem.
      """)
  }
}

// MARK: - BaseCommand conformance
extension RemoveFileCommand {

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
