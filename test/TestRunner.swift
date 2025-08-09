#!/usr/bin/swift sh

// XcodeProj CLI - Unified Test Runner
// Provides a single entry point for all test suites

import Foundation
import PathKit
import XcodeProj  // @tuist ~> 8.12.0

// ANSI color codes
struct Colors {
  static let red = "\u{001B}[0;31m"
  static let green = "\u{001B}[0;32m"
  static let yellow = "\u{001B}[1;33m"
  static let blue = "\u{001B}[0;34m"
  static let reset = "\u{001B}[0m"
}

// Test result tracking
struct TestResults {
  var passed = 0
  var failed = 0
  var skipped = 0

  var total: Int { passed + failed + skipped }

  func printSummary() {
    print("\n" + String(repeating: "=", count: 50))
    print("📊 Test Summary")
    print(String(repeating: "=", count: 50))
    print("\(Colors.green)✅ Passed: \(passed)\(Colors.reset)")
    if failed > 0 {
      print("\(Colors.red)❌ Failed: \(failed)\(Colors.reset)")
    }
    if skipped > 0 {
      print("\(Colors.yellow)⏭️  Skipped: \(skipped)\(Colors.reset)")
    }
    print("📈 Total: \(total)")

    if failed == 0 {
      print("\n\(Colors.green)🎉 All tests passed!\(Colors.reset)")
    } else {
      print("\n\(Colors.red)⚠️  Some tests failed\(Colors.reset)")
    }
  }
}

// Base test protocol
protocol TestSuite {
  static func run() -> TestResults
}

// Test runner
@main
struct TestRunner {
  static let toolPath = "../src/xcodeproj-cli.swift"
  static let testProjectPath = "TestData/TestProject.xcodeproj"

  static func main() {
    print("\(Colors.blue)🧪 XcodeProj CLI Test Runner\(Colors.reset)")
    print(String(repeating: "=", count: 50))

    // Check if test project exists
    if !FileManager.default.fileExists(atPath: testProjectPath) {
      print("\(Colors.yellow)📦 Creating test project...\(Colors.reset)")
      createTestProject()
    }

    // Check for command-line arguments
    let args = CommandLine.arguments
    if args.count > 1 {
      handleCommand(args[1])
    } else {
      // Show interactive menu
      showMenu()
    }
  }

  static func handleCommand(_ command: String) {
    var results = TestResults()

    switch command {
    case "validation", "--validation", "-v":
      print("\n\(Colors.blue)Running validation tests...\(Colors.reset)\n")
      results = ValidationTests.run()

    case "full", "core", "--full", "--core", "-f", "-c":
      print("\n\(Colors.blue)Running core operations tests...\(Colors.reset)\n")
      restoreProject()  // Start from clean state
      backupProject()
      results = FullTestSuite.run()
      restoreProject()

    case "security", "--security", "-s":
      print("\n\(Colors.blue)Running security tests...\(Colors.reset)\n")
      results = SecurityTestSuite.run()

    case "additional", "--additional", "-e":
      print("\n\(Colors.blue)Running additional edge case tests...\(Colors.reset)\n")
      results = AdditionalTestSuite.run()

    case "all", "--all", "-a":
      print("\n\(Colors.blue)Running all tests...\(Colors.reset)\n")

      print("\n📋 Validation Tests")
      print(String(repeating: "-", count: 30))
      let validationResults = ValidationTests.run()
      results.passed += validationResults.passed
      results.failed += validationResults.failed

      print("\n📋 Security Tests")
      print(String(repeating: "-", count: 30))
      let securityResults = SecurityTestSuite.run()
      results.passed += securityResults.passed
      results.failed += securityResults.failed

      print("\n📋 Core Operations Tests")
      print(String(repeating: "-", count: 30))
      restoreProject()  // Start from clean state
      backupProject()
      let fullResults = FullTestSuite.run()
      restoreProject()
      results.passed += fullResults.passed
      results.failed += fullResults.failed

      print("\n📋 Additional Edge Case Tests")
      print(String(repeating: "-", count: 30))
      let additionalResults = AdditionalTestSuite.run()
      results.passed += additionalResults.passed
      results.failed += additionalResults.failed

    case "help", "--help", "-h":
      printUsage()
      exit(0)

    default:
      print("\(Colors.red)Unknown command: \(command)\(Colors.reset)")
      printUsage()
      exit(1)
    }

    results.printSummary()
    exit(results.failed > 0 ? 1 : 0)
  }

  static func printUsage() {
    print(
      """

      Usage: ./TestRunner.swift [command]

      Commands:
        validation, -v    Run validation tests (read-only)
        core, -c         Run core operations tests (modifies test project)
        security, -s     Run security tests
        additional, -e    Run additional edge case tests
        all, -a          Run all test suites (complete coverage)
        help, -h         Show this help message

      If no command is provided, an interactive menu will be shown.

      Examples:
        ./TestRunner.swift validation
        ./TestRunner.swift core
        ./TestRunner.swift -a
      """)
  }

