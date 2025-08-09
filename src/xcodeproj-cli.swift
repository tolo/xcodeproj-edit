#!/usr/bin/swift sh

// XcodeProj CLI - Comprehensive Xcode Project Manipulation Utility
// Version: 1.0.0
// License: MIT
//
// A powerful command-line tool for programmatically manipulating Xcode project files
// without requiring Xcode or Docker. Provides complete project management capabilities
// including files, targets, dependencies, build settings, and Swift packages.
//
// Usage: ./xcodeproj-cli.swift <command> [options]
// Run with --help for full command reference

import Foundation
import PathKit
import XcodeProj  // @tuist ~> 9.4.3

// MARK: - String Extensions
extension String {
  func matches(_ pattern: String) -> Bool {
    return range(of: pattern, options: .regularExpression) != nil
  }
}

// MARK: - Error Types
enum ProjectError: Error, CustomStringConvertible {
  case fileAlreadyExists(String)
  case groupNotFound(String)
  case targetNotFound(String)
  case invalidArguments(String)
  case operationFailed(String)

  var description: String {
    switch self {
    case .fileAlreadyExists(let path): return "File already exists: \(path)"
    case .groupNotFound(let name): return "Group not found: \(name)"
    case .targetNotFound(let name): return "Target not found: \(name)"
    case .invalidArguments(let msg): return "Invalid arguments: \(msg)"
    case .operationFailed(let msg): return "Operation failed: \(msg)"
    }
  }
}

// MARK: - Security Helpers
func sanitizePath(_ path: String) -> String? {
  // Block obvious path traversal attempts that try to escape project boundaries
  if path.contains("../..") || path.contains("..\\..") {
    // Allow single ../ for referencing parent directories within project
    // but block multiple levels that could escape project root
    return nil
  }

  // For absolute paths, only block critical system directories
  // This allows adding files from user directories while protecting system
  if path.hasPrefix("/") {
    let criticalPaths = ["/etc/passwd", "/etc/shadow", "/private/etc", "/System/Library"]
    for critical in criticalPaths {
      if path.hasPrefix(critical) {
        return nil
      }
    }
  }

  // Allow ~ expansion as coding agents may use it
  // The shell will handle the actual expansion

  return path
}

func escapeShellCommand(_ command: String) -> String {
  // Escape common shell metacharacters
  let charactersToEscape = ["$", "`", "\\", "\"", "\n"]
  var escaped = command
  for char in charactersToEscape {
    escaped = escaped.replacingOccurrences(of: char, with: "\\\(char)")
  }
  return escaped
}

// MARK: - Helper Functions
func findGroup(named name: String, in groups: [PBXGroup]) -> PBXGroup? {
  for group in groups {
    if group.path == name || group.name == name {
      return group
    }
    let childGroups = group.children.compactMap { $0 as? PBXGroup }
    if let found = findGroup(named: name, in: childGroups) {
      return found
    }
  }
  return nil
}

func fileExists(path: String, in pbxproj: PBXProj) -> Bool {
  return pbxproj.fileReferences.contains { $0.path == path || $0.name == path }
}

func sourceBuildPhase(for target: PBXNativeTarget) -> PBXSourcesBuildPhase? {
  return target.buildPhases.first(where: { $0 is PBXSourcesBuildPhase }) as? PBXSourcesBuildPhase
}

func fileType(for path: String) -> String {
  switch (path as NSString).pathExtension.lowercased() {
  case "swift": return "sourcecode.swift"
  case "m": return "sourcecode.c.objc"
  case "mm": return "sourcecode.cpp.objcpp"
  case "cpp", "cc", "cxx": return "sourcecode.cpp.cpp"
  case "c": return "sourcecode.c.c"
  case "h": return "sourcecode.c.h"
  case "hpp", "hxx": return "sourcecode.cpp.h"
  case "storyboard": return "file.storyboard"
  case "xib": return "file.xib"
  case "plist": return "text.plist.xml"
  case "json": return "text.json"
  case "strings": return "text.plist.strings"
  case "xcassets": return "folder.assetcatalog"
  case "framework": return "wrapper.framework"
  case "dylib": return "compiled.mach-o.dylib"
  case "a": return "archive.ar"
  case "png", "jpg", "jpeg", "gif", "tiff", "bmp": return "image"
  case "mp3", "wav", "m4a", "aiff": return "audio"
  case "mp4", "mov", "avi": return "video"
  default: return "text"
  }
}

// MARK: - Argument Parsing Helpers
struct ParsedArguments {
  var positional: [String] = []
  var flags: [String: String] = [:]
  var boolFlags: Set<String> = []

  func getFlag(_ names: String...) -> String? {
    return getFlagFromArray(names)
  }

  func getFlagFromArray(_ names: [String]) -> String? {
    for name in names {
      if let value = flags[name] {
        return value
      }
    }
    return nil
  }

  func hasFlag(_ names: String...) -> Bool {
    return hasFlagFromArray(names)
  }

  func hasFlagFromArray(_ names: [String]) -> Bool {
    for name in names {
      if boolFlags.contains(name) {
        return true
      }
    }
    return false
  }

  func requireFlag(_ names: String..., error: String) throws -> String {
    guard let value = getFlagFromArray(names) else {
      throw ProjectError.invalidArguments(error)
    }
    return value
  }
}

func parseArguments(_ args: [String]) -> ParsedArguments {
  var parsed = ParsedArguments()
  var i = 0

  while i < args.count {
    let arg = args[i]

    if arg.hasPrefix("--") || arg.hasPrefix("-") {
      let flagName = arg

      // Check if it's a boolean flag or has a value
      if i + 1 < args.count && !args[i + 1].hasPrefix("-") {
        // Flag with value
        parsed.flags[flagName] = args[i + 1]
        i += 2
      } else {
        // Boolean flag
        parsed.boolFlags.insert(flagName)
        i += 1
      }
    } else {
      // Positional argument
      parsed.positional.append(arg)
      i += 1
    }
  }

  return parsed
}

// Enhanced file filtering
func shouldIncludeFile(_ path: String) -> Bool {
  let filename = (path as NSString).lastPathComponent
  let excludedFiles = [".DS_Store", "Thumbs.db", ".git", ".gitignore", ".gitkeep"]
  let excludedExtensions = [".orig", ".bak", ".tmp", ".temp"]

  // Skip hidden files (starting with .)
  if filename.hasPrefix(".") && !filename.hasSuffix(".h") && !filename.hasSuffix(".m") {
    return false
  }

  // Skip excluded files
  if excludedFiles.contains(filename) {
    return false
  }

  // Skip excluded extensions
  for ext in excludedExtensions {
    if filename.hasSuffix(ext) {
      return false
    }
  }

  return true
}

// Check if file should be added to compile sources
func isCompilableFile(_ path: String) -> Bool {
  let compilableExtensions = ["swift", "m", "mm", "cpp", "cc", "cxx", "c"]
  return compilableExtensions.contains((path as NSString).pathExtension.lowercased())
}

// Enhanced group finding with better path resolution
func findGroupByPath(_ path: String, in groups: [PBXGroup], rootGroup: PBXGroup) -> PBXGroup? {
  let pathComponents = path.split(separator: "/").map(String.init)
  var currentGroup = rootGroup

  for component in pathComponents {
    guard
      let nextGroup = currentGroup.children.compactMap({ $0 as? PBXGroup })
        .first(where: { $0.name == component || $0.path == component })
    else {
      return nil
    }
    currentGroup = nextGroup
  }

  return currentGroup
}

// MARK: - XcodeProj Utility
class XcodeProjUtility {
  let xcodeproj: XcodeProj
  let projectPath: Path
  let pbxproj: PBXProj
  private var transactionBackupPath: Path?

  init(path: String = "MyProject.xcodeproj") throws {
    // Resolve path relative to current working directory, not script location
    if path.hasPrefix("/") {
      // Absolute path
      self.projectPath = Path(path)
    } else {
      // Relative path - resolve from current working directory
      let currentDir = FileManager.default.currentDirectoryPath
      self.projectPath = Path(currentDir) + Path(path)
    }

    self.xcodeproj = try XcodeProj(path: projectPath)
    self.pbxproj = xcodeproj.pbxproj
  }

  // MARK: - Transaction Support
  func beginTransaction() throws {
    guard transactionBackupPath == nil else {
      throw ProjectError.operationFailed("Transaction already in progress")
    }

    let backupPath = Path("\(projectPath.string).transaction")
    if FileManager.default.fileExists(atPath: projectPath.string) {
      try FileManager.default.copyItem(atPath: projectPath.string, toPath: backupPath.string)
      transactionBackupPath = backupPath
      print("🔄 Transaction started")
    }
  }

  func commitTransaction() throws {
    guard let backupPath = transactionBackupPath else {
      return  // No transaction in progress
    }

    // Save changes
    try save()

    // Remove backup
    if FileManager.default.fileExists(atPath: backupPath.string) {
      try FileManager.default.removeItem(atPath: backupPath.string)
    }

    transactionBackupPath = nil
    print("✅ Transaction committed")
  }

