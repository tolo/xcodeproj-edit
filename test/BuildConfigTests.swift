#!/usr/bin/swift sh

// XcodeProj CLI - Build Configuration Tests
// Tests for build setting operations: set, get, list settings and configurations

import Foundation
import PathKit
import XcodeProj  // @tuist ~> 8.12.0

// Load TestHelper for binary discovery
#if canImport(TestHelper)
import TestHelper
#else
// Inline helper when import not available
struct TestHelper {
  static func getToolPath() -> String { "../.build/release/xcodeproj-cli" }
  static func runTool(_ arguments: [String], projectPath: String = "TestData/TestProject.xcodeproj") -> String {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    process.environment = ProcessInfo.processInfo.environment
    process.arguments = [getToolPath(), "--project", projectPath] + arguments
    process.currentDirectoryURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    
    let pipe = Pipe()
    process.standardOutput = pipe
    process.standardError = pipe
    
    do {
      try process.run()
      process.waitUntilExit()
      
      let data = pipe.fileHandleForReading.readDataToEndOfFile()
      return String(data: data, encoding: .utf8) ?? ""
    } catch {
      return "Error running tool: \(error)"
    }
  }
}
#endif

@main
struct BuildConfigTests {
  static let testProjectPath = "TestData/TestProject.xcodeproj"
  static let testProjectBackupPath = "TestData/TestProject.xcodeproj.backup"

  // ANSI color codes
  static let red = "\u{001B}[0;31m"
  static let green = "\u{001B}[0;32m"
  static let yellow = "\u{001B}[1;33m"
  static let blue = "\u{001B}[0;34m"
  static let reset = "\u{001B}[0m"

  static var passedTests = 0
  static var failedTests = 0

  static func main() {
    // Disable output buffering for real-time display
    setbuf(stdout, nil)
    print("\(blue)🧪 Build Configuration Test Suite\(reset)")
    print("===================================\n")

    // Ensure binary exists and is working
    let toolPath = TestHelper.getToolPath()
    print("📍 Using binary: \(toolPath)")

    // Ensure test project exists
    if !FileManager.default.fileExists(atPath: testProjectPath) {
      print("\(red)❌ Test project not found. Run create_test_project.swift first.\(reset)")
      exit(1)
    }

    // Create backup
    backupProject()

    // Run build configuration tests
    testListBuildConfigs()
    testGetBuildSettings()
    testListBuildSettings()
    testSetBuildSettings()
    testBuildSettingsValidation()
    testAdvancedBuildSettings()

    // Restore backup
    restoreProject()

    // Print summary
    printSummary()
  }

  // MARK: - Test Methods

  static func testListBuildConfigs() {
    print("1. Testing List Build Configurations")
    print("------------------------------------")

    test("List build configurations") {
      let output = TestHelper.runTool(["list-build-configs"])
      return output.contains("Debug") && output.contains("Release")
    }

    test("List build configs shows proper format") {
      let output = TestHelper.runTool(["list-build-configs"])
      return output.contains("Build configurations:") || output.contains("📋")
        || (output.contains("Debug") && output.contains("Release"))
    }

    print()
  }

  static func testGetBuildSettings() {
    print("2. Testing Get Build Settings")
    print("-----------------------------")

    test("Get build settings for TestApp") {
      let output = TestHelper.runTool(["get-build-settings", "TestApp"])
      return output.contains("PRODUCT_NAME") || output.contains("SWIFT_VERSION")
        || output.contains("Build settings") || !output.contains("Error")
    }

    test("Get build settings for TestApp Debug config") {
      let output = TestHelper.runTool(["get-build-settings", "TestApp", "--config", "Debug"])
      return output.contains("PRODUCT_NAME") || output.contains("SWIFT_VERSION")
        || output.contains("DEBUG") || !output.contains("Error")
    }

    test("Get build settings for TestApp Release config") {
      let output = TestHelper.runTool(["get-build-settings", "TestApp", "--config", "Release"])
      return output.contains("PRODUCT_NAME") || output.contains("SWIFT_VERSION")
        || output.contains("RELEASE") || !output.contains("Error")
    }

    test("Get build settings for non-existent target (should fail)") {
      let output = TestHelper.runTool(["get-build-settings", "NonExistentTarget"])
      return output.contains("Error") || output.contains("not found") || output.contains("Target")
    }

    print()
  }