  static func showMenu() {
    print("\nChoose test suite:")
    print("  1. Quick validation tests (read-only, basic checks)")
    print("  2. Core operations tests (file/folder/target/build operations)")
    print("  3. Security tests (input validation & safety)")
    print("  4. Additional edge case tests (argument parsing, packages, etc.)")
    print("  5. Run ALL test suites (complete test coverage)")
    print("  6. Exit")
    print("\nEnter choice (1-6): ", terminator: "")

    guard let input = readLine()?.trimmingCharacters(in: .whitespaces) else {
      print("\(Colors.red)Invalid input\(Colors.reset)")
      exit(1)
    }

    var results = TestResults()

    switch input {
    case "1":
      print("\n\(Colors.blue)Running validation tests...\(Colors.reset)\n")
      results = ValidationTests.run()

    case "2":
      print("\n\(Colors.blue)Running core operations tests...\(Colors.reset)\n")
      restoreProject()  // Start from clean state
      backupProject()
      results = FullTestSuite.run()
      restoreProject()

    case "3":
      print("\n\(Colors.blue)Running security tests...\(Colors.reset)\n")
      results = SecurityTestSuite.run()

    case "4":
      print("\n\(Colors.blue)Running additional edge case tests...\(Colors.reset)\n")
      results = AdditionalTestSuite.run()

    case "5":
      print("\n\(Colors.blue)Running all tests...\(Colors.reset)\n")

      print("\n📋 Validation Tests")
      print(String(repeating: "-", count: 30))
      let validationResults = ValidationTests.run()
      results.passed += validationResults.passed
      results.failed += validationResults.failed

      print("\n📋 Security Tests")
      print(String(repeating: "-", count: 30))
      let securityResults = SecurityTestSuite.run()
      results.passed += securityResults.passed
      results.failed += securityResults.failed

      print("\n📋 Core Operations Tests")
      print(String(repeating: "-", count: 30))
      restoreProject()  // Start from clean state
      backupProject()
      let fullResults = FullTestSuite.run()
      restoreProject()
      results.passed += fullResults.passed
      results.failed += fullResults.failed

      print("\n📋 Additional Edge Case Tests")
      print(String(repeating: "-", count: 30))
      let additionalResults = AdditionalTestSuite.run()
      results.passed += additionalResults.passed
      results.failed += additionalResults.failed

    case "6":
      print("Goodbye! 👋")
      exit(0)

    default:
      print("\(Colors.red)Invalid choice\(Colors.reset)")
      exit(1)
    }

    results.printSummary()
    exit(results.failed > 0 ? 1 : 0)
  }

  static func createTestProject() {
    let result = shell("./create_test_project.swift")
    if result.exitCode != 0 {
      print("\(Colors.red)Failed to create test project\(Colors.reset)")
      print(result.output)
      exit(1)
    }
  }

  static func backupProject() {
    let backupPath = "\(testProjectPath).backup"
    if FileManager.default.fileExists(atPath: testProjectPath) {
      try? FileManager.default.removeItem(atPath: backupPath)
      try? FileManager.default.copyItem(atPath: testProjectPath, toPath: backupPath)
    }
  }

  static func restoreProject() {
    let backupPath = "\(testProjectPath).backup"
    if FileManager.default.fileExists(atPath: backupPath) {
      try? FileManager.default.removeItem(atPath: testProjectPath)
      try? FileManager.default.copyItem(atPath: backupPath, toPath: testProjectPath)
    }
  }

  static func shell(_ command: String) -> (output: String, exitCode: Int32) {
    let task = Process()
    let pipe = Pipe()

    task.standardOutput = pipe
    task.standardError = pipe
    task.arguments = ["-c", command]
    task.launchPath = "/bin/bash"
    task.launch()
    task.waitUntilExit()

    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output = String(data: data, encoding: .utf8) ?? ""

    return (output, task.terminationStatus)
  }

