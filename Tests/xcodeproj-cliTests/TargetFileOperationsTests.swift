//
// TargetFileOperationsTests.swift
// xcodeproj-cliTests
//
// Tests for add-target-file and remove-target-file commands
//

import XCTest
@testable import xcodeproj_cli

final class TargetFileOperationsTests: XCTProjectTestCase {
  
  var tempFiles: [URL] = []
  
  override func setUp() {
    super.setUp()
    tempFiles = []
  }
  
  override func tearDown() {
    // Clean up temporary files
    TestHelpers.cleanupTestItems(tempFiles)
    super.tearDown()
  }
  
  // MARK: - add-target-file tests
  
  func testAddTargetFileToExistingFile() throws {
    // First add a file to the project with a target
    let sourceFile = try TestHelpers.createTestFile(name: "TestTargetFile.swift", content: "// Test file for target operations")
    tempFiles.append(sourceFile)
    
    // Add file to project with target
    var result = try runCommand("add-file", arguments: [
      sourceFile.path, 
      "--group", "Sources",
      "--targets", "TestApp"
    ])
    XCTAssertTrue(result.success, "Failed to add file: \(result.error)")
    
    // Remove the file from the target (but keep in project)
    result = try runCommand("remove-target-file", arguments: [
      "TestTargetFile.swift", "--targets", "TestApp"
    ])
    XCTAssertTrue(result.success, "Failed to remove file from target: \(result.error)")
    
    // Now re-add the file to the target using add-target-file
    result = try runCommand("add-target-file", arguments: [
      "TestTargetFile.swift", "--targets", "TestApp"
    ])
    XCTAssertTrue(result.success, "Failed to add file back to target: \(result.error)")
    
    // Verify file is in project
    result = try runCommand("list-files")
    XCTAssertTrue(result.output.contains("TestTargetFile.swift"))
  }
  
  func testAddTargetFileNonExistentFile() throws {
    let result = try runCommand("add-target-file", arguments: [
      "NonExistent.swift", "--targets", "TestApp"
    ])
    
    XCTAssertFalse(result.success)
    TestHelpers.assertOutputOrErrorContains(result, "not found in project")
  }
  
  // MARK: - remove-target-file tests
  
  func testRemoveTargetFileFromTarget() throws {
    let sourceFile = try TestHelpers.createTestFile(name: "RemovableFile.swift", content: "// File to remove from target")
    tempFiles.append(sourceFile)
    
    // Add file with target
    var result = try runCommand("add-file", arguments: [
      sourceFile.path,
      "--group", "Sources", "--targets", "TestApp"
    ])
    XCTAssertTrue(result.success, "Failed to add file: \(result.error)")
    
    // Remove from target only (file should remain in project)
    result = try runCommand("remove-target-file", arguments: [
      "RemovableFile.swift", "--targets", "TestApp"
    ])
    XCTAssertTrue(result.success, "Failed to remove file from target: \(result.error)")
    
    // Verify file still exists in project
    result = try runCommand("list-files")
    XCTAssertTrue(result.output.contains("RemovableFile.swift"), "File should still be in project")
  }
  
  func testRemoveFileCompletelyFromProject() throws {
    let sourceFile = try TestHelpers.createTestFile(name: "TempFile.swift", content: "// Temp file")
    tempFiles.append(sourceFile)
    
    // Add file
    var result = try runCommand("add-file", arguments: [
      sourceFile.path,
      "--group", "Sources", "--targets", "TestApp"
    ])
    XCTAssertTrue(result.success, "Failed to add file: \(result.error)")
    
    // Remove completely from project
    result = try runCommand("remove-file", arguments: [
      "TempFile.swift"
    ])
    XCTAssertTrue(result.success, "Failed to remove file: \(result.error)")
    
    // File should be gone from project
    result = try runCommand("list-files")
    XCTAssertFalse(result.output.contains("TempFile.swift"), "File should be removed from project")
  }
}