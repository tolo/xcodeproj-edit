//
// TransactionManager.swift
// xcodeproj-cli
//
// Transaction management for safe project modifications
//

import Foundation
import PathKit

/// Manages project transaction state for rollback capability
class TransactionManager {
  private let projectPath: Path
  private var transactionBackupPath: Path?

  init(projectPath: Path) {
    self.projectPath = projectPath
  }

  /// Start a new transaction by creating a backup
  func beginTransaction() throws {
    guard transactionBackupPath == nil else {
      throw ProjectError.operationFailed("Transaction already in progress")
    }

    let backupPath = Path("\(projectPath.string).transaction.\(getpid())")
    if FileManager.default.fileExists(atPath: projectPath.string) {
      try FileManager.default.copyItem(atPath: projectPath.string, toPath: backupPath.string)
      transactionBackupPath = backupPath
      print("🔄 Transaction started")
    }
  }

  /// Commit the transaction by removing the backup
  func commitTransaction() throws {
    guard let backupPath = transactionBackupPath else {
      return  // No transaction in progress
    }

    // Remove backup
    if FileManager.default.fileExists(atPath: backupPath.string) {
      try FileManager.default.removeItem(atPath: backupPath.string)
    }

    transactionBackupPath = nil
    print("✅ Transaction committed")
  }

  /// Rollback the transaction by restoring from backup
  func rollbackTransaction() throws {
    guard let backupPath = transactionBackupPath else {
      throw ProjectError.operationFailed("No transaction to rollback")
    }

    // Restore from backup
    if FileManager.default.fileExists(atPath: backupPath.string) {
      if FileManager.default.fileExists(atPath: projectPath.string) {
        try FileManager.default.removeItem(atPath: projectPath.string)
      }
      try FileManager.default.moveItem(atPath: backupPath.string, toPath: projectPath.string)
    }

    transactionBackupPath = nil
    print("↩️  Transaction rolled back")
  }

  /// Check if a transaction is currently active
  var hasActiveTransaction: Bool {
    return transactionBackupPath != nil
  }

  /// Clean up any leftover transaction files (called on deinit)
  func cleanup() {
    if let backupPath = transactionBackupPath,
      FileManager.default.fileExists(atPath: backupPath.string)
    {
      try? FileManager.default.removeItem(atPath: backupPath.string)
      transactionBackupPath = nil
    }
  }

  deinit {
    cleanup()
  }
}
