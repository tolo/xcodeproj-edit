//
// CommandRegistry.swift
// xcodeproj-cli
//
// Registry for managing all available commands
//

import Foundation
import XcodeProj

/// Registry for managing and executing commands
struct CommandRegistry {
  
  /// Execute a command by name with given arguments
  static func execute(command: String, arguments: ParsedArguments, utility: XcodeProjUtility) throws {
    switch command {
    // File Commands
    case AddFileCommand.commandName:
      try AddFileCommand.execute(with: arguments, utility: utility)
      
    case AddFilesCommand.commandName:
      try AddFilesCommand.execute(with: arguments, utility: utility)
      
    case AddFolderCommand.commandName:
      try AddFolderCommand.execute(with: arguments, utility: utility)
      
    case AddSyncFolderCommand.commandName:
      try AddSyncFolderCommand.execute(with: arguments, utility: utility)
      
    case RemoveFileCommand.commandName:
      try RemoveFileCommand.execute(with: arguments, utility: utility)
      
    case MoveFileCommand.commandName:
      try MoveFileCommand.execute(with: arguments, utility: utility)
      
    // Target Commands
    case AddTargetCommand.commandName:
      try AddTargetCommand.execute(with: arguments, utility: utility)
      
    case DuplicateTargetCommand.commandName:
      try DuplicateTargetCommand.execute(with: arguments, utility: utility)
      
    case AddDependencyCommand.commandName:
      try AddDependencyCommand.execute(with: arguments, utility: utility)
      
    case ListTargetsCommand.commandName:
      try ListTargetsCommand.execute(with: arguments, utility: utility)
      
    case RemoveTargetCommand.commandName:
      try RemoveTargetCommand.execute(with: arguments, utility: utility)
      
    // Group Commands
    case CreateGroupsCommand.commandName:
      try CreateGroupsCommand.execute(with: arguments, utility: utility)
      
    case ListGroupsCommand.commandName:
      try ListGroupsCommand.execute(with: arguments, utility: utility)
      
    case RemoveGroupCommand.commandName:
      try RemoveGroupCommand.execute(with: arguments, utility: utility)
      
    // Build Commands
    case SetBuildSettingCommand.commandName:
      try SetBuildSettingCommand.execute(with: arguments, utility: utility)
      
    case GetBuildSettingsCommand.commandName:
      try GetBuildSettingsCommand.execute(with: arguments, utility: utility)
      
    case ListBuildSettingsCommand.commandName:
      try ListBuildSettingsCommand.execute(with: arguments, utility: utility)
      
    case AddBuildPhaseCommand.commandName:
      try AddBuildPhaseCommand.execute(with: arguments, utility: utility)
      
    case ListBuildConfigsCommand.commandName:
      try ListBuildConfigsCommand.execute(with: arguments, utility: utility)
      
    // Framework Commands
    case AddFrameworkCommand.commandName:
      try AddFrameworkCommand.execute(with: arguments, utility: utility)
      
    // Package Commands
    case AddSwiftPackageCommand.commandName:
      try AddSwiftPackageCommand.execute(with: arguments, utility: utility)
      
    case RemoveSwiftPackageCommand.commandName:
      try RemoveSwiftPackageCommand.execute(with: arguments, utility: utility)
      
    case ListSwiftPackagesCommand.commandName:
      try ListSwiftPackagesCommand.execute(with: arguments, utility: utility)
      
    // Inspection Commands
    case ValidateCommand.commandName:
      try ValidateCommand.execute(with: arguments, utility: utility)
      
    case ListFilesCommand.commandName:
      try ListFilesCommand.execute(with: arguments, utility: utility)
      
    case ListTreeCommand.commandName:
      try ListTreeCommand.execute(with: arguments, utility: utility)
      
    case ListInvalidReferencesCommand.commandName:
      try ListInvalidReferencesCommand.execute(with: arguments, utility: utility)
      
    case RemoveInvalidReferencesCommand.commandName:
      try RemoveInvalidReferencesCommand.execute(with: arguments, utility: utility)
      
    // Path Commands
    case UpdatePathsCommand.commandName:
      try UpdatePathsCommand.execute(with: arguments, utility: utility)
      
    case UpdatePathsMapCommand.commandName:
      try UpdatePathsMapCommand.execute(with: arguments, utility: utility)
      
    default:
      throw ProjectError.invalidArguments("Unknown command: \(command)")
    }
  }
  
