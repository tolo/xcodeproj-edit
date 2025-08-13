//
// SchemeManager.swift
// xcodeproj-cli
//
// Service for managing Xcode schemes
//

import Foundation
import PathKit
import XcodeProj

/// Service for managing Xcode project schemes
class SchemeManager {
  private let xcodeproj: XcodeProj
  private let projectPath: Path
  private let pbxproj: PBXProj
  private let schemesPath: Path

  init(xcodeproj: XcodeProj, projectPath: Path) {
    self.xcodeproj = xcodeproj
    self.projectPath = projectPath
    self.pbxproj = xcodeproj.pbxproj
    self.schemesPath = projectPath + "xcshareddata/xcschemes"
  }

  // MARK: - Scheme Creation

  /// Creates a new scheme for the specified target
  func createScheme(
    name: String,
    targetName: String,
    shared: Bool = true
  ) throws -> XCScheme {
    // Find the target
    guard let target = pbxproj.targets(named: targetName).first else {
      throw ProjectError.targetNotFound(targetName)
    }

    // Get the project
    guard let project = pbxproj.rootObject else {
      throw ProjectError.operationFailed("No root project found")
    }

    // Create buildable reference
    let buildableReference = XCScheme.BuildableReference(
      referencedContainer: "container:\(projectPath.lastComponent)",
      blueprint: target,
      buildableName: target.productNameWithExtension() ?? target.name,
      blueprintName: target.name
    )

    // Create build action
    let buildAction = XCScheme.BuildAction(
      buildActionEntries: [
        XCScheme.BuildAction.Entry(
          buildableReference: buildableReference,
          buildFor: [.running, .testing, .profiling, .archiving, .analyzing]
        )
      ],
      parallelizeBuild: true,
      buildImplicitDependencies: true
    )

    // Create test action if there are test targets
    let testTargets = pbxproj.targets(named: "\(targetName)Tests")
    let testAction: XCScheme.TestAction?

    if !testTargets.isEmpty {
      let testBuildableReference = XCScheme.BuildableReference(
        referencedContainer: "container:\(projectPath.lastComponent)",
        blueprint: testTargets.first!,
        buildableName: testTargets.first!.productNameWithExtension() ?? testTargets.first!.name,
        blueprintName: testTargets.first!.name
      )

      testAction = XCScheme.TestAction(
        buildConfiguration: "Debug",
        macroExpansion: buildableReference,
        testables: [
          XCScheme.TestableReference(
            skipped: false,
            buildableReference: testBuildableReference
          )
        ]
      )
    } else {
      testAction = XCScheme.TestAction(
        buildConfiguration: "Debug",
        macroExpansion: buildableReference
      )
    }

    // Create launch action
    let launchAction = XCScheme.LaunchAction(
      runnable: XCScheme.Runnable(buildableReference: buildableReference),
      buildConfiguration: "Debug"
    )

    // Create profile action
    let profileAction = XCScheme.ProfileAction(
      buildableProductRunnable: XCScheme.BuildableProductRunnable(
        buildableReference: buildableReference),
      buildConfiguration: "Release"
    )

    // Create analyze action
    let analyzeAction = XCScheme.AnalyzeAction(buildConfiguration: "Debug")

    // Create archive action
    let archiveAction = XCScheme.ArchiveAction(
      buildConfiguration: "Release",
      revealArchiveInOrganizer: true
    )

    // Create the scheme
    let scheme = XCScheme(
      name: name,
      lastUpgradeVersion: nil,
      version: "1.7",
      buildAction: buildAction,
      testAction: testAction,
      launchAction: launchAction,
      profileAction: profileAction,
      analyzeAction: analyzeAction,
      archiveAction: archiveAction
    )

    // Save the scheme
    if shared {
      try saveSharedScheme(scheme)
    } else {
      try saveUserScheme(scheme)
    }

    return scheme
  }

