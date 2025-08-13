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

    // Handle version flag
    if args.contains("--version") || args.contains("-v") {
      CLIInterface.printVersion()
      exit(0)
    }

    // Handle help flag
    if args.contains("--help") || args.contains("-h") || args.isEmpty {
      CLIInterface.printUsage()
      exit(0)
    }

    // Extract flags and parse arguments
    let (projectPath, dryRun, verbose, command, parsedArgs) = try parseArguments(args)

    // Create utility with project path and verbose flag
    let utility = try XcodeProjUtility(path: projectPath, verbose: verbose)

    // Check if this is a command handled by the new system
    let availableCommands = CommandRegistry.availableCommands()
    
    if availableCommands.contains(command) {
      // Handle dry run mode message
      if dryRun {
        print("🔍 DRY RUN MODE - No changes will be saved")
      }
      
      // Execute via command registry
      try CommandRegistry.execute(command: command, arguments: parsedArgs, utility: utility)
      
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
        command: command, 
        arguments: parsedArgs, 
        utility: utility, 
        dryRun: dryRun,
        verbose: verbose
      )
    }
  }
  
  /// Parse command line arguments and extract project path, dry run flag, verbose flag, command, and parsed args
  private static func parseArguments(_ args: [String]) throws -> (String, Bool, Bool, String, ParsedArguments) {
    var projectPath: String? = nil
    var dryRun = false
    var verbose = false
    var filteredArgs = args

    // Process --project flag
    if let projectIndex = filteredArgs.firstIndex(of: "--project") ?? filteredArgs.firstIndex(of: "-p") {
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
    if let verboseIndex = filteredArgs.firstIndex(of: "--verbose") ?? filteredArgs.firstIndex(of: "-V") {
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
      "Command '\(command)' has not been migrated to the new command system yet. " +
      "Available commands: \(CommandRegistry.availableCommands().joined(separator: ", "))"
    )
  }
}