//
// PathUtilsTests.swift
// xcodeproj-cliTests
//
// Tests for PathUtils file matching improvements
//

import XCTest
@testable import xcodeproj_cli
@preconcurrency import XcodeProj
import PathKit

final class PathUtilsTests: XCTestCase {
  
  // MARK: - File Reference Matching Tests
  
  func testExactPathMatch() {
    // Create test file references
    let fileRef = PBXFileReference(
      sourceTree: .group,
      path: "Sources/Models/User.swift"
    )
    
    // Test exact path match
    XCTAssertTrue(
      PathUtils.fileReferenceMatches(fileRef: fileRef, searchPath: "Sources/Models/User.swift"),
      "Should match exact path"
    )
    
    // Test non-match
    XCTAssertFalse(
      PathUtils.fileReferenceMatches(fileRef: fileRef, searchPath: "Sources/Models/Post.swift"),
      "Should not match different path"
    )
  }
  
  func testExactNameMatch() {
    // Create file ref with name property
    let fileRef = PBXFileReference(
      sourceTree: .group,
      name: "CustomName.swift",
      path: "Sources/File.swift"
    )
    
    // Test exact name match
    XCTAssertTrue(
      PathUtils.fileReferenceMatches(fileRef: fileRef, searchPath: "CustomName.swift"),
      "Should match exact name"
    )
    
    // Path should still match
    XCTAssertTrue(
      PathUtils.fileReferenceMatches(fileRef: fileRef, searchPath: "Sources/File.swift"),
      "Should match path even when name is different"
    )
  }
  
  func testFilenameOnlyMatch() {
    let fileRef = PBXFileReference(
      sourceTree: .group,
      path: "Sources/Models/User.swift"
    )
    
    // Test filename-only match
    XCTAssertTrue(
      PathUtils.fileReferenceMatches(fileRef: fileRef, searchPath: "User.swift"),
      "Should match filename only"
    )
    
    // Should not match partial filename
    XCTAssertFalse(
      PathUtils.fileReferenceMatches(fileRef: fileRef, searchPath: "User"),
      "Should not match partial filename without extension"
    )
    
    // Should not match different filename
    XCTAssertFalse(
      PathUtils.fileReferenceMatches(fileRef: fileRef, searchPath: "OtherUser.swift"),
      "Should not match different filename"
    )
  }
  
  func testPartialPathMatch() {
    let fileRef = PBXFileReference(
      sourceTree: .group,
      path: "MyApp/Sources/Models/User.swift"
    )
    
    // Test partial path matches
    XCTAssertTrue(
      PathUtils.fileReferenceMatches(fileRef: fileRef, searchPath: "Models/User.swift"),
      "Should match partial path from end"
    )
    
    XCTAssertTrue(
      PathUtils.fileReferenceMatches(fileRef: fileRef, searchPath: "Sources/Models/User.swift"),
      "Should match longer partial path"
    )
    
    // Should not match if components don't align (but with our logic, partial paths need at least 2 components)
    XCTAssertFalse(
      PathUtils.fileReferenceMatches(fileRef: fileRef, searchPath: "odels/User.swift"),
      "Should not match misaligned components"
    )
    
    // Single component partial paths don't match (treated as filename search)
    XCTAssertFalse(
      PathUtils.fileReferenceMatches(fileRef: fileRef, searchPath: "Models"),
      "Should not match single directory component"
    )
  }
  
  func testNoFalsePositivesWithSimilarNames() {
    let fileRef1 = PBXFileReference(
      sourceTree: .group,
      path: "Sources/File.swift"
    )
    
    let fileRef2 = PBXFileReference(
      sourceTree: .group,
      path: "Sources/OtherFile.swift"
    )
    
    // File.swift should not match OtherFile.swift
    XCTAssertTrue(
      PathUtils.fileReferenceMatches(fileRef: fileRef1, searchPath: "File.swift"),
      "Should match File.swift"
    )
    
    XCTAssertFalse(
      PathUtils.fileReferenceMatches(fileRef: fileRef2, searchPath: "File.swift"),
      "Should not match OtherFile.swift when searching for File.swift"
    )
    
    // Verify the old hasSuffix problem is fixed
    XCTAssertFalse(
      PathUtils.fileReferenceMatches(fileRef: fileRef2, searchPath: "ile.swift"),
      "Should not match suffix of filename"
    )
  }
  
  // MARK: - Best Match Selection Tests
  
  func testFindBestMatchWithSingleResult() {
    let fileRefs = [
      PBXFileReference(sourceTree: .group, path: "Sources/Model.swift")
    ]
    
    let match = PathUtils.findBestFileMatch(in: fileRefs, searchPath: "Model.swift")
    XCTAssertNotNil(match)
    XCTAssertEqual(match?.path, "Sources/Model.swift")
  }
  
