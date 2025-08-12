//
// StringExtensions.swift
// xcodeproj-cli
//
// String utility extensions
//

import Foundation

extension String {
  /// Check if string matches a regular expression pattern
  func matches(_ pattern: String) -> Bool {
    return range(of: pattern, options: .regularExpression) != nil
  }
}