  func rollbackTransaction() throws {
    guard let backupPath = transactionBackupPath else {
      throw ProjectError.operationFailed("No transaction to rollback")
    }

    // Restore from backup
    if FileManager.default.fileExists(atPath: backupPath.string) {
      if FileManager.default.fileExists(atPath: projectPath.string) {
        try FileManager.default.removeItem(atPath: projectPath.string)
      }
      try FileManager.default.moveItem(atPath: backupPath.string, toPath: projectPath.string)
    }

    transactionBackupPath = nil
    print("↩️  Transaction rolled back")
  }

  // MARK: - File Operations
  func addFile(path: String, to groupPath: String, targets: [String]) throws {
    // Validate path
    guard sanitizePath(path) != nil else {
      throw ProjectError.invalidArguments("Invalid file path: \(path)")
    }

    let fileName = (path as NSString).lastPathComponent

    // Check if file already exists
    if fileExists(path: fileName, in: pbxproj) {
      print("⚠️  File \(fileName) already exists, skipping")
      return
    }

    // Find parent group
    guard let parentGroup = findGroup(named: groupPath, in: pbxproj.groups) else {
      throw ProjectError.groupNotFound(groupPath)
    }

    // Create file reference
    let fileRef = PBXFileReference(
      sourceTree: .group,
      lastKnownFileType: fileType(for: path),
      path: fileName
    )

    // Add to project
    pbxproj.add(object: fileRef)
    parentGroup.children.append(fileRef)

    // Add to targets (only compilable files go to sources build phase)
    for targetName in targets {
      guard let target = pbxproj.nativeTargets.first(where: { $0.name == targetName }) else {
        print("⚠️  Target '\(targetName)' not found")
        continue
      }

      if isCompilableFile(path) {
        // Add to sources build phase
        guard let sourcesBuildPhase = sourceBuildPhase(for: target) else {
          print("⚠️  Target '\(targetName)' has no sources build phase")
          continue
        }

        let buildFile = PBXBuildFile(file: fileRef)
        pbxproj.add(object: buildFile)
        sourcesBuildPhase.files?.append(buildFile)
      } else {
        // Add to resources build phase for non-compilable files
        if let resourcesBuildPhase = target.buildPhases.first(where: {
          $0 is PBXResourcesBuildPhase
        }) as? PBXResourcesBuildPhase {
          let buildFile = PBXBuildFile(file: fileRef)
          pbxproj.add(object: buildFile)
          resourcesBuildPhase.files?.append(buildFile)
        }
      }
    }

    print("✅ Added \(fileName) to \(targets.joined(separator: ", "))")
  }

  // MARK: - Folder Operations
  func addFolder(
    folderPath: String, to groupPath: String, targets: [String], recursive: Bool = true
  ) throws {
    let folderURL = URL(fileURLWithPath: folderPath)

    // Ensure the folder exists
    guard FileManager.default.fileExists(atPath: folderPath) else {
      throw ProjectError.operationFailed("Folder not found: \(folderPath)")
    }

    let folderName = folderURL.lastPathComponent
    print("📁 Adding folder: \(folderName)")

    // Create group for the folder
    let fullGroupPath = groupPath.isEmpty ? folderName : "\(groupPath)/\(folderName)"
    guard let folderGroup = ensureGroupHierarchy(fullGroupPath) else {
      throw ProjectError.operationFailed("Could not create group hierarchy: \(fullGroupPath)")
    }

    // Add files from folder
    try addFilesFromFolder(
      folderURL, to: folderGroup, groupPath: fullGroupPath, targets: targets, recursive: recursive)

    print("✅ Added folder \(folderName) with all contents")
  }

  private func addFilesFromFolder(
    _ folderURL: URL, to group: PBXGroup, groupPath: String, targets: [String], recursive: Bool
  ) throws {
    let fileManager = FileManager.default

    guard
      let enumerator = fileManager.enumerator(
        at: folderURL,
        includingPropertiesForKeys: [.isDirectoryKey, .nameKey],
        options: recursive ? [] : [.skipsSubdirectoryDescendants])
    else {
      throw ProjectError.operationFailed("Could not enumerate folder contents")
    }

    for case let fileURL as URL in enumerator {
      let relativePath = String(fileURL.path.dropFirst(folderURL.path.count + 1))

      // Skip if file should be excluded
      if !shouldIncludeFile(fileURL.lastPathComponent) {
        continue
      }

      var isDirectory: ObjCBool = false
      fileManager.fileExists(atPath: fileURL.path, isDirectory: &isDirectory)

      if isDirectory.boolValue {
        // Create subgroup for subdirectory
        if recursive {
          let subgroupName = fileURL.lastPathComponent
          let subgroupPath = "\(groupPath)/\(subgroupName)"

          if let subgroup = ensureGroupHierarchy(subgroupPath) {
            try addFilesFromFolder(
              fileURL, to: subgroup, groupPath: subgroupPath, targets: targets, recursive: recursive
            )
          }
        }
      } else {
        // Add file to current group
        let fileName = fileURL.lastPathComponent

        // Check if file already exists
        if fileExists(path: fileName, in: pbxproj) {
          print("⚠️  File \(fileName) already exists, skipping")
          continue
        }

        // Create file reference with relative path
        let fileRef = PBXFileReference(
          sourceTree: .group,
          lastKnownFileType: fileType(for: fileName),
          path: fileName
        )

        // Add to project and group
        pbxproj.add(object: fileRef)
        group.children.append(fileRef)

        // Add to targets if compilable
        if isCompilableFile(fileName) {
          for targetName in targets {
            guard let target = pbxproj.nativeTargets.first(where: { $0.name == targetName }),
              let sourcesBuildPhase = sourceBuildPhase(for: target)
            else {
              continue
            }

            let buildFile = PBXBuildFile(file: fileRef)
            pbxproj.add(object: buildFile)
            sourcesBuildPhase.files?.append(buildFile)
          }
        }

        print("  📄 Added: \(relativePath)")
      }
    }
  }

  // MARK: - File Management (Move/Remove)
  func moveFile(from oldPath: String, to newPath: String) throws {
    guard
      let fileRef = pbxproj.fileReferences.first(where: { $0.path == oldPath || $0.name == oldPath }
      )
    else {
      throw ProjectError.operationFailed("File not found: \(oldPath)")
    }

    let newName = (newPath as NSString).lastPathComponent
    fileRef.path = newName
    if fileRef.name == nil || fileRef.name == oldPath {
      fileRef.name = newName
    }

    print("✅ Moved \(oldPath) -> \(newPath)")
  }

  func removeFile(_ filePath: String) throws {
    // Try to find the file reference by exact match or by filename
    let fileName = (filePath as NSString).lastPathComponent

    guard
      let fileRef = pbxproj.fileReferences.first(where: {
        // Check exact path match
        $0.path == filePath
          // Check name match
          || $0.name == filePath
          // Check filename match (just the last component)
          || $0.path == fileName || $0.name == fileName
          // Check if the path ends with the provided path (for partial paths like "Sources/File.swift")
          || ($0.path?.hasSuffix(filePath) ?? false)
      })
    else {
      throw ProjectError.operationFailed("File not found: \(filePath)")
    }

    // Remove from all groups
    for group in pbxproj.groups {
      group.children.removeAll { $0 === fileRef }
    }

    // Remove from all build phases
    for target in pbxproj.nativeTargets {
      for buildPhase in target.buildPhases {
        if let sourcesBuildPhase = buildPhase as? PBXSourcesBuildPhase {
          sourcesBuildPhase.files?.removeAll { $0.file === fileRef }
        }
        if let resourcesBuildPhase = buildPhase as? PBXResourcesBuildPhase {
          resourcesBuildPhase.files?.removeAll { $0.file === fileRef }
        }
        if let frameworksBuildPhase = buildPhase as? PBXFrameworksBuildPhase {
          frameworksBuildPhase.files?.removeAll { $0.file === fileRef }
        }
        if let copyFilesBuildPhase = buildPhase as? PBXCopyFilesBuildPhase {
          copyFilesBuildPhase.files?.removeAll { $0.file === fileRef }
        }
      }
    }

    // Remove build files that reference this file
    let buildFilesToRemove = pbxproj.buildFiles.filter { $0.file === fileRef }
    for buildFile in buildFilesToRemove {
      pbxproj.delete(object: buildFile)
    }

    // Remove from project
    pbxproj.delete(object: fileRef)

    print("✅ Removed \(fileRef.path ?? fileRef.name ?? filePath)")
  }

