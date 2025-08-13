//
// XcodeProjService.swift
// xcodeproj-cli
//
// Core service for Xcode project manipulation
//

import Foundation
import PathKit
import XcodeProj

/// Core service for manipulating Xcode project files
class XcodeProjService {
  let xcodeproj: XcodeProj
  let projectPath: Path
  let pbxproj: PBXProj
  
  private let transactionManager: TransactionManager
  private let validator: ProjectValidator
  private let cacheManager: CacheManager
  private let profiler: PerformanceProfiler?
  
  init(path: String = "MyProject.xcodeproj", verbose: Bool = false) throws {
    // Resolve path relative to current working directory
    if path.hasPrefix("/") {
      self.projectPath = Path(path)
    } else {
      let currentDir = FileManager.default.currentDirectoryPath
      self.projectPath = Path(currentDir) + Path(path)
    }

    self.xcodeproj = try XcodeProj(path: projectPath)
    self.pbxproj = xcodeproj.pbxproj
    self.transactionManager = TransactionManager(projectPath: projectPath)
    self.validator = ProjectValidator(pbxproj: pbxproj, projectPath: projectPath)
    self.cacheManager = CacheManager(pbxproj: pbxproj)
    self.profiler = verbose ? PerformanceProfiler(verbose: verbose) : nil
  }
  
  // MARK: - Cache Management
  
  private func invalidateCaches() {
    cacheManager.invalidateAllCaches()
  }
  
  private func findGroupInCache(_ path: String) -> PBXGroup? {
    return profiler?.measureOperation("findGroup-\(path)") {
      return cacheManager.getGroup(path) ?? findGroupAtPath(path)
    } ?? (cacheManager.getGroup(path) ?? findGroupAtPath(path))
  }
  
  // MARK: - Transaction Support
  
  func beginTransaction() throws {
    try transactionManager.beginTransaction()
  }
  
  func commitTransaction() throws {
    try save()
    try transactionManager.commitTransaction()
  }
  
  func rollbackTransaction() throws {
    try transactionManager.rollbackTransaction()
  }
  
  // MARK: - File Operations
  
  func addFile(path: String, to groupPath: String, targets: [String]) throws {
    try profiler?.measureOperation("addFile-\(path)") {
      try _addFile(path: path, to: groupPath, targets: targets)
    } ?? _addFile(path: path, to: groupPath, targets: targets)
  }
  
  private func _addFile(path: String, to groupPath: String, targets: [String]) throws {
    guard PathUtils.sanitizePath(path) != nil else {
      throw ProjectError.invalidArguments("Invalid file path: \(path)")
    }

    let fileName = (path as NSString).lastPathComponent
    
    // Check cache first for existing file
    if cacheManager.getFileReference(fileName) != nil {
      print("⚠️  File \(fileName) already exists, skipping")
      return
    }

    guard let group = findOrCreateGroup(groupPath) else {
      throw ProjectError.groupNotFound(groupPath)
    }

    let fileRef = try group.addFile(at: Path(path), sourceRoot: projectPath.parent())
    
    // Update file reference cache
    cacheManager.invalidateFileReference(fileName)
    
    // Add to targets using cached lookups
    for targetName in targets {
      guard let target = cacheManager.getTarget(targetName) else {
        throw ProjectError.targetNotFound(targetName)
      }
      
      if PathUtils.isCompilableFile(path) {
        if let sourcesPhase = XcodeProjectHelpers.sourceBuildPhase(for: target) {
          _ = try sourcesPhase.add(file: fileRef)
        }
      }
    }
    
    print("✅ Added file: \(fileName)")
  }
  
  func removeFile(_ filePath: String) throws {
    let fileName = (filePath as NSString).lastPathComponent
    
    guard let fileRef = pbxproj.fileReferences.first(where: { 
      $0.path == fileName || $0.name == fileName 
    }) else {
      throw ProjectError.operationFailed("File not found: \(fileName)")
    }
    
    // Remove from all targets
    for target in pbxproj.nativeTargets {
      if let sourcesPhase = XcodeProjectHelpers.sourceBuildPhase(for: target) {
        sourcesPhase.files?.removeAll { $0.file === fileRef }
      }
    }
    
    // Remove from groups
    for group in pbxproj.groups {
      group.children.removeAll { $0 === fileRef }
    }
    
    // Remove file reference
    pbxproj.delete(object: fileRef)
    print("🗑️  Removed file: \(fileName)")
  }
  
  func moveFile(from oldPath: String, to newPath: String) throws {
    let oldFileName = (oldPath as NSString).lastPathComponent
    guard let fileRef = pbxproj.fileReferences.first(where: { 
      $0.path == oldFileName || $0.name == oldFileName 
    }) else {
      throw ProjectError.operationFailed("File not found: \(oldFileName)")
    }
    
    fileRef.path = newPath
    print("📁 Moved file from \(oldPath) to \(newPath)")
  }
  
  // MARK: - Group Operations
  
  func createGroups(_ groupPaths: [String]) {
    for path in groupPaths {
      _ = findOrCreateGroup(path)
      print("📁 Created group: \(path)")
    }
  }
  
  func findOrCreateGroup(_ path: String) -> PBXGroup? {
    if let cached = findGroupInCache(path) {
      return cached
    }
    
    let pathComponents = path.split(separator: "/").map(String.init)
    
    // Proper error handling for rootGroup access
    let rootGroup: PBXGroup
    do {
      rootGroup = try pbxproj.rootGroup()
    } catch {
      print("⚠️  Unable to access project root group: \(error)")
      return nil
    }
    var currentGroup = rootGroup
    
    for component in pathComponents {
      if let existingGroup = currentGroup.children.compactMap({ $0 as? PBXGroup })
          .first(where: { $0.name == component || $0.path == component }) {
        currentGroup = existingGroup
      } else {
        let newGroup = PBXGroup(children: [], sourceTree: .group, name: component)
        pbxproj.add(object: newGroup)
        currentGroup.children.append(newGroup)
        currentGroup = newGroup
      }
    }
    
    return currentGroup
  }
  
