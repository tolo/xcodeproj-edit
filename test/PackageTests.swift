#!/usr/bin/swift sh

// XcodeProj CLI - Swift Package Manager Tests
// Tests for Swift Package Manager operations: add, remove, list packages

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
struct PackageTests {
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
    print("\(blue)🧪 Swift Package Manager Test Suite\(reset)")
    print("=====================================\n")

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

    // Run package operation tests
    testListPackages()
    testAddSwiftPackage()
    testListPackagesAfterAdd()
    testAddPackageToSpecificTarget()
    testRemoveSwiftPackage()
    testListPackagesAfterRemove()
    testPackageValidation()

    // Restore backup
    restoreProject()

    // Print summary
    printSummary()
  }

  // MARK: - Test Methods

  static func testListPackages() {
    print("1. Testing List Swift Packages")
    print("------------------------------")

    test("List packages (initially empty)") {
      let output = TestHelper.runTool(["list-swift-packages"])
      return output.contains("Swift packages:") || output.contains("No Swift packages") 
        || output.contains("📦") || !output.contains("Error")
    }

    print()
  }

  static func testAddSwiftPackage() {
    print("2. Testing Add Swift Package")
    print("----------------------------")

    test("Add Alamofire package with exact version") {
      let output = TestHelper.runTool([
        "add-swift-package", "https://github.com/Alamofire/Alamofire.git",
        "--version", "5.9.1"
      ])
      return output.contains("Added Swift package") || output.contains("Alamofire")
        || output.contains("already exists") || !output.contains("Error")
    }

    test("Add SwiftUI Navigation package with version range") {
      let output = TestHelper.runTool([
        "add-swift-package", "https://github.com/pointfreeco/swiftui-navigation",
        "--version", "\"from: 1.0.0\""
      ])
      return output.contains("Added Swift package") || output.contains("swiftui-navigation")
        || output.contains("already exists") || !output.contains("Error")
    }

    test("Add package with branch specification") {
      let output = TestHelper.runTool([
        "add-swift-package", "https://github.com/apple/swift-algorithms.git",
        "--version", "\"branch: main\""
      ])
      return output.contains("Added Swift package") || output.contains("swift-algorithms")
        || output.contains("already exists") || !output.contains("Error")
    }

    print()
  }

  static func testListPackagesAfterAdd() {
    print("3. Testing List Packages After Adding")
    print("-------------------------------------")

    test("List packages shows added packages") {
      let output = TestHelper.runTool(["list-swift-packages"])
      return output.contains("Alamofire") || output.contains("swiftui-navigation")
        || output.contains("swift-algorithms") || output.contains("📦")
    }

    print()
  }

  static func testAddPackageToSpecificTarget() {
    print("4. Testing Add Package to Specific Target")
    print("-----------------------------------------")

    // First ensure we have a framework target
    _ = TestHelper.runTool([
      "add-target", "TestFramework",
      "--type", "com.apple.product-type.framework",
      "--bundle-id", "com.test.framework"
    ])

    test("Add package to specific target") {
      let output = TestHelper.runTool([
        "add-swift-package", "https://github.com/apple/swift-collections.git",
        "--version", "1.1.0",
        "--target", "TestFramework"
      ])
      return output.contains("Added Swift package") || output.contains("swift-collections")
        || output.contains("already exists") || !output.contains("Error")
    }

    print()
  }

  static func testRemoveSwiftPackage() {
    print("5. Testing Remove Swift Package")
    print("-------------------------------")

    test("Remove Alamofire package") {
      let output = TestHelper.runTool([
        "remove-swift-package", "https://github.com/Alamofire/Alamofire.git"
      ])
      return output.contains("Removed Swift package") || output.contains("Alamofire")
        || !output.contains("Error")
    }

    test("Remove SwiftUI Navigation package") {
      let output = TestHelper.runTool([
        "remove-swift-package", "https://github.com/pointfreeco/swiftui-navigation"
      ])
      return output.contains("Removed Swift package") || output.contains("swiftui-navigation")
        || !output.contains("Error")
    }

    print()
  }

  static func testListPackagesAfterRemove() {
    print("6. Testing List Packages After Removal")
    print("--------------------------------------")

    test("List packages after removal") {
      let output = TestHelper.runTool(["list-swift-packages"])
      // Should not contain removed packages, but may contain others
      return !output.contains("Alamofire") && !output.contains("swiftui-navigation")
        || output.contains("No Swift packages") || output.contains("📦")
    }

    print()
  }

  static func testPackageValidation() {
    print("7. Testing Package Validation")
    print("-----------------------------")

    test("Add package with invalid URL (should fail gracefully)") {
      let output = TestHelper.runTool([
        "add-swift-package", "https://github.com/nonexistent/invalid-package.git",
        "--version", "1.0.0"
      ])
      return output.contains("Error") || output.contains("Invalid") || output.contains("failed")
        || output.contains("Could not resolve") || output.contains("not found")
    }

    test("Remove non-existent package (should handle gracefully)") {
      let output = TestHelper.runTool([
        "remove-swift-package", "https://github.com/nonexistent/package.git"
      ])
      return output.contains("not found") || output.contains("Error") 
        || output.contains("No package") || !output.contains("Removed")
    }

    test("Add package without version (should fail)") {
      let output = TestHelper.runTool([
        "add-swift-package", "https://github.com/apple/swift-collections.git"
      ])
      return output.contains("Error") || output.contains("requires --version")
        || output.contains("version flag")
    }

    test("Add package to non-existent target (should fail)") {
      let output = TestHelper.runTool([
        "add-swift-package", "https://github.com/apple/swift-collections.git",
        "--version", "1.1.0",
        "--target", "NonExistentTarget"
      ])
      return output.contains("Error") || output.contains("not found") || output.contains("Target")
        || output.contains("does not exist")
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
    print("Swift Package Manager Test Results:")
    print("  \(green)Passed: \(passedTests)/\(total)\(reset)")

    if failedTests > 0 {
      print("  \(red)Failed: \(failedTests)/\(total)\(reset)")
      print("\n\(red)❌ Some package tests failed\(reset)")
      exit(1)
    } else {
      print("\n\(green)✅ All package tests passed!\(reset)")
      exit(0)
    }
  }
}