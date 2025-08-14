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
  
  /// Indicates if this is a read-only command that doesn't modify the project
  static var isReadOnly: Bool { get }

  /// Execute the command with parsed arguments and utility
  @MainActor
  static func execute(with arguments: ParsedArguments, utility: XcodeProjUtility) throws

  /// Print usage information for this specific command
  static func printUsage()
}

// Default implementation for isReadOnly (most commands modify the project)
extension Command {
  static var isReadOnly: Bool { false }
}

/// Abstract base class providing common functionality for commands
@MainActor
class BaseCommand {

  /// Validate that required positional arguments are provided
  static func requirePositionalArguments(_ arguments: ParsedArguments, count: Int, usage: String)
    throws
  {
    guard arguments.positional.count >= count else {
      let missingCount = count - arguments.positional.count
      let errorMessage =
        missingCount == 1
        ? "Missing required argument. \(usage)"
        : "Missing \(missingCount) required arguments. \(usage)"
      throw ProjectError.invalidArguments(errorMessage)
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

  /// Validate that a product type is supported
  static func validateProductType(_ productType: String) throws {
    let validProductTypes = [
      "app",
      "application",
      "com.apple.product-type.application",
      "framework",
      "com.apple.product-type.framework",
      "static-library",
      "com.apple.product-type.library.static",
      "dynamic-library",
      "com.apple.product-type.library.dynamic",
      "test",
      "com.apple.product-type.bundle.unit-test",
      "ui-test",
      "com.apple.product-type.bundle.ui-testing",
      "bundle",
      "com.apple.product-type.bundle",
      "tool",
      "com.apple.product-type.tool",
    ]

    guard validProductTypes.contains(productType) else {
      throw ProjectError.invalidArguments(
        "Invalid product type '\(productType)'. Valid types: \(validProductTypes.joined(separator: ", "))"
      )
    }
  }
}