  /// Get list of all available commands
  static func availableCommands() -> [String] {
    return [
      // File Commands
      AddFileCommand.commandName,
      AddFilesCommand.commandName,
      AddFolderCommand.commandName,
      AddSyncFolderCommand.commandName,
      RemoveFileCommand.commandName,
      MoveFileCommand.commandName,
      
      // Target Commands
      AddTargetCommand.commandName,
      DuplicateTargetCommand.commandName,
      AddDependencyCommand.commandName,
      ListTargetsCommand.commandName,
      RemoveTargetCommand.commandName,
      
      // Group Commands
      CreateGroupsCommand.commandName,
      ListGroupsCommand.commandName,
      RemoveGroupCommand.commandName,
      
      // Build Commands
      SetBuildSettingCommand.commandName,
      GetBuildSettingsCommand.commandName,
      ListBuildSettingsCommand.commandName,
      AddBuildPhaseCommand.commandName,
      ListBuildConfigsCommand.commandName,
      
      // Framework Commands
      AddFrameworkCommand.commandName,
      
      // Package Commands
      AddSwiftPackageCommand.commandName,
      RemoveSwiftPackageCommand.commandName,
      ListSwiftPackagesCommand.commandName,
      
      // Inspection Commands
      ValidateCommand.commandName,
      ListFilesCommand.commandName,
      ListTreeCommand.commandName,
      ListInvalidReferencesCommand.commandName,
      RemoveInvalidReferencesCommand.commandName,
      
      // Path Commands
      UpdatePathsCommand.commandName,
      UpdatePathsMapCommand.commandName
    ]
  }
  
  /// Print usage information for a specific command
  static func printCommandUsage(_ command: String) {
    switch command {
    // File Commands
    case AddFileCommand.commandName:
      AddFileCommand.printUsage()
    case AddFilesCommand.commandName:
      AddFilesCommand.printUsage()
    case AddFolderCommand.commandName:
      AddFolderCommand.printUsage()
    case AddSyncFolderCommand.commandName:
      AddSyncFolderCommand.printUsage()
    case RemoveFileCommand.commandName:
      RemoveFileCommand.printUsage()
    case MoveFileCommand.commandName:
      MoveFileCommand.printUsage()
      
    // Target Commands
    case AddTargetCommand.commandName:
      AddTargetCommand.printUsage()
    case DuplicateTargetCommand.commandName:
      DuplicateTargetCommand.printUsage()
    case AddDependencyCommand.commandName:
      AddDependencyCommand.printUsage()
    case ListTargetsCommand.commandName:
      ListTargetsCommand.printUsage()
    case RemoveTargetCommand.commandName:
      RemoveTargetCommand.printUsage()
      
    // Group Commands
    case CreateGroupsCommand.commandName:
      CreateGroupsCommand.printUsage()
    case ListGroupsCommand.commandName:
      ListGroupsCommand.printUsage()
    case RemoveGroupCommand.commandName:
      RemoveGroupCommand.printUsage()
      
    // Build Commands
    case SetBuildSettingCommand.commandName:
      SetBuildSettingCommand.printUsage()
    case GetBuildSettingsCommand.commandName:
      GetBuildSettingsCommand.printUsage()
    case ListBuildSettingsCommand.commandName:
      ListBuildSettingsCommand.printUsage()
    case AddBuildPhaseCommand.commandName:
      AddBuildPhaseCommand.printUsage()
    case ListBuildConfigsCommand.commandName:
      ListBuildConfigsCommand.printUsage()
      
    // Framework Commands
    case AddFrameworkCommand.commandName:
      AddFrameworkCommand.printUsage()
      
    // Package Commands
    case AddSwiftPackageCommand.commandName:
      AddSwiftPackageCommand.printUsage()
    case RemoveSwiftPackageCommand.commandName:
      RemoveSwiftPackageCommand.printUsage()
    case ListSwiftPackagesCommand.commandName:
      ListSwiftPackagesCommand.printUsage()
      
    // Inspection Commands
    case ValidateCommand.commandName:
      ValidateCommand.printUsage()
    case ListFilesCommand.commandName:
      ListFilesCommand.printUsage()
    case ListTreeCommand.commandName:
      ListTreeCommand.printUsage()
    case ListInvalidReferencesCommand.commandName:
      ListInvalidReferencesCommand.printUsage()
    case RemoveInvalidReferencesCommand.commandName:
      RemoveInvalidReferencesCommand.printUsage()
      
    // Path Commands
    case UpdatePathsCommand.commandName:
      UpdatePathsCommand.printUsage()
    case UpdatePathsMapCommand.commandName:
      UpdatePathsMapCommand.printUsage()
      
    default:
      print("Unknown command: \(command)")
    }
  }
}