  static func shellRealtime(_ command: String) -> (passed: Int, failed: Int, exitCode: Int32) {
    let task = Process()
    let pipe = Pipe()

    var passed = 0
    var failed = 0
    var buffer = ""

    task.standardOutput = pipe
    task.standardError = pipe
    task.arguments = ["-c", command]
    task.launchPath = "/bin/bash"

    // Read output in real-time
    let outHandle = pipe.fileHandleForReading
    outHandle.readabilityHandler = { handle in
      let data = handle.availableData
      if data.count > 0 {
        if let str = String(data: data, encoding: .utf8) {
          // Add to buffer
          buffer += str

          // Process complete lines
          while let newlineRange = buffer.range(of: "\n") {
            let line = String(buffer[..<newlineRange.lowerBound])
            buffer.removeSubrange(..<newlineRange.upperBound)

            // Skip build output and warnings
            let skipPatterns = [
              "Building for debugging", "[0/", "warning:", "swift-sh", "Fetching", "Planning build",
            ]
            let shouldSkip = skipPatterns.contains { line.contains($0) }

            if !shouldSkip && !line.isEmpty {
              // Count test results - look for lines with both Testing: and result
              if line.contains("Testing:") {
                if line.contains("✅") {
                  passed += 1
                } else if line.contains("❌") {
                  failed += 1
                }
              }

              // Print the line as-is (it already has formatting)
              print(line)
            }
          }
        }
      }
    }

    task.launch()
    task.waitUntilExit()
    outHandle.readabilityHandler = nil

    // Process any remaining buffer
    if !buffer.isEmpty && buffer.contains("Testing:") {
      if buffer.contains("✅") {
        passed += 1
      } else if buffer.contains("❌") {
        failed += 1
      }
      print(buffer)
    }

    return (passed, failed, task.terminationStatus)
  }
}

// Validation Tests (read-only)
struct ValidationTests: TestSuite {
  static func run() -> TestResults {
    var results = TestResults()

    // Test help command
    runTest("Help command", &results) {
      let result = TestRunner.shell("\(TestRunner.toolPath) --help")
      return result.output.contains("Usage:") && result.exitCode == 0
    }

    // Test listing commands with test project
    let testProject = TestRunner.testProjectPath

    // Check if test project exists
    if FileManager.default.fileExists(atPath: testProject) {
      runTest("List targets", &results) {
        let result = TestRunner.shell(
          "\(TestRunner.toolPath) --project \(testProject) list-targets")
        return result.exitCode == 0
      }

      runTest("List groups", &results) {
        let result = TestRunner.shell("\(TestRunner.toolPath) --project \(testProject) list-groups")
        return result.exitCode == 0
      }

      runTest("List build configs", &results) {
        let result = TestRunner.shell(
          "\(TestRunner.toolPath) --project \(testProject) list-build-configs")
        return result.exitCode == 0
      }

      runTest("Validate project", &results) {
        let result = TestRunner.shell("\(TestRunner.toolPath) --project \(testProject) validate")
        return result.exitCode == 0 || result.output.contains("issues found")
      }
    } else {
      print("\(Colors.yellow)⚠️  No project found for validation tests\(Colors.reset)")
      results.skipped += 5
    }

    // Test error handling
    runTest("Invalid arguments handling", &results) {
      let result = TestRunner.shell("\(TestRunner.toolPath) add-file 2>&1")
      return result.output.contains("Error:") && result.exitCode == 1
    }

    runTest("Missing parameters handling", &results) {
      let result = TestRunner.shell("\(TestRunner.toolPath) add-target 2>&1")
      return result.output.contains("Error:") && result.exitCode == 1
    }

    // Test dry-run mode
    runTest("Dry-run flag", &results) {
      let result = TestRunner.shell("\(TestRunner.toolPath) --dry-run --help")
      return result.exitCode == 0
    }

    return results
  }
}

// Core Operations Test Suite (from TestSuite.swift)
struct FullTestSuite: TestSuite {
  static func run() -> TestResults {
    // Run the test suite with real-time output
    let (passed, failed, exitCode) = TestRunner.shellRealtime("./TestSuite.swift")

    var results = TestResults()
    results.passed = passed
    results.failed = failed

    return results
  }
}

// Security Test Suite (from SecurityTests.swift)
struct SecurityTestSuite: TestSuite {
  static func run() -> TestResults {
    // Run the test suite with real-time output
    let (passed, failed, exitCode) = TestRunner.shellRealtime("./SecurityTests.swift")

    var results = TestResults()
    results.passed = passed
    results.failed = failed

    return results
  }
}

// Additional Test Suite (from AdditionalTests.swift)
struct AdditionalTestSuite: TestSuite {
  static func run() -> TestResults {
    // Run the test suite with real-time output
    let (passed, failed, exitCode) = TestRunner.shellRealtime("./AdditionalTests.swift")

    var results = TestResults()
    results.passed = passed
    results.failed = failed

    return results
  }
}

// Helper function for tests
func runTest(_ description: String, _ results: inout TestResults, _ closure: () -> Bool) {
  print("  Testing: \(description)...", terminator: "")
  fflush(stdout)

  let result = closure()
  if result {
    print(" \(Colors.green)✅\(Colors.reset)")
    results.passed += 1
  } else {
    print(" \(Colors.red)❌\(Colors.reset)")
    results.failed += 1
  }
  fflush(stdout)
}