  func removeGroup(_ groupPath: String) throws {
    // Find the group to remove
    guard let group = findGroup(named: groupPath, in: pbxproj.groups) else {
      throw ProjectError.groupNotFound(groupPath)
    }

    // Recursively collect all file references in this group and subgroups
    var filesToRemove: [PBXFileReference] = []
    var groupsToRemove: [PBXGroup] = [group]

    func collectFilesAndGroups(from group: PBXGroup) {
      for child in group.children {
        if let fileRef = child as? PBXFileReference {
          filesToRemove.append(fileRef)
        } else if let subgroup = child as? PBXGroup {
          groupsToRemove.append(subgroup)
          collectFilesAndGroups(from: subgroup)
        }
      }
    }

    collectFilesAndGroups(from: group)

    // Remove all files from build phases
    for fileRef in filesToRemove {
      // Remove from all build phases
      for target in pbxproj.nativeTargets {
        for buildPhase in target.buildPhases {
          if let sourcesBuildPhase = buildPhase as? PBXSourcesBuildPhase {
            sourcesBuildPhase.files?.removeAll { $0.file === fileRef }
          }
          if let resourcesBuildPhase = buildPhase as? PBXResourcesBuildPhase {
            resourcesBuildPhase.files?.removeAll { $0.file === fileRef }
          }
          if let frameworksBuildPhase = buildPhase as? PBXFrameworksBuildPhase {
            frameworksBuildPhase.files?.removeAll { $0.file === fileRef }
          }
          if let copyFilesBuildPhase = buildPhase as? PBXCopyFilesBuildPhase {
            copyFilesBuildPhase.files?.removeAll { $0.file === fileRef }
          }
        }
      }

      // Remove build files that reference this file
      let buildFilesToRemove = pbxproj.buildFiles.filter { $0.file === fileRef }
      for buildFile in buildFilesToRemove {
        pbxproj.delete(object: buildFile)
      }

      // Remove file reference from project
      pbxproj.delete(object: fileRef)
    }

    // Remove the group from its parent
    for parentGroup in pbxproj.groups {
      parentGroup.children.removeAll { $0 === group }
    }

    // Remove all groups from project
    for groupToRemove in groupsToRemove {
      pbxproj.delete(object: groupToRemove)
    }

    print("✅ Removed group '\(groupPath)' and \(filesToRemove.count) file(s)")
  }

  func removeFolder(_ folderPath: String) throws {
    // This function removes a folder reference (filesystem-synced folder)
    // First try to find it as a file reference with folder type
    if let folderRef = pbxproj.fileReferences.first(where: {
      ($0.path == folderPath || $0.name == folderPath)
        && ($0.lastKnownFileType == "folder" || $0.lastKnownFileType == "folder.assetcatalog")
    }) {
      // Remove from all groups
      for group in pbxproj.groups {
        group.children.removeAll { $0 === folderRef }
      }

      // Remove from resource build phases (folders are typically in resources)
      for target in pbxproj.nativeTargets {
        for buildPhase in target.buildPhases {
          if let resourcesBuildPhase = buildPhase as? PBXResourcesBuildPhase {
            resourcesBuildPhase.files?.removeAll { $0.file === folderRef }
          }
          if let copyFilesBuildPhase = buildPhase as? PBXCopyFilesBuildPhase {
            copyFilesBuildPhase.files?.removeAll { $0.file === folderRef }
          }
        }
      }

      // Remove build files
      let buildFilesToRemove = pbxproj.buildFiles.filter { $0.file === folderRef }
      for buildFile in buildFilesToRemove {
        pbxproj.delete(object: buildFile)
      }

      // Remove from project
      pbxproj.delete(object: folderRef)

      print("✅ Removed folder reference '\(folderPath)'")
    } else {
      // If not found as folder reference, try as group
      try removeGroup(folderPath)
    }
  }

  // Add synchronized folder reference (Xcode 16+ filesystem synchronized group)
  func addSynchronizedFolder(folderPath: String, to groupPath: String, targets: [String]) throws {
    let folderURL = URL(fileURLWithPath: folderPath)
    let folderName = folderURL.lastPathComponent

    // Ensure the folder exists
    guard FileManager.default.fileExists(atPath: folderPath) else {
      throw ProjectError.operationFailed("Folder not found: \(folderPath)")
    }

    // Find parent group
    guard let parentGroup = findGroup(named: groupPath, in: pbxproj.groups) else {
      throw ProjectError.groupNotFound(groupPath)
    }

    // Create a filesystem synchronized root group (Xcode 16+)
    let syncGroup = PBXFileSystemSynchronizedRootGroup(
      sourceTree: .group,
      path: folderName,
      name: folderName
    )

    // Add to project and parent group
    pbxproj.add(object: syncGroup)
    parentGroup.children.append(syncGroup)

    // For each target, we need to add the sync group to the sources build phase
    for targetName in targets {
      guard let target = pbxproj.nativeTargets.first(where: { $0.name == targetName }) else {
        print("⚠️  Target '\(targetName)' not found")
        continue
      }

      // Find or create sources build phase
      let sourcesBuildPhase =
        target.buildPhases.first(where: { $0 is PBXSourcesBuildPhase }) as? PBXSourcesBuildPhase
        ?? {
          let phase = PBXSourcesBuildPhase()
          pbxproj.add(object: phase)
          target.buildPhases.append(phase)
          return phase
        }()

      // Add the synchronized group as a build file
      let buildFile = PBXBuildFile(file: syncGroup)
      pbxproj.add(object: buildFile)
      sourcesBuildPhase.files?.append(buildFile)

      print("📁 Added synchronized folder to target: \(targetName)")
    }

    print("✅ Added filesystem synchronized folder: \(folderName) (auto-syncs with filesystem)")
  }

  // MARK: - Target Management
  func addTarget(name: String, productType: String, bundleId: String, platform: String = "iOS")
    throws
  {
    // Check if target already exists
    if pbxproj.nativeTargets.contains(where: { $0.name == name }) {
      throw ProjectError.operationFailed("Target \(name) already exists")
    }

    // Create build configurations
    let debugConfig = XCBuildConfiguration(name: "Debug")
    debugConfig.buildSettings = [
      "BUNDLE_IDENTIFIER": .string(bundleId),
      "PRODUCT_NAME": .string("$(TARGET_NAME)"),
      "SWIFT_VERSION": .string("5.0"),
    ]

    let releaseConfig = XCBuildConfiguration(name: "Release")
    releaseConfig.buildSettings = [
      "BUNDLE_IDENTIFIER": .string(bundleId),
      "PRODUCT_NAME": .string("$(TARGET_NAME)"),
      "SWIFT_VERSION": .string("5.0"),
    ]

    pbxproj.add(object: debugConfig)
    pbxproj.add(object: releaseConfig)

    let configList = XCConfigurationList(buildConfigurations: [debugConfig, releaseConfig])
    pbxproj.add(object: configList)

    // Create target
    let target = PBXNativeTarget(
      name: name,
      buildConfigurationList: configList,
      buildPhases: [],
      buildRules: [],
      dependencies: [],
      productInstallPath: nil,
      productName: name,
      productType: PBXProductType(rawValue: productType)
    )

    // Add build phases
    let sourcesBuildPhase = PBXSourcesBuildPhase()
    let resourcesBuildPhase = PBXResourcesBuildPhase()
    let frameworksBuildPhase = PBXFrameworksBuildPhase()

    pbxproj.add(object: sourcesBuildPhase)
    pbxproj.add(object: resourcesBuildPhase)
    pbxproj.add(object: frameworksBuildPhase)

    target.buildPhases = [sourcesBuildPhase, frameworksBuildPhase, resourcesBuildPhase]

    pbxproj.add(object: target)
    pbxproj.rootObject?.targets.append(target)

    print("✅ Added target: \(name) (\(productType))")
  }

  func duplicateTarget(source: String, newName: String, newBundleId: String? = nil) throws {
    guard let sourceTarget = pbxproj.nativeTargets.first(where: { $0.name == source }) else {
      throw ProjectError.targetNotFound(source)
    }

    // Check if new target already exists
    if pbxproj.nativeTargets.contains(where: { $0.name == newName }) {
      throw ProjectError.operationFailed("Target \(newName) already exists")
    }

    // Clone build configuration list
    guard let sourceConfigList = sourceTarget.buildConfigurationList else {
      throw ProjectError.operationFailed("Source target has no build configurations")
    }

    var newConfigs: [XCBuildConfiguration] = []
    for sourceConfig in sourceConfigList.buildConfigurations {
      let newConfig = XCBuildConfiguration(name: sourceConfig.name)
      newConfig.buildSettings = sourceConfig.buildSettings

      // Update bundle identifier if provided
      if let bundleId = newBundleId {
        newConfig.buildSettings["BUNDLE_IDENTIFIER"] = .string(bundleId)
      }

      pbxproj.add(object: newConfig)
      newConfigs.append(newConfig)
    }

    let newConfigList = XCConfigurationList(buildConfigurations: newConfigs)
    pbxproj.add(object: newConfigList)

    // Create new target
    let newTarget = PBXNativeTarget(
      name: newName,
      buildConfigurationList: newConfigList,
      buildPhases: [],
      buildRules: sourceTarget.buildRules,
      dependencies: [],
      productInstallPath: sourceTarget.productInstallPath,
      productName: newName,
      productType: sourceTarget.productType
    )

    // Clone build phases
    for phase in sourceTarget.buildPhases {
      if let sourcePhase = phase as? PBXSourcesBuildPhase {
        let newPhase = PBXSourcesBuildPhase()
        newPhase.files = sourcePhase.files
        pbxproj.add(object: newPhase)
        newTarget.buildPhases.append(newPhase)
      } else if let resourcePhase = phase as? PBXResourcesBuildPhase {
        let newPhase = PBXResourcesBuildPhase()
        newPhase.files = resourcePhase.files
        pbxproj.add(object: newPhase)
        newTarget.buildPhases.append(newPhase)
      } else if let frameworkPhase = phase as? PBXFrameworksBuildPhase {
        let newPhase = PBXFrameworksBuildPhase()
        newPhase.files = frameworkPhase.files
        pbxproj.add(object: newPhase)
        newTarget.buildPhases.append(newPhase)
      }
    }

    pbxproj.add(object: newTarget)
    pbxproj.rootObject?.targets.append(newTarget)

    print("✅ Duplicated target: \(source) -> \(newName)")
  }

