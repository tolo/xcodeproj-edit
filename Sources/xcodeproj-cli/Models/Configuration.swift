//
// Configuration.swift
// xcodeproj-cli
//
// Configuration models for xcodeproj-cli
//

import Foundation

/// Configuration model for xcodeproj-cli operations
struct Configuration {
  let projectPath: String
  let verbose: Bool
  
  init(projectPath: String = "MyProject.xcodeproj", verbose: Bool = false) {
    self.projectPath = projectPath
    self.verbose = verbose
  }
}