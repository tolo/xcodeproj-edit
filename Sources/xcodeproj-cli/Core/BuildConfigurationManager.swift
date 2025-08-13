//
// BuildConfigurationManager.swift
// xcodeproj-cli
//
// Service for managing build configurations and .xcconfig files
//

import Foundation
import PathKit
import XcodeProj

/// Service for managing build configurations and .xcconfig files
class BuildConfigurationManager {
    private let xcodeproj: XcodeProj
    private let projectPath: Path
    private let pbxproj: PBXProj
    
    init(xcodeproj: XcodeProj, projectPath: Path) {
        self.xcodeproj = xcodeproj
        self.projectPath = projectPath
        self.pbxproj = xcodeproj.pbxproj
    }
    
    // MARK: - Configuration File Management
    
    /// Adds an .xcconfig file to a configuration
    func addConfigFile(
        configName: String,
        filePath: String,
        targetName: String? = nil
    ) throws {
        // Resolve the file path
        let resolvedPath: String
        if filePath.hasPrefix("/") {
            // Absolute path - convert to relative if possible
            let configPath = Path(filePath)
            let projectDir = projectPath.parent()
            if let relativePath = configPath.relative(to: projectDir) {
                resolvedPath = relativePath.string
            } else {
                resolvedPath = filePath
            }
        } else {
            resolvedPath = filePath
        }
        
        // Create or find file reference
        let fileRef: PBXFileReference
        if let existingRef = pbxproj.fileReferences.first(where: { $0.path == resolvedPath }) {
            fileRef = existingRef
        } else {
            // Create new file reference
            fileRef = PBXFileReference(
                sourceTree: .group,
                lastKnownFileType: "text.xcconfig",
                path: resolvedPath
            )
            pbxproj.add(object: fileRef)
            
            // Add to project group
            if let mainGroup = pbxproj.rootObject?.mainGroup {
                mainGroup.children.append(fileRef)
            }
        }
        
        // Apply to configurations
        if let targetName = targetName {
            // Apply to specific target
            guard let target = pbxproj.targets(named: targetName).first else {
                throw ProjectError.targetNotFound(targetName)
            }
            
            guard let configList = target.buildConfigurationList else {
                throw ProjectError.operationFailed("Target has no build configuration list")
            }
            
            for config in configList.buildConfigurations {
                if config.name == configName {
                    config.baseConfiguration = fileRef
                    print("✅ Added config file to \(targetName):\(configName)")
                }
            }
        } else {
            // Apply to project-level configurations
            guard let configList = pbxproj.rootObject?.buildConfigurationList else {
                throw ProjectError.operationFailed("Project has no build configuration list")
            }
            
            for config in configList.buildConfigurations {
                if config.name == configName {
                    config.baseConfiguration = fileRef
                    print("✅ Added config file to project:\(configName)")
                }
            }
        }
    }
    
    /// Removes an .xcconfig file from a configuration
    func removeConfigFile(
        configName: String,
        targetName: String? = nil
    ) throws {
        if let targetName = targetName {
            // Remove from specific target
            guard let target = pbxproj.targets(named: targetName).first else {
                throw ProjectError.targetNotFound(targetName)
            }
            
            guard let configList = target.buildConfigurationList else {
                throw ProjectError.operationFailed("Target has no build configuration list")
            }
            
            for config in configList.buildConfigurations {
                if config.name == configName {
                    config.baseConfiguration = nil
                    print("✅ Removed config file from \(targetName):\(configName)")
                }
            }
        } else {
            // Remove from project-level configurations
            guard let configList = pbxproj.rootObject?.buildConfigurationList else {
                throw ProjectError.operationFailed("Project has no build configuration list")
            }
            
            for config in configList.buildConfigurations {
                if config.name == configName {
                    config.baseConfiguration = nil
                    print("✅ Removed config file from project:\(configName)")
                }
            }
        }
    }
    
    /// Lists all configuration files
    func listConfigFiles() -> [(config: String, file: String, target: String?)] {
        var configFiles: [(config: String, file: String, target: String?)] = []
        
        // Project-level configurations
        if let configList = pbxproj.rootObject?.buildConfigurationList {
            for config in configList.buildConfigurations {
                if let baseConfig = config.baseConfiguration {
                    let filePath = baseConfig.path ?? baseConfig.name ?? "Unknown"
                    configFiles.append((config: config.name, file: filePath, target: nil))
                }
            }
        }
        
        // Target-level configurations
        for target in pbxproj.nativeTargets {
            if let configList = target.buildConfigurationList {
                for config in configList.buildConfigurations {
                    if let baseConfig = config.baseConfiguration {
                        let filePath = baseConfig.path ?? baseConfig.name ?? "Unknown"
                        configFiles.append((config: config.name, file: filePath, target: target.name))
                    }
                }
            }
        }
        
        return configFiles
    }
    
    // MARK: - Build Settings Management
    
