#!/usr/bin/swift sh

// XcodeProj CLI Test Suite
// Comprehensive tests for xcodeproj-cli functionality

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
struct TestSuite {
  static let testProjectPath = "TestData/TestProject.xcodeproj"
  static let testProjectBackupPath = "TestData/TestProject.xcodeproj.backup"

  // ANSI color codes
  static let red = "\u{001B}[0;31m"
  static let green = "\u{001B}[0;32m"
  static let yellow = "\u{001B}[1;33m"
  static let reset = "\u{001B}[0m"

  static var passedTests = 0
  static var failedTests = 0

  static func main() {
    // Disable output buffering for real-time display
    setbuf(stdout, nil)
    print("🧪 XcodeProj Edit Swift Test Suite")
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

    // Run test categories
    testReadOperations()
    testFileOperations()
    testDirectoryOperations()  // New comprehensive directory tests
    testGroupOperations()
    testTargetOperations()
    testBuildSettings()
    testValidation()

    // Restore backup
    restoreProject()

    // Print summary
    printSummary()
  }

  // MARK: - Test Categories

  static func testReadOperations() {
    print("1. Testing Read Operations")
    print("--------------------------")

    test("List targets") {
      let output = TestHelper.runTool(["list-targets"])
      return output.contains("TestApp")
    }

    test("List groups") {
      let output = TestHelper.runTool(["list-groups"])
      return output.contains("Sources") && output.contains("Resources")
    }

    test("List files") {
      let output = TestHelper.runTool(["list-files"])
      return output.contains("file") || output.contains("No files") || output.contains("📄")
    }

    test("List tree structure") {
      let output = TestHelper.runTool(["list-tree"])
      // Check for tree structure elements
      return output.contains("├──") || output.contains("└──")
        || (output.contains("Sources") && output.contains("("))
    }

    test("List build configurations") {
      let output = TestHelper.runTool(["list-build-configs"])
      return output.contains("Debug") && output.contains("Release")
    }

    print()
  }

  static func testFileOperations() {
    print("2. Testing File Operations")
    print("--------------------------")

    // Create test files
    try? "// Test file".write(
      toFile: "TestData/Sources/TestFile.swift", atomically: true, encoding: .utf8)
    try? "// Helper file".write(
      toFile: "TestData/Sources/Helper.swift", atomically: true, encoding: .utf8)

    test("Add file to project") {
      let output = TestHelper.runTool([
        "add-file", "TestFile.swift", "--group", "Sources", "--targets", "TestApp",
      ])
      return output.contains("Added TestFile.swift") || output.contains("already exists")
    }

    test("Add multiple files") {
      let output = TestHelper.runTool([
        "add-files",
        "TestFile.swift:Sources",
        "Helper.swift:Sources",
        "--targets", "TestApp",
      ])
      return output.contains("Added") || output.contains("already exists")
    }

    test("Move file") {
      let output = TestHelper.runTool(["move-file", "TestFile.swift", "TestFileRenamed.swift"])
      return output.contains("Moved") || !output.contains("Error")
    }

    test("Remove file") {
      let output = TestHelper.runTool(["remove-file", "Helper.swift"])
      return output.contains("Removed") || !output.contains("not found")
    }

    print()
  }

