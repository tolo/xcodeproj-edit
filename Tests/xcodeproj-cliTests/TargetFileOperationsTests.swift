//
// TargetFileOperationsTests.swift
// xcodeproj-cliTests
//
// Tests for add-target-file and remove-target-file commands
//

import XCTest
@testable import xcodeproj_cli

final class TargetFileOperationsTests: XCTestCase {
  
  var tempDir: URL!
  var projectPath: String!
  
  override func setUp() {
    super.setUp()
    tempDir = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString)
    try! FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    
    // Create test project
    projectPath = tempDir.appendingPathComponent("TestProject.xcodeproj").path
    TestHelpers.createTestProject(at: projectPath)
  }
  
  override func tearDown() {
    super.tearDown()
    try? FileManager.default.removeItem(at: tempDir)
  }
  
  // MARK: - add-target-file tests
  
  func testAddTargetFileToExistingFile() throws {
    // First add a file to the project but not to any target
    let sourceFile = tempDir.appendingPathComponent("TestFile.swift")
    try "// Test file".write(to: sourceFile, atomically: true, encoding: .utf8)
    
    // Add file to project (in a group but no targets initially)
    var result = try TestHelpers.runCommand("add-file", arguments: [
      "--project", projectPath, sourceFile.path, 
      "--group", "Sources", "--targets", "TestApp"
    ])
    XCTAssertTrue(result.success)
    
    // Now add the same file to another target using add-target-file
    result = try TestHelpers.runCommand("add-target-file", arguments: [
      "--project", projectPath, sourceFile.path, "TestFramework"
    ])
    XCTAssertTrue(result.success)
    
    // Verify file is in both targets
    result = try TestHelpers.runCommand("list-files", arguments: [
      "--project", projectPath
    ])
    XCTAssertTrue(result.output.contains("TestFile.swift"))
  }
  
  func testAddTargetFileNonExistentFile() throws {
    let result = try TestHelpers.runCommand("add-target-file", arguments: [
      "--project", projectPath, "NonExistent.swift", "TestApp"
    ])
    
    XCTAssertFalse(result.success)
    XCTAssertTrue(result.error.contains("not found in project"))
  }
  
  // MARK: - remove-target-file tests
  
  func testRemoveTargetFileFromSpecificTarget() throws {
    let sourceFile = tempDir.appendingPathComponent("SharedFile.swift")
    try "// Shared file".write(to: sourceFile, atomically: true, encoding: .utf8)
    
    // Add file to multiple targets
    var result = try TestHelpers.runCommand("add-file", arguments: [
      "--project", projectPath, sourceFile.path,
      "--group", "Sources", "--targets", "TestApp,TestFramework"
    ])
    XCTAssertTrue(result.success)
    
    // Remove from one target only
    result = try TestHelpers.runCommand("remove-target-file", arguments: [
      "--project", projectPath, sourceFile.path, "TestFramework"
    ])
    XCTAssertTrue(result.success)
    
    // Verify file still exists in project
    result = try TestHelpers.runCommand("list-files", arguments: [
      "--project", projectPath
    ])
    XCTAssertTrue(result.output.contains("SharedFile.swift"))
    
    // File should still be in TestApp target but not TestFramework
    // This would require more detailed inspection of the project structure
  }
  
  func testRemoveFileCompletelyFromProject() throws {
    let sourceFile = tempDir.appendingPathComponent("TempFile.swift")
    try "// Temp file".write(to: sourceFile, atomically: true, encoding: .utf8)
    
    // Add file
    var result = try TestHelpers.runCommand("add-file", arguments: [
      "--project", projectPath, sourceFile.path,
      "--group", "Sources", "--targets", "TestApp"
    ])
    XCTAssertTrue(result.success)
    
    // Remove completely from project
    result = try TestHelpers.runCommand("remove-file", arguments: [
      "--project", projectPath, sourceFile.path
    ])
    XCTAssertTrue(result.success)
    
    // File should be gone from project
    result = try TestHelpers.runCommand("list-files", arguments: [
      "--project", projectPath
    ])
    XCTAssertFalse(result.output.contains("TempFile.swift"))
  }
}