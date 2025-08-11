# Changelog

All notable changes to xcodeproj-cli will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- `list-build-settings` command - Enhanced Xcode-style display of build settings with multiple output formats
  - Setting-centric view (like Xcode) showing values across configurations
  - `--json`/`-j` flag for JSON output suitable for automation
  - `--all`/`-a` flag to display all project and target settings at once
  - `--show-inherited`/`-i` flag to include inherited settings from project level
  - `--target`/`-t` flag for consistency with other commands
  - `--config`/`-c` flag to filter by specific configuration
  - Inline display for uniform values, expanded view for configuration-specific values
  - JSON output uses setting-centric structure for easier parsing
  - Clear inheritance tracking showing which settings override project values

### Changed
- Improved error handling consistency across all commands (exit codes)
- Enhanced error messages to include available options (e.g., list of valid targets)

### Fixed
- JSON error responses now properly structured with error details
- Eliminated code duplication in build settings display logic (~150 lines reduced)
- Fixed force unwrapping risks in configuration handling

## [1.1.0] - 2025-08-11

### Added
- `list-tree` command - Display complete project structure as a tree with filesystem paths for actual files/folders
- `add-group` command - Create empty virtual groups (renamed from `create-groups`)
- `remove-invalid-references` command - Automatically clean up broken file and folder references
- Enhanced test coverage for invalid references operations
- Improved test coverage for group operations
- Auto discovery of project file in current directory

### Changed
- `list-groups` command now uses tree-style formatting with box-drawing characters (├──, └──, │)
- `list-tree` intelligently shows paths only for actual file/folder references, not virtual groups
- `create-groups` command renamed to `add-group` for consistency
- `remove-folder` command deprecated in favor of `remove-group` (handles all group types)
- Improved documentation for groups vs folders vs file references
- Enhanced README with clearer explanations of Xcode project organization
- Promoted `list-tree` as the recommended command for viewing project structure

### Fixed
- Invalid folder references detection and removal
- Test suite compatibility improvements

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