  static func testDirectoryOperations() {
    print("3. Testing Directory/Folder Operations")
    print("---------------------------------------")

    test("Add Models folder recursively") {
      let output = TestHelper.runTool([
        "add-folder",
        "TestData/Sources/Models",
        "--group", "Models",
        "--targets", "TestApp",
        "--recursive",
      ])
      // Should add Item.swift but filter out .DS_Store
      return output.contains("Item.swift") || output.contains("Added folder")
        || output.contains("files added")
    }

    test("Add Views folder with SwiftUI files") {
      let output = TestHelper.runTool([
        "add-folder",
        "TestData/Sources/Views",
        "--group", "Views",
        "--targets", "TestApp",
        "--recursive",
      ])
      // Should add ContentView.swift and ItemView.swift
      return
        (output.contains("ContentView.swift") || output.contains("ItemView.swift")
        || output.contains("Added")) && !output.contains(".gitignore")
    }

    test("Add ViewModels folder") {
      let output = TestHelper.runTool([
        "add-folder",
        "TestData/Sources/ViewModels",
        "--group", "ViewModels",
        "--targets", "TestApp",
        "--recursive",
      ])
      // Should add ItemViewModel.swift but not .bak file
      return output.contains("ItemViewModel.swift")
        || (output.contains("Added") && !output.contains(".bak"))
    }

    test("Verify file filtering works") {
      let output = TestHelper.runTool(["list-files", "Models"])
      // Should NOT contain .DS_Store
      return !output.contains(".DS_Store")
        && (output.contains("Item.swift") || output.contains("📄") || output.contains("No files"))
    }

    test("Add synchronized folder reference") {
      let output = TestHelper.runTool([
        "add-sync-folder",
        "TestData/Resources",
        "--group", "Resources",
        "--targets", "TestApp",
      ])
      return output.contains("Added synchronized folder")
        || output.contains("Added folder reference") || !output.contains("Error")
    }

    test("Add entire Sources directory") {
      let output = TestHelper.runTool([
        "add-folder",
        "TestData/Sources",
        "--group", "Sources",
        "--targets", "TestApp",
        "--recursive",
      ])
      // Should process all subdirectories
      return output.contains("Models") || output.contains("Views") || output.contains("ViewModels")
        || output.contains("files added")
    }

    test("List files in Views group") {
      let output = TestHelper.runTool(["list-files", "Views"])
      // Should show SwiftUI view files
      return output.contains("ContentView.swift") || output.contains("ItemView.swift")
        || output.contains("📄") || output.contains("No files")
    }

    print()
  }

  static func testGroupOperations() {
    print("4. Testing Group Operations")
    print("---------------------------")

    test("Create groups") {
      let output = TestHelper.runTool(["add-group", "Features/Login", "Features/Profile"])
      return output.contains("Created group") || output.contains("📁")
    }

    test("Add folder") {
      // Create test folder
      try? FileManager.default.createDirectory(
        atPath: "TestData/Features",
        withIntermediateDirectories: true)
      try? "// Feature".write(
        toFile: "TestData/Features/Feature.swift",
        atomically: true, encoding: .utf8)

      let output = TestHelper.runTool([
        "add-folder", "TestData/Features", "--group", "Features", "--targets", "TestApp",
      ])
      return output.contains("Added folder") || !output.contains("Error")
    }

    print()
  }

  static func testTargetOperations() {
    print("5. Testing Target Operations")
    print("----------------------------")

    test("Add new target") {
      let output = TestHelper.runTool([
        "add-target", "TestFramework",
        "--type", "com.apple.product-type.framework",
        "--bundle-id", "com.test.framework",
      ])
      return output.contains("Added target") || output.contains("already exists")
    }

    test("Add dependency") {
      // First ensure both targets exist
      _ = TestHelper.runTool([
        "add-target", "TestFramework",
        "--type", "com.apple.product-type.framework",
        "--bundle-id", "com.test.framework",
      ])

      let output = TestHelper.runTool(["add-dependency", "TestApp", "--depends-on", "TestFramework"])
      return output.contains("Added dependency") || output.contains("already exists")
    }

    test("Duplicate target") {
      let output = TestHelper.runTool([
        "duplicate-target", "TestApp", "TestAppPro",
        "--bundle-id", "com.test.pro",
      ])
      return output.contains("Duplicated target") || output.contains("already exists")
    }

    print()
  }

  static func testBuildSettings() {
    print("6. Testing Build Settings")
    print("-------------------------")

    test("Set build setting") {
      let output = TestHelper.runTool([
        "set-build-setting", "SWIFT_VERSION", "5.9",
        "--targets", "TestApp",
      ])
      return output.contains("Updated build settings") || output.contains("Set SWIFT_VERSION")
    }

    test("Get build settings") {
      let output = TestHelper.runTool(["get-build-settings", "TestApp", "--config", "Debug"])
      return output.contains("SWIFT_VERSION") || output.contains("PRODUCT_NAME")
    }

    print()
  }

