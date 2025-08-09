# Changelog

All notable changes to xcodeproj-cli will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-08-09

### 🎉 Initial Release

A powerful command-line utility for programmatically manipulating Xcode project files (.xcodeproj) without requiring Xcode or Docker.

### ✨ Core Features

#### 30+ Commands for Complete Project Manipulation
- **File Operations**: `add-file`, `add-files`, `add-folder`, `add-sync-folder`, `move-file`, `remove-file`
- **Target Management**: `add-target`, `duplicate-target`, `remove-target`, `list-targets`
- **Build Configuration**: `set-build-setting`, `get-build-settings`, `list-build-configs`
- **Dependencies**: `add-framework`, `add-dependency`, `add-swift-package`, `remove-swift-package`, `list-swift-packages`
- **Project Structure**: `create-groups`, `list-groups`, `list-files`, `validate`
- **Diagnostics**: `list-invalid-references` - Identifies invalid file and directory references

#### Smart File Handling
- **Automatic filtering** of system files (.DS_Store, .git, .bak, etc.)
- **Recursive folder scanning** with intelligent file type detection (20+ types supported)
- **Automatic build phase assignment** (sources vs resources)
- **Synchronized folder references** for dynamic content

#### Named Arguments CLI
- Clean, modern CLI with named arguments for better usability
- `--project` flag for working with any .xcodeproj file
- `-p` shorthand support
- `--dry-run` mode to preview changes without saving
- Clear, actionable error messages

### 🔒 Security Features
- **Path traversal protection** - Sanitizes file paths to prevent directory escaping
- **Command injection prevention** - Escapes shell metacharacters in build scripts
- **Input validation** - Validates package versions, URLs, and paths
- **Atomic file operations** - Automatic backup/restore on failures

### 🧪 Testing & Quality
- **Comprehensive test suite** with 25+ test cases
- **SwiftUI-based test data** for realistic testing scenarios
- **Security test suite** validating input sanitization
- **Swift test infrastructure** using modern testing patterns

### 📝 Developer Experience
- **Fast execution** via direct swift-sh script
- **Transaction support** with automatic rollback on failures
- **Extensive documentation** with real-world examples
- **Simple installation** via curl-based installer

### 📦 Requirements
- Swift 5.0+
- macOS 10.15+
- swift-sh (installed automatically)
- XcodeProj library v9.4.3+ (managed via swift-sh)

### 🚀 Installation
```bash
curl -fsSL https://raw.githubusercontent.com/tolo/xcodeproj-cli/main/install.sh | bash
```

### 📖 Documentation
- Comprehensive README with all commands
- Details -h and --help flags for usage
