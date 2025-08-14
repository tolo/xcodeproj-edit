//
// main.swift
// xcodeproj-cli
//
// Entry point for the xcodeproj-cli command-line tool
//

import Foundation

// Run the CLI directly without @main attribute
// This ensures everything runs on the MainActor
MainActor.assumeIsolated {
  do {
    try CLIRunner.run()
  } catch {
    print("❌ Error: \(error)")
    exit(1)
  }
}