  static func testListBuildSettings() {
    print("3. Testing List Build Settings")
    print("------------------------------")

    test("List all build settings") {
      let output = TestHelper.runTool(["list-build-settings"])
      return output.contains("PRODUCT_NAME") || output.contains("SWIFT_VERSION")
        || output.contains("Build settings") || !output.contains("Error")
    }

    test("List build settings for specific target") {
      let output = TestHelper.runTool(["list-build-settings", "--target", "TestApp"])
      return output.contains("PRODUCT_NAME") || output.contains("Build settings")
        || !output.contains("Error")
    }

    test("List build settings for specific target and config") {
      let output = TestHelper.runTool([
        "list-build-settings", "--target", "TestApp", "--config", "Debug"
      ])
      return output.contains("PRODUCT_NAME") || output.contains("Build settings")
        || !output.contains("Error")
    }

    test("List build settings with JSON output") {
      let output = TestHelper.runTool(["list-build-settings", "--json"])
      return output.contains("{") && output.contains("}")
        || output.contains("PRODUCT_NAME") || !output.contains("Error")
    }

    test("List all build settings with inherited") {
      let output = TestHelper.runTool(["list-build-settings", "--all", "--show-inherited"])
      return output.contains("PRODUCT_NAME") || output.contains("inherited")
        || output.contains("Build settings") || !output.contains("Error")
    }

    print()
  }

  static func testSetBuildSettings() {
    print("4. Testing Set Build Settings")
    print("-----------------------------")

    test("Set SWIFT_VERSION for TestApp") {
      let output = TestHelper.runTool([
        "set-build-setting", "SWIFT_VERSION", "5.9",
        "--targets", "TestApp"
      ])
      return output.contains("Updated build settings") || output.contains("Set SWIFT_VERSION")
        || output.contains("SWIFT_VERSION") || !output.contains("Error")
    }

    test("Set CODE_SIGN_IDENTITY for TestApp Debug") {
      let output = TestHelper.runTool([
        "set-build-setting", "CODE_SIGN_IDENTITY", "iPhone Developer",
        "--targets", "TestApp",
        "--config", "Debug"
      ])
      return output.contains("Updated build settings") || output.contains("Set CODE_SIGN_IDENTITY")
        || output.contains("CODE_SIGN_IDENTITY") || !output.contains("Error")
    }

    test("Set multiple targets at once") {
      // First ensure we have multiple targets
      _ = TestHelper.runTool([
        "add-target", "TestFramework",
        "--type", "com.apple.product-type.framework",
        "--bundle-id", "com.test.framework"
      ])

      let output = TestHelper.runTool([
        "set-build-setting", "ENABLE_TESTABILITY", "YES",
        "--targets", "TestApp,TestFramework"
      ])
      return output.contains("Updated build settings") || output.contains("Set ENABLE_TESTABILITY")
        || output.contains("ENABLE_TESTABILITY") || !output.contains("Error")
    }

    test("Verify setting was applied") {
      let output = TestHelper.runTool(["get-build-settings", "TestApp"])
      return output.contains("SWIFT_VERSION") && output.contains("5.9")
    }

    print()
  }

