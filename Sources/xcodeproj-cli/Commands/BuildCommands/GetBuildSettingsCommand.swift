//
// GetBuildSettingsCommand.swift
// xcodeproj-cli
//
// Command for getting build settings from targets
//

import Foundation
import XcodeProj

/// Command for getting build settings from a target
struct GetBuildSettingsCommand: Command {
  static let commandName = "get-build-settings"
  
  static let description = "Get build settings from a target"
  
  static func execute(with arguments: ParsedArguments, utility: XcodeProjUtility) throws {
    // Validate required arguments
    try requirePositionalArguments(
      arguments,
      count: 1,
      usage: "get-build-settings requires: <target> [--config <configuration>]"
    )
    
    let targetName = arguments.positional[0]
    let configuration = arguments.getFlag("--config", "-c")
    
    // Validate target exists
    try validateTargets([targetName], in: utility)
    
    // Execute the command
    let settings = utility.getBuildSettings(for: targetName, configuration: configuration)
    
    print("🔧 Build settings for \(targetName):")
    if settings.isEmpty {
      print("  No settings found")
    } else {
      for (configName, configSettings) in settings {
        print("  \(configName):")
        let sortedKeys = configSettings.keys.sorted()
        for key in sortedKeys {
          let value = configSettings[key]
          print("    \(key) = \(value ?? "nil")")
        }
      }
    }
  }
  
  static func printUsage() {
    print("""
      get-build-settings <target> [--config <configuration>]
        Get build settings from a target
        
        Arguments:
          <target>                  Target name to get settings from
          --config, -c <config>     Optional: specific configuration name
        
        Examples:
          get-build-settings MyApp
          get-build-settings MyApp --config Debug
      """)
  }
}

// MARK: - BaseCommand conformance
extension GetBuildSettingsCommand {
  private static func requirePositionalArguments(_ arguments: ParsedArguments, count: Int, usage: String) throws {
    try BaseCommand.requirePositionalArguments(arguments, count: count, usage: usage)
  }
  
  private static func validateTargets(_ targetNames: [String], in utility: XcodeProjUtility) throws {
    try BaseCommand.validateTargets(targetNames, in: utility)
  }
}