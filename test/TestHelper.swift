#!/usr/bin/swift sh

// TestHelper for xcodeproj-cli
// Provides utilities for finding and executing the compiled binary
// across different locations and build configurations

import Foundation

public struct TestHelper {
  // ANSI color codes
  public static let red = "\u{001B}[0;31m"
  public static let green = "\u{001B}[0;32m"
  public static let yellow = "\u{001B}[1;33m"
  public static let blue = "\u{001B}[0;34m"
  public static let reset = "\u{001B}[0m"
  
  // Potential locations for the xcodeproj-cli binary
  private static let binarySearchPaths = [
    "../.build/release/xcodeproj-cli",     // Release build
    "../.build/debug/xcodeproj-cli",       // Debug build
    "../xcodeproj-cli",                    // Universal binary in root
    "/usr/local/bin/xcodeproj-cli",        // Installed via Homebrew
    "xcodeproj-cli"                        // In PATH
  ]
  
  // Cached tool path to avoid repeated searches
  private static var cachedToolPath: String?
  
  /// Finds the xcodeproj-cli binary in standard locations
  /// Returns the first working executable found
  public static func findToolPath() -> String? {
    if let cached = cachedToolPath {
      return cached
    }
    
    for path in binarySearchPaths {
      if isExecutable(path) {
        cachedToolPath = path
        return path
      }
    }
    
    return nil
  }
  
  /// Gets the tool path or exits with error if not found
  public static func getToolPath() -> String {
    guard let toolPath = findToolPath() else {
      print("\(red)❌ ERROR: xcodeproj-cli binary not found!\(reset)")
      print("\(yellow)Searched in:\(reset)")
      for path in binarySearchPaths {
        print("  - \(path)")
      }
      print("\n\(yellow)💡 Try building the project first:\(reset)")
      print("  swift build -c release")
      print("  ./build-universal.sh")
      exit(1)
    }
    return toolPath
  }
  
  /// Checks if a file exists and is executable
  private static func isExecutable(_ path: String) -> Bool {
    var isDirectory: ObjCBool = false
    let exists = FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory)
    
    if !exists || isDirectory.boolValue {
      return false
    }
    
    // Check if file is executable
    return FileManager.default.isExecutableFile(atPath: path)
  }
  
  /// Builds the binary if not found
  public static func ensureBinaryExists() -> String {
    if let toolPath = findToolPath() {
      return toolPath
    }
    
    print("\(yellow)🔨 Binary not found. Building...\(reset)")
    
    // Try building release version
    let buildResult = shell("cd .. && swift build -c release")
    if buildResult.exitCode != 0 {
      print("\(red)❌ Failed to build binary:\(reset)")
      print(buildResult.output)
      exit(1)
    }
    
    // Check again after building
    guard let toolPath = findToolPath() else {
      print("\(red)❌ Binary still not found after build!\(reset)")
      exit(1)
    }
    
    print("\(green)✅ Binary built successfully: \(toolPath)\(reset)")
    return toolPath
  }
  
  /// Executes a shell command and returns result
  public static func shell(_ command: String) -> (output: String, exitCode: Int32) {
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
  
  /// Runs the xcodeproj-cli tool with specified arguments
  /// Automatically adds the --project flag for test project
  public static func runTool(_ arguments: [String], projectPath: String = "TestData/TestProject.xcodeproj") -> String {
    let toolPath = getToolPath()
    
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    process.environment = ProcessInfo.processInfo.environment
    // Add --project flag to specify test project
    process.arguments = [toolPath, "--project", projectPath] + arguments
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
  
  /// Validates that the tool is working correctly
  public static func validateTool() -> Bool {
    let toolPath = getToolPath()
    
    // Test help command
    let helpResult = shell("\(toolPath) --help")
    guard helpResult.exitCode == 0 && helpResult.output.contains("Usage:") else {
      print("\(red)❌ Tool validation failed - help command broken\(reset)")
      return false
    }
    
    // Test version command
    let versionResult = shell("\(toolPath) --version")
    guard versionResult.exitCode == 0 else {
      print("\(red)❌ Tool validation failed - version command broken\(reset)")
      return false
    }
    
    print("\(green)✅ Tool validation passed\(reset)")
    return true
  }
  
  /// Prints information about the found binary
  public static func printBinaryInfo() {
    let toolPath = getToolPath()
    print("\(blue)📍 Using binary: \(toolPath)\(reset)")
    
    // Get binary info
    let infoResult = shell("file \(toolPath)")
    if infoResult.exitCode == 0 {
      print("\(blue)🔍 Binary info: \(infoResult.output.trimmingCharacters(in: .whitespacesAndNewlines))\(reset)")
    }
    
    // Check if it's a universal binary
    let lipoResult = shell("lipo -info \(toolPath) 2>/dev/null")
    if lipoResult.exitCode == 0 && lipoResult.output.contains("arm64") {
      print("\(green)🎯 Universal binary detected\(reset)")
    }
  }
}