  func removeTarget(name: String) throws {
    guard let target = pbxproj.nativeTargets.first(where: { $0.name == name }) else {
      throw ProjectError.targetNotFound(name)
    }

    // Remove from project targets
    pbxproj.rootObject?.targets.removeAll { $0 === target }

    // Remove dependencies from other targets
    for otherTarget in pbxproj.nativeTargets {
      otherTarget.dependencies.removeAll { dependency in
        dependency.target === target
      }
    }

    // Remove from project
    pbxproj.delete(object: target)

    print("✅ Removed target: \(name)")
  }

  // MARK: - Dependencies & Frameworks
  func addDependency(to targetName: String, dependsOn dependencyName: String) throws {
    guard let target = pbxproj.nativeTargets.first(where: { $0.name == targetName }) else {
      throw ProjectError.targetNotFound(targetName)
    }

    guard let dependency = pbxproj.nativeTargets.first(where: { $0.name == dependencyName }) else {
      throw ProjectError.targetNotFound(dependencyName)
    }

    // Check if dependency already exists
    if target.dependencies.contains(where: { $0.target === dependency }) {
      print("⚠️  Dependency already exists")
      return
    }

    let targetDependency = PBXTargetDependency(target: dependency)
    pbxproj.add(object: targetDependency)
    target.dependencies.append(targetDependency)

    print("✅ Added dependency: \(targetName) -> \(dependencyName)")
  }

  func addFramework(name: String, to targetName: String, embed: Bool = false) throws {
    guard let target = pbxproj.nativeTargets.first(where: { $0.name == targetName }) else {
      throw ProjectError.targetNotFound(targetName)
    }

    // Find or create frameworks build phase
    var frameworksPhase =
      target.buildPhases.first { $0 is PBXFrameworksBuildPhase } as? PBXFrameworksBuildPhase
    if frameworksPhase == nil {
      frameworksPhase = PBXFrameworksBuildPhase()
      pbxproj.add(object: frameworksPhase!)
      target.buildPhases.append(frameworksPhase!)
    }

    // Create framework reference
    let frameworkRef = PBXFileReference(
      sourceTree: .sdkRoot,
      name: "\(name).framework",
      lastKnownFileType: "wrapper.framework",
      path: "System/Library/Frameworks/\(name).framework"
    )

    pbxproj.add(object: frameworkRef)

    // Add to build phase
    let buildFile = PBXBuildFile(file: frameworkRef)
    pbxproj.add(object: buildFile)
    frameworksPhase?.files?.append(buildFile)

    // Handle embedding if needed
    if embed {
      // Create embed frameworks phase if needed
      var embedPhase =
        target.buildPhases.first {
          $0 is PBXCopyFilesBuildPhase
            && ($0 as? PBXCopyFilesBuildPhase)?.dstSubfolderSpec == .frameworks
        } as? PBXCopyFilesBuildPhase

      if embedPhase == nil {
        embedPhase = PBXCopyFilesBuildPhase(dstSubfolderSpec: .frameworks, name: "Embed Frameworks")
        pbxproj.add(object: embedPhase!)
        target.buildPhases.append(embedPhase!)
      }

      let embedFile = PBXBuildFile(file: frameworkRef, settings: ["ATTRIBUTES": ["CodeSignOnCopy"]])
      pbxproj.add(object: embedFile)
      embedPhase?.files?.append(embedFile)
    }

    print("✅ Added framework: \(name) to \(targetName)\(embed ? " (embedded)" : "")")
  }

  // MARK: - Swift Packages
  func addSwiftPackage(url: String, requirement: String, to targetName: String? = nil) throws {
    // Validate URL format
    guard url.hasPrefix("https://") || url.hasPrefix("git@") else {
      throw ProjectError.invalidArguments("Package URL must be a valid git repository URL")
    }

    // Parse requirement (e.g., "1.0.0", "from: 1.0.0", "branch: main")
    let versionRequirement: XCRemoteSwiftPackageReference.VersionRequirement

    if requirement.hasPrefix("from:") {
      let version = requirement.replacingOccurrences(of: "from:", with: "").trimmingCharacters(
        in: .whitespaces)
      // Basic semver validation
      if !version.matches("^\\d+\\.\\d+(\\.\\d+)?$") {
        throw ProjectError.invalidArguments("Invalid version format. Expected: X.Y.Z or X.Y")
      }
      versionRequirement = .upToNextMajorVersion(version)
    } else if requirement.hasPrefix("branch:") {
      let branch = requirement.replacingOccurrences(of: "branch:", with: "").trimmingCharacters(
        in: .whitespaces)
      guard !branch.isEmpty else {
        throw ProjectError.invalidArguments("Branch name cannot be empty")
      }
      versionRequirement = .branch(branch)
    } else if requirement.hasPrefix("exact:") {
      let version = requirement.replacingOccurrences(of: "exact:", with: "").trimmingCharacters(
        in: .whitespaces)
      if !version.matches("^\\d+\\.\\d+(\\.\\d+)?$") {
        throw ProjectError.invalidArguments("Invalid version format. Expected: X.Y.Z or X.Y")
      }
      versionRequirement = .exact(version)
    } else {
      // Assume exact version
      if !requirement.matches("^\\d+\\.\\d+(\\.\\d+)?$") {
        throw ProjectError.invalidArguments("Invalid version format. Expected: X.Y.Z or X.Y")
      }
      versionRequirement = .exact(requirement)
    }

    // Create package reference
    let packageRef = XCRemoteSwiftPackageReference(
      repositoryURL: url,
      versionRequirement: versionRequirement
    )

    pbxproj.add(object: packageRef)

    // Add to remotePackages through public API
    pbxproj.rootObject?.remotePackages.append(packageRef)

    print("✅ Added Swift Package: \(url) (\(requirement))")

    // Add to target if specified
    if let targetName = targetName {
      guard let target = pbxproj.nativeTargets.first(where: { $0.name == targetName }) else {
        throw ProjectError.targetNotFound(targetName)
      }

      // Note: Adding package products to targets requires more complex logic
      // to handle package product dependencies
      print("ℹ️  To link package products, use Xcode or specify product name")
    }
  }

  func removeSwiftPackage(url: String) throws {
    guard
      let packageRef = pbxproj.rootObject?.remotePackages.first(where: { $0.repositoryURL == url })
    else {
      throw ProjectError.operationFailed("Package not found: \(url)")
    }

    // Remove from project
    pbxproj.rootObject?.remotePackages.removeAll { $0 === packageRef }
    pbxproj.delete(object: packageRef)

    print("✅ Removed Swift Package: \(url)")
  }

  func listSwiftPackages() {
    print("📦 Swift Packages:")

    let packages = pbxproj.rootObject?.remotePackages ?? []

    if packages.isEmpty {
      print("  No packages found")
      return
    }

    for package in packages {
      print("  - \(package.repositoryURL ?? "Unknown")")
      if let requirement = package.versionRequirement {
        print("    Requirement: \(requirement)")
      }
    }
  }

  // MARK: - Build Phases
  func addBuildPhase(type: String, name: String, to targetName: String, script: String? = nil)
    throws
  {
    guard let target = pbxproj.nativeTargets.first(where: { $0.name == targetName }) else {
      throw ProjectError.targetNotFound(targetName)
    }

    switch type.lowercased() {
    case "run_script", "script":
      guard let script = script else {
        throw ProjectError.operationFailed("Script required for run_script phase")
      }

      let scriptPhase = PBXShellScriptBuildPhase(
        name: name,
        shellScript: escapeShellCommand(script)
      )

      pbxproj.add(object: scriptPhase)
      target.buildPhases.append(scriptPhase)

      print("✅ Added run script phase: \(name)")

    case "copy_files", "copy":
      let copyPhase = PBXCopyFilesBuildPhase(
        dstSubfolderSpec: .resources,
        name: name
      )

      pbxproj.add(object: copyPhase)
      target.buildPhases.append(copyPhase)

      print("✅ Added copy files phase: \(name)")

    default:
      throw ProjectError.operationFailed("Unknown build phase type: \(type)")
    }
  }

