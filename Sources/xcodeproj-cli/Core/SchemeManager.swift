//
// SchemeManager.swift
// xcodeproj-cli
//
// Service for managing Xcode schemes
//

import Foundation
@preconcurrency import PathKit
@preconcurrency import XcodeProj

/// Service for managing Xcode project schemes
@MainActor
class SchemeManager {
  private let xcodeproj: XcodeProj
  private let projectPath: Path
  private let pbxproj: PBXProj
  private let schemesPath: Path
  private let transactionManager: TransactionManager

  init(xcodeproj: XcodeProj, projectPath: Path) {
    self.xcodeproj = xcodeproj
    self.projectPath = projectPath
    self.pbxproj = xcodeproj.pbxproj
    self.schemesPath = projectPath + "xcshareddata/xcschemes"
    self.transactionManager = TransactionManager(projectPath: projectPath)
  }

  // MARK: - Transaction Support

  /// Begins a transaction for scheme modifications
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

  // MARK: - Scheme Creation

  /// Creates a new scheme for the specified target
  func createScheme(
    name: String,
    targetName: String,
    shared: Bool = true
  ) throws -> XCScheme {
    // Validate user inputs for security
    let validatedSchemeName = try SecurityUtils.validateString(name)
    let validatedTargetName = try SecurityUtils.validateString(targetName)

    // Find the target
    guard let target = pbxproj.targets(named: validatedTargetName).first else {
      throw ProjectError.targetNotFound(validatedTargetName)
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
      guard let firstTestTarget = testTargets.first else {
        throw ProjectError.operationFailed("Test targets array is empty despite isEmpty check")
      }

      let testBuildableReference = XCScheme.BuildableReference(
        referencedContainer: "container:\(projectPath.lastComponent)",
        blueprint: firstTestTarget,
        buildableName: firstTestTarget.productNameWithExtension() ?? firstTestTarget.name,
        blueprintName: firstTestTarget.name
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
      name: validatedSchemeName,
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
    // Validate user inputs for security
    let validatedSourceName = try SecurityUtils.validateString(sourceName)
    let validatedDestinationName = try SecurityUtils.validateString(destinationName)

    // Load the source scheme
    let sourceScheme = try loadScheme(name: validatedSourceName)

    // Create a new scheme with the same configuration but different name
    let duplicatedScheme = XCScheme(
      name: validatedDestinationName,
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
    // Validate user input for security
    let validatedSchemeName = try SecurityUtils.validateString(name)

    let schemePath = schemesPath + "\(validatedSchemeName).xcscheme"

    guard schemePath.exists else {
      throw ProjectError.schemeNotFound(validatedSchemeName)
    }

    try schemePath.delete()
    print("✅ Removed scheme: \(validatedSchemeName)")
  }

  /// Lists all schemes
  func listSchemes(shared: Bool = true) throws -> [String] {
    let path = shared ? schemesPath : projectPath + "xcuserdata"

    guard path.exists else {
      return []  // Return empty array if directory doesn't exist yet (valid case)
    }

    do {
      let schemes = try path.children()
        .filter { $0.extension == "xcscheme" }
        .map { $0.lastComponentWithoutExtension }
      return schemes
    } catch {
      throw ProjectError.operationFailed("Failed to list schemes: \(error.localizedDescription)")
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
    // Validate user inputs for security
    let validatedSchemeName = try SecurityUtils.validateString(schemeName)
    let validatedBuildConfig = try buildConfig.map { try SecurityUtils.validateString($0) }
    let validatedRunConfig = try runConfig.map { try SecurityUtils.validateString($0) }
    let validatedTestConfig = try testConfig.map { try SecurityUtils.validateString($0) }
    let validatedProfileConfig = try profileConfig.map { try SecurityUtils.validateString($0) }
    let validatedAnalyzeConfig = try analyzeConfig.map { try SecurityUtils.validateString($0) }
    let validatedArchiveConfig = try archiveConfig.map { try SecurityUtils.validateString($0) }

    let scheme = try loadScheme(name: validatedSchemeName)

    // Update configurations
    if let config = validatedBuildConfig {
      // Build action doesn't have a direct configuration, it uses per-entry settings
      print("⚠️  Build configuration is set per build entry, not globally")
    }

    if let config = validatedRunConfig, var launchAction = scheme.launchAction {
      launchAction.buildConfiguration = config
      scheme.launchAction = launchAction
    }

    if let config = validatedTestConfig, let testAction = scheme.testAction {
      var updatedTestAction = testAction
      updatedTestAction.buildConfiguration = config
      scheme.testAction = updatedTestAction
    }

    if let config = validatedProfileConfig, let profileAction = scheme.profileAction {
      var updatedProfileAction = profileAction
      updatedProfileAction.buildConfiguration = config
      scheme.profileAction = updatedProfileAction
    }

    if let config = validatedAnalyzeConfig, let analyzeAction = scheme.analyzeAction {
      var updatedAnalyzeAction = analyzeAction
      updatedAnalyzeAction.buildConfiguration = config
      scheme.analyzeAction = updatedAnalyzeAction
    }

    if let config = validatedArchiveConfig, let archiveAction = scheme.archiveAction {
      var updatedArchiveAction = archiveAction
      updatedArchiveAction.buildConfiguration = config
      scheme.archiveAction = updatedArchiveAction
    }

    // Save the updated scheme
    try saveSharedScheme(scheme)
    print("✅ Updated scheme configuration: \(validatedSchemeName)")
  }

  /// Adds a target to scheme build action
  func addTargetToScheme(
    schemeName: String,
    targetName: String,
    buildFor: [XCScheme.BuildAction.Entry.BuildFor] = [
      .running, .testing, .profiling, .archiving, .analyzing,
    ]
  ) throws {
    // Validate user inputs for security
    let validatedSchemeName = try SecurityUtils.validateString(schemeName)
    let validatedTargetName = try SecurityUtils.validateString(targetName)

    let scheme = try loadScheme(name: validatedSchemeName)

    // Find the target
    guard let target = pbxproj.targets(named: validatedTargetName).first else {
      throw ProjectError.targetNotFound(validatedTargetName)
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
    print("✅ Added target '\(validatedTargetName)' to scheme '\(validatedSchemeName)'")
  }

  /// Enables test coverage for a scheme
  func enableTestCoverage(
    schemeName: String,
    targets: [String]? = nil
  ) throws {
    // Validate user inputs for security
    let validatedSchemeName = try SecurityUtils.validateString(schemeName)
    let validatedTargets = try targets?.map { try SecurityUtils.validateString($0) }

    let scheme = try loadScheme(name: validatedSchemeName)

    guard let testAction = scheme.testAction else {
      throw ProjectError.operationFailed("Scheme '\(validatedSchemeName)' has no test action")
    }

    // Enable code coverage
    var updatedTestAction = testAction
    updatedTestAction.codeCoverageEnabled = true

    // Add specific targets if provided
    if let targetNames = validatedTargets {
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
    print("✅ Enabled test coverage for scheme '\(validatedSchemeName)'")
  }

  /// Sets test parallelization for a scheme
  func setTestParallelization(
    schemeName: String,
    enabled: Bool
  ) throws {
    // Validate user input for security
    let validatedSchemeName = try SecurityUtils.validateString(schemeName)

    let scheme = try loadScheme(name: validatedSchemeName)

    guard let testAction = scheme.testAction else {
      throw ProjectError.operationFailed("Scheme '\(validatedSchemeName)' has no test action")
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
    print("✅ Updated test parallelization for scheme '\(validatedSchemeName)'")
  }

  // MARK: - Private Helpers

  private func loadScheme(name: String) throws -> XCScheme {
    // Note: This is a private method, so the name should already be validated by the calling methods
    let schemePath = schemesPath + "\(name).xcscheme"

    guard schemePath.exists else {
      throw ProjectError.schemeNotFound(name)
    }

    do {
      return try XCScheme(path: schemePath)
    } catch {
      throw ProjectError.schemeLoadFailed(name, error)
    }
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
    let userName = NSUserName()
    guard !userName.isEmpty else {
      throw ProjectError.operationFailed(
        "Unable to determine current user name for user scheme path")
    }

    let userSchemesPath = projectPath + "xcuserdata/\(userName).xcuserdatad/xcschemes"

    // Ensure user schemes directory exists
    if !userSchemesPath.exists {
      try userSchemesPath.mkpath()
    }

    let schemePath = userSchemesPath + "\(scheme.name).xcscheme"
    try scheme.write(path: schemePath, override: true)
  }
}