    /// Copies build settings from one configuration to another
    func copyBuildSettings(
        sourceConfig: String,
        destConfig: String,
        targetName: String? = nil
    ) throws {
        if let targetName = targetName {
            // Copy target-level settings
            guard let target = pbxproj.targets(named: targetName).first else {
                throw ProjectError.targetNotFound(targetName)
            }
            
            guard let configList = target.buildConfigurationList else {
                throw ProjectError.operationFailed("Target has no build configuration list")
            }
            
            let sourceSettings = configList.buildConfigurations
                .first { $0.name == sourceConfig }?.buildSettings
            
            guard let settings = sourceSettings else {
                throw ProjectError.operationFailed("Source configuration '\(sourceConfig)' not found")
            }
            
            guard let destConfigObj = configList.buildConfigurations
                .first(where: { $0.name == destConfig }) else {
                throw ProjectError.operationFailed("Destination configuration '\(destConfig)' not found")
            }
            
            destConfigObj.buildSettings = settings
            print("✅ Copied build settings from \(sourceConfig) to \(destConfig) for target \(targetName)")
            
        } else {
            // Copy project-level settings
            guard let configList = pbxproj.rootObject?.buildConfigurationList else {
                throw ProjectError.operationFailed("Project has no build configuration list")
            }
            
            let sourceSettings = configList.buildConfigurations
                .first { $0.name == sourceConfig }?.buildSettings
            
            guard let settings = sourceSettings else {
                throw ProjectError.operationFailed("Source configuration '\(sourceConfig)' not found")
            }
            
            guard let destConfigObj = configList.buildConfigurations
                .first(where: { $0.name == destConfig }) else {
                throw ProjectError.operationFailed("Destination configuration '\(destConfig)' not found")
            }
            
            destConfigObj.buildSettings = settings
            print("✅ Copied build settings from \(sourceConfig) to \(destConfig) for project")
        }
    }
    
    /// Compares build settings between two configurations
    func diffBuildSettings(
        config1: String,
        config2: String,
        targetName: String? = nil
    ) -> [(key: String, value1: Any?, value2: Any?)] {
        let configList: XCConfigurationList?
        
        if let targetName = targetName {
            configList = pbxproj.targets(named: targetName).first?.buildConfigurationList
        } else {
            configList = pbxproj.rootObject?.buildConfigurationList
        }
        
        guard let list = configList else {
            return []
        }
        
        let settings1 = list.buildConfigurations
            .first { $0.name == config1 }?.buildSettings ?? BuildSettings()
        let settings2 = list.buildConfigurations
            .first { $0.name == config2 }?.buildSettings ?? BuildSettings()
        
        var differences: [(key: String, value1: Any?, value2: Any?)] = []
        
        // Get all keys from both configurations
        let allKeys = Set(settings1.keys).union(Set(settings2.keys))
        
        for key in allKeys.sorted() {
            let value1 = settings1[key]
            let value2 = settings2[key]
            
            // Compare values
            if !areSettingsEqual(value1, value2) {
                differences.append((key: key, value1: value1, value2: value2))
            }
        }
        
        return differences
    }
    
    /// Exports build settings to a file
    func exportBuildSettings(
        configName: String,
        outputPath: String,
        format: ExportFormat = .xcconfig,
        targetName: String? = nil
    ) throws {
        let configList: XCConfigurationList?
        
        if let targetName = targetName {
            guard let target = pbxproj.targets(named: targetName).first else {
                throw ProjectError.targetNotFound(targetName)
            }
            configList = target.buildConfigurationList
        } else {
            configList = pbxproj.rootObject?.buildConfigurationList
        }
        
        guard let list = configList else {
            throw ProjectError.operationFailed("No build configuration list found")
        }
        
        guard let config = list.buildConfigurations.first(where: { $0.name == configName }) else {
            throw ProjectError.operationFailed("Configuration '\(configName)' not found")
        }
        
        let content: String
        switch format {
        case .xcconfig:
            content = exportAsXCConfig(config.buildSettings)
        case .json:
            content = try exportAsJSON(config.buildSettings)
        }
        
        // Write to file
        let outputURL = URL(fileURLWithPath: outputPath)
        try content.write(to: outputURL, atomically: true, encoding: .utf8)
        
        print("✅ Exported build settings to \(outputPath)")
    }
    
    // MARK: - Private Helpers
    
    private func areSettingsEqual(_ value1: Any?, _ value2: Any?) -> Bool {
        switch (value1, value2) {
        case (nil, nil):
            return true
        case (nil, _), (_, nil):
            return false
        case let (v1 as String, v2 as String):
            return v1 == v2
        case let (v1 as [String], v2 as [String]):
            return v1 == v2
        case let (v1 as Bool, v2 as Bool):
            return v1 == v2
        case let (v1 as Int, v2 as Int):
            return v1 == v2
        default:
            return String(describing: value1) == String(describing: value2)
        }
    }
    
    private func exportAsXCConfig(_ settings: BuildSettings) -> String {
        var lines: [String] = []
        
        lines.append("// Build Settings exported from Xcode project")
        lines.append("")
        
        for (key, value) in settings.sorted(by: { $0.key < $1.key }) {
            let valueString = formatSettingValue(value)
            lines.append("\(key) = \(valueString)")
        }
        
        return lines.joined(separator: "\n")
    }
    
    private func exportAsJSON(_ settings: BuildSettings) throws -> String {
        var jsonDict: [String: Any] = [:]
        
        for (key, value) in settings {
            jsonDict[key] = value
        }
        
        let data = try JSONSerialization.data(withJSONObject: jsonDict, options: [.prettyPrinted, .sortedKeys])
        return String(data: data, encoding: .utf8) ?? "{}"
    }
    
    private func formatSettingValue(_ value: Any) -> String {
        switch value {
        case let array as [String]:
            return array.joined(separator: " ")
        case let string as String:
            return string
        case let bool as Bool:
            return bool ? "YES" : "NO"
        default:
            return String(describing: value)
        }
    }
    
    /// Export format options
    enum ExportFormat {
        case xcconfig
        case json
    }
}