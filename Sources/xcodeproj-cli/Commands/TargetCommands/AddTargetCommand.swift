//
// AddTargetCommand.swift
// xcodeproj-cli
//
// Command for adding a new target to the project
//

import Foundation
import XcodeProj

/// Command for adding a new target to the project
struct AddTargetCommand: Command {
  static let commandName = "add-target"
  
  static let description = "Add a new target to the project"
  
  static func execute(with arguments: ParsedArguments, utility: XcodeProjUtility) throws {
    // Validate required arguments
    try requirePositionalArguments(
      arguments, 
      count: 1, 
      usage: "add-target requires: <name> --type <product-type> --bundle-id <bundle-id> [--platform <platform>]"
    )
    
    let targetName = arguments.positional[0]
    
    // Get required flags
    let productType = try arguments.requireFlag(
      "--type", "-T", 
      error: "add-target requires --type or -T flag"
    )
    
    let bundleId = try arguments.requireFlag(
      "--bundle-id", "-b", 
      error: "add-target requires --bundle-id or -b flag"
    )
    
    // Get optional flags
    let platform = arguments.getFlag("--platform", "-p") ?? "iOS"
    
    // Execute the command
    try utility.addTarget(
      name: targetName, 
      productType: productType, 
      bundleId: bundleId, 
      platform: platform
    )
  }
  
  static func printUsage() {
    print("""
      add-target <name> --type <product-type> --bundle-id <bundle-id> [--platform <platform>]
        Add a new target to the project
        
        Arguments:
          <name>                    Name of the new target
          --type, -T <type>         Product type (app, framework, test, etc.)
          --bundle-id, -b <id>      Bundle identifier for the target
          --platform, -p <platform> Target platform (default: iOS)
        
        Common product types:
          app                Application
          framework          Framework
          static-library     Static Library
          dynamic-library    Dynamic Library
          test               Unit Test Bundle
          ui-test            UI Test Bundle
        
        Examples:
          add-target MyAppTests --type test --bundle-id com.example.tests
          add-target MyFramework -T framework -b com.example.framework -p iOS
      """)
  }
}

// MARK: - BaseCommand conformance
extension AddTargetCommand {
  private static func requirePositionalArguments(_ arguments: ParsedArguments, count: Int, usage: String) throws {
    try BaseCommand.requirePositionalArguments(arguments, count: count, usage: usage)
  }
}