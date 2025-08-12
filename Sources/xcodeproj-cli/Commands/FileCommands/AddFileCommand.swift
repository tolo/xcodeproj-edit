//
// AddFileCommand.swift
// xcodeproj-cli
//
// Command for adding a single file to the project
//

import Foundation
import XcodeProj

/// Command for adding a single file to specified group and targets
struct AddFileCommand: Command {
  static let commandName = "add-file"
  
  static let description = "Add a single file to specified group and targets"
  
  static func execute(with arguments: ParsedArguments, utility: XcodeProjUtility) throws {
    // Validate required arguments
    try requirePositionalArguments(
      arguments, 
      count: 1, 
      usage: "add-file requires: <file-path> --group <group> --targets <target1,target2>"
    )
    
    let filePath = arguments.positional[0]
    
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
  
  static func printUsage() {
    print("""
      add-file <file-path> --group <group> --targets <target1,target2>
        Add a single file to specified group and targets
        
        Arguments:
          <file-path>           Path to the file to add
          --group, -g <group>   Group to add the file to
          --targets, -t <list>  Comma-separated list of target names
        
        Examples:
          add-file Sources/Model.swift --group Models --targets MyApp,MyAppTests
          add-file Helper.swift -g Utils -t MyApp
      """)
  }
}

// MARK: - BaseCommand conformance
extension AddFileCommand {
  private static func requirePositionalArguments(_ arguments: ParsedArguments, count: Int, usage: String) throws {
    try BaseCommand.requirePositionalArguments(arguments, count: count, usage: usage)
  }
  
  private static func parseTargets(from targetsString: String) -> [String] {
    return BaseCommand.parseTargets(from: targetsString)
  }
  
  private static func validateTargets(_ targetNames: [String], in utility: XcodeProjUtility) throws {
    try BaseCommand.validateTargets(targetNames, in: utility)
  }
  
  private static func validateGroup(_ groupPath: String, in utility: XcodeProjUtility) throws {
    try BaseCommand.validateGroup(groupPath, in: utility)
  }
}