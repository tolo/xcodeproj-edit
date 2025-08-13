#!/usr/bin/swift sh

// Additional Tests for xcodeproj-cli
// Tests for edge cases and missing coverage areas

import Foundation
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
struct AdditionalTests {
  static let testProjectPath = "TestData/TestProject.xcodeproj"

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
    print("🧩 Additional Edge Case Tests")
    print("==============================\n")

    // Ensure binary exists and is working
    let toolPath = TestHelper.getToolPath()
    print("📍 Using binary: \(toolPath)")

    testArgumentParsing()
    testSwiftPackageOperations()
    testSpecialFileNames()
    testBuildPhaseOperations()
    testUpdateCommands()

    printSummary()
  }

  // MARK: - Test Categories

  static func testArgumentParsing() {
    print("1. Argument Parsing Edge Cases")
    print("-------------------------------")

    test("Short flags work correctly") {
      let output = TestHelper.runTool([
        "add-file", "test.swift", "-g", "Sources", "-t", "TestApp", "--dry-run",
      ])
      return !output.contains("Error") && output.contains("DRY RUN")
    }

    test("Mixed short and long flags") {
      let output = TestHelper.runTool([
        "add-file", "test.swift", "--group", "Sources", "-t", "TestApp", "--dry-run",
      ])
      return !output.contains("Error") && output.contains("DRY RUN")
    }

    test("Empty flag values rejected") {
      let output = TestHelper.runTool(["add-file", "test.swift", "--group", "", "--targets", "TestApp"])
      return output.contains("Error") || output.contains("Invalid")
    }

    test("Multiple targets with comma separation") {
      let output = TestHelper.runTool([
        "add-file", "test.swift", "--group", "Sources", "--targets", "App1,App2,App3", "--dry-run",
      ])
      return !output.contains("Error")
    }

    test("Recursive flag with add-folder") {
      let output = TestHelper.runTool([
        "add-folder", "TestData/Sources", "--group", "Sources", "--targets", "TestApp", "-r",
        "--dry-run",
      ])
      return !output.contains("Error")
    }

    print()
  }

  static func testSwiftPackageOperations() {
    print("2. Swift Package Manager Operations")
    print("------------------------------------")

    test("List Swift packages command") {
      let output = TestHelper.runTool(["list-swift-packages"])
      // Should either list packages or say no packages found
      return !output.contains("Error")
        && (output.contains("packages") || output.contains("No Swift packages"))
    }

    test("Package with exact version") {
      let output = TestHelper.runTool([
        "add-swift-package",
        "https://github.com/Alamofire/Alamofire",
        "--version", "exact: 5.8.0",
        "--target", "TestApp",
        "--dry-run",
      ])
      return !output.contains("Invalid")
    }

    test("Package with version range") {
      let output = TestHelper.runTool([
        "add-swift-package",
        "https://github.com/SwiftyJSON/SwiftyJSON",
        "--version", "5.0.0..<6.0.0",
        "--target", "TestApp",
        "--dry-run",
      ])
      return !output.contains("Invalid")
    }

    test("Package with tag requirement") {
      let output = TestHelper.runTool([
        "add-swift-package",
        "https://github.com/test/test",
        "--version", "tag: v1.0.0",
        "--dry-run",
      ])
      return !output.contains("Invalid version")
    }

    test("Remove Swift package") {
      let output = TestHelper.runTool([
        "remove-swift-package",
        "https://github.com/Alamofire/Alamofire",
      ])
      // Should either remove or say not found
      return !output.contains("Error") || output.contains("not found")
    }

    print()
  }

  static func testSpecialFileNames() {
    print("3. Special File Name Handling")
    print("------------------------------")

    test("File with spaces in name") {
      let output = TestHelper.runTool([
        "add-file", "Test File With Spaces.swift",
        "--group", "Sources",
        "--targets", "TestApp",
        "--dry-run",
      ])
      return !output.contains("Error")
    }

    test("File with Unicode characters") {
      let output = TestHelper.runTool([
        "add-file", "测试文件.swift",
        "--group", "Sources",
        "--targets", "TestApp",
        "--dry-run",
      ])
      return !output.contains("Error")
    }

    test("File with emoji in name") {
      let output = TestHelper.runTool([
        "add-file", "🚀Rocket.swift",
        "--group", "Sources",
        "--targets", "TestApp",
        "--dry-run",
      ])
      return !output.contains("Error")
    }

    test("Very long file path") {
      let longPath =
        "Very/Long/Path/With/Many/Nested/Directories/That/Exceeds/Normal/Length/file.swift"
      let output = TestHelper.runTool([
        "add-file", longPath,
        "--group", "Sources",
        "--targets", "TestApp",
        "--dry-run",
      ])
      return !output.contains("Error")
    }

    print()
  }

  static func testBuildPhaseOperations() {
    print("4. Build Phase Operations")
    print("-------------------------")

    test("Add copy files build phase") {
      let output = TestHelper.runTool([
        "add-build-phase", "copy_files", "Copy Resources",
        "--target", "TestApp",
        "--dry-run",
      ])
      return !output.contains("Error")
    }

    test("Add multiple script phases") {
      let output1 = TestHelper.runTool([
        "add-build-phase", "run_script", "SwiftLint",
        "--target", "TestApp",
        "--script", "swiftlint",
        "--dry-run",
      ])
      let output2 = TestHelper.runTool([
        "add-build-phase", "run_script", "SwiftGen",
        "--target", "TestApp",
        "--script", "swiftgen",
        "--dry-run",
      ])
      return !output1.contains("Error") && !output2.contains("Error")
    }

    test("Build phase with empty script allowed") {
      let output = TestHelper.runTool([
        "add-build-phase", "run_script", "Empty",
        "--target", "TestApp",
        "--script", "",
        "--dry-run",
      ])
      // Empty scripts are allowed - some phases might not need scripts
      return !output.contains("Error")
    }

    print()
  }

  static func testUpdateCommands() {
    print("5. Update Path Commands")
    print("-----------------------")

    test("Update paths with prefix") {
      let output = TestHelper.runTool([
        "update-paths", "Old/Path", "New/Path",
        "--dry-run",
      ])
      return !output.contains("Error")
    }

    test("Update paths map") {
      let output = TestHelper.runTool([
        "update-paths-map",
        "OldFile.swift:NewFile.swift",
        "Legacy.m:Modern.swift",
        "--dry-run",
      ])
      return !output.contains("Error")
    }

    test("Update paths with empty mapping rejected") {
      let output = TestHelper.runTool([
        "update-paths-map",
        "OldFile.swift:",
      ])
      return output.contains("Error") || output.contains("Invalid")
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


  static func printSummary() {
    let total = passedTests + failedTests
    print("\n=====================================")
    print("Additional Test Results:")
    print("  \(green)Passed: \(passedTests)/\(total)\(reset)")

    if failedTests > 0 {
      print("  \(red)Failed: \(failedTests)/\(total)\(reset)")
      print("\n\(red)❌ Some tests failed\(reset)")
      exit(1)
    } else {
      print("\n\(green)✅ All additional tests passed! (\(total) tests)\(reset)")
      exit(0)
    }
  }
}