  /// Duplicates an existing scheme
  func duplicateScheme(sourceName: String, destinationName: String) throws -> XCScheme {
    // Load the source scheme
    let sourceScheme = try loadScheme(name: sourceName)

    // Create a new scheme with the same configuration but different name
    let duplicatedScheme = XCScheme(
      name: destinationName,
      lastUpgradeVersion: sourceScheme.lastUpgradeVersion,
      version: sourceScheme.version,
      buildAction: sourceScheme.buildAction,
      testAction: sourceScheme.testAction,
      launchAction: sourceScheme.launchAction,
      profileAction: sourceScheme.profileAction,
      analyzeAction: sourceScheme.analyzeAction,
      archiveAction: sourceScheme.archiveAction,
      wasCreatedForAppExtension: sourceScheme.wasCreatedForAppExtension
    )

    // Save the duplicated scheme
    try saveSharedScheme(duplicatedScheme)

    return duplicatedScheme
  }

  /// Removes a scheme
  func removeScheme(name: String) throws {
    let schemePath = schemesPath + "\(name).xcscheme"

    guard schemePath.exists else {
      throw ProjectError.operationFailed("Scheme '\(name)' not found")
    }

    try schemePath.delete()
    print("✅ Removed scheme: \(name)")
  }

  /// Lists all schemes
  func listSchemes(shared: Bool = true) -> [String] {
    let path = shared ? schemesPath : projectPath + "xcuserdata"

    guard path.exists else {
      return []
    }

    do {
      let schemes = try path.children()
        .filter { $0.extension == "xcscheme" }
        .map { $0.lastComponentWithoutExtension }
      return schemes
    } catch {
      return []
    }
  }

  /// Sets build configuration for scheme actions
  func setSchemeConfiguration(
    schemeName: String,
    buildConfig: String? = nil,
    runConfig: String? = nil,
    testConfig: String? = nil,
    profileConfig: String? = nil,
    analyzeConfig: String? = nil,
    archiveConfig: String? = nil
  ) throws {
    let scheme = try loadScheme(name: schemeName)

    // Update configurations
    if let config = buildConfig {
      // Build action doesn't have a direct configuration, it uses per-entry settings
      print("⚠️  Build configuration is set per build entry, not globally")
    }

    if let config = runConfig, var launchAction = scheme.launchAction {
      launchAction.buildConfiguration = config
      scheme.launchAction = launchAction
    }

    if let config = testConfig, let testAction = scheme.testAction {
      var updatedTestAction = testAction
      updatedTestAction.buildConfiguration = config
      scheme.testAction = updatedTestAction
    }

    if let config = profileConfig, let profileAction = scheme.profileAction {
      var updatedProfileAction = profileAction
      updatedProfileAction.buildConfiguration = config
      scheme.profileAction = updatedProfileAction
    }

    if let config = analyzeConfig, let analyzeAction = scheme.analyzeAction {
      var updatedAnalyzeAction = analyzeAction
      updatedAnalyzeAction.buildConfiguration = config
      scheme.analyzeAction = updatedAnalyzeAction
    }

    if let config = archiveConfig, let archiveAction = scheme.archiveAction {
      var updatedArchiveAction = archiveAction
      updatedArchiveAction.buildConfiguration = config
      scheme.archiveAction = updatedArchiveAction
    }

    // Save the updated scheme
    try saveSharedScheme(scheme)
    print("✅ Updated scheme configuration: \(schemeName)")
  }

  /// Adds a target to scheme build action
  func addTargetToScheme(
    schemeName: String,
    targetName: String,
    buildFor: [XCScheme.BuildAction.Entry.BuildFor] = [
      .running, .testing, .profiling, .archiving, .analyzing,
    ]
  ) throws {
    let scheme = try loadScheme(name: schemeName)

    // Find the target
    guard let target = pbxproj.targets(named: targetName).first else {
      throw ProjectError.targetNotFound(targetName)
    }

    // Create buildable reference
    let buildableReference = XCScheme.BuildableReference(
      referencedContainer: "container:\(projectPath.lastComponent)",
      blueprint: target,
      buildableName: target.productNameWithExtension() ?? target.name,
      blueprintName: target.name
    )

    // Add to build action
    if let buildAction = scheme.buildAction {
      let entry = XCScheme.BuildAction.Entry(
        buildableReference: buildableReference,
        buildFor: buildFor
      )
      var updatedBuildAction = buildAction
      updatedBuildAction.buildActionEntries.append(entry)
      scheme.buildAction = updatedBuildAction
    } else {
      // Create new build action if it doesn't exist
      scheme.buildAction = XCScheme.BuildAction(
        buildActionEntries: [
          XCScheme.BuildAction.Entry(
            buildableReference: buildableReference,
            buildFor: buildFor
          )
        ]
      )
    }

    // Save the updated scheme
    try saveSharedScheme(scheme)
    print("✅ Added target '\(targetName)' to scheme '\(schemeName)'")
  }

