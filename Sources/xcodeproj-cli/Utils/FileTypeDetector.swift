//
// FileTypeDetector.swift
// xcodeproj-cli
//
// File type detection utilities
//

import Foundation

/// Utility for detecting Xcode file types based on file extensions
struct FileTypeDetector {

  /// Determine the appropriate Xcode file type for a given file path
  static func fileType(for path: String) -> String {
    switch (path as NSString).pathExtension.lowercased() {
    case "swift": return "sourcecode.swift"
    case "m": return "sourcecode.c.objc"
    case "mm": return "sourcecode.cpp.objcpp"
    case "cpp", "cc", "cxx": return "sourcecode.cpp.cpp"
    case "c": return "sourcecode.c.c"
    case "h": return "sourcecode.c.h"
    case "hpp", "hxx": return "sourcecode.cpp.h"
    case "storyboard": return "file.storyboard"
    case "xib": return "file.xib"
    case "plist": return "text.plist.xml"
    case "json": return "text.json"
    case "strings": return "text.plist.strings"
    case "xcassets": return "folder.assetcatalog"
    case "framework": return "wrapper.framework"
    case "dylib": return "compiled.mach-o.dylib"
    case "a": return "archive.ar"
    case "png", "jpg", "jpeg", "gif", "tiff", "bmp": return "image"
    case "mp3", "wav", "m4a", "aiff": return "audio"
    case "mp4", "mov", "avi": return "video"
    default: return "text"
    }
  }
}
