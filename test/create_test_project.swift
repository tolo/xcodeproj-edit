#!/usr/bin/swift sh

// Creates a minimal test Xcode project for testing xcodeproj-cli
// Note: This only creates the .xcodeproj file. Test source files should
// already exist in TestData/Sources, TestData/Resources, etc.

import Foundation
import PathKit
import XcodeProj  // @tuist ~> 8.12.0

@main
struct TestProjectCreator {
  static func createTestProject() throws {
    let projectPath = Path("TestData/TestProject.xcodeproj")

    // Create build configurations
    let debugConfig = XCBuildConfiguration(
      name: "Debug",
      buildSettings: [
        "PRODUCT_NAME": "$(TARGET_NAME)",
        "SWIFT_VERSION": "5.0",
        "ALWAYS_SEARCH_USER_PATHS": "NO",
        "CLANG_ANALYZER_NONNULL": "YES",
        "CLANG_ANALYZER_NUMBER_OBJECT_CONVERSION": "YES_AGGRESSIVE",
        "CLANG_CXX_LANGUAGE_STANDARD": "gnu++20",
        "CLANG_ENABLE_MODULES": "YES",
        "CLANG_ENABLE_OBJC_ARC": "YES",
        "CLANG_ENABLE_OBJC_WEAK": "YES",
        "CLANG_WARN_DOCUMENTATION_COMMENTS": "YES",
        "CLANG_WARN_UNGUARDED_AVAILABILITY": "YES_AGGRESSIVE",
        "DEBUG_INFORMATION_FORMAT": "dwarf",
        "ENABLE_STRICT_OBJC_MSGSEND": "YES",
        "ENABLE_TESTABILITY": "YES",
        "GCC_C_LANGUAGE_STANDARD": "gnu11",
        "GCC_DYNAMIC_NO_PIC": "NO",
        "GCC_NO_COMMON_BLOCKS": "YES",
        "GCC_OPTIMIZATION_LEVEL": "0",
        "GCC_WARN_ABOUT_RETURN_TYPE": "YES_ERROR",
        "GCC_WARN_UNDECLARED_SELECTOR": "YES",
        "GCC_WARN_UNINITIALIZED_AUTOS": "YES_AGGRESSIVE",
        "GCC_WARN_UNUSED_FUNCTION": "YES",
        "GCC_WARN_UNUSED_VARIABLE": "YES",
        "MTL_ENABLE_DEBUG_INFO": "INCLUDE_SOURCE",
        "MTL_FAST_MATH": "YES",
        "ONLY_ACTIVE_ARCH": "YES",
        "SWIFT_ACTIVE_COMPILATION_CONDITIONS": "DEBUG",
        "SWIFT_OPTIMIZATION_LEVEL": "-Onone",
      ]
    )

    let releaseConfig = XCBuildConfiguration(
      name: "Release",
      buildSettings: [
        "PRODUCT_NAME": "$(TARGET_NAME)",
        "SWIFT_VERSION": "5.0",
        "ALWAYS_SEARCH_USER_PATHS": "NO",
        "CLANG_ANALYZER_NONNULL": "YES",
        "CLANG_ANALYZER_NUMBER_OBJECT_CONVERSION": "YES_AGGRESSIVE",
        "CLANG_CXX_LANGUAGE_STANDARD": "gnu++20",
        "CLANG_ENABLE_MODULES": "YES",
        "CLANG_ENABLE_OBJC_ARC": "YES",
        "CLANG_ENABLE_OBJC_WEAK": "YES",
        "CLANG_WARN_DOCUMENTATION_COMMENTS": "YES",
        "CLANG_WARN_UNGUARDED_AVAILABILITY": "YES_AGGRESSIVE",
        "COPY_PHASE_STRIP": "NO",
        "DEBUG_INFORMATION_FORMAT": "dwarf-with-dsym",
        "ENABLE_NS_ASSERTIONS": "NO",
        "ENABLE_STRICT_OBJC_MSGSEND": "YES",
        "GCC_C_LANGUAGE_STANDARD": "gnu11",
        "GCC_NO_COMMON_BLOCKS": "YES",
        "GCC_WARN_ABOUT_RETURN_TYPE": "YES_ERROR",
        "GCC_WARN_UNDECLARED_SELECTOR": "YES",
        "GCC_WARN_UNINITIALIZED_AUTOS": "YES_AGGRESSIVE",
        "GCC_WARN_UNUSED_FUNCTION": "YES",
        "GCC_WARN_UNUSED_VARIABLE": "YES",
        "MTL_ENABLE_DEBUG_INFO": "NO",
        "MTL_FAST_MATH": "YES",
        "SWIFT_COMPILATION_MODE": "wholemodule",
        "SWIFT_OPTIMIZATION_LEVEL": "-O",
        "VALIDATE_PRODUCT": "YES",
      ]
    )

    let pbxproj = PBXProj()
    pbxproj.add(object: debugConfig)
    pbxproj.add(object: releaseConfig)

    let projectConfigList = XCConfigurationList(
      buildConfigurations: [debugConfig, releaseConfig],
      defaultConfigurationName: "Release"
    )
    pbxproj.add(object: projectConfigList)

    // Create main group
    let mainGroup = PBXGroup(children: [], sourceTree: .group)
    pbxproj.add(object: mainGroup)

    // Create project
    let project = PBXProject(
      name: "TestProject",
      buildConfigurationList: projectConfigList,
      compatibilityVersion: "Xcode 14.0",
      preferredProjectObjectVersion: nil,
      minimizedProjectReferenceProxies: nil,
      mainGroup: mainGroup,
      developmentRegion: "en",
      hasScannedForEncodings: 0,
      knownRegions: ["en", "Base"],
      productsGroup: nil,
      projectDirPath: "",
      projects: [],
      projectRoots: [],
      targets: [],
      packages: []
    )

    // Create Sources group
    let sourcesGroup = PBXGroup(children: [], sourceTree: .group, name: "Sources", path: "Sources")
    pbxproj.add(object: sourcesGroup)
    mainGroup.children.append(sourcesGroup)

    // Create Resources group
    let resourcesGroup = PBXGroup(
      children: [], sourceTree: .group, name: "Resources", path: "Resources")
    pbxproj.add(object: resourcesGroup)
    mainGroup.children.append(resourcesGroup)

    // Create Tests group
    let testsGroup = PBXGroup(children: [], sourceTree: .group, name: "Tests", path: "Tests")
    pbxproj.add(object: testsGroup)
    mainGroup.children.append(testsGroup)

    // Create a sample target
    let targetDebugConfig = XCBuildConfiguration(
      name: "Debug",
      buildSettings: [
        "BUNDLE_IDENTIFIER": "com.test.TestApp",
        "PRODUCT_NAME": "$(TARGET_NAME)",
        "SWIFT_VERSION": "5.0",
        "IPHONEOS_DEPLOYMENT_TARGET": "15.0",
        "TARGETED_DEVICE_FAMILY": "1,2",
      ]
    )

    let targetReleaseConfig = XCBuildConfiguration(
      name: "Release",
      buildSettings: [
        "BUNDLE_IDENTIFIER": "com.test.TestApp",
        "PRODUCT_NAME": "$(TARGET_NAME)",
        "SWIFT_VERSION": "5.0",
        "IPHONEOS_DEPLOYMENT_TARGET": "15.0",
        "TARGETED_DEVICE_FAMILY": "1,2",
      ]
    )

    pbxproj.add(object: targetDebugConfig)
    pbxproj.add(object: targetReleaseConfig)

    let targetConfigList = XCConfigurationList(
      buildConfigurations: [targetDebugConfig, targetReleaseConfig],
      defaultConfigurationName: "Release"
    )
    pbxproj.add(object: targetConfigList)

    // Create build phases
    let sourcesBuildPhase = PBXSourcesBuildPhase()
    let resourcesBuildPhase = PBXResourcesBuildPhase()
    let frameworksBuildPhase = PBXFrameworksBuildPhase()

    pbxproj.add(object: sourcesBuildPhase)
    pbxproj.add(object: resourcesBuildPhase)
    pbxproj.add(object: frameworksBuildPhase)

    // Create app target
    let appTarget = PBXNativeTarget(
      name: "TestApp",
      buildConfigurationList: targetConfigList,
      buildPhases: [sourcesBuildPhase, frameworksBuildPhase, resourcesBuildPhase],
      buildRules: [],
      dependencies: [],
      productInstallPath: nil,
      productName: "TestApp",
      productType: PBXProductType.application
    )

    pbxproj.add(object: appTarget)
    project.targets.append(appTarget)

    // Add the project
    pbxproj.add(object: project)
    pbxproj.rootObject = project

    // Create the XcodeProj
    let workspace = XCWorkspace(data: XCWorkspaceData(children: []))
    let xcodeproj = XcodeProj(workspace: workspace, pbxproj: pbxproj)

    // Ensure TestData directory exists
    try FileManager.default.createDirectory(
      at: URL(fileURLWithPath: "TestData"),
      withIntermediateDirectories: true)

    // Write project to disk
    try xcodeproj.write(path: projectPath)
    print("✅ Created test project at: \(projectPath)")

    // Verify expected directories exist
    let sourcesDir = "TestData/Sources"
    let resourcesDir = "TestData/Resources"
    let testsDir = "TestData/Tests"

    if !FileManager.default.fileExists(atPath: sourcesDir) {
      print("⚠️  Warning: Sources directory not found at \(sourcesDir)")
      print("   Please ensure test data files are present in the repository")
    }

    if !FileManager.default.fileExists(atPath: resourcesDir) {
      print("⚠️  Warning: Resources directory not found at \(resourcesDir)")
    }

    if !FileManager.default.fileExists(atPath: testsDir) {
      print("⚠️  Warning: Tests directory not found at \(testsDir)")
    }
  }

  static func main() {
    do {
      try createTestProject()
    } catch {
      print("❌ Error: \(error)")
      exit(1)
    }
  }
}