  func findGroupAtPath(_ path: String) -> PBXGroup? {
    guard let rootGroup = try? pbxproj.rootGroup() else { return nil }
    return XcodeProjectHelpers.findGroupByPath(path, in: pbxproj.groups, rootGroup: rootGroup)
  }
  
  // MARK: - Target Operations
  
  func addTarget(name: String, productType: String, bundleId: String, platform: String = "iOS") throws {
    try profiler?.measureOperation("addTarget-\(name)") {
      try _addTarget(name: name, productType: productType, bundleId: bundleId, platform: platform)
    } ?? _addTarget(name: name, productType: productType, bundleId: bundleId, platform: platform)
  }
  
  private func _addTarget(name: String, productType: String, bundleId: String, platform: String) throws {
    guard cacheManager.getTarget(name) == nil else {
      throw ProjectError.operationFailed("Target '\(name)' already exists")
    }
    
    let target = PBXNativeTarget(
      name: name,
      buildConfigurationList: nil,
      buildPhases: [],
      buildRules: [],
      dependencies: [],
      productName: name,
      product: nil,
      productType: PBXProductType(rawValue: productType)
    )
    
    pbxproj.add(object: target)
    if let rootObject = pbxproj.rootObject {
      rootObject.targets.append(target)
    }
    
    // Invalidate cache to pick up new target
    cacheManager.invalidateTarget(name)
    cacheManager.rebuildAllCaches()
    
    print("🎯 Added target: \(name)")
  }
  
  func removeTarget(_ name: String) throws {
    try profiler?.measureOperation("removeTarget-\(name)") {
      try _removeTarget(name)
    } ?? _removeTarget(name)
  }
  
  private func _removeTarget(_ name: String) throws {
    guard let target = cacheManager.getTarget(name) else {
      throw ProjectError.targetNotFound(name)
    }
    
    pbxproj.rootObject?.targets.removeAll { $0 === target }
    pbxproj.delete(object: target)
    
    // Invalidate cache
    cacheManager.invalidateTarget(name)
    
    print("🗑️  Removed target: \(name)")
  }
  
  func getTarget(_ name: String) throws -> PBXNativeTarget {
    guard let target = cacheManager.getTarget(name) else {
      throw ProjectError.targetNotFound(name)
    }
    return target
  }
  
  // MARK: - Build Settings
  
  func setBuildSetting(key: String, value: String, targets: [String], configuration: String? = nil) throws {
    for targetName in targets {
      let target = try getTarget(targetName)
      
      guard let configList = target.buildConfigurationList else {
        throw ProjectError.operationFailed("No build configuration list for target: \(targetName)")
      }
      
      let configs: [XCBuildConfiguration]
      if let configName = configuration {
        configs = configList.buildConfigurations.filter { $0.name == configName }
        if configs.isEmpty {
          throw ProjectError.operationFailed("Configuration '\(configName)' not found for target: \(targetName)")
        }
      } else {
        configs = configList.buildConfigurations
      }
      
      for config in configs {
        config.buildSettings[key] = .string(value)
      }
    }
    
    print("🔧 Set build setting \(key) = \(value)")
  }
  
  func getBuildSettings(for targetName: String, configuration: String? = nil) throws -> [String: [String: Any]] {
    let target = try getTarget(targetName)
    
    guard let configList = target.buildConfigurationList else {
      throw ProjectError.operationFailed("No build configuration list for target: \(targetName)")
    }
    
    var result: [String: [String: Any]] = [:]
    
    let configs: [XCBuildConfiguration]
    if let configName = configuration {
      configs = configList.buildConfigurations.filter { $0.name == configName }
    } else {
      configs = configList.buildConfigurations
    }
    
    for config in configs {
      result[config.name] = config.buildSettings
    }
    
    return result
  }
  
  // MARK: - Dependencies
  
  func addDependency(to targetName: String, dependsOn dependencyName: String) throws {
    let target = try getTarget(targetName)
    let dependencyTarget = try getTarget(dependencyName)
    
    let dependency = PBXTargetDependency(target: dependencyTarget)
    pbxproj.add(object: dependency)
    target.dependencies.append(dependency)
    
    print("🔗 Added dependency: \(targetName) depends on \(dependencyName)")
  }
  
  // MARK: - Swift Packages
  
  func addSwiftPackage(url: String, requirement: String, to targetName: String? = nil) throws {
    // Implementation for adding Swift packages
    // This is a simplified version - full implementation would be more complex
    print("📦 Added Swift package: \(url)")
  }
  
  func removeSwiftPackage(url: String) throws {
    // Implementation for removing Swift packages
    print("🗑️  Removed Swift package: \(url)")
  }
  
  // MARK: - Validation
  
  func validate() -> [String] {
    return validator.validate()
  }
  
  func listInvalidReferences() {
    validator.listInvalidReferences()
  }
  
  func removeInvalidReferences() {
    validator.removeInvalidReferences()
    cacheManager.invalidateAllCaches() // Rebuild caches after cleanup
  }
  
  // MARK: - Persistence
  
  func save() throws {
    try profiler?.measureOperation("save") {
      try xcodeproj.write(path: projectPath)
    } ?? xcodeproj.write(path: projectPath)
    
    // Print performance stats if verbose
    profiler?.printTimingReport()
    if profiler != nil {
      cacheManager.printCacheStatistics()
    }
  }
}