//
// XcodeProjectHelpers.swift
// xcodeproj-cli
//
// Core helper functions for Xcode project manipulation
//

import Foundation
import PathKit
import XcodeProj

/// Helper functions for working with Xcode project components
struct XcodeProjectHelpers {

  /// Find a group by name in the project hierarchy
  static func findGroup(named name: String, in groups: [PBXGroup]) -> PBXGroup? {
    for group in groups {
      if group.path == name || group.name == name {
        return group
      }
      let childGroups = group.children.compactMap { $0 as? PBXGroup }
      if let found = findGroup(named: name, in: childGroups) {
        return found
      }
    }
    return nil
  }

  /// Check if a file already exists in the project
  static func fileExists(path: String, in pbxproj: PBXProj) -> Bool {
    return pbxproj.fileReferences.contains { $0.path == path || $0.name == path }
  }

  /// Find the sources build phase for a target
  static func sourceBuildPhase(for target: PBXNativeTarget) -> PBXSourcesBuildPhase? {
    return target.buildPhases.first(where: { $0 is PBXSourcesBuildPhase }) as? PBXSourcesBuildPhase
  }

  /// Find a group by its path components
  static func findGroupByPath(_ path: String, in groups: [PBXGroup], rootGroup: PBXGroup)
    -> PBXGroup?
  {
    let pathComponents = path.split(separator: "/").map(String.init)
    var currentGroup = rootGroup

    for component in pathComponents {
      guard
        let nextGroup = currentGroup.children.compactMap({ $0 as? PBXGroup })
          .first(where: { $0.name == component || $0.path == component })
      else {
        return nil
      }
      currentGroup = nextGroup
    }

    return currentGroup
  }
}
