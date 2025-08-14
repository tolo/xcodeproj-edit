//
// AddFileCommand.swift
// xcodeproj-cli
//
// Command for adding a single file to the project
//

import Foundation
@preconcurrency import XcodeProj

/// Command for adding a single file to specified group and targets

struct AddFileCommand: Command {
  static let commandName = "add-file"

  static let description = "Add a single file to specified group and targets"

  static func execute(with arguments: ParsedArguments, utility: XcodeProjUtility) throws {
    // Check if --targets-only flag is present
    let targetsOnly = arguments.boolFlags.contains("--targets-only")
    
    if targetsOnly {
      // Mode: Add existing file to targets only
      try executeTargetsOnlyMode(with: arguments, utility: utility)
    } else {
      // Mode: Add new file to project and targets
      try executeStandardMode(with: arguments, utility: utility)
    }
  }
  
  @MainActor
  private static func executeStandardMode(with arguments: ParsedArguments, utility: XcodeProjUtility) throws {
    // Validate required arguments
    try requirePositionalArguments(
      arguments,
      count: 1,
      usage: "add-file requires: <file-path> --group <group> --targets <target1,target2>"
    )

    let filePath = try PathUtils.validatePath(arguments.positional[0])

    // Get required flags
    let group = try arguments.requireFlag(
      "--group", "-g",
      error: "add-file requires --group or -g flag"
    )

    let targetsStr = try arguments.requireFlag(
      "--targets", "-t",
      error: "add-file requires --targets or -t flag"
    )

    let targets = parseTargets(from: targetsStr)

    // Validate inputs
    try validateGroup(group, in: utility)
    try validateTargets(targets, in: utility)

    // Execute the command
    try utility.addFile(path: filePath, to: group, targets: targets)
  }
  
  @MainActor
  private static func executeTargetsOnlyMode(with arguments: ParsedArguments, utility: XcodeProjUtility) throws {
    // Validate required arguments
    try requirePositionalArguments(
      arguments,
      count: 1,
      usage: "add-file --targets-only requires: <file-path> --targets <target1,target2>"
    )

    let filePath = try PathUtils.validatePath(arguments.positional[0])

    let targetsStr = try arguments.requireFlag(
      "--targets", "-t",
      error: "add-file --targets-only requires --targets or -t flag"
    )

    let targets = parseTargets(from: targetsStr)

    // Validate inputs
    try validateTargets(targets, in: utility)

    // Execute the command - add to targets only
    try utility.addFileToTargetsOnly(path: filePath, targets: targets)
  }

  static func printUsage() {
    print(
      """
      add-file <file-path> --group <group> --targets <target1,target2> [--targets-only]
        Add a single file to specified group and targets
        
        Arguments:
          <file-path>           Path to the file to add
          --group, -g <group>   Group to add the file to (not required with --targets-only)
          --targets, -t <list>  Comma-separated list of target names
          --targets-only        Add existing file to targets only (skip group)
        
        Examples:
          add-file Sources/Model.swift --group Models --targets MyApp,MyAppTests
          add-file Helper.swift -g Utils -t MyApp
          add-file Sources/Existing.swift --targets-only --targets MyApp
      """)
  }
}

// MARK: - BaseCommand conformance
extension AddFileCommand {
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

  @MainActor
  private static func validateGroup(_ groupPath: String, in utility: XcodeProjUtility) throws {
    try BaseCommand.validateGroup(groupPath, in: utility)
  }
}
