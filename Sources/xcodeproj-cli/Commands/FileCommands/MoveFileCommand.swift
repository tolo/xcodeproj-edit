//
// MoveFileCommand.swift
// xcodeproj-cli
//
// Command for moving/renaming a file in the project
//

import Foundation
import XcodeProj

/// Command for moving or renaming a file in the project
struct MoveFileCommand: Command {
  static let commandName = "move-file"
  
  static let description = "Move or rename a file in the project"
  
  static func execute(with arguments: ParsedArguments, utility: XcodeProjUtility) throws {
    // Validate required arguments
    try requirePositionalArguments(
      arguments, 
      count: 2, 
      usage: "move-file requires: <old-path> <new-path>"
    )
    
    let oldPath = arguments.positional[0]
    let newPath = arguments.positional[1]
    
    // Execute the command
    try utility.moveFile(from: oldPath, to: newPath)
  }
  
  static func printUsage() {
    print("""
      move-file <old-path> <new-path>
        Move or rename a file in the project
        
        Arguments:
          <old-path>  Current path or name of the file
          <new-path>  New path or name for the file
        
        Examples:
          move-file OldName.swift NewName.swift
          move-file Sources/Helper.swift Utils/Helper.swift
          
        Note: This updates the file reference in the project.
              If the file needs to be moved on disk, you should do that separately.
      """)
  }
}

// MARK: - BaseCommand conformance
extension MoveFileCommand {
  private static func requirePositionalArguments(_ arguments: ParsedArguments, count: Int, usage: String) throws {
    try BaseCommand.requirePositionalArguments(arguments, count: count, usage: usage)
  }
}