  func addFiles(_ files: [(path: String, group: String)], to targets: [String]) throws {
    for (path, group) in files {
      try addFile(path: path, to: group, targets: targets)
    }
  }

  // MARK: - Path Updates
  func updateFilePaths(_ mappings: [String: String]) {
    var count = 0

    for fileRef in pbxproj.fileReferences {
      guard let oldPath = fileRef.path,
        let newPath = mappings[oldPath],
        let sanitized = sanitizePath(newPath)
      else { continue }

      fileRef.path = sanitized
      count += 1
      print("📝 Updated \(oldPath) -> \(sanitized)")
    }

    print("✅ Updated \(count) file paths")
  }

  func updatePathsWithPrefix(from oldPrefix: String, to newPrefix: String) {
    var mappings: [String: String] = [:]

    for fileRef in pbxproj.fileReferences {
      guard let path = fileRef.path,
        path.hasPrefix(oldPrefix)
      else { continue }

      mappings[path] = path.replacingOccurrences(of: oldPrefix, with: newPrefix)
    }

    updateFilePaths(mappings)
  }

  // MARK: - Group Management
  func ensureGroupHierarchy(_ path: String) -> PBXGroup? {
    let components = path.split(separator: "/").map(String.init)
    guard let mainGroup = pbxproj.rootObject?.mainGroup else {
      print("⚠️  No main group found in project")
      return nil
    }

    var currentGroup = mainGroup

    for component in components {
      // Look for existing child group
      if let existingGroup = currentGroup.children.compactMap({ $0 as? PBXGroup })
        .first(where: { $0.name == component || $0.path == component })
      {
        currentGroup = existingGroup
      } else {
        // Create new group
        let newGroup = PBXGroup(
          children: [],
          sourceTree: .group,
          name: component,
          path: component
        )

        pbxproj.add(object: newGroup)
        currentGroup.children.append(newGroup)
        currentGroup = newGroup

        print("📁 Created group: \(component)")
      }
    }

    return currentGroup
  }

  // Create multiple groups at once
  func createGroups(_ groupPaths: [String]) {
    for groupPath in groupPaths {
      _ = ensureGroupHierarchy(groupPath)
    }
  }

  // Enhanced group finding that supports nested paths
  func findGroupAtPath(_ path: String) -> PBXGroup? {
    guard let mainGroup = pbxproj.rootObject?.mainGroup else { return nil }

    if path.isEmpty {
      return mainGroup
    }

    return findGroupByPath(path, in: pbxproj.groups, rootGroup: mainGroup)
  }

  // MARK: - Build Settings & Configuration
  func updateBuildSettings(targets: [String], update: (inout BuildSettings) -> Void) {
    for targetName in targets {
      guard let target = pbxproj.nativeTargets.first(where: { $0.name == targetName }),
        let configList = target.buildConfigurationList
      else {
        print("⚠️  Target '\(targetName)' not found")
        continue
      }

      for config in configList.buildConfigurations {
        update(&config.buildSettings)
        print("⚙️  Updated build settings for \(targetName) - \(config.name)")
      }
    }
  }

  func setBuildSetting(key: String, value: String, targets: [String], configuration: String? = nil)
  {
    for targetName in targets {
      guard let target = pbxproj.nativeTargets.first(where: { $0.name == targetName }),
        let configList = target.buildConfigurationList
      else {
        print("⚠️  Target '\(targetName)' not found")
        continue
      }

      for config in configList.buildConfigurations {
        if let filterConfig = configuration, config.name != filterConfig {
          continue
        }
        config.buildSettings[key] = .string(value)
        print("⚙️  Set \(key) = \(value) for \(targetName) - \(config.name)")
      }
    }
  }

  func getBuildSettings(for targetName: String, configuration: String? = nil) -> [String: [String:
    Any]]
  {
    guard let target = pbxproj.nativeTargets.first(where: { $0.name == targetName }),
      let configList = target.buildConfigurationList
    else {
      print("⚠️  Target '\(targetName)' not found")
      return [:]
    }

    var result: [String: [String: Any]] = [:]

    for config in configList.buildConfigurations {
      if let filterConfig = configuration, config.name != filterConfig {
        continue
      }
      result[config.name] = config.buildSettings
    }

    return result
  }

  func listBuildConfigurations(for targetName: String? = nil) {
    if let targetName = targetName {
      guard let target = pbxproj.nativeTargets.first(where: { $0.name == targetName }) else {
        print("⚠️  Target '\(targetName)' not found")
        return
      }

      print("🔧 Build configurations for \(targetName):")
      if let configList = target.buildConfigurationList {
        for config in configList.buildConfigurations {
          print("  - \(config.name)")
        }
      }
    } else {
      // List all project configurations
      print("🔧 Project build configurations:")
      if let configList = pbxproj.rootObject?.buildConfigurationList {
        for config in configList.buildConfigurations {
          print("  - \(config.name)")
        }
      }
    }
  }

  // MARK: - Validation
  func validate() -> [String] {
    var issues: [String] = []

    // Check for orphaned file references
    for fileRef in pbxproj.fileReferences {
      var found = false
      for group in pbxproj.groups {
        if group.children.contains(where: { $0 === fileRef }) {
          found = true
          break
        }
      }
      if !found {
        issues.append("Orphaned file reference: \(fileRef.path ?? fileRef.name ?? "unknown")")
      }
    }

    // Check for missing build files
    for target in pbxproj.nativeTargets {
      guard let sourcePhase = sourceBuildPhase(for: target) else { continue }
      for buildFileRef in sourcePhase.files ?? [] {
        if buildFileRef.file == nil {
          issues.append("Missing file reference in target: \(target.name)")
        }
      }
    }

    return issues
  }

  func listInvalidReferences() {
    print("🔍 Checking for invalid file references...")

    var invalidRefs: [(group: String, path: String, issue: String)] = []
    let fileManager = FileManager.default
    let projectDir = projectPath.parent()

    // Helper to resolve absolute path for a file reference
    func resolveAbsolutePath(for fileRef: PBXFileReference, in group: PBXGroup?) -> Path? {
      // Get the path from the file reference
      guard let filePath = fileRef.path ?? fileRef.name else { return nil }

      // Start with project directory
      var basePath = projectDir

      // If file has a source tree, handle it
      if let sourceTree = fileRef.sourceTree {
        switch sourceTree {
        case .absolute:
          return Path(filePath)
        case .group:
          // Need to calculate path from group hierarchy
          if let group = group {
            var groupPath = Path("")
            var currentGroup: PBXGroup? = group
            var pathComponents: [String] = []

            // Build path from group hierarchy
            while let g = currentGroup {
              if let path = g.path, !path.isEmpty {
                pathComponents.insert(path, at: 0)
              }
              // Find parent group
              currentGroup = pbxproj.groups.first { parent in
                parent.children.contains { $0 === g }
              }
            }

            for component in pathComponents {
              groupPath = groupPath + Path(component)
            }
            basePath = basePath + groupPath
          }
        case .sourceRoot:
          // Relative to project root
          basePath = projectDir
        default:
          break
        }
      }

      return basePath + Path(filePath)
    }

    // Check each file reference
    func checkFilesInGroup(_ group: PBXGroup, groupPath: String) {
      for child in group.children {
        if let fileRef = child as? PBXFileReference {
          if let absolutePath = resolveAbsolutePath(for: fileRef, in: group) {
            let pathString = absolutePath.string

            // Check if file exists
            if !fileManager.fileExists(atPath: pathString) {
              let displayPath = fileRef.path ?? fileRef.name ?? "unknown"
              invalidRefs.append(
                (
                  group: groupPath,
                  path: displayPath,
                  issue: "File not found at: \(pathString)"
                ))
            } else {
              // Check if it's a directory when it shouldn't be or vice versa
              var isDirectory: ObjCBool = false
              fileManager.fileExists(atPath: pathString, isDirectory: &isDirectory)

              let isFolder =
                fileRef.lastKnownFileType == "folder"
                || fileRef.lastKnownFileType == "folder.assetcatalog"
                || fileRef.lastKnownFileType == "wrapper.framework"

              if isFolder && !isDirectory.boolValue {
                invalidRefs.append(
                  (
                    group: groupPath,
                    path: fileRef.path ?? fileRef.name ?? "unknown",
                    issue: "Expected directory but found file at: \(pathString)"
                  ))
              } else if !isFolder && isDirectory.boolValue && fileRef.lastKnownFileType != nil {
                invalidRefs.append(
                  (
                    group: groupPath,
                    path: fileRef.path ?? fileRef.name ?? "unknown",
                    issue: "Expected file but found directory at: \(pathString)"
                  ))
              }
            }
          }
        } else if let subgroup = child as? PBXGroup {
          let subgroupName = subgroup.name ?? subgroup.path ?? "unnamed"
          let newPath = groupPath.isEmpty ? subgroupName : "\(groupPath)/\(subgroupName)"
          checkFilesInGroup(subgroup, groupPath: newPath)
        }
      }
    }

    // Start checking from root group
    if let rootGroup = pbxproj.rootObject?.mainGroup {
      checkFilesInGroup(rootGroup, groupPath: "")
    }

    // Report results
    if invalidRefs.isEmpty {
      print("✅ All file references are valid")
    } else {
      print("❌ Found \(invalidRefs.count) invalid file reference(s):\n")
      for ref in invalidRefs {
        print("  Group: \(ref.group.isEmpty ? "Root" : ref.group)")
        print("  File:  \(ref.path)")
        print("  Issue: \(ref.issue)")
        print("")
      }
    }
  }