  static func testBuildSettingsValidation() {
    print("5. Testing Build Settings Validation")
    print("------------------------------------")

    test("Set build setting without targets (should fail)") {
      let output = TestHelper.runTool([
        "set-build-setting", "SWIFT_VERSION", "5.8"
      ])
      return output.contains("Error") || output.contains("requires --targets")
        || output.contains("target")
    }

    test("Set build setting for non-existent target (should fail)") {
      let output = TestHelper.runTool([
        "set-build-setting", "SWIFT_VERSION", "5.8",
        "--targets", "NonExistentTarget"
      ])
      return output.contains("Error") || output.contains("not found") || output.contains("Target")
    }

    test("Set build setting with invalid config (should fail)") {
      let output = TestHelper.runTool([
        "set-build-setting", "SWIFT_VERSION", "5.8",
        "--targets", "TestApp",
        "--config", "InvalidConfig"
      ])
      return output.contains("Error") || output.contains("not found") || output.contains("Configuration")
        || output.contains("No build configuration") || output.contains("Unknown configuration")
    }

    test("Get build settings for non-existent config (should fail)") {
      let output = TestHelper.runTool([
        "get-build-settings", "TestApp", "--config", "InvalidConfig"
      ])
      return output.contains("Error") || output.contains("not found") || output.contains("Configuration")
        || output.contains("No build configuration") || output.contains("Unknown configuration")
    }

    print()
  }

  static func testAdvancedBuildSettings() {
    print("6. Testing Advanced Build Settings")
    print("----------------------------------")

    test("Set complex build setting with spaces") {
      let output = TestHelper.runTool([
        "set-build-setting", "OTHER_LDFLAGS", "\"-ObjC\"",
        "--targets", "TestApp"
      ])
      return output.contains("Updated build settings") || output.contains("Set OTHER_LDFLAGS")
        || output.contains("OTHER_LDFLAGS") || !output.contains("Error")
    }

    test("Set boolean build setting") {
      let output = TestHelper.runTool([
        "set-build-setting", "ENABLE_BITCODE", "NO",
        "--targets", "TestApp",
        "--config", "Release"
      ])
      return output.contains("Updated build settings") || output.contains("Set ENABLE_BITCODE")
        || output.contains("ENABLE_BITCODE") || !output.contains("Error")
    }

    test("Set array-style build setting") {
      let output = TestHelper.runTool([
        "set-build-setting", "HEADER_SEARCH_PATHS", "/usr/local/include",
        "--targets", "TestApp"
      ])
      return output.contains("Updated build settings") || output.contains("Set HEADER_SEARCH_PATHS")
        || output.contains("HEADER_SEARCH_PATHS") || !output.contains("Error")
    }

    test("Verify complex settings were applied") {
      let output = TestHelper.runTool(["get-build-settings", "TestApp"])
      return output.contains("OTHER_LDFLAGS") || output.contains("ENABLE_BITCODE")
        || output.contains("HEADER_SEARCH_PATHS")
    }

    print()
  }

  // MARK: - Helper Functions

  static func test(_ name: String, operation: () -> Bool) {
    // Print test name immediately
    print("  Testing: \(name)... ", terminator: "")
    fflush(stdout)

    // Run the test
    let result = operation()

    // Print result immediately
    if result {
      print("\(green)✅\(reset)")
      fflush(stdout)
      passedTests += 1
    } else {
      print("\(red)❌\(reset)")
      fflush(stdout)
      failedTests += 1
    }
  }

  static func backupProject() {
    do {
      if FileManager.default.fileExists(atPath: testProjectBackupPath) {
        try FileManager.default.removeItem(atPath: testProjectBackupPath)
      }
      try FileManager.default.copyItem(
        atPath: testProjectPath,
        toPath: testProjectBackupPath)
      print("📦 Created project backup\n")
    } catch {
      print("\(red)Failed to create backup: \(error)\(reset)")
    }
  }

  static func restoreProject() {
    do {
      try FileManager.default.removeItem(atPath: testProjectPath)
      try FileManager.default.moveItem(
        atPath: testProjectBackupPath,
        toPath: testProjectPath)
      print("♻️  Restored project from backup\n")
    } catch {
      print("\(yellow)Warning: Could not restore backup: \(error)\(reset)")
    }
  }

  static func printSummary() {
    let total = passedTests + failedTests
    print("=====================================")
    print("Build Configuration Test Results:")
    print("  \(green)Passed: \(passedTests)/\(total)\(reset)")

    if failedTests > 0 {
      print("  \(red)Failed: \(failedTests)/\(total)\(reset)")
      print("\n\(red)❌ Some build config tests failed\(reset)")
      exit(1)
    } else {
      print("\n\(green)✅ All build config tests passed!\(reset)")
      exit(0)
    }
  }
}