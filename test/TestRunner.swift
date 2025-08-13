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

// Load TestHelper for binary discovery
#if canImport(TestHelper)
import TestHelper
#else
// Inline helper when import not available
struct TestHelper {
  static func getToolPath() -> String { "../.build/release/xcodeproj-cli" }
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
}
#endif

// Test runner
@main
struct TestRunner {
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

    case "packages", "package", "--packages", "-p":
      print("\n\(Colors.blue)Running Swift Package Manager tests...\(Colors.reset)\n")
      restoreProject()  // Start from clean state
      backupProject()
      results = PackageTestSuite.run()
      restoreProject()

    case "build", "build-config", "--build", "-b":
      print("\n\(Colors.blue)Running Build Configuration tests...\(Colors.reset)\n")
      restoreProject()  // Start from clean state
      backupProject()
      results = BuildConfigTestSuite.run()
      restoreProject()

    case "integration", "--integration", "-i":
      print("\n\(Colors.blue)Running Integration tests...\(Colors.reset)\n")
      restoreProject()  // Start from clean state
      backupProject()
      results = IntegrationTestSuite.run()
      restoreProject()

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

      print("\n📋 Swift Package Manager Tests")
      print(String(repeating: "-", count: 30))
      restoreProject()  // Start from clean state
      backupProject()
      let packageResults = PackageTestSuite.run()
      restoreProject()
      results.passed += packageResults.passed
      results.failed += packageResults.failed

      print("\n📋 Build Configuration Tests")
      print(String(repeating: "-", count: 30))
      restoreProject()  // Start from clean state
      backupProject()
      let buildResults = BuildConfigTestSuite.run()
      restoreProject()
      results.passed += buildResults.passed
      results.failed += buildResults.failed

      print("\n📋 Integration Tests")
      print(String(repeating: "-", count: 30))
      restoreProject()  // Start from clean state
      backupProject()
      let integrationResults = IntegrationTestSuite.run()
      restoreProject()
      results.passed += integrationResults.passed
      results.failed += integrationResults.failed

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
        validation, -v       Run validation tests (read-only)
        core, -c            Run core operations tests (modifies test project)
        security, -s        Run security tests
        packages, -p        Run Swift Package Manager tests
        build, -b           Run Build Configuration tests
        integration, -i     Run Integration tests (complete workflows)
        additional, -e      Run additional edge case tests
        all, -a            Run all test suites (complete coverage)
        help, -h           Show this help message

      If no command is provided, an interactive menu will be shown.