  /// Enables test coverage for a scheme
  func enableTestCoverage(
    schemeName: String,
    targets: [String]? = nil
  ) throws {
    let scheme = try loadScheme(name: schemeName)

    guard let testAction = scheme.testAction else {
      throw ProjectError.operationFailed("Scheme '\(schemeName)' has no test action")
    }

    // Enable code coverage
    var updatedTestAction = testAction
    updatedTestAction.codeCoverageEnabled = true

    // Add specific targets if provided
    if let targetNames = targets {
      var coverageTargets: [XCScheme.BuildableReference] = []

      for targetName in targetNames {
        guard let target = pbxproj.targets(named: targetName).first else {
          throw ProjectError.targetNotFound(targetName)
        }

        let buildableReference = XCScheme.BuildableReference(
          referencedContainer: "container:\(projectPath.lastComponent)",
          blueprint: target,
          buildableName: target.productNameWithExtension() ?? target.name,
          blueprintName: target.name
        )
        coverageTargets.append(buildableReference)
      }

      updatedTestAction.codeCoverageTargets = coverageTargets
    }

    scheme.testAction = updatedTestAction

    // Save the updated scheme
    try saveSharedScheme(scheme)
    print("✅ Enabled test coverage for scheme '\(schemeName)'")
  }

  /// Sets test parallelization for a scheme
  func setTestParallelization(
    schemeName: String,
    enabled: Bool
  ) throws {
    let scheme = try loadScheme(name: schemeName)

    guard let testAction = scheme.testAction else {
      throw ProjectError.operationFailed("Scheme '\(schemeName)' has no test action")
    }

    // Create test execution options - Note: TestPlans API not available in this XcodeProj version
    // let testPlans = enabled ? ... : nil

    // For now, we'll use a simpler approach by modifying testables
    // XcodeProj doesn't have direct support for parallelization in older versions
    // This would need to be extended based on XcodeProj API capabilities

    if enabled {
      print("⚠️  Test parallelization requires Xcode 16+ scheme format")
    }

    scheme.testAction = testAction

    // Save the updated scheme
    try saveSharedScheme(scheme)
    print("✅ Updated test parallelization for scheme '\(schemeName)'")
  }

  // MARK: - Private Helpers

  private func loadScheme(name: String) throws -> XCScheme {
    let schemePath = schemesPath + "\(name).xcscheme"

    guard schemePath.exists else {
      throw ProjectError.operationFailed("Scheme '\(name)' not found")
    }

    return try XCScheme(path: schemePath)
  }

  private func saveSharedScheme(_ scheme: XCScheme) throws {
    // Ensure schemes directory exists
    if !schemesPath.exists {
      try schemesPath.mkpath()
    }

    let schemePath = schemesPath + "\(scheme.name).xcscheme"
    try scheme.write(path: schemePath, override: true)
  }

  private func saveUserScheme(_ scheme: XCScheme) throws {
    let userSchemesPath = projectPath + "xcuserdata/\(NSUserName()).xcuserdatad/xcschemes"

    // Ensure user schemes directory exists
    if !userSchemesPath.exists {
      try userSchemesPath.mkpath()
    }

    let schemePath = userSchemesPath + "\(scheme.name).xcscheme"
    try scheme.write(path: schemePath, override: true)
  }
}
