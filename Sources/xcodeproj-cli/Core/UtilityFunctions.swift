//
// UtilityFunctions.swift
// xcodeproj-cli
//
// Helper and utility functions for Xcode project manipulation
//

import Foundation
import PathKit
import XcodeProj

// MARK: - Security & Path Helpers

func sanitizePath(_ path: String) -> String? {
  // Use the centralized, secure implementation from PathUtils
  return PathUtils.sanitizePath(path)
}

func escapeShellCommand(_ command: String) -> String {
  // Escape common shell metacharacters
  let charactersToEscape = ["$", "`", "\\", "\"", "\n"]
  var escaped = command
  for char in charactersToEscape {
    escaped = escaped.replacingOccurrences(of: char, with: "\\\(char)")
  }
  return escaped
}

// MARK: - Project Helper Functions

func findGroup(named name: String, in groups: [PBXGroup]) -> PBXGroup? {
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

func fileExists(path: String, in pbxproj: PBXProj) -> Bool {
  return pbxproj.fileReferences.contains { $0.path == path || $0.name == path }
}

func sourceBuildPhase(for target: PBXNativeTarget) -> PBXSourcesBuildPhase? {
  return target.buildPhases.first { $0 is PBXSourcesBuildPhase } as? PBXSourcesBuildPhase
}

func fileType(for path: String) -> String {
  let pathExtension = (path as NSString).pathExtension.lowercased()

  switch pathExtension {
  case "swift": return "sourcecode.swift"
  case "m": return "sourcecode.c.objc"
  case "mm": return "sourcecode.cpp.objcpp"
  case "h": return "sourcecode.c.h"
  case "cpp", "cc": return "sourcecode.cpp.cpp"
  case "c": return "sourcecode.c.c"
  case "plist": return "text.plist.xml"
  case "strings": return "text.plist.strings"
  case "json": return "text.json"
  case "xml": return "text.xml"
  case "txt": return "text"
  case "md": return "net.daringfireball.markdown"
  
  // Asset/bundle types
  case "xcassets": return "folder.assetcatalog"
  case "bundle": return "wrapper.cfbundle"
  case "framework": return "wrapper.framework"
  case "app": return "wrapper.application"
  case "appex": return "wrapper.app-extension"
  case "xcodeproj": return "wrapper.pb-project"
  case "xcworkspace": return "wrapper.workspace"
  case "playground": return "file.playground"
  case "playgroundbook": return "wrapper.playgroundbook"
  
  // Image/media formats
  case "png": return "image.png"
  case "jpg", "jpeg": return "image.jpeg"
  case "gif": return "image.gif"
  case "pdf": return "image.pdf"
  case "svg": return "image.svg"
  case "mov": return "video.quicktime"
  case "mp4": return "video.mp4"
  case "m4v": return "video.x-m4v"
  case "mp3": return "audio.mp3"
  case "m4a": return "audio.x-m4a"
  case "wav": return "audio.wav"
  case "aiff": return "audio.aiff"
  
  // UI files
  case "storyboard": return "file.storyboard"
  case "xib": return "file.xib"
  
  // Data formats
  case "sqlite": return "file"
  case "db": return "file"
  case "realm": return "file"
  case "coredata": return "wrapper.xcdatamodel"
  case "xcdatamodeld": return "wrapper.xcdatamodel"
  
  // Configuration files
  case "entitlements": return "text.plist.entitlements"
  case "pch": return "sourcecode.c.h"
  case "xcconfig": return "text.xcconfig"
  case "gpx": return "text.xml"
  
  // Archive/compressed formats
  case "zip": return "archive.zip"
  case "tar": return "archive.tar"
  case "gz": return "archive.gzip"
  
  // Documents
  case "rtf": return "text.rtf"
  case "html": return "text.html"
  case "css": return "text.css"
  case "js": return "sourcecode.javascript"
  case "ts": return "sourcecode.javascript"  // TypeScript
  case "py": return "text.script.python"
  case "rb": return "text.script.ruby"
  case "sh": return "text.script.sh"
  case "zsh": return "text.script.sh"
  case "bash": return "text.script.sh"
  case "fish": return "text.script.sh"
  case "pl": return "text.script.perl"
  case "php": return "text.script.php"
  case "yaml", "yml": return "text.yaml"
  
  // Development files
  case "gitignore": return "text"
  case "gitmodules": return "text"
  case "gitattributes": return "text"
  case "podfile": return "text"
  case "podspec": return "text"
  case "gemfile": return "text"
  case "dockerfile": return "text"
  case "makefile": return "text"
  case "cartfile": return "text"
  case "license": return "text"
  case "readme": return "text"
  case "changelog": return "text"
  
  // No extension or unknown types
  default:
    if path.hasSuffix("Podfile") || path.hasSuffix("Cartfile") || path.hasSuffix("Makefile") {
      return "text"
    }
    if path.hasPrefix(".") {
      return "text"  // Hidden files are generally text
    }
    return "text"  // Default to text file
  }
}

func shouldIncludeFile(_ filename: String) -> Bool {
  // Skip hidden files and common ignore patterns
  if filename.hasPrefix(".") && filename != ".gitkeep" {
    return false
  }

  // Skip common temporary and build files
  let skipPatterns = [
    ".DS_Store", "Thumbs.db", ".tmp", ".temp", "~", ".swp", ".swo",
    "DerivedData", "build", ".build", "Build", "*.dSYM",
    "xcuserdata", "project.xcworkspace",
    "*.orig", "*.rej", "*.bak", "*.backup",
    "node_modules", ".git", ".svn", ".hg",
    "__pycache__", "*.pyc", ".pytest_cache",
    "Pods", "Carthage/Build", ".carthage"
  ]

  for pattern in skipPatterns {
    if pattern.contains("*") {
      let cleanPattern = pattern.replacingOccurrences(of: "*", with: "")
      if filename.contains(cleanPattern) {
        return false
      }
    } else if filename == pattern || filename.hasSuffix(pattern) {
      return false
    }
  }

  return true
}

func isCompilableFile(_ path: String) -> Bool {
  let pathExtension = (path as NSString).pathExtension.lowercased()
  return ["swift", "m", "mm", "cpp", "cc", "c"].contains(pathExtension)
}

func findGroupByPath(_ path: String, in groups: [PBXGroup], rootGroup: PBXGroup) -> PBXGroup? {
  let components = path.split(separator: "/").map(String.init)
  var currentGroup = rootGroup

  for component in components {
    if let childGroup = currentGroup.children.compactMap({ $0 as? PBXGroup })
        .first(where: { $0.name == component || $0.path == component }) {
      currentGroup = childGroup
    } else {
      return nil
    }
  }

  return currentGroup
}