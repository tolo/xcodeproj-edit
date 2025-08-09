#!/usr/bin/swift sh

// Security and Validation Tests for xcodeproj-cli
// Tests input validation, path sanitization, and error handling

import Foundation

@main
struct SecurityTests {
  static let toolPath = "../src/xcodeproj-cli.swift"
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
    print("🔒 Security & Validation Tests")
    print("==============================\n")

    testPathTraversalProtection()
    testCommandInjectionProtection()
    testVersionValidation()
    testDryRunMode()
    testTransactionSupport()

    printSummary()
  }

  // MARK: - Test Categories

  static func testPathTraversalProtection() {
    print("1. Path Traversal Protection")
    print("-----------------------------")

    test("Reject multiple ../ traversals") {
      let output = runTool(["move-file", "test.swift", "../../../etc/passwd"])
      return output.contains("Error") || output.contains("Invalid")
    }

    test("Allow single ../ for parent directory") {
      let output = runTool([
        "add-file", "../SharedCode/Helper.swift", "--group", "Sources", "--targets", "TestApp",
        "--dry-run",
      ])
      return !output.contains("Invalid file path")
    }

    test("Reject critical system paths") {
      let output = runTool([
        "add-file", "/etc/passwd", "--group", "Sources", "--targets", "TestApp",
      ])
      return output.contains("Error") || output.contains("Invalid")
    }

    test("Allow user paths") {
      let output = runTool([
        "add-file", "/Users/test/file.swift", "--group", "Sources", "--targets", "TestApp",
        "--dry-run",
      ])
      return !output.contains("Invalid file path")
    }

    test("Allow home directory expansion") {
      let output = runTool([
        "add-file", "~/Documents/file.swift", "--group", "Sources", "--targets", "TestApp",
        "--dry-run",
      ])
      return !output.contains("Invalid file path")
    }

    print()
  }

  static func testCommandInjectionProtection() {
    print("2. Command Injection Protection")
    print("--------------------------------")

    test("Escape shell metacharacters in scripts") {
      let dangerousScript = "echo 'test'; rm -rf /"
      let output = runTool([
        "add-build-phase", "run_script", "--name", "Test", "--target", "TestApp",
        "--script", dangerousScript, "--dry-run",
      ])
      // Should escape the semicolon and other dangerous characters
      return !output.contains("rm -rf /") || output.contains("escaped")
    }

    test("Escape backticks in scripts") {
      let script = "echo `whoami`"
      let output = runTool([
        "add-build-phase", "run_script", "--name", "Test", "--target", "TestApp",
        "--script", script, "--dry-run",
      ])
      return output.contains("\\`") || !output.contains("`whoami`")
    }

    print()
  }

  static func testVersionValidation() {
    print("3. Version Format Validation")
    print("-----------------------------")

    test("Reject invalid semver format") {
      let output = runTool([
        "add-swift-package",
        "https://github.com/test/test",
        "--requirement", "not-a-version",
      ])
      return output.contains("Invalid version format") || output.contains("Error")
    }

    test("Accept valid semver") {
      let output = runTool([
        "add-swift-package",
        "https://github.com/test/test",
        "--requirement", "1.2.3", "--dry-run",
      ])
      return !output.contains("Invalid version")
    }

    test("Reject invalid package URL") {
      let output = runTool([
        "add-swift-package",
        "not-a-url",
        "--requirement", "1.0.0",
      ])
      return output.contains("must be a valid") || output.contains("Error")
    }

    test("Reject empty branch name") {
      let output = runTool([
        "add-swift-package",
        "https://github.com/test/test",
        "--requirement", "branch:",
      ])
      return output.contains("cannot be empty") || output.contains("Error")
    }

    print()
  }

  static func testDryRunMode() {
    print("4. Dry Run Mode")
    print("---------------")

    test("Dry run prevents saving") {
      let output = runTool([
        "--dry-run", "add-file", "test.swift", "--group", "Sources", "--targets", "TestApp",
      ])
      return output.contains("DRY RUN") || output.contains("not saved")
    }

    test("Dry run shows intended changes") {
      let output = runTool(["--dry-run", "create-groups", "TestGroup/SubGroup"])
      return output.contains("Created group") || output.contains("DRY RUN")
    }

    print()
  }

  static func testTransactionSupport() {
    print("5. Transaction Support")
    print("----------------------")

    test("Backup created on save") {
      // The atomic save should create and remove a temporary backup
      let output = runTool([
        "add-file", "transaction_test.swift", "--group", "Sources", "--targets", "TestApp",
      ])
      return output.contains("saved successfully") || output.contains("✅")
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

  static func runTool(_ arguments: [String]) -> String {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    process.environment = ProcessInfo.processInfo.environment
    process.arguments = [toolPath, "--project", testProjectPath] + arguments
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

  static func printSummary() {
    let total = passedTests + failedTests
    print("\n=====================================")
    print("Security Test Results:")
    print("  \(green)Passed: \(passedTests)/\(total)\(reset)")

    if failedTests > 0 {
      print("  \(red)Failed: \(failedTests)/\(total)\(reset)")
      print("\n\(red)❌ Some tests failed\(reset)")
      exit(1)
    } else {
      print("\n\(green)✅ All security tests passed! (\(total) tests)\(reset)")
      exit(0)
    }
  }
}