  func removeInvalidReferences() {
    print("🔍 Checking for invalid file references to remove...")

    var removedCount = 0
    let fileManager = FileManager.default
    let projectDir = projectPath.parent()

    // Helper to resolve absolute path for a file reference
    func resolveAbsolutePath(for fileRef: PBXFileReference, in group: PBXGroup?) -> Path? {
      // Get the path from the file reference
      guard let filePath = fileRef.path ?? fileRef.name else { return nil }

      // Start with project directory
      var basePath = projectDir

      // If file has a source tree, handle it
      if let sourceTree = fileRef.sourceTree {
        switch sourceTree {
        case .absolute:
          return Path(filePath)
        case .group:
          // Need to calculate path from group hierarchy
          if let group = group {
            var groupPath = Path("")
            var currentGroup: PBXGroup? = group
            var pathComponents: [String] = []

            // Build path from group hierarchy
            while let g = currentGroup {
              if let path = g.path, !path.isEmpty {
                pathComponents.insert(path, at: 0)
              }
              // Find parent group
              currentGroup = pbxproj.groups.first { parent in
                parent.children.contains { $0 === g }
              }
            }

            for component in pathComponents {
              groupPath = groupPath + Path(component)
            }
            basePath = basePath + groupPath
          }
        case .sourceRoot:
          // Relative to project root
          basePath = projectDir
        default:
          break
        }
      }

      return basePath + Path(filePath)
    }

    // Collect invalid references to remove
    var refsToRemove: [PBXFileReference] = []

    func findInvalidFilesInGroup(_ group: PBXGroup) {
      for child in group.children {
        if let fileRef = child as? PBXFileReference {
          if let absolutePath = resolveAbsolutePath(for: fileRef, in: group) {
            let pathString = absolutePath.string

            // Check if file exists
            if !fileManager.fileExists(atPath: pathString) {
              refsToRemove.append(fileRef)
              let displayPath = fileRef.path ?? fileRef.name ?? "unknown"
              print("  ❌ Will remove: \(displayPath)")
            } else {
              // Check if it's a directory when it shouldn't be or vice versa
              var isDirectory: ObjCBool = false
              fileManager.fileExists(atPath: pathString, isDirectory: &isDirectory)

              let isFolder =
                fileRef.lastKnownFileType == "folder"
                || fileRef.lastKnownFileType == "folder.assetcatalog"
                || fileRef.lastKnownFileType == "wrapper.framework"

              if (isFolder && !isDirectory.boolValue)
                || (!isFolder && isDirectory.boolValue && fileRef.lastKnownFileType != nil)
              {
                refsToRemove.append(fileRef)
                let displayPath = fileRef.path ?? fileRef.name ?? "unknown"
                print("  ❌ Will remove: \(displayPath) (type mismatch)")
              }
            }
          }
        } else if let subgroup = child as? PBXGroup {
          findInvalidFilesInGroup(subgroup)
        }
      }
    }

    // Start checking from root group
    if let rootGroup = pbxproj.rootObject?.mainGroup {
      findInvalidFilesInGroup(rootGroup)
    }

    // Remove invalid references
    for fileRef in refsToRemove {
      // Remove from all groups
      for group in pbxproj.groups {
        group.children.removeAll { $0 === fileRef }
      }

      // Remove from all build phases
      for target in pbxproj.nativeTargets {
        for buildPhase in target.buildPhases {
          if let sourcesBuildPhase = buildPhase as? PBXSourcesBuildPhase {
            sourcesBuildPhase.files?.removeAll { $0.file === fileRef }
          }
          if let resourcesBuildPhase = buildPhase as? PBXResourcesBuildPhase {
            resourcesBuildPhase.files?.removeAll { $0.file === fileRef }
          }
          if let frameworksBuildPhase = buildPhase as? PBXFrameworksBuildPhase {
            frameworksBuildPhase.files?.removeAll { $0.file === fileRef }
          }
          if let copyFilesBuildPhase = buildPhase as? PBXCopyFilesBuildPhase {
            copyFilesBuildPhase.files?.removeAll { $0.file === fileRef }
          }
        }
      }

      // Remove build files that reference this file
      let buildFilesToRemove = pbxproj.buildFiles.filter { $0.file === fileRef }
      for buildFile in buildFilesToRemove {
        pbxproj.delete(object: buildFile)
      }

      // Remove from project
      pbxproj.delete(object: fileRef)
      removedCount += 1
    }

    // Report results
    if removedCount == 0 {
      print("✅ No invalid references to remove")
    } else {
      print("✅ Removed \(removedCount) invalid file reference(s)")
    }
  }

  // MARK: - Save
  func save() throws {
    // Validate before saving
    let issues = validate()
    if !issues.isEmpty {
      print("⚠️  Validation issues found:")
      issues.forEach { print("  - \($0)") }
    }

    // Create backup for atomic write
    let backupPath = Path("\(projectPath.string).tmp")
    let fileManager = FileManager.default

    // Backup existing project
    if fileManager.fileExists(atPath: projectPath.string) {
      try fileManager.copyItem(atPath: projectPath.string, toPath: backupPath.string)
    }

    do {
      // Write to project
      try xcodeproj.write(path: projectPath)

      // Remove backup on success
      if fileManager.fileExists(atPath: backupPath.string) {
        try fileManager.removeItem(atPath: backupPath.string)
      }

      print("💾 Project saved successfully")
    } catch {
      // Restore from backup on failure
      if fileManager.fileExists(atPath: backupPath.string) {
        if fileManager.fileExists(atPath: projectPath.string) {
          try fileManager.removeItem(atPath: projectPath.string)
        }
        try fileManager.moveItem(atPath: backupPath.string, toPath: projectPath.string)
        print("⚠️  Save failed, restored from backup")
      }
      throw error
    }
  }
}

// MARK: - Command Line Interface
struct CLI {
  static let version = "1.0.0"