      Examples:
        ./TestRunner.swift validation
        ./TestRunner.swift packages
        ./TestRunner.swift build
        ./TestRunner.swift integration
        ./TestRunner.swift -a
      """)
  }

  static func showMenu() {
    print("\nChoose test suite:")
    print("  1. Quick validation tests (read-only, basic checks)")
    print("  2. Core operations tests (file/folder/target/build operations)")
    print("  3. Security tests (input validation & safety)")
    print("  4. Swift Package Manager tests (add/remove/list packages)")
    print("  5. Build Configuration tests (set/get/list build settings)")
    print("  6. Integration tests (complete workflows)")
    print("  7. Additional edge case tests (argument parsing, etc.)")
    print("  8. Run ALL test suites (complete test coverage)")
    print("  9. Exit")
    print("\nEnter choice (1-9): ", terminator: "")

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
      print("\n\(Colors.blue)Running Swift Package Manager tests...\(Colors.reset)\n")
      restoreProject()  // Start from clean state
      backupProject()
      results = PackageTestSuite.run()
      restoreProject()

    case "5":
      print("\n\(Colors.blue)Running Build Configuration tests...\(Colors.reset)\n")
      restoreProject()  // Start from clean state
      backupProject()
      results = BuildConfigTestSuite.run()
      restoreProject()

    case "6":
      print("\n\(Colors.blue)Running Integration tests...\(Colors.reset)\n")
      restoreProject()  // Start from clean state
      backupProject()
      results = IntegrationTestSuite.run()
      restoreProject()

    case "7":
      print("\n\(Colors.blue)Running additional edge case tests...\(Colors.reset)\n")
      results = AdditionalTestSuite.run()

    case "8":
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

      print("\n📋 Swift Package Manager Tests")
      print(String(repeating: "-", count: 30))
      restoreProject()  // Start from clean state
      backupProject()
      let packageResults = PackageTestSuite.run()
      restoreProject()
      results.passed += packageResults.passed
      results.failed += packageResults.failed

      print("\n📋 Build Configuration Tests")
      print(String(repeating: "-", count: 30))
      restoreProject()  // Start from clean state
      backupProject()
      let buildResults = BuildConfigTestSuite.run()
      restoreProject()
      results.passed += buildResults.passed
      results.failed += buildResults.failed

      print("\n📋 Integration Tests")
      print(String(repeating: "-", count: 30))
      restoreProject()  // Start from clean state
      backupProject()
      let integrationResults = IntegrationTestSuite.run()
      restoreProject()
      results.passed += integrationResults.passed
      results.failed += integrationResults.failed

      print("\n📋 Additional Edge Case Tests")
      print(String(repeating: "-", count: 30))
      let additionalResults = AdditionalTestSuite.run()
      results.passed += additionalResults.passed
      results.failed += additionalResults.failed

    case "9":
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
    let result = TestHelper.shell("./create_test_project.swift")
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


}

// Validation Tests (read-only)
struct ValidationTests: TestSuite {
  static func run() -> TestResults {
    var results = TestResults()

    // Test help command
    runTest("Help command", &results) {
      let result = TestHelper.shell("\(TestHelper.getToolPath()) --help")
      return result.output.contains("Usage:") && result.exitCode == 0
    }

    // Test listing commands with test project
    let testProject = TestRunner.testProjectPath

    // Check if test project exists
    if FileManager.default.fileExists(atPath: testProject) {
      runTest("List targets", &results) {
        let result = TestHelper.shell(
          "\(TestHelper.getToolPath()) --project \(testProject) list-targets")
        return result.exitCode == 0
      }

      runTest("List groups", &results) {
        let result = TestHelper.shell("\(TestHelper.getToolPath()) --project \(testProject) list-groups")
        return result.exitCode == 0
      }

      runTest("List build configs", &results) {
        let result = TestHelper.shell(
          "\(TestHelper.getToolPath()) --project \(testProject) list-build-configs")
        return result.exitCode == 0
      }

      runTest("Validate project", &results) {
        let result = TestHelper.shell("\(TestHelper.getToolPath()) --project \(testProject) validate")
        return result.exitCode == 0 || result.output.contains("issues found")
      }
    } else {
      print("\(Colors.yellow)⚠️  No project found for validation tests\(Colors.reset)")
      results.skipped += 5
    }

    // Test error handling
    runTest("Invalid arguments handling", &results) {
      let result = TestHelper.shell("\(TestHelper.getToolPath()) add-file 2>&1")
      return result.output.contains("Error:") && result.exitCode == 1
    }

    runTest("Missing parameters handling", &results) {
      let result = TestHelper.shell("\(TestHelper.getToolPath()) add-target 2>&1")
      return result.output.contains("Error:") && result.exitCode == 1
    }

    // Test dry-run mode
    runTest("Dry-run flag", &results) {
      let result = TestHelper.shell("\(TestHelper.getToolPath()) --dry-run --help")
      return result.exitCode == 0
    }

    return results
  }
}

// Core Operations Test Suite (from TestSuite.swift)
struct FullTestSuite: TestSuite {
  static func run() -> TestResults {
    // Run the test suite and parse results
    let result = TestHelper.shell("./TestSuite.swift")
    
    var results = TestResults()
    let lines = result.output.split(separator: "\n")
    
    // Parse the output for passed/failed counts
    for line in lines {
      let lineStr = String(line)
      if lineStr.contains("Passed:") && lineStr.contains("/") {
        // Extract passed count from "Passed: X/Y" format
        if let match = lineStr.range(of: "Passed: "), 
           let slashRange = lineStr[match.upperBound...].range(of: "/") {
          let passedStr = String(lineStr[match.upperBound..<slashRange.lowerBound])
          results.passed = Int(passedStr) ?? 0
        }
      }
      if lineStr.contains("Failed:") && lineStr.contains("/") {
        // Extract failed count from "Failed: X/Y" format
        if let match = lineStr.range(of: "Failed: "), 
           let slashRange = lineStr[match.upperBound...].range(of: "/") {
          let failedStr = String(lineStr[match.upperBound..<slashRange.lowerBound])
          results.failed = Int(failedStr) ?? 0
        }
      }
    }
    
    // Print the output for real-time feedback
    print(result.output)

    return results
  }
}

// Security Test Suite (from SecurityTests.swift)
struct SecurityTestSuite: TestSuite {
  static func run() -> TestResults {
    // Run the test suite and parse results
    let result = TestHelper.shell("./SecurityTests.swift")
    
    var results = TestResults()
    let lines = result.output.split(separator: "\n")
    
    // Parse the output for passed/failed counts
    for line in lines {
      let lineStr = String(line)
      if lineStr.contains("Passed:") && lineStr.contains("/") {
        if let match = lineStr.range(of: "Passed: "), 
           let slashRange = lineStr[match.upperBound...].range(of: "/") {
          let passedStr = String(lineStr[match.upperBound..<slashRange.lowerBound])
          results.passed = Int(passedStr) ?? 0
        }
      }
      if lineStr.contains("Failed:") && lineStr.contains("/") {
        if let match = lineStr.range(of: "Failed: "), 
           let slashRange = lineStr[match.upperBound...].range(of: "/") {
          let failedStr = String(lineStr[match.upperBound..<slashRange.lowerBound])
          results.failed = Int(failedStr) ?? 0
        }
      }
    }
    
    // Print the output for real-time feedback
    print(result.output)

    return results
  }
}

// Additional Test Suite (from AdditionalTests.swift)
struct AdditionalTestSuite: TestSuite {
  static func run() -> TestResults {
    // Run the test suite and parse results
    let result = TestHelper.shell("./AdditionalTests.swift")
    
    var results = TestResults()
    let lines = result.output.split(separator: "\n")
    
    // Parse the output for passed/failed counts
    for line in lines {
      let lineStr = String(line)
      if lineStr.contains("Passed:") && lineStr.contains("/") {
        if let match = lineStr.range(of: "Passed: "), 
           let slashRange = lineStr[match.upperBound...].range(of: "/") {
          let passedStr = String(lineStr[match.upperBound..<slashRange.lowerBound])
          results.passed = Int(passedStr) ?? 0
        }
      }
      if lineStr.contains("Failed:") && lineStr.contains("/") {
        if let match = lineStr.range(of: "Failed: "), 
           let slashRange = lineStr[match.upperBound...].range(of: "/") {
          let failedStr = String(lineStr[match.upperBound..<slashRange.lowerBound])
          results.failed = Int(failedStr) ?? 0
        }
      }
    }
    
    // Print the output for real-time feedback
    print(result.output)

    return results
  }
}

// Package Test Suite (from PackageTests.swift)
struct PackageTestSuite: TestSuite {
  static func run() -> TestResults {
    // Run the test suite and parse results
    let result = TestHelper.shell("./PackageTests.swift")
    
    var results = TestResults()
    let lines = result.output.split(separator: "\n")
    
    // Parse the output for passed/failed counts
    for line in lines {
      let lineStr = String(line)
      if lineStr.contains("Passed:") && lineStr.contains("/") {
        if let match = lineStr.range(of: "Passed: "), 
           let slashRange = lineStr[match.upperBound...].range(of: "/") {
          let passedStr = String(lineStr[match.upperBound..<slashRange.lowerBound])
          results.passed = Int(passedStr) ?? 0
        }
      }
      if lineStr.contains("Failed:") && lineStr.contains("/") {
        if let match = lineStr.range(of: "Failed: "), 
           let slashRange = lineStr[match.upperBound...].range(of: "/") {
          let failedStr = String(lineStr[match.upperBound..<slashRange.lowerBound])
          results.failed = Int(failedStr) ?? 0
        }
      }
    }
    
    // Print the output for real-time feedback
    print(result.output)

    return results
  }
}

// Build Config Test Suite (from BuildConfigTests.swift)
struct BuildConfigTestSuite: TestSuite {
  static func run() -> TestResults {
    // Run the test suite and parse results
    let result = TestHelper.shell("./BuildConfigTests.swift")
    
    var results = TestResults()
    let lines = result.output.split(separator: "\n")
    
    // Parse the output for passed/failed counts
    for line in lines {
      let lineStr = String(line)
      if lineStr.contains("Passed:") && lineStr.contains("/") {
        if let match = lineStr.range(of: "Passed: "), 
           let slashRange = lineStr[match.upperBound...].range(of: "/") {
          let passedStr = String(lineStr[match.upperBound..<slashRange.lowerBound])
          results.passed = Int(passedStr) ?? 0
        }
      }
      if lineStr.contains("Failed:") && lineStr.contains("/") {
        if let match = lineStr.range(of: "Failed: "), 
           let slashRange = lineStr[match.upperBound...].range(of: "/") {
          let failedStr = String(lineStr[match.upperBound..<slashRange.lowerBound])
          results.failed = Int(failedStr) ?? 0
        }
      }
    }
    
    // Print the output for real-time feedback
    print(result.output)

    return results
  }
}

// Integration Test Suite (from IntegrationTests.swift)
struct IntegrationTestSuite: TestSuite {
  static func run() -> TestResults {
    // Run the test suite and parse results
    let result = TestHelper.shell("./IntegrationTests.swift")
    
    var results = TestResults()
    let lines = result.output.split(separator: "\n")
    
    // Parse the output for passed/failed counts
    for line in lines {
      let lineStr = String(line)
      if lineStr.contains("Passed:") && lineStr.contains("/") {
        if let match = lineStr.range(of: "Passed: "), 
           let slashRange = lineStr[match.upperBound...].range(of: "/") {
          let passedStr = String(lineStr[match.upperBound..<slashRange.lowerBound])
          results.passed = Int(passedStr) ?? 0
        }
      }
      if lineStr.contains("Failed:") && lineStr.contains("/") {
        if let match = lineStr.range(of: "Failed: "), 
           let slashRange = lineStr[match.upperBound...].range(of: "/") {
          let failedStr = String(lineStr[match.upperBound..<slashRange.lowerBound])
          results.failed = Int(failedStr) ?? 0
        }
      }
    }
    
    // Print the output for real-time feedback
    print(result.output)

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
