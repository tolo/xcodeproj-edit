//
// SetBuildSettingCommand.swift
// xcodeproj-cli
//
// Command for setting build settings on targets
//

import Foundation
import XcodeProj

/// Command for setting build settings on specified targets

struct SetBuildSettingCommand: Command {
  static let commandName = "set-build-setting"

  static let description = "Set build setting on specified targets"

  static func execute(with arguments: ParsedArguments, utility: XcodeProjUtility) throws {
    // Validate required arguments
    try requirePositionalArguments(
      arguments,
      count: 2,
      usage: "set-build-setting requires: <key> <value> --targets <target1,target2>"
    )

    let key = arguments.positional[0]
    let value = arguments.positional[1]

    // Validate build setting for security
    guard SecurityUtils.validateBuildSetting(key: key, value: value) else {
      throw ProjectError.invalidArguments(
        "Build setting '\(key)' contains potentially dangerous value")
    }

    // Get required flags
    let targetsStr = try arguments.requireFlag(
      "--targets", "-t",
      error: "set-build-setting requires --targets or -t flag"
    )

    let targets = parseTargets(from: targetsStr)
    let configuration = arguments.getFlag("--config", "-c")

    // Validate targets
    try validateTargets(targets, in: utility)

    // Execute the command
    utility.setBuildSetting(key: key, value: value, targets: targets, configuration: configuration)

    // Save changes
    try utility.save()
  }

  static func printUsage() {
    print(
      """
      set-build-setting <key> <value> --targets <target1,target2> [--config <configuration>]
        Set build setting on specified targets
        
        Arguments:
          <key>                     Build setting key
          <value>                   Build setting value
          --targets, -t <list>      Comma-separated list of target names
          --config, -c <config>     Optional: specific configuration name
        
        Examples:
          set-build-setting SWIFT_VERSION 5.0 --targets MyApp,MyTests
          set-build-setting CODE_SIGN_IDENTITY "iPhone Developer" -t MyApp -c Debug
      """)
  }
}

// MARK: - BaseCommand conformance
extension SetBuildSettingCommand {

  private static func requirePositionalArguments(
    _ arguments: ParsedArguments, count: Int, usage: String
  ) throws {
    try BaseCommand.requirePositionalArguments(arguments, count: count, usage: usage)
  }

  private static func parseTargets(from targetsString: String) -> [String] {
    return BaseCommand.parseTargets(from: targetsString)
  }

  @MainActor
  private static func validateTargets(_ targetNames: [String], in utility: XcodeProjUtility) throws
  {
    try BaseCommand.validateTargets(targetNames, in: utility)
  }
}