  static func printUsage() {
    print(
      """
      XcodeProj CLI v\(version)
      A powerful command-line tool for Xcode project manipulation

      Usage: xcodeproj-cli.swift [--project <path>] <command> [options]

      Options:
        --project <path>  Path to .xcodeproj file (default: MyProject.xcodeproj)
        --dry-run         Preview changes without saving
        --version         Display version information
        --help, -h        Show this help message

      FILE & FOLDER OPERATIONS:
        
        Understanding Groups vs Folders:
        • Groups: Virtual organization in Xcode only (yellow folder icon)
        • add-folder: Adds files from a folder individually (you control what's included)
        • add-sync-folder: Creates folder reference that auto-syncs with filesystem (blue folder icon in Xcode 16+)
        
        add-file <file-path> --group <group> --targets <target1,target2>
          Add a single file to specified group and targets
          Short flags: -g for group, -t for targets
          Example: add-file Sources/Model.swift --group Models --targets MyApp,MyAppTests
          Example: add-file Helper.swift -g Utils -t MyApp
          
        add-files <file1:group1> [file2:group2] ... --targets <target1,target2>
          Add multiple files at once to different groups
          Short flag: -t for targets
          Example: add-files User.swift:Models View.swift:Views --targets MyApp
          Example: add-files Helper.swift:Utils Logger.swift:Debug -t MyApp,Tests
          
        add-folder <folder-path> --group <group> --targets <target1,target2> [--recursive]
          Add all files from a folder as individual file references
          Short flags: -g for group, -t for targets, -r for recursive
          Groups are created automatically if they don't exist
          Example: add-folder Sources/Features --group Features --targets MyApp --recursive
          Example: add-folder UI -g Presentation -t MyApp,Tests -r
          
        add-sync-folder <folder-path> --group <group> --targets <target1,target2>
          Add filesystem synchronized folder (Xcode 16+, auto-syncs with filesystem)
          Creates PBXFileSystemSynchronizedRootGroup for automatic content syncing
          Short flags: -g for group, -t for targets
          Example: add-sync-folder Resources --group Assets --targets MyApp
          Example: add-sync-folder Images -g Resources -t MyApp
          
        move-file <old-path> <new-path>
          Move or rename a file within the project
          Example: move-file OldName.swift NewName.swift
          
        remove-file <file-path>
          Remove a file from the project (supports partial paths)
          Example: remove-file ViewController.swift
          Example: remove-file Sources/Old/Legacy.swift
          
        remove-group <group-name>
          Remove a group and all its contents from the project
          Example: remove-group Features/OldFeature
          
        remove-folder <folder-name>
          Remove a folder reference or group from the project
          Example: remove-folder Resources
          
      TARGET OPERATIONS:
        add-target <name> --type <product-type> --bundle-id <id> [--platform iOS|macOS|tvOS|watchOS]
          Create a new target (app, framework, etc.)
          Product types: com.apple.product-type.application, .framework, .bundle, .unit-test-bundle
          Example: add-target MyFramework --type com.apple.product-type.framework --bundle-id com.example.framework
          
        duplicate-target <source-target> <new-name> --bundle-id <id>
          Create a copy of an existing target with a new name
          Example: duplicate-target MyApp MyAppPro --bundle-id com.example.pro
          
        remove-target <target-name>
          Remove a target and its dependencies from the project
          Example: remove-target OldTarget
          
        add-dependency <target> --depends-on <target>
          Link targets - make one target depend on another
          Example: add-dependency MyApp --depends-on MyFramework
          
      DEPENDENCIES & PACKAGES:
        add-framework <framework-name> --target <target> [--embed]
          Add framework to target (use --embed for custom/dynamic frameworks)
          Example: add-framework CoreData --target MyApp
          Example: add-framework Custom.framework --target MyApp --embed
          
        add-swift-package <url> --requirement <req> [--target <target>]
          Add Swift Package Manager dependency
          Requirements: "1.0.0" (exact), "from: 1.0.0" (minimum), "branch: main"
          Example: add-swift-package https://github.com/Alamofire/Alamofire --requirement "from: 5.0.0" --target MyApp
          
        remove-swift-package <url>
          Remove a Swift Package dependency
          Example: remove-swift-package https://github.com/Alamofire/Alamofire
          
        list-swift-packages
          Show all Swift Package dependencies in the project
          
      BUILD CONFIGURATION:
        add-build-phase <type> --name <name> --target <target> [--script <script>]
          Add custom build phase to target
          Types: run_script, copy_files
          Example: add-build-phase run_script --name "SwiftLint" --target MyApp --script "swiftlint"
          
        set-build-setting <key> <value> --targets <target1,target2>
          Set build configuration value for targets
          Example: set-build-setting SWIFT_VERSION 5.9 --targets MyApp,MyAppTests
          
        get-build-settings <target> [--config <configuration>]
          Display build settings for a target
          Example: get-build-settings MyApp --config Debug
          
        list-build-configs [--target <target-name>]
          List available build configurations (Debug, Release, etc.)
          
      PROJECT STRUCTURE:
        create-groups <group1/subgroup1> <group2/subgroup2> ...
          Create virtual group hierarchy in project navigator (no filesystem folders created)
          Use this to organize files in Xcode without moving them on disk
          Example: create-groups Features/Login Features/Settings Utils/Extensions
          
        update-paths <old-prefix> <new-prefix>
          Batch update file paths with new prefix
          Example: update-paths "Old/Path" "New/Path"
          
        update-paths-map <old1:new1> <old2:new2> ...
          Update specific file paths individually
          Example: update-paths-map OldFile.swift:NewFile.swift Legacy.m:Updated.m
          
      INSPECTION & VALIDATION:
        list-targets
          Show all targets in the project with their types
          
        list-files [group-name]
          Show files in entire project or specific group
          Example: list-files
          Example: list-files Sources/Models
          
        list-groups
          Show the group hierarchy in the project navigator
          
        list-invalid-references
          Find all broken file references (files that don't exist)
          
        remove-invalid-references
          Clean up all broken file references automatically
          
        validate
          Check project integrity and report any issues
          
      COMMON WORKFLOWS:

        # Adding files to your project:
        ./xcodeproj-cli.swift --project MyApp.xcodeproj add-file NewFeature.swift --group Features --targets MyApp
        ./xcodeproj-cli.swift --project MyApp.xcodeproj add-folder Sources/Features --group Features --targets MyApp --recursive
        
        # Cleaning up the project:
        ./xcodeproj-cli.swift --project MyApp.xcodeproj list-invalid-references
        ./xcodeproj-cli.swift --project MyApp.xcodeproj remove-invalid-references
        ./xcodeproj-cli.swift --project MyApp.xcodeproj validate
        
        # Managing dependencies:
        ./xcodeproj-cli.swift --project MyApp.xcodeproj add-swift-package https://github.com/Alamofire/Alamofire --requirement "from: 5.0.0" --target MyApp
        ./xcodeproj-cli.swift --project MyApp.xcodeproj add-framework CoreML --target MyApp
        
        # Working with targets:
        ./xcodeproj-cli.swift --project MyApp.xcodeproj list-targets
        ./xcodeproj-cli.swift --project MyApp.xcodeproj duplicate-target MyApp MyAppPro --bundle-id com.example.pro
        
        # Reorganizing files:
        ./xcodeproj-cli.swift --project MyApp.xcodeproj create-groups Features/Login Features/Profile Utils
        ./xcodeproj-cli.swift --project MyApp.xcodeproj move-file OldName.swift NewName.swift
        ./xcodeproj-cli.swift --project MyApp.xcodeproj remove-group OldFeatures
      """)
  }

