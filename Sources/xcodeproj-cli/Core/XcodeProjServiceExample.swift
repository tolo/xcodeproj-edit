//
// XcodeProjServiceExample.swift
// xcodeproj-cli
//
// Example showing how to refactor main.swift to use the new service architecture
// This file demonstrates the refactoring pattern but is not meant to be used directly
//

/*
 * EXAMPLE REFACTORING PATTERN
 *
 * This shows how to replace XcodeProjUtility with XcodeProjService in main.swift:
 *
 * OLD CODE (in main.swift around line 2729):
 * ```
 * let utility = try XcodeProjUtility(path: projectPath)
 * ```
 *
 * NEW CODE:
 * ```
 * let service = try XcodeProjService(path: projectPath)
 * ```
 *
 * Then all utility.method() calls become service.method() calls.
 *
 * EXAMPLE COMMAND HANDLERS:
 *
 * OLD:
 * ```
 * case "add-file":
 *   // ... argument parsing ...
 *   try utility.addFile(path: filePath, to: group, targets: targets)
 * ```
 *
 * NEW:
 * ```
 * case "add-file":
 *   // ... argument parsing ...
 *   try service.addFile(path: filePath, to: group, targets: targets)
 * ```
 *
 * TRANSACTION EXAMPLES:
 *
 * OLD:
 * ```
 * try utility.beginTransaction()
 * // ... operations ...
 * try utility.commitTransaction()
 * ```
 *
 * NEW:
 * ```
 * try service.beginTransaction()
 * // ... operations ...
 * try service.commitTransaction()
 * ```
 *
 * VALIDATION EXAMPLES:
 *
 * OLD:
 * ```
 * let issues = utility.validate()
 * utility.listInvalidReferences()
 * ```
 *
 * NEW:
 * ```
 * let issues = service.validate()
 * service.listInvalidReferences()
 * ```
 *
 * BENEFITS OF THE NEW ARCHITECTURE:
 *
 * 1. Clean separation of concerns - each service has a single responsibility
 * 2. Better testability - services can be mocked and tested independently
 * 3. Performance improvements - built-in caching for groups and targets
 * 4. Maintainability - smaller, focused classes are easier to maintain
 * 5. Extensibility - new features can be added to specific services
 *
 * MIGRATION NOTES:
 *
 * - The XcodeProjService provides all the same public methods as XcodeProjUtility
 * - No breaking changes to the CLI interface
 * - Improved error handling and validation through dedicated services
 * - Transaction management is now handled by TransactionManager
 * - Validation logic is handled by ProjectValidator
 * - Performance caching is built into the service layer
 */

import Foundation
import PathKit
import XcodeProj

// This is how the main command handling would look after refactoring:
func exampleCommandHandler() throws {
  // Initialize the service (replaces XcodeProjUtility)
  let service = try XcodeProjService(path: "MyProject.xcodeproj")

  // Example: Add a file
  try service.addFile(path: "NewFile.swift", to: "Sources", targets: ["MyApp"])

  // Example: Create groups
  service.createGroups(["Sources/Features", "Sources/Utils"])

  // Example: Add target
  try service.addTarget(
    name: "MyNewTarget", productType: "com.apple.product-type.application",
    bundleId: "com.example.mynewapp")

  // Example: Validation
  let issues = service.validate()
  if !issues.isEmpty {
    print("Found validation issues:")
    for issue in issues {
      print("  - \(issue)")
    }
  }

  // Example: Set build settings
  try service.setBuildSetting(key: "SWIFT_VERSION", value: "5.0", targets: ["MyApp"])

  // Save changes
  try service.save()
}
