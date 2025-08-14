//
// ListSwiftPackagesCommand.swift
// xcodeproj-cli
//
// Command for listing Swift Package dependencies
//

import Foundation
import XcodeProj

/// Command for listing Swift Package dependencies in the project
struct ListSwiftPackagesCommand: Command {
  static let commandName = "list-swift-packages"

  static let description = "List Swift Package dependencies in the project"

  static let isReadOnly = true
  static func execute(with arguments: ParsedArguments, utility: XcodeProjUtility) throws {
    utility.listSwiftPackages()
  }

  static func printUsage() {
    print(
      """
      list-swift-packages
        List Swift Package dependencies in the project
        
        Examples:
          list-swift-packages
      """)
  }
}

// MARK: - BaseCommand conformance
extension ListSwiftPackagesCommand {
  // No additional BaseCommand methods needed for this command
}
