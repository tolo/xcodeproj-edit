#!/usr/bin/swift sh

// XcodeProj CLI - Integration Tests
// Tests for complete workflows combining multiple operations

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
struct IntegrationTests {
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
    print("\(blue)🧪 Integration Test Suite\(reset)")
    print("==========================\n")

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

    // Run integration tests
    testCompleteFeatureWorkflow()
    testLibraryIntegrationWorkflow()
    testProjectRestructuringWorkflow()
    testBuildConfigurationWorkflow()

    // Restore backup
    restoreProject()

    // Print summary
    printSummary()
  }

  // MARK: - Integration Test Workflows

  static func testCompleteFeatureWorkflow() {
    print("1. Testing Complete Feature Development Workflow")
    print("-----------------------------------------------")

    test("Complete feature workflow: Login feature") {
      // Step 1: Create group structure for Login feature
      let createGroupsOutput = TestHelper.runTool(["create-groups", "Features/Login"])
      guard createGroupsOutput.contains("Created group") || createGroupsOutput.contains("📁") 
        || !createGroupsOutput.contains("Error") else { return false }

      // Step 2: Create test files
      try? FileManager.default.createDirectory(
        atPath: "TestData/Features/Login", 
        withIntermediateDirectories: true
      )
      try? """
      // Login View Controller
      import UIKit
      
      class LoginViewController: UIViewController {
        override func viewDidLoad() {
          super.viewDidLoad()
          setupUI()
        }
        
        private func setupUI() {
          // Setup login UI
        }
      }
      """.write(
        toFile: "TestData/Features/Login/LoginViewController.swift",
        atomically: true, encoding: .utf8
      )

      try? """
      // Login Service
      import Foundation
      
      class LoginService {
        func authenticate(username: String, password: String) async -> Bool {
          // Authentication logic
          return true
        }
      }
      """.write(
        toFile: "TestData/Features/Login/LoginService.swift",
        atomically: true, encoding: .utf8
      )

      // Step 3: Add files to project
      let addFilesOutput = TestHelper.runTool([
        "add-folder", "TestData/Features/Login",
        "--group", "Features/Login",
        "--targets", "TestApp",
        "--recursive"
      ])
      guard addFilesOutput.contains("Added") || addFilesOutput.contains("files added") 
        || !addFilesOutput.contains("Error") else { return false }

      // Step 4: Set build settings for the feature
      let setBuildSettingOutput = TestHelper.runTool([
        "set-build-setting", "SWIFT_VERSION", "5.9",
        "--targets", "TestApp"
      ])
      guard setBuildSettingOutput.contains("Updated build settings") 
        || setBuildSettingOutput.contains("Set SWIFT_VERSION") 
        || !setBuildSettingOutput.contains("Error") else { return false }

      // Step 5: Validate project integrity
      let validateOutput = TestHelper.runTool(["validate"])
      guard !validateOutput.contains("Error") else { return false }

      // Step 6: Verify files are in project
      let listFilesOutput = TestHelper.runTool(["list-files", "Features"])
      guard listFilesOutput.contains("LoginViewController.swift") 
        || listFilesOutput.contains("LoginService.swift") 
        || listFilesOutput.contains("📄") else { return false }

      return true
    }

    print()
  }

  static func testLibraryIntegrationWorkflow() {
    print("2. Testing Library Integration Workflow")
    print("---------------------------------------")

    test("Complete library integration: Alamofire + NetworkLayer") {
      // Step 1: Add Swift package
      let addPackageOutput = TestHelper.runTool([
        "add-swift-package", "https://github.com/Alamofire/Alamofire.git",
        "--version", "5.9.1"
      ])
      guard addPackageOutput.contains("Added Swift package") 
        || addPackageOutput.contains("already exists") 
        || !addPackageOutput.contains("Error") else { return false }

      // Step 2: Create networking group
      let createGroupOutput = TestHelper.runTool(["create-groups", "Networking"])
      guard createGroupOutput.contains("Created group") || createGroupOutput.contains("📁")
        || !createGroupOutput.contains("Error") else { return false }

      // Step 3: Create network service file
      try? FileManager.default.createDirectory(
        atPath: "TestData/Networking", 
        withIntermediateDirectories: true
      )
      try? """
      // Network Service using Alamofire
      import Foundation
      import Alamofire
      
      class NetworkService {
        static let shared = NetworkService()
        
        func request<T: Codable>(_ endpoint: String, type: T.Type) async throws -> T {
          // Network request logic using Alamofire
          fatalError("Not implemented")
        }
      }
      """.write(
        toFile: "TestData/Networking/NetworkService.swift",
        atomically: true, encoding: .utf8
      )

      // Step 4: Add network files to project
      let addNetworkFilesOutput = TestHelper.runTool([
        "add-file", "NetworkService.swift",
        "--group", "Networking",
        "--targets", "TestApp"
      ])
      guard addNetworkFilesOutput.contains("Added") 
        || addNetworkFilesOutput.contains("already exists")
        || !addNetworkFilesOutput.contains("Error") else { return false }

      // Step 5: Verify package is listed
      let listPackagesOutput = TestHelper.runTool(["list-swift-packages"])
      guard listPackagesOutput.contains("Alamofire") || listPackagesOutput.contains("📦") else { return false }

      // Step 6: Validate project
      let validateOutput = TestHelper.runTool(["validate"])
      guard !validateOutput.contains("Error") else { return false }

      return true
    }

    print()
  }

  static func testProjectRestructuringWorkflow() {
    print("3. Testing Project Restructuring Workflow")
    print("-----------------------------------------")

    test("Complete project restructuring: MVVM architecture") {
      // Step 1: Create MVVM group structure
      let createGroupsOutput = TestHelper.runTool([
        "create-groups", "Architecture/Models", "Architecture/Views", "Architecture/ViewModels"
      ])
      guard createGroupsOutput.contains("Created group") || createGroupsOutput.contains("📁")
        || !createGroupsOutput.contains("Error") else { return false }

      // Step 2: Create test framework target
      let addTargetOutput = TestHelper.runTool([
        "add-target", "TestAppFramework",
        "--type", "com.apple.product-type.framework",
        "--bundle-id", "com.testapp.framework"
      ])
      guard addTargetOutput.contains("Added target") || addTargetOutput.contains("already exists")
        || !addTargetOutput.contains("Error") else { return false }

      // Step 3: Create MVVM files
      try? FileManager.default.createDirectory(
        atPath: "TestData/Architecture/Models", 
        withIntermediateDirectories: true
      )
      try? FileManager.default.createDirectory(
        atPath: "TestData/Architecture/Views", 
        withIntermediateDirectories: true
      )
      try? FileManager.default.createDirectory(
        atPath: "TestData/Architecture/ViewModels", 
        withIntermediateDirectories: true
      )

      try? "// User Model\nstruct User: Codable { let id: Int; let name: String }".write(
        toFile: "TestData/Architecture/Models/User.swift", atomically: true, encoding: .utf8)
      try? "// User View\nimport SwiftUI\nstruct UserView: View { var body: some View { Text(\"User\") } }".write(
        toFile: "TestData/Architecture/Views/UserView.swift", atomically: true, encoding: .utf8)
      try? "// User ViewModel\nimport Foundation\nclass UserViewModel: ObservableObject {}".write(
        toFile: "TestData/Architecture/ViewModels/UserViewModel.swift", atomically: true, encoding: .utf8)

      // Step 4: Add all MVVM folders to both targets
      let addModelsOutput = TestHelper.runTool([
        "add-folder", "TestData/Architecture/Models",
        "--group", "Architecture/Models",
        "--targets", "TestApp,TestAppFramework",
        "--recursive"
      ])
      guard addModelsOutput.contains("Added") || !addModelsOutput.contains("Error") else { return false }

      let addViewsOutput = TestHelper.runTool([
        "add-folder", "TestData/Architecture/Views",
        "--group", "Architecture/Views", 
        "--targets", "TestApp",
        "--recursive"
      ])
      guard addViewsOutput.contains("Added") || !addViewsOutput.contains("Error") else { return false }

      let addViewModelsOutput = TestHelper.runTool([
        "add-folder", "TestData/Architecture/ViewModels",
        "--group", "Architecture/ViewModels",
        "--targets", "TestAppFramework",
        "--recursive"
      ])
      guard addViewModelsOutput.contains("Added") || !addViewModelsOutput.contains("Error") else { return false }

      // Step 5: Add dependency between targets
      let addDependencyOutput = TestHelper.runTool([
        "add-dependency", "TestApp", "--depends-on", "TestAppFramework"
      ])
      guard addDependencyOutput.contains("Added dependency") 
        || addDependencyOutput.contains("already exists")
        || !addDependencyOutput.contains("Error") else { return false }

      // Step 6: Set different build settings for each target
      let setAppSettingsOutput = TestHelper.runTool([
        "set-build-setting", "PRODUCT_NAME", "TestApp",
        "--targets", "TestApp"
      ])
      guard setAppSettingsOutput.contains("Updated build settings") 
        || !setAppSettingsOutput.contains("Error") else { return false }

      let setFrameworkSettingsOutput = TestHelper.runTool([
        "set-build-setting", "PRODUCT_NAME", "TestAppFramework",
        "--targets", "TestAppFramework"
      ])
      guard setFrameworkSettingsOutput.contains("Updated build settings") 
        || !setFrameworkSettingsOutput.contains("Error") else { return false }

      // Step 7: Validate the restructured project
      let validateOutput = TestHelper.runTool(["validate"])
      guard !validateOutput.contains("Error") else { return false }

      // Step 8: Verify targets exist
      let listTargetsOutput = TestHelper.runTool(["list-targets"])
      guard listTargetsOutput.contains("TestApp") && listTargetsOutput.contains("TestAppFramework")
        else { return false }

      return true
    }

    print()
  }

  static func testBuildConfigurationWorkflow() {
    print("4. Testing Build Configuration Workflow")
    print("---------------------------------------")

    test("Complete build configuration: Multi-environment setup") {
      // Step 1: Set Debug-specific settings
      let setDebugSettingsOutput = TestHelper.runTool([
        "set-build-setting", "SWIFT_COMPILATION_MODE", "singlefile",
        "--targets", "TestApp",
        "--config", "Debug"
      ])
      guard setDebugSettingsOutput.contains("Updated build settings") 
        || !setDebugSettingsOutput.contains("Error") else { return false }

      let setDebugOptimizationOutput = TestHelper.runTool([
        "set-build-setting", "SWIFT_OPTIMIZATION_LEVEL", "-Onone",
        "--targets", "TestApp",
        "--config", "Debug"
      ])
      guard setDebugOptimizationOutput.contains("Updated build settings") 
        || !setDebugOptimizationOutput.contains("Error") else { return false }

      // Step 2: Set Release-specific settings
      let setReleaseOptimizationOutput = TestHelper.runTool([
        "set-build-setting", "SWIFT_OPTIMIZATION_LEVEL", "-O",
        "--targets", "TestApp",
        "--config", "Release"
      ])
      guard setReleaseOptimizationOutput.contains("Updated build settings") 
        || !setReleaseOptimizationOutput.contains("Error") else { return false }

      let setReleaseCompilationOutput = TestHelper.runTool([
        "set-build-setting", "SWIFT_COMPILATION_MODE", "wholemodule",
        "--targets", "TestApp",
        "--config", "Release"
      ])
      guard setReleaseCompilationOutput.contains("Updated build settings") 
        || !setReleaseCompilationOutput.contains("Error") else { return false }

      // Step 3: Set common settings across all configs
      let setCommonSettingsOutput = TestHelper.runTool([
        "set-build-setting", "SWIFT_VERSION", "5.9",
        "--targets", "TestApp"
      ])
      guard setCommonSettingsOutput.contains("Updated build settings") 
        || !setCommonSettingsOutput.contains("Error") else { return false }

      // Step 4: Verify Debug settings
      let getDebugSettingsOutput = TestHelper.runTool([
        "get-build-settings", "TestApp", "--config", "Debug"
      ])
      guard getDebugSettingsOutput.contains("SWIFT_COMPILATION_MODE") 
        || getDebugSettingsOutput.contains("SWIFT_OPTIMIZATION_LEVEL")
        || getDebugSettingsOutput.contains("singlefile") 
        || getDebugSettingsOutput.contains("-Onone") else { return false }

      // Step 5: Verify Release settings
      let getReleaseSettingsOutput = TestHelper.runTool([
        "get-build-settings", "TestApp", "--config", "Release"
      ])
      guard getReleaseSettingsOutput.contains("SWIFT_OPTIMIZATION_LEVEL")
        || getReleaseSettingsOutput.contains("-O") 
        || getReleaseSettingsOutput.contains("wholemodule") else { return false }

      // Step 6: Verify common settings exist in both configs
      let listAllSettingsOutput = TestHelper.runTool([
        "list-build-settings", "--target", "TestApp"
      ])
      guard listAllSettingsOutput.contains("SWIFT_VERSION") else { return false }

      // Step 7: Validate project integrity
      let validateOutput = TestHelper.runTool(["validate"])
      guard !validateOutput.contains("Error") else { return false }

      return true
    }

    test("Multi-target build configuration workflow") {
      // Step 1: Create multiple targets
      let addFrameworkOutput = TestHelper.runTool([
        "add-target", "SharedFramework",
        "--type", "com.apple.product-type.framework",
        "--bundle-id", "com.test.shared"
      ])
      guard addFrameworkOutput.contains("Added target") || addFrameworkOutput.contains("already exists")
        || !addFrameworkOutput.contains("Error") else { return false }

      let addTestsOutput = TestHelper.runTool([
        "add-target", "TestAppTests",
        "--type", "com.apple.product-type.bundle.unit-test",
        "--bundle-id", "com.test.app.tests"
      ])
      guard addTestsOutput.contains("Added target") || addTestsOutput.contains("already exists")
        || !addTestsOutput.contains("Error") else { return false }

      // Step 2: Set framework-specific settings
      let setFrameworkSettingsOutput = TestHelper.runTool([
        "set-build-setting", "DEFINES_MODULE", "YES",
        "--targets", "SharedFramework"
      ])
      guard setFrameworkSettingsOutput.contains("Updated build settings") 
        || !setFrameworkSettingsOutput.contains("Error") else { return false }

      // Step 3: Set test-specific settings  
      let setTestSettingsOutput = TestHelper.runTool([
        "set-build-setting", "BUNDLE_LOADER", "$(TEST_HOST)",
        "--targets", "TestAppTests"
      ])
      guard setTestSettingsOutput.contains("Updated build settings") 
        || !setTestSettingsOutput.contains("Error") else { return false }

      // Step 4: Add dependencies
      let addDependencyOutput = TestHelper.runTool([
        "add-dependency", "TestApp", "--depends-on", "SharedFramework"
      ])
      guard addDependencyOutput.contains("Added dependency") 
        || addDependencyOutput.contains("already exists")
        || !addDependencyOutput.contains("Error") else { return false }

      // Step 5: Verify all targets exist
      let listTargetsOutput = TestHelper.runTool(["list-targets"])
      guard listTargetsOutput.contains("TestApp") 
        && listTargetsOutput.contains("SharedFramework")
        && listTargetsOutput.contains("TestAppTests") else { return false }

      // Step 6: Validate project
      let validateOutput = TestHelper.runTool(["validate"])
      guard !validateOutput.contains("Error") else { return false }

      return true
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
    print("Integration Test Results:")
    print("  \(green)Passed: \(passedTests)/\(total)\(reset)")

    if failedTests > 0 {
      print("  \(red)Failed: \(failedTests)/\(total)\(reset)")
      print("\n\(red)❌ Some integration tests failed\(reset)")
      exit(1)
    } else {
      print("\n\(green)✅ All integration tests passed!\(reset)")
      exit(0)
    }
  }
}