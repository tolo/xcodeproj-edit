//
// LocalizationManager.swift
// xcodeproj-cli
//
// Service for managing localization and variant groups
//

import Foundation
@preconcurrency import PathKit
@preconcurrency import XcodeProj

/// Service for managing localization and variant groups
@MainActor
class LocalizationManager {
  private let xcodeproj: XcodeProj
  private let projectPath: Path
  private let pbxproj: PBXProj
  private let transactionManager: TransactionManager

  init(xcodeproj: XcodeProj, projectPath: Path) {
    self.xcodeproj = xcodeproj
    self.projectPath = projectPath
    self.pbxproj = xcodeproj.pbxproj
    self.transactionManager = TransactionManager(projectPath: projectPath)
  }

  // MARK: - Transaction Support

  /// Begins a transaction for localization modifications
  func beginTransaction() throws {
    try transactionManager.beginTransaction()
  }

  /// Commits the current transaction
  func commitTransaction() throws {
    try transactionManager.commitTransaction()
  }

  /// Rolls back the current transaction
  func rollbackTransaction() throws {
    try transactionManager.rollbackTransaction()
  }

  // MARK: - Localization Management

  /// Adds a new localization to the project
  func addLocalization(_ languageCode: String) throws {
    // Get or create known regions
    if pbxproj.rootObject?.knownRegions == nil {
      pbxproj.rootObject?.knownRegions = []
    }

    // Check if localization already exists
    if pbxproj.rootObject?.knownRegions.contains(languageCode) == true {
      throw ProjectError.localizationAlreadyExists(languageCode)
    }

    // Add the localization
    pbxproj.rootObject?.knownRegions.append(languageCode)

    // Update development region if it's the first non-base localization
    if pbxproj.rootObject?.knownRegions.count == 1 {
      pbxproj.rootObject?.developmentRegion = languageCode
    }

    print("✅ Added localization: \(languageCode)")
  }

  /// Removes a localization from the project
  func removeLocalization(_ languageCode: String) throws {
    guard var knownRegions = pbxproj.rootObject?.knownRegions else {
      throw ProjectError.operationFailed("No localizations found in project")
    }

    guard knownRegions.contains(languageCode) else {
      throw ProjectError.localizationNotFound(languageCode)
    }

    // Remove from known regions
    knownRegions.removeAll { $0 == languageCode }
    pbxproj.rootObject?.knownRegions = knownRegions

    // Remove localized files from variant groups
    for variantGroup in pbxproj.variantGroups {
      variantGroup.children.removeAll { child in
        if let fileRef = child as? PBXFileReference {
          return fileRef.name == languageCode || fileRef.path?.contains(".\(languageCode).") == true
        }
        return false
      }
    }

    print("✅ Removed localization: \(languageCode)")
  }

  /// Lists all localizations in the project
  func listLocalizations() -> [String] {
    return pbxproj.rootObject?.knownRegions ?? []
  }

  // MARK: - Variant Group Management

  /// Creates a variant group for localized resources
  func createVariantGroup(
    name: String,
    baseFilePath: String,
    languages: [String]? = nil
  ) throws -> PBXVariantGroup {
    // Check if variant group already exists
    if let existingGroup = pbxproj.variantGroups.first(where: { $0.name == name }) {
      print("⚠️  Variant group '\(name)' already exists")
      return existingGroup
    }

    // Create variant group
    let variantGroup = PBXVariantGroup(
      sourceTree: .group,
      name: name
    )
    pbxproj.add(object: variantGroup)

    // Add base localization
    let baseRef = PBXFileReference(
      sourceTree: .group,
      name: "Base",
      lastKnownFileType: fileType(for: baseFilePath),
      path: baseFilePath
    )
    pbxproj.add(object: baseRef)
    variantGroup.children.append(baseRef)

    // Add additional language variants if specified
    if let languages = languages {
      for language in languages {
        let localizedPath = baseFilePath.replacingOccurrences(
          of: ".lproj/", with: ".\(language).lproj/")
        let localizedRef = PBXFileReference(
          sourceTree: .group,
          name: language,
          lastKnownFileType: fileType(for: localizedPath),
          path: localizedPath
        )
        pbxproj.add(object: localizedRef)
        variantGroup.children.append(localizedRef)
      }
    }

    // Add to main group
    if let mainGroup = pbxproj.rootObject?.mainGroup {
      mainGroup.children.append(variantGroup)
    }

    print("✅ Created variant group: \(name)")

    return variantGroup
  }

  /// Adds a localized resource to the project
  func addLocalizedResource(
    filePath: String,
    language: String,
    groupPath: String? = nil
  ) throws {
    // Extract the resource name from the path
    let fileName = Path(filePath).lastComponent
    let resourceName = fileName.replacingOccurrences(of: ".\(language).lproj/", with: "")

    // Find or create variant group
    let variantGroup: PBXVariantGroup
    if let existingGroup = pbxproj.variantGroups.first(where: { $0.name == resourceName }) {
      variantGroup = existingGroup
    } else {
      variantGroup = try createVariantGroup(name: resourceName, baseFilePath: filePath)
    }

    // Check if this language variant already exists
    let hasLanguage = variantGroup.children.contains { child in
      if let fileRef = child as? PBXFileReference {
        return fileRef.name == language
      }
      return false
    }

    if hasLanguage {
      print("⚠️  Language '\(language)' already exists for resource '\(resourceName)'")
      return
    }

    // Add the localized file reference
    let localizedRef = PBXFileReference(
      sourceTree: .group,
      name: language,
      lastKnownFileType: fileType(for: filePath),
      path: filePath
    )
    pbxproj.add(object: localizedRef)
    variantGroup.children.append(localizedRef)

    // Add to specified group if needed
    if let groupPath = groupPath {
      if let group = findGroup(named: groupPath) {
        if !group.children.contains(where: { $0 === variantGroup }) {
          group.children.append(variantGroup)
        }
      }
    }

    print("✅ Added localized resource: \(fileName) (\(language))")
  }

  /// Lists all variant groups in the project
  func listVariantGroups() -> [(name: String, languages: [String])] {
    var groups: [(name: String, languages: [String])] = []

    for variantGroup in pbxproj.variantGroups {
      let languages = variantGroup.children.compactMap { child -> String? in
        if let fileRef = child as? PBXFileReference {
          return fileRef.name
        }
        return nil
      }

      if let name = variantGroup.name {
        groups.append((name: name, languages: languages))
      }
    }

    return groups
  }

  // MARK: - Private Helpers

  private func findGroup(named path: String) -> PBXGroup? {
    let components = path.split(separator: "/").map(String.init)

    guard !components.isEmpty else {
      return pbxproj.rootObject?.mainGroup
    }

    var currentGroups = pbxproj.groups
    var currentGroup: PBXGroup?

    for component in components {
      currentGroup = currentGroups.first { group in
        group.name == component || group.path == component
      }

      guard let group = currentGroup else {
        return nil
      }

      currentGroups = group.children.compactMap { $0 as? PBXGroup }
    }

    return currentGroup
  }

  private func fileType(for path: String) -> String? {
    let ext = Path(path).extension ?? ""

    switch ext.lowercased() {
    case "strings":
      return "text.plist.strings"
    case "stringsdict":
      return "text.plist.stringsdict"
    case "plist":
      return "text.plist.xml"
    case "storyboard":
      return "file.storyboard"
    case "xib":
      return "file.xib"
    case "json":
      return "text.json"
    case "xml":
      return "text.xml"
    case "html":
      return "text.html"
    case "rtf":
      return "text.rtf"
    case "txt":
      return "text"
    default:
      return nil
    }
  }
}
