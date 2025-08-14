//
// main.swift
// xcodeproj-cli
//
// Entry point for the xcodeproj-cli command-line tool
//

import Foundation

// MARK: - Main Entry Point
do {
  try CLIRunner.run()
} catch {
  print("❌ Error: \(error)")
  exit(1)
}