  static func run() throws {
    let args = Array(CommandLine.arguments.dropFirst())

    // Handle version flag
    if args.contains("--version") || args.contains("-v") {
      print("XcodeProj CLI v\(version)")
      exit(0)
    }

    // Handle help flag
    if args.contains("--help") || args.contains("-h") || args.isEmpty {
      printUsage()
      exit(0)
    }

    // Extract flags
    var projectPath = "MyProject.xcodeproj"
    var dryRun = false
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

    // Process --dry-run flag
    if let dryRunIndex = filteredArgs.firstIndex(of: "--dry-run") {
      dryRun = true
      filteredArgs.remove(at: dryRunIndex)
      print("🔍 DRY RUN MODE - No changes will be saved")
    }

    guard let command = filteredArgs.first else {
      printUsage()
      exit(0)
    }

    let utility = try XcodeProjUtility(path: projectPath)
    let remainingArgs = Array(filteredArgs.dropFirst())

    // Parse the remaining arguments using the new parser
    let parsedArgs = parseArguments(remainingArgs)

    switch command {
    case "add-file":
      guard let filePath = parsedArgs.positional.first else {
        throw ProjectError.invalidArguments(
          "add-file requires: <file-path> --group <group> --targets <target1,target2>")
      }
      let group = try parsedArgs.requireFlag(
        "--group", "-g", error: "add-file requires --group or -g flag")
      let targetsStr = try parsedArgs.requireFlag(
        "--targets", "-t", error: "add-file requires --targets or -t flag")
      let targets = targetsStr.split(separator: ",").map(String.init)
      try utility.addFile(path: filePath, to: group, targets: targets)

    case "add-folder":
      guard let folderPath = parsedArgs.positional.first else {
        throw ProjectError.invalidArguments(
          "add-folder requires: <folder-path> --group <group> --targets <target1,target2> [--recursive]"
        )
      }
      let group = try parsedArgs.requireFlag(
        "--group", "-g", error: "add-folder requires --group or -g flag")
      let targetsStr = try parsedArgs.requireFlag(
        "--targets", "-t", error: "add-folder requires --targets or -t flag")
      let targets = targetsStr.split(separator: ",").map(String.init)
      let recursive = parsedArgs.hasFlag("--recursive", "-r")
      try utility.addFolder(
        folderPath: folderPath, to: group, targets: targets, recursive: recursive)

    case "add-sync-folder":
      guard let folderPath = parsedArgs.positional.first else {
        throw ProjectError.invalidArguments(
          "add-sync-folder requires: <folder-path> --group <group> --targets <target1,target2>")
      }
      let group = try parsedArgs.requireFlag(
        "--group", "-g", error: "add-sync-folder requires --group or -g flag")
      let targetsStr = try parsedArgs.requireFlag(
        "--targets", "-t", error: "add-sync-folder requires --targets or -t flag")
      let targets = targetsStr.split(separator: ",").map(String.init)
      try utility.addSynchronizedFolder(folderPath: folderPath, to: group, targets: targets)

    case "add-files":
      // Parse file:group pairs from positional arguments
      var files: [(String, String)] = []
      for arg in parsedArgs.positional {
        let parts = arg.split(separator: ":")
        if parts.count == 2 {
          files.append((String(parts[0]), String(parts[1])))
        }
      }

      guard !files.isEmpty else {
        throw ProjectError.invalidArguments(
          "add-files requires: <file1:group1> [file2:group2] ... --targets <target1,target2>")
      }

      let targetsStr = try parsedArgs.requireFlag(
        "--targets", "-t", error: "add-files requires --targets or -t flag")
      let targets = targetsStr.split(separator: ",").map(String.init)

      try utility.addFiles(files, to: targets)

    case "update-paths":
      guard parsedArgs.positional.count >= 2 else {
        throw ProjectError.invalidArguments("update-paths requires: <old-prefix> <new-prefix>")
      }
      utility.updatePathsWithPrefix(from: parsedArgs.positional[0], to: parsedArgs.positional[1])

    case "update-paths-map":
      var mappings: [String: String] = [:]
      for arg in parsedArgs.positional {
        let parts = arg.split(separator: ":")
        if parts.count == 2 {
          mappings[String(parts[0])] = String(parts[1])
        }
      }
      guard !mappings.isEmpty else {
        throw ProjectError.invalidArguments(
          "update-paths-map requires: <old1:new1> [old2:new2] ...")
      }
      utility.updateFilePaths(mappings)

    case "move-file":
      guard parsedArgs.positional.count >= 2 else {
        throw ProjectError.invalidArguments("move-file requires: <old-path> <new-path>")
      }
      try utility.moveFile(from: parsedArgs.positional[0], to: parsedArgs.positional[1])

    case "remove-file":
      guard let filePath = parsedArgs.positional.first else {
        throw ProjectError.invalidArguments("remove-file requires: <file-path>")
      }
      try utility.removeFile(filePath)

    case "remove-group":
      guard let groupPath = parsedArgs.positional.first else {
        throw ProjectError.invalidArguments("remove-group requires: <group-path>")
      }
      try utility.removeGroup(groupPath)

    case "remove-folder":
      guard let folderPath = parsedArgs.positional.first else {
        throw ProjectError.invalidArguments("remove-folder requires: <folder-path>")
      }
      try utility.removeFolder(folderPath)

    case "add-target":
      guard let targetName = parsedArgs.positional.first else {
        throw ProjectError.invalidArguments(
          "add-target requires: <name> --type <product-type> --bundle-id <bundle-id> [--platform <platform>]"
        )
      }
      let productType = try parsedArgs.requireFlag(
        "--type", "-T", error: "add-target requires --type or -T flag")
      let bundleId = try parsedArgs.requireFlag(
        "--bundle-id", "-b", error: "add-target requires --bundle-id or -b flag")
      let platform = parsedArgs.getFlag("--platform", "-p") ?? "iOS"
      try utility.addTarget(
        name: targetName, productType: productType, bundleId: bundleId, platform: platform)

    case "duplicate-target":
      guard parsedArgs.positional.count >= 2 else {
        throw ProjectError.invalidArguments(
          "duplicate-target requires: <source-target> <new-name> [--bundle-id <bundle-id>]")
      }
      let bundleId = parsedArgs.getFlag("--bundle-id", "-b")
      try utility.duplicateTarget(
        source: parsedArgs.positional[0], newName: parsedArgs.positional[1], newBundleId: bundleId)

    case "remove-target":
      guard let targetName = parsedArgs.positional.first else {
        throw ProjectError.invalidArguments("remove-target requires: <target-name>")
      }
      try utility.removeTarget(name: targetName)

    case "add-dependency":
      guard let target = parsedArgs.positional.first else {
        throw ProjectError.invalidArguments(
          "add-dependency requires: <target> --depends-on <target>")
      }
      let dependsOn = try parsedArgs.requireFlag(
        "--depends-on", error: "add-dependency requires --depends-on flag")
      try utility.addDependency(to: target, dependsOn: dependsOn)

    case "add-framework":
      guard let frameworkName = parsedArgs.positional.first else {
        throw ProjectError.invalidArguments(
          "add-framework requires: <framework-name> --target <target> [--embed]")
      }
      let targetName = try parsedArgs.requireFlag(
        "--target", "-t", error: "add-framework requires --target or -t flag")
      let embed = parsedArgs.hasFlag("--embed", "-e")
      try utility.addFramework(name: frameworkName, to: targetName, embed: embed)

    case "add-swift-package":
      guard let url = parsedArgs.positional.first else {
        throw ProjectError.invalidArguments(
          "add-swift-package requires: <url> --version <requirement> [--target <target>]")
      }
      let requirement = try parsedArgs.requireFlag(
        "--version", "-v", error: "add-swift-package requires --version or -v flag")
      let targetName = parsedArgs.getFlag("--target", "-t")
      try utility.addSwiftPackage(url: url, requirement: requirement, to: targetName)

    case "remove-swift-package":
      guard let url = parsedArgs.positional.first else {
        throw ProjectError.invalidArguments("remove-swift-package requires: <url>")
      }
      try utility.removeSwiftPackage(url: url)

    case "list-swift-packages":
      utility.listSwiftPackages()
      exit(0)

    case "add-build-phase":
      guard parsedArgs.positional.count >= 2 else {
        throw ProjectError.invalidArguments(
          "add-build-phase requires: <type> <name> --target <target> [--script <script>]")
      }
      let type = parsedArgs.positional[0]
      let name = parsedArgs.positional[1]
      let targetName = try parsedArgs.requireFlag(
        "--target", "-t", error: "add-build-phase requires --target or -t flag")
      let script = parsedArgs.getFlag("--script", "-s")
      try utility.addBuildPhase(type: type, name: name, to: targetName, script: script)

    case "get-build-settings":
      guard let targetName = parsedArgs.positional.first else {
        throw ProjectError.invalidArguments(
          "get-build-settings requires: <target> [--config <configuration>]")
      }
      let config = parsedArgs.getFlag("--config", "-c")
      let settings = utility.getBuildSettings(for: targetName, configuration: config)
      for (configName, configSettings) in settings {
        print("\n🔧 \(configName):")
        for (key, value) in configSettings {
          print("  \(key) = \(value)")
        }
      }
      exit(0)

    case "list-build-configs":
      let targetName = parsedArgs.getFlag("--target", "-t")
      utility.listBuildConfigurations(for: targetName)
      exit(0)

    case "list-groups":
      print("📁 Groups in project:")
      for group in utility.pbxproj.groups {
        if let name = group.name ?? group.path {
          print("  - \(name)")
          listGroupHierarchy(group, indent: "    ")
        }
      }
      exit(0)

    case "create-groups":
      guard !parsedArgs.positional.isEmpty else {
        throw ProjectError.invalidArguments("create-groups requires: <group1> [group2] ...")
      }
      for groupPath in parsedArgs.positional {
        _ = utility.ensureGroupHierarchy(groupPath)
      }

    case "set-build-setting":
      guard parsedArgs.positional.count >= 2 else {
        throw ProjectError.invalidArguments(
          "set-build-setting requires: <key> <value> --targets <target1,target2>")
      }
      let key = parsedArgs.positional[0]
      let value = parsedArgs.positional[1]
      let targetsStr = try parsedArgs.requireFlag(
        "--targets", "-t", error: "set-build-setting requires --targets or -t flag")
      let targets = targetsStr.split(separator: ",").map(String.init)

      utility.updateBuildSettings(targets: targets) { settings in
        settings[key] = .string(value)
      }

    case "validate":
      let issues = utility.validate()
      if issues.isEmpty {
        print("✅ No validation issues found")
      } else {
        print("❌ Validation issues:")
        issues.forEach { print("  - \($0)") }
      }
      exit(issues.isEmpty ? 0 : 1)

    case "list-invalid-references":
      utility.listInvalidReferences()
      exit(0)

    case "remove-invalid-references":
      utility.removeInvalidReferences()

    case "list-targets":
      print("📱 Targets in project:")
      for target in utility.pbxproj.nativeTargets {
        print("  - \(target.name) (\(target.productType?.rawValue ?? "unknown"))")
      }
      exit(0)

    case "list-files":
      let groupName = parsedArgs.positional.first
      if let name = groupName,
        let group = findGroup(named: name, in: utility.pbxproj.groups)
      {
        print("📄 Files in \(name):")
        listFilesInGroup(group, indent: "  ")
      } else {
        print("📄 All files in project:")
        for fileRef in utility.pbxproj.fileReferences {
          print("  - \(fileRef.path ?? fileRef.name ?? "unknown")")
        }
      }
      exit(0)

    default:
      print("❌ Unknown command: \(command)")
      printUsage()
      exit(1)
    }

    if !dryRun {
      try utility.save()
    } else {
      print("🔍 DRY RUN - Changes not saved")
    }
  }

  static func listFilesInGroup(_ group: PBXGroup, indent: String = "") {
    for child in group.children {
      if let fileRef = child as? PBXFileReference {
        print("\(indent)- \(fileRef.path ?? fileRef.name ?? "unknown")")
      } else if let subgroup = child as? PBXGroup {
        print("\(indent)📁 \(subgroup.name ?? subgroup.path ?? "unknown")/")
        listFilesInGroup(subgroup, indent: indent + "  ")
      }
    }
  }

  static func listGroupHierarchy(_ group: PBXGroup, indent: String = "") {
    for child in group.children {
      if let subgroup = child as? PBXGroup {
        if let name = subgroup.name ?? subgroup.path {
          print("\(indent)- \(name)")
          listGroupHierarchy(subgroup, indent: indent + "  ")
        }
      }
    }
  }
}

// MARK: - Main
do {
  try CLI.run()
} catch {
  print("❌ Error: \(error)")
  exit(1)
}
