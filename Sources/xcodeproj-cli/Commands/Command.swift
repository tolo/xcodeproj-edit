//
// Command.swift
// xcodeproj-cli
//
// Base command protocol and abstract base class for command implementations
//

import Foundation
import XcodeProj

/// Protocol for command implementations
protocol Command {
  /// The name of the command as used on the command line
  static var commandName: String { get }
  
  /// Brief description of what the command does
  static var description: String { get }
  
  /// Execute the command with parsed arguments and utility
  static func execute(with arguments: ParsedArguments, utility: XcodeProjUtility) throws
  
  /// Print usage information for this specific command
  static func printUsage()
}

/// Abstract base class providing common functionality for commands
class BaseCommand {
  
  /// Validate that required positional arguments are provided
  static func requirePositionalArguments(_ arguments: ParsedArguments, count: Int, usage: String) throws {
    guard arguments.positional.count >= count else {
      throw ProjectError.invalidArguments(usage)
    }
  }
  
  /// Parse comma-separated target list from string
  static func parseTargets(from targetsString: String) -> [String] {
    return targetsString.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
  }
  
  /// Validate that targets exist in the project
  static func validateTargets(_ targetNames: [String], in utility: XcodeProjUtility) throws {
    let projectTargets = Set(utility.pbxproj.nativeTargets.map { $0.name })
    
    for targetName in targetNames {
      guard projectTargets.contains(targetName) else {
        throw ProjectError.targetNotFound(targetName)
      }
    }
  }
  
  /// Validate that a group exists in the project
  static func validateGroup(_ groupPath: String, in utility: XcodeProjUtility) throws {
    guard XcodeProjectHelpers.findGroup(named: groupPath, in: utility.pbxproj.groups) != nil else {
      throw ProjectError.groupNotFound(groupPath)
    }
  }
}