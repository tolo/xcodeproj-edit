//
// PerformanceProfiler.swift
// xcodeproj-cli
//
// Performance monitoring and profiling utilities
//

import Foundation

/// Performance profiler for monitoring operation timing and providing debug output
class PerformanceProfiler {
  // MARK: - Timing Storage

  private var timings: [String: TimeInterval] = [:]
  private var startTimes: [String: CFAbsoluteTime] = [:]
  private var operationCounts: [String: Int] = [:]

  private let isVerbose: Bool

  init(verbose: Bool = false) {
    self.isVerbose = verbose
  }

  // MARK: - Timing Operations

  func startTiming(_ operationName: String) {
    startTimes[operationName] = CFAbsoluteTimeGetCurrent()
    operationCounts[operationName, default: 0] += 1

    if isVerbose {
      print("⏱️  Started: \(operationName)")
    }
  }

  func stopTiming(_ operationName: String) -> TimeInterval {
    guard let startTime = startTimes[operationName] else {
      if isVerbose {
        print("⚠️  No start time found for operation: \(operationName)")
      }
      return 0
    }

    let endTime = CFAbsoluteTimeGetCurrent()
    let duration = endTime - startTime

    // Update cumulative timing
    timings[operationName, default: 0] += duration
    startTimes.removeValue(forKey: operationName)

    if isVerbose {
      print("✅ Completed: \(operationName) in \(formatDuration(duration))")
    }

    return duration
  }

  func measureOperation<T>(_ operationName: String, operation: () throws -> T) rethrows -> T {
    startTiming(operationName)
    defer { _ = stopTiming(operationName) }
    return try operation()
  }

  func measureAsyncOperation<T>(_ operationName: String, operation: () async throws -> T)
    async rethrows -> T
  {
    startTiming(operationName)
    defer { _ = stopTiming(operationName) }
    return try await operation()
  }

  // MARK: - Batch Operations Timing

  func measureBatchOperation<T>(_ operationName: String, items: [T], operation: (T) throws -> Void)
    rethrows
  {
    let batchName = "\(operationName) (batch of \(items.count))"
    startTiming(batchName)
    defer { _ = stopTiming(batchName) }

    if isVerbose {
      print("🔄 Processing \(items.count) items for \(operationName)")
    }

    for (index, item) in items.enumerated() {
      if isVerbose && items.count > 10 && index % (items.count / 10) == 0 {
        print(
          "  Progress: \(index)/\(items.count) (\(Int(Double(index) / Double(items.count) * 100))%)"
        )
      }
      try operation(item)
    }
  }

  // MARK: - Reporting

  func printTimingReport() {
    guard !timings.isEmpty else {
      print("No timing data collected")
      return
    }

    print("\n⏱️  Performance Report:")
    print("─" + String(repeating: "─", count: 50))

    let sortedTimings = timings.sorted { $0.value > $1.value }

    for (operation, totalTime) in sortedTimings {
      let count = operationCounts[operation] ?? 1
      let averageTime = totalTime / Double(count)

      print("  \(operation):")
      print("    Total: \(formatDuration(totalTime))")
      if count > 1 {
        print("    Count: \(count)")
        print("    Average: \(formatDuration(averageTime))")
      }
    }

    let totalTime = timings.values.reduce(0, +)
    print("\n  Total measured time: \(formatDuration(totalTime))")
  }

  func getTimingData() -> [String: (total: TimeInterval, count: Int, average: TimeInterval)] {
    var result: [String: (total: TimeInterval, count: Int, average: TimeInterval)] = [:]

    for (operation, totalTime) in timings {
      let count = operationCounts[operation] ?? 1
      let averageTime = totalTime / Double(count)
      result[operation] = (total: totalTime, count: count, average: averageTime)
    }

    return result
  }

  // MARK: - Memory Usage Tracking

  func getCurrentMemoryUsage() -> UInt64 {
    var info = mach_task_basic_info()
    var count = mach_msg_type_number_t(
      MemoryLayout<mach_task_basic_info>.size / MemoryLayout<integer_t>.size)

    // Ensure count is valid before proceeding
    guard count > 0 else { return 0 }

    let result = withUnsafeMutablePointer(to: &info) {
      $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
        task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
      }
    }

    if result == KERN_SUCCESS {
      return info.resident_size
    }
    return 0
  }

  func measureMemoryUsage(_ operationName: String, operation: () throws -> Void) rethrows {
    let beforeMemory = getCurrentMemoryUsage()
    try operation()
    let afterMemory = getCurrentMemoryUsage()

    let memoryDelta = Int64(afterMemory) - Int64(beforeMemory)

    if isVerbose {
      print("🧠 Memory change for \(operationName): \(formatMemory(memoryDelta))")
    }
  }

  // MARK: - Formatting Helpers

  private func formatDuration(_ duration: TimeInterval) -> String {
    if duration >= 1.0 {
      return String(format: "%.2fs", duration)
    } else if duration >= 0.001 {
      return String(format: "%.1fms", duration * 1000)
    } else {
      return String(format: "%.1fμs", duration * 1_000_000)
    }
  }

  private func formatMemory(_ bytes: Int64) -> String {
    let absBytes = abs(bytes)
    let sign = bytes >= 0 ? "+" : "-"

    if absBytes >= 1024 * 1024 {
      return String(format: "%@%.1f MB", sign, Double(absBytes) / (1024 * 1024))
    } else if absBytes >= 1024 {
      return String(format: "%@%.1f KB", sign, Double(absBytes) / 1024)
    } else {
      return String(format: "%@%lld bytes", sign, absBytes)
    }
  }

  // MARK: - Cache Statistics and Debug

  // Note: Cache statistics are managed by CacheManager
  // This method is left for backward compatibility
  func printCacheStatistics() {
    // Implementation moved to CacheManager.printCacheStatistics()
  }

  func resetStatistics() {
    // Reset only timing statistics
    timings.removeAll()
    operationCounts.removeAll()
  }

  // MARK: - Quick Performance Test

  func benchmarkOperation(_ name: String, iterations: Int = 100, operation: () throws -> Void)
    rethrows
  {
    guard isVerbose else { return }

    print("🚀 Benchmarking \(name) (\(iterations) iterations)...")

    let startTime = CFAbsoluteTimeGetCurrent()
    for _ in 0..<iterations {
      try operation()
    }
    let endTime = CFAbsoluteTimeGetCurrent()

    let totalTime = endTime - startTime
    let averageTime = totalTime / Double(iterations)

    print("  Total: \(formatDuration(totalTime))")
    print("  Average: \(formatDuration(averageTime))")
    print("  Operations/sec: \(Int(Double(iterations) / totalTime))")
  }
}

// MARK: - Global Performance Profiler

/// Global performance profiler instance
private var globalProfiler: PerformanceProfiler?

/// Initialize global profiler with verbose flag
func initializePerformanceProfiler(verbose: Bool) {
  globalProfiler = PerformanceProfiler(verbose: verbose)
}

/// Get global profiler instance
func getPerformanceProfiler() -> PerformanceProfiler? {
  return globalProfiler
}

/// Measure an operation using the global profiler
func measureGlobalOperation<T>(_ operationName: String, operation: () throws -> T) rethrows -> T {
  if let profiler = globalProfiler {
    return try profiler.measureOperation(operationName, operation: operation)
  } else {
    return try operation()
  }
}
