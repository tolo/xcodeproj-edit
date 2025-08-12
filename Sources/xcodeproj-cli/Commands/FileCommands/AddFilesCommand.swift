//
// AddFilesCommand.swift
// xcodeproj-cli
//
// Command for adding multiple files to the project in batch
//

import Foundation
import XcodeProj

/// Command for adding multiple files to specified groups and targets in batch
struct AddFilesCommand: Command {
  static let commandName = "add-files"
  
  static let description = "Add multiple files to specified groups and targets in batch"
  
  static func execute(with arguments: ParsedArguments, utility: XcodeProjUtility) throws {
    // Parse file:group pairs from positional arguments
    var files: [(String, String)] = []
    for arg in arguments.positional {
      let parts = arg.split(separator: ":")
      if parts.count == 2 {
        files.append((String(parts[0]), String(parts[1])))
      }
    }
    
    guard !files.isEmpty else {
      throw ProjectError.invalidArguments(
        "add-files requires: <file1:group1> [file2:group2] ... --targets <target1,target2>")
    }
    
    // Get required targets flag
    let targetsStr = try arguments.requireFlag(
      "--targets", "-t", 
      error: "add-files requires --targets or -t flag"
    )
    
    let targets = parseTargets(from: targetsStr)
    
    // Validate targets exist
    try validateTargets(targets, in: utility)
    
    // Validate groups exist
    for (_, group) in files {
      try validateGroup(group, in: utility)
    }
    
    // Execute the command
    try utility.addFiles(files, to: targets)
  }
  
  static func printUsage() {
    print("""
      add-files <file1:group1> [file2:group2] ... --targets <target1,target2>
        Add multiple files to specified groups and targets in batch
        
        Arguments:
          <fileN:groupN>        File path paired with destination group (colon-separated)
          --targets, -t <list>  Comma-separated list of target names
        
        Examples:
          add-files Model.swift:Models View.swift:Views --targets MyApp,MyAppTests
          add-files Helper.swift:Utils Config.swift:Config -t MyApp
        
        Notes:
          - Each file:group pair is processed independently
          - All files are added to all specified targets
          - Groups must exist before adding files
      """)
  }
}

// MARK: - BaseCommand conformance
extension AddFilesCommand {
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