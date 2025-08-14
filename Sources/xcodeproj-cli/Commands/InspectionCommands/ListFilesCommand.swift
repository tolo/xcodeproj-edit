//
// ListFilesCommand.swift
// xcodeproj-cli
//
// Command for listing files in the project or a specific group
//

import Foundation
import XcodeProj

/// Command for listing files in the project or a specific group

struct ListFilesCommand: Command {
  static let commandName = "list-files"

  static let description = "List files in the project or a specific group"

  static let isReadOnly = true

  static func execute(with arguments: ParsedArguments, utility: XcodeProjUtility) throws {
    let groupName = arguments.positional.first

    if let name = groupName,
      let group = XcodeProjectHelpers.findGroup(named: name, in: utility.pbxproj.groups)
    {
      print("📁 Files in group '\(name)':")
      ListFilesCommand.listFilesInGroup(group)
    } else if let name = groupName {
      throw ProjectError.groupNotFound(name)
    } else {
      print("📁 All files in project:")
      if let rootGroup = utility.pbxproj.rootObject?.mainGroup {
        ListFilesCommand.listFilesInGroup(rootGroup)
      } else {
        print("❌ No project structure found")
      }
    }
  }

  static func printUsage() {
    print(
      """
      list-files [group-name]
        List files in the project or a specific group
        
        Arguments:
          [group-name]  Optional: specific group to list files from
        
        Examples:
          list-files              # List all files in project
          list-files Sources      # List files in Sources group
      """)
  }
}

// MARK: - Helper methods
extension ListFilesCommand {
  static func listFilesInGroup(_ group: PBXGroup, indent: String = "") {
    for child in group.children {
      if let fileRef = child as? PBXFileReference {
        print("\(indent)- \(fileRef.path ?? fileRef.name ?? "unknown")")
      } else if let subgroup = child as? PBXGroup {
        print("\(indent)📁 \(subgroup.name ?? subgroup.path ?? "unknown")/")
        listFilesInGroup(subgroup, indent: indent + "  ")
      }
    }
  }
}
