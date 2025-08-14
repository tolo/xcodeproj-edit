//
// ListTreeCommand.swift
// xcodeproj-cli
//
// Command for listing the project structure as a tree
//

import Foundation
@preconcurrency import XcodeProj

/// Command for listing the complete project structure as a tree

struct ListTreeCommand: Command {
  static let commandName = "list-tree"

  static let description = "List the complete project structure as a tree"

  static let isReadOnly = true

  static func execute(with arguments: ParsedArguments, utility: XcodeProjUtility) throws {
    utility.listProjectTree()
  }

  static func printUsage() {
    print(
      """
      list-tree
        List the complete project structure as a tree
        
        Examples:
          list-tree
        
        Note: Shows complete project structure including files and groups
      """)
  }
}

// MARK: - BaseCommand conformance
extension ListTreeCommand {
  // No additional BaseCommand methods needed for this command
}