  func testFindBestMatchWithMultipleMatches() {
    let fileRefs = [
      PBXFileReference(sourceTree: .group, path: "Sources/Model.swift"),
      PBXFileReference(sourceTree: .group, path: "Tests/Model.swift"),
      PBXFileReference(sourceTree: .group, path: "Examples/Demo/Model.swift")
    ]
    
    // When searching with partial path, should prefer exact match
    let match1 = PathUtils.findBestFileMatch(in: fileRefs, searchPath: "Sources/Model.swift")
    XCTAssertNotNil(match1)
    XCTAssertEqual(match1?.path, "Sources/Model.swift", "Should prefer exact path match")
    
    // When searching with filename only, should prefer longer (more specific) path
    let match2 = PathUtils.findBestFileMatch(in: fileRefs, searchPath: "Model.swift")
    XCTAssertNotNil(match2)
    XCTAssertEqual(match2?.path, "Examples/Demo/Model.swift", "Should prefer longer/more specific path")
  }
  
  func testFindBestMatchPrioritizesExactMatch() {
    let fileRefs = [
      PBXFileReference(sourceTree: .group, path: "Long/Path/To/File.swift"),
      PBXFileReference(sourceTree: .group, path: "File.swift"),
      PBXFileReference(sourceTree: .group, name: "File.swift", path: "ActualPath.swift")
    ]
    
    // Exact path match should win
    let match = PathUtils.findBestFileMatch(in: fileRefs, searchPath: "File.swift")
    XCTAssertNotNil(match)
    XCTAssertEqual(match?.path, "File.swift", "Should prefer exact path match over longer paths")
  }
  
  func testFindBestMatchWithNoMatches() {
    let fileRefs = [
      PBXFileReference(sourceTree: .group, path: "Sources/Model.swift"),
      PBXFileReference(sourceTree: .group, path: "Tests/Helper.swift")
    ]
    
    let match = PathUtils.findBestFileMatch(in: fileRefs, searchPath: "Controller.swift")
    XCTAssertNil(match, "Should return nil when no matches found")
  }
  
  func testComplexPathMatchingScenarios() {
    let fileRefs = [
      PBXFileReference(sourceTree: .group, path: "App/Sources/UI/Views/LoginView.swift"),
      PBXFileReference(sourceTree: .group, path: "App/Tests/UI/Views/LoginView.swift"),
      PBXFileReference(sourceTree: .group, path: "Modules/Auth/Sources/LoginView.swift")
    ]
    
    // Test various search patterns
    let match1 = PathUtils.findBestFileMatch(in: fileRefs, searchPath: "UI/Views/LoginView.swift")
    XCTAssertNotNil(match1)
    XCTAssertTrue(
      match1?.path?.contains("UI/Views") ?? false,
      "Should match files containing UI/Views path"
    )
    
    let match2 = PathUtils.findBestFileMatch(in: fileRefs, searchPath: "Auth/Sources/LoginView.swift")
    XCTAssertNotNil(match2)
    // With multiple matches, it will return the best one (could be any that matches the pattern)
    XCTAssertTrue(
      match2?.path?.contains("Auth/Sources/LoginView.swift") ?? false,
      "Should match path containing Auth/Sources pattern"
    )
    
    let match3 = PathUtils.findBestFileMatch(in: fileRefs, searchPath: "LoginView.swift")
    XCTAssertNotNil(match3, "Should find at least one match for filename")
  }
  
  // MARK: - Edge Cases
  
  func testEmptySearchPath() {
    let fileRef = PBXFileReference(sourceTree: .group, path: "Sources/Model.swift")
    
    XCTAssertFalse(
      PathUtils.fileReferenceMatches(fileRef: fileRef, searchPath: ""),
      "Empty search path should not match"
    )
  }
  
  func testFileReferenceWithNilPath() {
    let fileRef = PBXFileReference(sourceTree: .group, name: "File.swift")
    // Path is nil, only name is set
    
    XCTAssertTrue(
      PathUtils.fileReferenceMatches(fileRef: fileRef, searchPath: "File.swift"),
      "Should match by name when path is nil"
    )
  }
  
  func testCaseSensitivity() {
    let fileRef = PBXFileReference(sourceTree: .group, path: "Sources/Model.swift")
    
    // File system is usually case-insensitive on macOS, but our matching is case-sensitive
    XCTAssertFalse(
      PathUtils.fileReferenceMatches(fileRef: fileRef, searchPath: "sources/model.swift"),
      "Matching should be case-sensitive"
    )
  }
  
  func testSpecialCharactersInPath() {
    let fileRef = PBXFileReference(
      sourceTree: .group,
      path: "Sources/My-File (2).swift"
    )
    
    XCTAssertTrue(
      PathUtils.fileReferenceMatches(fileRef: fileRef, searchPath: "My-File (2).swift"),
      "Should handle special characters in filename"
    )
    
    XCTAssertTrue(
      PathUtils.fileReferenceMatches(fileRef: fileRef, searchPath: "Sources/My-File (2).swift"),
      "Should handle special characters in full path"
    )
  }
}