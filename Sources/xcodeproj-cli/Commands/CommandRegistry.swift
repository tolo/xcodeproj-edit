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
  static func execute(command: String, arguments: ParsedArguments, utility: XcodeProjUtility) throws
  {
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

    case UpdateSwiftPackagesCommand.commandName:
      try UpdateSwiftPackagesCommand.execute(with: arguments, utility: utility)

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

    // Scheme Commands
    case CreateSchemeCommand.commandName:
      try CreateSchemeCommand.execute(with: arguments, utility: utility)

    case DuplicateSchemeCommand.commandName:
      try DuplicateSchemeCommand.execute(with: arguments, utility: utility)

    case RemoveSchemeCommand.commandName:
      try RemoveSchemeCommand.execute(with: arguments, utility: utility)

    case ListSchemesCommand.commandName:
      try ListSchemesCommand.execute(with: arguments, utility: utility)

    case SetSchemeConfigCommand.commandName:
      try SetSchemeConfigCommand.execute(with: arguments, utility: utility)

    case AddSchemeTargetCommand.commandName:
      try AddSchemeTargetCommand.execute(with: arguments, utility: utility)

    case EnableTestCoverageCommand.commandName:
      try EnableTestCoverageCommand.execute(with: arguments, utility: utility)

    case SetTestParallelCommand.commandName:
      try SetTestParallelCommand.execute(with: arguments, utility: utility)

    // Workspace Commands
    case "create-workspace":
      try CreateWorkspaceCommand.execute(with: arguments, utility: utility)

    case "add-project-to-workspace":
      try AddProjectToWorkspaceCommand.execute(with: arguments, utility: utility)

    case "remove-project-from-workspace":
      try RemoveProjectFromWorkspaceCommand.execute(with: arguments, utility: utility)

    case "list-workspace-projects":
      try ListWorkspaceProjectsCommand.execute(with: arguments, utility: utility)

    case "add-project-reference":
      try AddProjectReferenceCommand.execute(with: arguments, utility: utility)

    case "add-cross-project-dependency":
      try AddCrossProjectDependencyCommand.execute(with: arguments, utility: utility)

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
      UpdateSwiftPackagesCommand.commandName,

      // Inspection Commands
      ValidateCommand.commandName,
      ListFilesCommand.commandName,
      ListTreeCommand.commandName,
      ListInvalidReferencesCommand.commandName,
      RemoveInvalidReferencesCommand.commandName,

      // Path Commands
      UpdatePathsCommand.commandName,
      UpdatePathsMapCommand.commandName,

      // Scheme Commands
      CreateSchemeCommand.commandName,
      DuplicateSchemeCommand.commandName,
      RemoveSchemeCommand.commandName,
      ListSchemesCommand.commandName,
      SetSchemeConfigCommand.commandName,
      AddSchemeTargetCommand.commandName,
      EnableTestCoverageCommand.commandName,
      SetTestParallelCommand.commandName,

      // Workspace Commands
      "create-workspace",
      "add-project-to-workspace",
      "remove-project-from-workspace",
      "list-workspace-projects",
      "add-project-reference",
      "add-cross-project-dependency",
    ]
  }

  /// Execute a workspace command that doesn't require a project context
  static func executeWorkspaceCommand(command: String, arguments: ParsedArguments, verbose: Bool)
    throws
  {
    switch command {
    case "create-workspace":
      try CreateWorkspaceCommand.executeAsWorkspaceCommand(with: arguments, verbose: verbose)
    case "add-project-to-workspace":
      try AddProjectToWorkspaceCommand.executeAsWorkspaceCommand(with: arguments, verbose: verbose)
    case "remove-project-from-workspace":
      try RemoveProjectFromWorkspaceCommand.executeAsWorkspaceCommand(
        with: arguments, verbose: verbose)
    case "list-workspace-projects":
      try ListWorkspaceProjectsCommand.executeAsWorkspaceCommand(with: arguments, verbose: verbose)
    default:
      throw ProjectError.invalidArguments("Unknown workspace command: \(command)")
    }
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
    case UpdateSwiftPackagesCommand.commandName:
      UpdateSwiftPackagesCommand.printUsage()

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

    // Scheme Commands
    case CreateSchemeCommand.commandName:
      CreateSchemeCommand.printUsage()
    case DuplicateSchemeCommand.commandName:
      DuplicateSchemeCommand.printUsage()
    case RemoveSchemeCommand.commandName:
      RemoveSchemeCommand.printUsage()
    case ListSchemesCommand.commandName:
      ListSchemesCommand.printUsage()
    case SetSchemeConfigCommand.commandName:
      SetSchemeConfigCommand.printUsage()
    case AddSchemeTargetCommand.commandName:
      AddSchemeTargetCommand.printUsage()
    case EnableTestCoverageCommand.commandName:
      EnableTestCoverageCommand.printUsage()
    case SetTestParallelCommand.commandName:
      SetTestParallelCommand.printUsage()

    // Workspace Commands
    case "create-workspace":
      CreateWorkspaceCommand.printUsage()
    case "add-project-to-workspace":
      AddProjectToWorkspaceCommand.printUsage()
    case "remove-project-from-workspace":
      RemoveProjectFromWorkspaceCommand.printUsage()
    case "list-workspace-projects":
      ListWorkspaceProjectsCommand.printUsage()
    case "add-project-reference":
      AddProjectReferenceCommand.printUsage()
    case "add-cross-project-dependency":
      AddCrossProjectDependencyCommand.printUsage()

    default:
      print("Unknown command: \(command)")
    }
  }
}
