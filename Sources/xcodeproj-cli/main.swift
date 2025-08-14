//
// main.swift
// xcodeproj-cli
//
// Entry point for the xcodeproj-cli command-line tool
//

import Foundation

// Run the CLI synchronously on the main thread
@MainActor
func runCLI() throws {
  // Since CLIRunner.run() is async, we need to run it in a Task
  let semaphore = DispatchSemaphore(value: 0)
  var error: Error?
  
  Task { @MainActor in
    do {
      try await CLIRunner.run()
    } catch let e {
      error = e
    }
    semaphore.signal()
  }
  
  semaphore.wait()
  
  if let error = error {
    throw error
  }
}

// Main entry point
do {
  try runCLI()
} catch {
  print("❌ Error: \(error)")
  exit(1)
}