//
// CLIRunner.swift
// xcodeproj-cli
//
// Main CLI execution logic and argument processing
//

import Foundation
import XcodeProj

/// Main CLI runner that handles argument processing and command execution
struct CLIRunner {

  /// Run the CLI with the given command line arguments
  static func run() throws {
    let args = Array(CommandLine.arguments.dropFirst())

    // Handle global flags that should be checked early
    // Only check for --version/-v if they're not preceded by another flag
    let isVersionRequest = args.count > 0 && (args[0] == "--version" || args[0] == "-v")
    if isVersionRequest {
      CLIInterface.printVersion()
      exit(0)
    }

    // Handle help flag 
    let isHelpRequest = args.isEmpty || args.count > 0 && (args[0] == "--help" || args[0] == "-h")
    if isHelpRequest {
      CLIInterface.printUsage()
      exit(0)
    }

    // Extract command early to check if it's workspace-only
    let command = args.first { !$0.starts(with: "-") } ?? ""
    
    // Commands that don't require a project file
    let workspaceOnlyCommands = [
      "create-workspace",
      "add-project-to-workspace", 
      "remove-project-from-workspace",
      "list-workspace-projects"
    ]

    // Handle workspace-only commands separately
    if workspaceOnlyCommands.contains(command) {
      let (_, dryRun, verbose, command, parsedArgs) = try parseArgumentsForWorkspaceCommand(args)
      
      // Handle dry run mode message
      if dryRun {
        print("🔍 DRY RUN MODE - No changes will be saved")
      }

      // Execute workspace command without project context
      try CommandRegistry.executeWorkspaceCommand(command: command, arguments: parsedArgs, verbose: verbose)
      
      if !dryRun {
        print("✅ Operation completed successfully")
      } else {
        print("🔍 DRY RUN - Changes not saved")
      }
      return
    }

    // Extract flags and parse arguments for regular commands
    let (projectPath, dryRun, verbose, actualCommand, parsedArgs) = try parseArguments(args)
    
    // Validate unknown flags
    try validateFlags(parsedArgs, for: actualCommand)

    // Create utility with project path and verbose flag
    let utility = try XcodeProjUtility(path: projectPath, verbose: verbose)

    // Check if this is a command handled by the new system
    let availableCommands = CommandRegistry.availableCommands()

    if availableCommands.contains(actualCommand) {
      // Handle dry run mode message
      if dryRun {
        print("🔍 DRY RUN MODE - No changes will be saved")
      }

      // Execute via command registry
      try CommandRegistry.execute(command: actualCommand, arguments: parsedArgs, utility: utility)

      // Save changes (unless dry run or command exited)
      if !dryRun {
        try utility.save()
        print("✅ Operation completed successfully")
      } else {
        print("🔍 DRY RUN - Changes not saved")
      }
    } else {
      // Fall back to legacy system for unimplemented commands
      try executeLegacyCommand(
        command: actualCommand,
        arguments: parsedArgs,
        utility: utility,
        dryRun: dryRun,
        verbose: verbose
      )
    }
  }

  /// Parse command line arguments and extract project path, dry run flag, verbose flag, command, and parsed args
  private static func parseArguments(_ args: [String]) throws -> (
    String, Bool, Bool, String, ParsedArguments
  ) {
    var projectPath: String? = nil
    var dryRun = false
    var verbose = false
    var filteredArgs = args

    // Process --project flag
    if let projectIndex = filteredArgs.firstIndex(of: "--project")
      ?? filteredArgs.firstIndex(of: "-p")
    {
      if projectIndex + 1 < filteredArgs.count {
        projectPath = filteredArgs[projectIndex + 1]
        filteredArgs.remove(at: projectIndex + 1)
        filteredArgs.remove(at: projectIndex)
      } else {
        throw ProjectError.invalidArguments("--project requires a path")
      }
    }

    // If no project specified, look for .xcodeproj in current directory
    if projectPath == nil {
      projectPath = try findProjectInCurrentDirectory()
    }

    // Process --dry-run flag
    if let dryRunIndex = filteredArgs.firstIndex(of: "--dry-run") {
      dryRun = true
      filteredArgs.remove(at: dryRunIndex)
    }

    // Process --verbose flag
    if let verboseIndex = filteredArgs.firstIndex(of: "--verbose")
      ?? filteredArgs.firstIndex(of: "-V")
    {
      verbose = true
      filteredArgs.remove(at: verboseIndex)
    }

    guard let command = filteredArgs.first else {
      CLIInterface.printUsage()
      exit(0)
    }

    guard let finalProjectPath = projectPath else {
      throw ProjectError.invalidArguments("Project path is required")
    }

    let remainingArgs = Array(filteredArgs.dropFirst())
    let parsedArgs = ArgumentParser.parseArguments(remainingArgs)

    return (finalProjectPath, dryRun, verbose, command, parsedArgs)
  }

  /// Find .xcodeproj file in current directory
  private static func findProjectInCurrentDirectory() throws -> String {
    let fileManager = FileManager.default
    let currentPath = fileManager.currentDirectoryPath
    let contents = try fileManager.contentsOfDirectory(atPath: currentPath)
    let xcodeprojFiles = contents.filter { $0.hasSuffix(".xcodeproj") }

    if xcodeprojFiles.isEmpty {
      throw ProjectError.invalidArguments(
        "No .xcodeproj file found in current directory. Use --project to specify the path."
      )
    } else if xcodeprojFiles.count > 1 {
      throw ProjectError.invalidArguments(
        "Multiple .xcodeproj files found: \(xcodeprojFiles.joined(separator: ", ")). Use --project to specify which one."
      )
    }

    return xcodeprojFiles[0]
  }

