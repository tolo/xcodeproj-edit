//
// CLIInterface.swift
// xcodeproj-cli
//
// Command-line interface definitions and help system
//

import Foundation

/// Main CLI interface for xcodeproj-cli
struct CLIInterface {
  static let version = "2.0.0"

  static func printUsage() {
    print(
      """
      XcodeProj CLI v\(version)
      A powerful command-line tool for Xcode project manipulation

      Usage: xcodeproj-cli [--project <path>] <command> [options]

      Options:
        --project <path>  Path to .xcodeproj file (default: looks for *.xcodeproj in current directory)
        --dry-run         Preview changes without saving
        --verbose, -V     Enable verbose output with performance metrics
        --version         Display version information
        --help, -h        Show this help message

      FILE & FOLDER OPERATIONS:
        
        Understanding Groups, Folders, and References:
        • add-group: Creates empty virtual groups for organization (yellow folder icon)
        • add-folder: Creates a group and adds files from a filesystem folder (yellow folder icon)
        • add-sync-folder: Creates a folder reference that auto-syncs with filesystem (blue folder icon in Xcode 16+)
        • remove-group: Removes any group, folder group, or synced folder from the project
        
        add-file <file-path> --group <group> --targets <target1,target2>
          Add a single file to specified group and targets
          Short flags: -g for group, -t for targets
          Example: add-file Sources/Model.swift --group Models --targets MyApp,MyAppTests
          Example: add-file Helper.swift -g Utils -t MyApp

        add-files <pattern> --group <group> --targets <target1,target2>
          Add multiple files matching pattern to group and targets
          Example: add-files "Sources/**/*.swift" --group Sources --targets MyApp

        add-folder <folder-path> --group <group> --targets <target1,target2> [--recursive]
          Add files from filesystem folder to project group
          Example: add-folder Sources/Utils --group Utils --targets MyApp --recursive

      For full command reference, visit: https://github.com/tolo/xcodeproj-cli
      """
    )
  }

  static func printVersion() {
    print("xcodeproj-cli version \(version)")
  }
}