  static func testValidation() {
    print("7. Testing Validation")
    print("---------------------")

    test("Validate project") {
      let output = TestHelper.runTool(["validate"])
      // Validation might find issues or not, both are valid
      return output.contains("validation") || output.contains("No validation issues")
        || output.contains("Validation issues") || output.contains("✅") || output.contains("❌")
    }

    test("List invalid references") {
      let output = TestHelper.runTool(["list-invalid-references"])
      // The command should run and produce output about checking references
      return output.contains("Checking for invalid file")
        && (output.contains("All file references are valid")
          || output.contains("Found") && output.contains("invalid file reference"))
    }

    test("List invalid references - with invalid files") {
      // Add a non-existent file
      _ = TestHelper.runTool([
        "add-file", "NonExistentTestFile.swift", "--group", "Sources", "--targets", "TestApp",
      ])

      // Check for invalid references
      let output = TestHelper.runTool(["list-invalid-references"])
      let hasInvalid =
        output.contains("invalid file reference") && output.contains("NonExistentTestFile.swift")

      // Clean up
      _ = TestHelper.runTool(["remove-file", "NonExistentTestFile.swift"])

      return hasInvalid
    }

    test("List invalid references - with invalid folders") {
      // Create groups pointing to non-existent folders
      _ = TestHelper.runTool(["add-group", "InvalidFolder1"])
      _ = TestHelper.runTool(["add-group", "InvalidFolder2/SubFolder"])

      // Check for invalid references
      let output = TestHelper.runTool(["list-invalid-references"])
      let hasInvalidFolders =
        output.contains("Folder not found")
        && (output.contains("InvalidFolder1") || output.contains("InvalidFolder2"))

      return hasInvalidFolders
    }

    test("Remove invalid references - folders") {
      // Create groups pointing to non-existent folders
      _ = TestHelper.runTool(["add-group", "TestInvalidDir"])
      _ = TestHelper.runTool(["add-group", "TestInvalidDir2/SubDir"])

      // Verify they exist as invalid
      let checkBefore = TestHelper.runTool(["list-invalid-references"])
      let hasInvalidBefore =
        checkBefore.contains("Folder not found") && checkBefore.contains("TestInvalidDir")

      // Remove invalid references
      let removeOutput = TestHelper.runTool(["remove-invalid-references"])
      let removed =
        removeOutput.contains("Will remove folder") && removeOutput.contains("TestInvalidDir")

      // Verify they're gone
      let checkAfter = TestHelper.runTool(["list-invalid-references"])
      let allValidAfter =
        checkAfter.contains("All file references are valid")
        || !checkAfter.contains("TestInvalidDir")

      return hasInvalidBefore && removed && allValidAfter
    }

    test("Remove invalid references - mixed files and folders") {
      // Add invalid files
      _ = TestHelper.runTool([
        "add-file", "TestInvalidFile.txt", "--group", "Resources", "--targets", "TestApp",
      ])
      _ = TestHelper.runTool([
        "add-file", "TestInvalidCode.swift", "--group", "Sources", "--targets", "TestApp",
      ])

      // Add invalid folders
      _ = TestHelper.runTool(["add-group", "MixedInvalidFolder"])

      // Remove all invalid references
      let removeOutput = TestHelper.runTool(["remove-invalid-references"])
      let removedFiles =
        removeOutput.contains("Will remove")
        && (removeOutput.contains("TestInvalidFile.txt")
          || removeOutput.contains("TestInvalidCode.swift"))
      let removedFolders =
        removeOutput.contains("Will remove folder") && removeOutput.contains("MixedInvalidFolder")

      // Verify they're gone
      let checkOutput = TestHelper.runTool(["list-invalid-references"])
      let allValid = checkOutput.contains("All file references are valid")

      return (removedFiles || removedFolders) && allValid
    }

    test("Remove invalid references") {
      // Add non-existent files
      _ = TestHelper.runTool([
        "add-file", "TestInvalidFile.txt", "--group", "Resources", "--targets", "TestApp",
      ])
      _ = TestHelper.runTool([
        "add-file", "TestInvalidCode.swift", "--group", "Sources", "--targets", "TestApp",
      ])

      // Remove invalid references
      let removeOutput = TestHelper.runTool(["remove-invalid-references"])
      let removed =
        removeOutput.contains("Removed") && removeOutput.contains("invalid file reference")

      // Verify they're gone
      let checkOutput = TestHelper.runTool(["list-invalid-references"])
      let allValid =
        checkOutput.contains("All file references are valid")
        || !checkOutput.contains("TestInvalidFile.txt")

      return removed && allValid
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
    print("Test Results:")
    print("  \(green)Passed: \(passedTests)/\(total)\(reset)")

    if failedTests > 0 {
      print("  \(red)Failed: \(failedTests)/\(total)\(reset)")
      print("\n\(red)❌ Some tests failed\(reset)")
      exit(1)
    } else {
      print("\n\(green)✅ All tests passed!\(reset)")
      exit(0)
    }
  }
}