  /// Parse command line arguments for workspace commands that don't require a project
  private static func parseArgumentsForWorkspaceCommand(_ args: [String]) throws -> (
    String?, Bool, Bool, String, ParsedArguments
  ) {
    var dryRun = false
    var verbose = false
    var filteredArgs = args

    // Process --dry-run flag
    if let dryRunIndex = filteredArgs.firstIndex(of: "--dry-run") {
      dryRun = true
      filteredArgs.remove(at: dryRunIndex)
    }

    // Process --verbose flag
    if let verboseIndex = filteredArgs.firstIndex(of: "--verbose")
      ?? filteredArgs.firstIndex(of: "-V")
    {
      verbose = true
      filteredArgs.remove(at: verboseIndex)
    }

    guard let command = filteredArgs.first else {
      CLIInterface.printUsage()
      exit(0)
    }

    let remainingArgs = Array(filteredArgs.dropFirst())
    let parsedArgs = ArgumentParser.parseArguments(remainingArgs)

    return (nil, dryRun, verbose, command, parsedArgs)
  }

  /// Execute legacy commands that haven't been migrated yet
  private static func executeLegacyCommand(
    command: String,
    arguments: ParsedArguments,
    utility: XcodeProjUtility,
    dryRun: Bool,
    verbose: Bool
  ) throws {
    // For now, we'll throw an error for unmigrated commands
    // This forces us to migrate commands rather than falling back
    throw ProjectError.invalidArguments(
      "Command '\(command)' has not been migrated to the new command system yet. "
        + "Available commands: \(CommandRegistry.availableCommands().joined(separator: ", "))"
    )
  }
  
  /// Validate that all flags used are known for the given command
  private static func validateFlags(_ parsedArgs: ParsedArguments, for command: String) throws {
    // Common flags accepted by all commands
    let globalFlags: Set<String> = [
      "--help", "-h", "--version", "-v", "--verbose", "-V", 
      "--dry-run", "--project", "-p"
    ]
    
    // Command-specific valid flags
    let commandFlags = getValidFlagsForCommand(command)
    let allValidFlags = globalFlags.union(commandFlags)
    
    // Check for unknown flags
    for flag in parsedArgs.flags.keys {
      if !allValidFlags.contains(flag) {
        throw ProjectError.invalidArguments("Unknown flag: \(flag)")
      }
    }
    
    // Check for unknown boolean flags
    for flag in parsedArgs.boolFlags {
      if !allValidFlags.contains(flag) {
        throw ProjectError.invalidArguments("Unknown flag: \(flag)")
      }
    }
  }
  
  /// Get valid flags for a specific command
  private static func getValidFlagsForCommand(_ command: String) -> Set<String> {
    switch command {
    case "add-file":
      return ["--group", "-g", "--targets", "-t", "--create-groups", "--no-groups"]
    case "add-files":
      return ["--group", "-g", "--targets", "-t", "--create-groups", "--no-groups"] 
    case "add-folder":
      return ["--group", "-g", "--targets", "-t", "--recursive", "-r", "--create-groups"]
    case "add-sync-folder":
      return ["--group", "-g", "--targets", "-t", "--recursive", "-r", "--create-groups"]
    case "remove-file":
      return ["--targets"]
    case "move-file":
      return ["--to-group"]
    case "add-target":
      return ["--type", "-T", "--bundle-id", "-b", "--platform", "-p"]
    case "duplicate-target":
      return ["--bundle-id", "-b"]
    case "add-dependency":
      return ["--depends-on"]
    case "list-targets":
      return []
    case "remove-target":
      return []
    case "create-groups":
      return []
    case "list-groups":
      return []
    case "remove-group":
      return []
    case "set-build-setting":
      return ["--targets", "--configs"]
    case "get-build-settings":
      return ["--targets", "--configs"]
    case "list-build-settings":
      return ["--targets", "--configs"]
    case "add-build-phase":
      return ["--target", "-t", "--script", "-s"]
    case "list-build-configs":
      return []
    case "add-framework":
      return ["--targets", "--search-path"]
    case "add-swift-package":
      return ["--version", "-v", "--branch", "-b", "--commit", "-c", "--target", "-t"]
    case "remove-swift-package":
      return []
    case "list-swift-packages":
      return []
    case "update-swift-packages":
      return []
    case "validate":
      return ["--fix"]
    case "list-files":
      return ["--targets", "--groups"]
    case "list-tree":
      return []
    case "list-invalid-references":
      return []
    case "remove-invalid-references":
      return []
    case "update-paths":
      return ["--from", "--to"]
    case "update-paths-map":
      return ["--map"]
    case "create-scheme":
      return ["--targets", "--test-targets"]
    case "duplicate-scheme":
      return ["--new-name"]
    case "remove-scheme":
      return []
    case "list-schemes":
      return []
    case "set-scheme-config":
      return ["--config"]
    case "add-scheme-target":
      return ["--target", "--type"]
    case "enable-test-coverage":
      return []
    case "set-test-parallel":
      return ["--enabled"]
    default:
      return []
    }
  }
}
