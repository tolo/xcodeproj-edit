#!/usr/bin/env swift-sh

import Foundation
import PathKit
import XcodeProj  // @tuist ~> 8.12.0

let projectPath = Path("/Users/tobias/Repos/PlayMyQueue/PlayMyQueue.xcodeproj")
let xcodeproj = try XcodeProj(path: projectPath)
let pbxproj = xcodeproj.pbxproj

print("Main group name: \(pbxproj.rootObject?.mainGroup?.name ?? "nil")")
print("Main group path: \(pbxproj.rootObject?.mainGroup?.path ?? "nil")")
print("Products group name: \(pbxproj.rootObject?.productsGroup?.name ?? "nil")")

print("\nAll top-level groups:")
if let mainGroup = pbxproj.rootObject?.mainGroup {
  for child in mainGroup.children {
    if let group = child as? PBXGroup {
      print("  - \(group.name ?? group.path ?? "unnamed") (isMainGroup: \(group === mainGroup))")
    }
  }
}

print("\nSearching for LePlayaP1:")
for group in pbxproj.groups {
  if group.name == "LePlayaP1" || group.path == "LePlayaP1" {
    print("  Found: \(group.name ?? group.path ?? "unnamed")")
    print("  Is main group: \(group === pbxproj.rootObject?.mainGroup)")
    print("  Is products group: \(group === pbxproj.rootObject?.productsGroup)")
  }
}
