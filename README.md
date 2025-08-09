# XcodeProj CLI

A powerful command-line utility for manipulating Xcode project files (.xcodeproj) without requiring Xcode or Docker. Designed for both **human developers** and **AI coding assistants** (like Claude Code, GitHub Copilot, and other LLM-based tools) to automate Xcode project management.

## Acknowledgments

This tool is built on top of the excellent [XcodeProj](https://github.com/tuist/XcodeProj) library by the Tuist team, which provides the core functionality for reading and writing Xcode project files.

The tool's comprehensive feature set was inspired by [xcodeproj-mcp-server](https://github.com/giginet/xcodeproj-mcp-server) by giginet, reimplemented as a standalone Swift script for easier deployment and use.

## Why This Tool?

### 🤖 AI-Agent Friendly
- **Simple CLI interface** - Easy for LLMs to understand and use
- **Clear error messages** - Helps agents self-correct
- **Dry-run mode** - Agents can preview changes before applying
- **Predictable behavior** - Consistent outputs for reliable automation

### 👨‍💻 Developer Friendly
- **No Xcode required** - Works on any macOS system
- **Script-friendly** - Perfect for CI/CD pipelines
- **Fast execution** - Direct Swift implementation
- **Comprehensive commands** - Cover all common project operations

## Features

### 🎯 Complete Project Manipulation
- **File Management** - Add, remove, move files and folders
- **Target Management** - Create, duplicate, remove targets
- **Build Configuration** - Modify build settings and configurations
- **Dependencies** - Manage frameworks and target dependencies
- **Swift Packages** - Add/remove SPM dependencies with version validation
- **Build Phases** - Add run scripts and copy files phases
- **Group Management** - Create and organize project groups

### ✨ Smart Features
- **Recursive folder scanning** with intelligent file filtering
- **Automatic build phase assignment** (sources vs resources)
- **File type detection** for 20+ file types
- **Batch operations** for efficiency
- **Comprehensive validation** and error handling
- **Dry-run mode** - Preview changes before applying
- **Atomic saves** - Automatic backup and rollback on failure
- **Transaction support** - Group operations with rollback capability

### 🔒 Security Features
- **Path traversal protection** - Prevents directory escaping
- **Command injection prevention** - Escapes shell metacharacters
- **Input validation** - Validates versions, URLs, and paths
- **Safe file operations** - Atomic writes with automatic backup

## Installation

### Prerequisites
- macOS 10.15+
- Swift 5.0+
- [swift-sh](https://github.com/mxcl/swift-sh) (for dependency management)

### Installation

#### Quick Install (Recommended)
Install dependencies and download the tool in one command:
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/tolo/xcodeproj-cli/main/install.sh)"
```

This will:
- Check for and install `swift-sh` if needed (via Homebrew)
- Download the tool to your current directory
- Make it executable

#### Manual Install
If you prefer to install manually:

1. Install swift-sh (required for dependency management):
```bash
brew install swift-sh
```

2. Download the tool:
```bash
curl -O https://raw.githubusercontent.com/tolo/xcodeproj-cli/main/src/xcodeproj-cli.swift
chmod +x xcodeproj-cli.swift
```

#### Clone Repository
To get the full project with tests and examples:
```bash
git clone https://github.com/tolo/xcodeproj-cli.git
cd xcodeproj-cli
./install.sh
```


## Usage

### Getting Started

#### Command Syntax & Options
```bash
# Basic syntax
./xcodeproj-cli.swift [options] <command> [arguments]

# Specify project (default: looks for *.xcodeproj in current directory)
./xcodeproj-cli.swift --project MyApp.xcodeproj <command>

# Preview changes without saving (dry-run mode)
./xcodeproj-cli.swift --dry-run <command>

# Combine options
./xcodeproj-cli.swift --project App.xcodeproj --dry-run add-file File.swift --group Group --targets Target

# Many flags have short forms for convenience:
# --group / -g, --targets / -t, --recursive / -r
./xcodeproj-cli.swift add-file Helper.swift -g Utils -t MyApp
```

### Common Workflows

#### 📁 Working with Files and Folders

**Adding Files**
```bash
# Add a single file to a group and target
./xcodeproj-cli.swift add-file Sources/Helper.swift --group Utils --targets MyApp

# Add multiple files at once
./xcodeproj-cli.swift add-files \
  Model.swift:Models \
  View.swift:Views \
  Controller.swift:Controllers \
  --targets MyApp
```

**Adding Folders**
```bash
# Add all files from a folder recursively (files are added individually)
./xcodeproj-cli.swift add-folder Sources/Features --group Features --targets MyApp --recursive

# Add a synchronized folder (Xcode 16+ - auto-syncs with filesystem)
./xcodeproj-cli.swift add-sync-folder Resources/Assets --group Assets --targets MyApp
```

**Managing Files**
```bash
# Move or rename a file
./xcodeproj-cli.swift move-file OldPath/File.swift NewPath/File.swift

# Remove a file from the project
./xcodeproj-cli.swift remove-file Sources/Deprecated.swift

# Remove an entire folder
./xcodeproj-cli.swift remove-folder Resources/OldAssets
```

#### 🗂️ Working with Groups (Virtual Organization)

```bash
# Create groups for organizing files (no filesystem folders created)
./xcodeproj-cli.swift create-groups UI/Components UI/Screens Services/API

# List all groups in the project
./xcodeproj-cli.swift list-groups

# List files in a specific group
./xcodeproj-cli.swift list-files UI/Components

# Remove a group (files remain in project)
./xcodeproj-cli.swift remove-group UI/OldComponents
```

#### 🎯 Target Management

```bash
# Create a new target
./xcodeproj-cli.swift add-target MyFramework --type com.apple.product-type.framework --bundle-id com.example.framework

# Duplicate an existing target
./xcodeproj-cli.swift duplicate-target MyApp MyAppPro --bundle-id com.example.pro

# Remove a target
./xcodeproj-cli.swift remove-target OldTarget

# Add dependency between targets
./xcodeproj-cli.swift add-dependency MyApp --depends-on MyFramework

# List all targets
./xcodeproj-cli.swift list-targets
```

#### ⚙️ Build Settings & Configuration

```bash
# Set a build setting for specific targets
./xcodeproj-cli.swift set-build-setting SWIFT_VERSION 5.9 --targets MyApp,MyAppTests

# Get build settings for a target
./xcodeproj-cli.swift get-build-settings MyApp --config Debug

# List all build configurations
./xcodeproj-cli.swift list-build-configs --target MyApp
```

#### 📦 Dependencies & Frameworks

**System Frameworks**
```bash
# Add a system framework
./xcodeproj-cli.swift add-framework CoreData --target MyApp

# Add and embed a custom framework
./xcodeproj-cli.swift add-framework Custom.framework --target MyApp --embed
```

**Swift Package Manager**
```bash
# Add package with version requirement
./xcodeproj-cli.swift add-swift-package \
  https://github.com/Alamofire/Alamofire \
  --requirement "from: 5.8.0" \
  --target MyApp

# Add package from branch
./xcodeproj-cli.swift add-swift-package \
  https://github.com/realm/SwiftLint \
  --requirement "branch: main" \
  --target MyApp

# Remove a package
./xcodeproj-cli.swift remove-swift-package https://github.com/Alamofire/Alamofire

# List all packages
./xcodeproj-cli.swift list-swift-packages
```

#### 🔧 Build Phases

```bash
# Add a run script phase
./xcodeproj-cli.swift add-build-phase run_script \
  --name "SwiftLint" --target MyApp \
  --script "if which swiftlint; then swiftlint; fi"

# Add a copy files phase
./xcodeproj-cli.swift add-build-phase copy_files --name "Copy Fonts" --target MyApp
```

#### 🔍 Project Inspection & Validation

```bash
# Validate project integrity
./xcodeproj-cli.swift validate

# List and clean up invalid file references
./xcodeproj-cli.swift list-invalid-references
./xcodeproj-cli.swift remove-invalid-references

# List all files in the project
./xcodeproj-cli.swift list-files
```

## Understanding Xcode Project Organization

### Groups vs Folders vs Files - What's the Difference?

Xcode has three distinct ways to organize and reference files in your project:

#### 1️⃣ **Groups** - Virtual Organization Only
- **What**: Virtual containers that only exist in the `.xcodeproj` file
- **Icon**: Yellow folder icon in Xcode
- **Filesystem**: NO actual folders created on disk
- **Use When**: You want to organize files in Xcode differently than on disk
- **Commands**: `create-groups`, `remove-group`

```bash
# Create virtual organization structure
./xcodeproj-cli.swift create-groups UI/Components UI/Screens

# Files can be in any disk location but appear organized in Xcode
./xcodeproj-cli.swift add-file random/path/Button.swift --group UI/Components --targets MyApp
```

#### 2️⃣ **Folder References** - Live Filesystem Sync
- **What**: References to actual filesystem folders that auto-sync
- **Icon**: Blue folder icon in Xcode 16+ 
- **Filesystem**: Directly linked to a real folder - changes auto-reflect
- **Use When**: Resources/assets that change frequently outside Xcode
- **Commands**: `add-sync-folder`

```bash
# Creates a synchronized folder reference (Xcode 16+)
./xcodeproj-cli.swift add-sync-folder Resources/Images --group Images --targets MyApp
# Any files added to Resources/Images on disk automatically appear in Xcode
```

#### 3️⃣ **Regular File/Folder Addition** - Individual File References
- **What**: Adds files from a folder as individual references
- **Icon**: Individual file icons in Xcode
- **Filesystem**: Each file is tracked separately
- **Use When**: Source code where you want control over what's included
- **Commands**: `add-file`, `add-folder --recursive`

```bash
# Adds each file from the folder individually
./xcodeproj-cli.swift add-folder Sources/Features --group Features --targets MyApp --recursive
# You control exactly which files are included
```

### Common Scenarios Explained

**Scenario 1: Organizing existing files**
```bash
# Just create groups - no need to move files on disk
./xcodeproj-cli.swift create-groups Architecture/MVVM/Models Architecture/MVVM/Views
./xcodeproj-cli.swift add-file Sources/User.swift --group Architecture/MVVM/Models --targets MyApp
```

**Scenario 2: Adding a folder of source files**
```bash
# No groups needed - they're created automatically
./xcodeproj-cli.swift add-folder Sources/NewFeature --group Features --targets MyApp --recursive
```

**Scenario 3: Adding frequently-changing resources**
```bash
# Use sync folder for assets that designers update
./xcodeproj-cli.swift add-sync-folder Design/Assets --group Resources --targets MyApp
```


## For AI Coding Assistants

If you're an AI coding assistant (Claude Code, GitHub Copilot, etc.), here are key points:

### Quick Start
```bash
# Always specify the project file
./xcodeproj-cli.swift --project App.xcodeproj <command>

# Test your command first with dry-run
./xcodeproj-cli.swift --dry-run --project App.xcodeproj add-file Helper.swift --group Utils --targets App

# Common operations
add-file File.swift --group Group --targets Target  # Add single file
add-folder /path/to/folder --group Group --targets Target --recursive  # Add entire folder
list-targets                          # See available targets
validate                              # Check project health
```

### Best Practices
1. **Always use `--project`** to specify the exact .xcodeproj file
2. **Use `--dry-run`** first to preview changes
3. **Check available targets** with `list-targets` before adding files
4. **Use `list-groups`** to see the project structure
5. **Run `validate`** after bulk operations

### Path Handling
- Relative paths (e.g., `Sources/Helper.swift`) are preferred for project files
- Absolute paths (e.g., `/Users/dev/libs/SDK.framework`) work for external dependencies
- Single `../` is allowed for parent directory references
- Home directory `~/` expansion is supported

## Real-World Examples

### Setting Up a New Feature Module

```bash
# Create the folder structure
./xcodeproj-cli.swift create-groups \
  Features/UserProfile \
  Features/UserProfile/Models \
  Features/UserProfile/Views \
  Features/UserProfile/ViewModels

# Add all files from your feature folder
./xcodeproj-cli.swift add-folder \
  Sources/UserProfile \
  --group Features/UserProfile \
  --targets MyApp,MyAppTests \
  --recursive

# Add required dependencies
./xcodeproj-cli.swift add-swift-package \
  https://github.com/firebase/firebase-ios-sdk \
  --requirement "from: 10.0.0" \
  --target MyApp
```

### Creating Multiple App Variants

```bash
# Create Pro and Lite versions of your app
./xcodeproj-cli.swift duplicate-target MyApp MyAppPro --bundle-id com.example.pro
./xcodeproj-cli.swift duplicate-target MyApp MyAppLite --bundle-id com.example.lite

# Configure different build settings for each variant
./xcodeproj-cli.swift set-build-setting PRODUCT_NAME "MyApp Pro" --targets MyAppPro
./xcodeproj-cli.swift set-build-setting ENABLE_PREMIUM_FEATURES YES --targets MyAppPro
./xcodeproj-cli.swift set-build-setting ENABLE_ADS YES --targets MyAppLite
```

### Adding CI/CD Build Phases

```bash
# Add SwiftLint
./xcodeproj-cli.swift add-build-phase \
  run_script \
  --name "SwiftLint" \
  --target MyApp \
  --script 'if which swiftlint > /dev/null; then
  swiftlint
else
  echo "warning: SwiftLint not installed"
fi'

# Add automatic build number increment
./xcodeproj-cli.swift add-build-phase \
  run_script \
  --name "Increment Build Number" \
  --target MyApp \
  --script 'buildNumber=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "${PROJECT_DIR}/${INFOPLIST_FILE}")
buildNumber=$((buildNumber + 1))
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $buildNumber" "${PROJECT_DIR}/${INFOPLIST_FILE}"'
```

### Batch Import Script

```bash
#!/bin/bash
# Import all Swift files from a directory while preserving structure
find Sources -name "*.swift" | while read file; do
  group=$(dirname "$file" | sed 's/Sources\//Classes\//')
  ./xcodeproj-cli.swift add-file "$file" --group "$group" --targets MyApp
done
```

## Command Reference

### 📂 Project Inspection
| Command | Description | Example |
|---------|-------------|---------|
| `list-targets` | Show all targets in project | `list-targets` |
| `list-groups` | Show project group hierarchy | `list-groups` |
| `list-files` | Show files (all or in group) | `list-files [group-name]` |
| `validate` | Check project integrity | `validate` |
| `list-invalid-references` | Find broken file references | `list-invalid-references` |
| `remove-invalid-references` | Clean up broken references | `remove-invalid-references` |

### 🗂️ Group Management
| Command | Description | Example |
|---------|-------------|---------|  
| `create-groups` | Create virtual groups | `create-groups UI/Components Services/API` |
| `remove-group` | Remove a group | `remove-group OldGroup` |

### 📁 File & Folder Management
| Command | Description | Example |
|---------|-------------|---------|
| `add-file` | Add single file | `add-file Path/File.swift --group GroupName --targets Target1,Target2` |
| `add-files` | Add multiple files | `add-files file1:group1 file2:group2 --targets Target` |
| `add-folder` | Add folder contents as individual files | `add-folder Path/Folder --group GroupName --targets Target --recursive` |
| `add-sync-folder` | Add synced folder reference (Xcode 16+) | `add-sync-folder Path/Assets --group GroupName --targets Target` |
| `move-file` | Move or rename file | `move-file old/path new/path` |
| `remove-file` | Remove file from project | `remove-file Path/File.swift` |
| `remove-folder` | Remove folder reference | `remove-folder Path/Folder` |

### 🎯 Target Operations
| Command | Description | Example |
|---------|-------------|---------|
| `add-target` | Create new target | `add-target MyKit --type com.apple.product-type.framework --bundle-id com.example.kit` |
| `duplicate-target` | Clone existing target | `duplicate-target MyApp MyAppPro --bundle-id com.example.pro` |
| `remove-target` | Delete target | `remove-target OldTarget` |
| `add-dependency` | Link targets | `add-dependency AppTarget --depends-on FrameworkTarget` |

### ⚙️ Build Settings
| Command | Description | Example |
|---------|-------------|---------|
| `set-build-setting` | Modify build setting | `set-build-setting SWIFT_VERSION 5.9 --targets MyApp,Tests` |
| `get-build-settings` | View build settings | `get-build-settings MyApp --config Debug` |
| `list-build-configs` | Show configurations | `list-build-configs --target MyApp` |

### 📦 Dependencies & Packages
| Command | Description | Example |
|---------|-------------|---------|
| `add-framework` | Add framework | `add-framework CoreData --target MyApp` |
| `add-framework` | Embed framework | `add-framework Custom.framework --target MyApp --embed` |
| `add-swift-package` | Add Swift package | `add-swift-package https://github.com/pkg --requirement "from: 1.0.0" --target MyApp` |
| `remove-swift-package` | Remove package | `remove-swift-package https://github.com/pkg` |
| `list-swift-packages` | Show all packages | `list-swift-packages` |

### 🔨 Build Phases
| Command | Description | Example |
|---------|-------------|---------|
| `add-build-phase` | Add run script | `add-build-phase run_script --name "SwiftLint" --target MyApp --script "swiftlint"` |
| `add-build-phase` | Add copy files | `add-build-phase copy_files --name "Copy Resources" --target MyApp` |


## File Filtering

The tool automatically excludes certain files when adding folders:

### Excluded Files
- `.DS_Store`
- `.git`, `.gitignore`, `.gitkeep`
- `Thumbs.db`
- Files starting with `.` (except `.h` and `.m`)
- Files ending with `.orig`, `.bak`, `.tmp`, `.temp`

## Supported File Types

The tool recognizes and properly categorizes:

- **Source Files**: `.swift`, `.m`, `.mm`, `.cpp`, `.cc`, `.cxx`, `.c`, `.h`, `.hpp`
- **Interface Files**: `.xib`, `.storyboard`
- **Resources**: `.xcassets`, `.strings`, `.plist`, `.json`
- **Media**: `.png`, `.jpg`, `.jpeg`, `.gif`, `.mp3`, `.wav`, `.mp4`, `.mov`
- **Frameworks**: `.framework`, `.dylib`, `.a`

## Product Types

When creating targets, use these Apple product type identifiers:

- `com.apple.product-type.application` - iOS/macOS App
- `com.apple.product-type.framework` - Dynamic Framework
- `com.apple.product-type.library.static` - Static Library
- `com.apple.product-type.bundle` - Bundle
- `com.apple.product-type.bundle.unit-test` - Unit Test Bundle
- `com.apple.product-type.bundle.ui-testing` - UI Test Bundle
- `com.apple.product-type.app-extension` - App Extension
- `com.apple.product-type.watchkit2-extension` - WatchKit Extension

## Advanced Usage

### Tips for Efficient Usage

**Batch Operations**
```bash
# Add multiple files with different groups
./xcodeproj-cli.swift add-files \
  Model.swift:Models \
  View.swift:Views \
  ViewModel.swift:ViewModels \
  --targets MyApp,MyAppTests

# Create a complete group structure at once
./xcodeproj-cli.swift create-groups \
  Features/Authentication \
  Features/Profile \
  Features/Settings \
  Services/API \
  Services/Storage
```

**Using Dry-Run Mode**
```bash
# Always test complex operations first
./xcodeproj-cli.swift --dry-run add-folder LargeFolder / MyApp --recursive
# Review output, then run without --dry-run if correct
```

### Real-World Examples

**Example 1: Adding a new feature module**
```bash
# Add source files from a feature folder (groups are created automatically)
./xcodeproj-cli.swift add-folder Sources/Checkout --group Features/Checkout --targets ShoppingCart --recursive

# Add the payment SDK
./xcodeproj-cli.swift add-swift-package https://github.com/stripe/stripe-ios --requirement "from: 23.0.0" --target ShoppingCart
```

**Example 2: Setting up a Pro version of your app**
```bash
# Duplicate the target
./xcodeproj-cli.swift duplicate-target MyApp MyAppPro --bundle-id com.example.pro

# Customize the Pro version
./xcodeproj-cli.swift set-build-setting PRODUCT_NAME "MyApp Pro" --targets MyAppPro
./xcodeproj-cli.swift set-build-setting ENABLE_PRO_FEATURES YES --targets MyAppPro
```

**Example 3: Organizing an existing messy project**
```bash
# Create a clean structure with groups (no files are moved on disk)
./xcodeproj-cli.swift create-groups \
  Architecture/Models \
  Architecture/Views \
  Architecture/ViewModels \
  Architecture/Services \
  Architecture/Utilities

# Now you can add existing files to these groups
./xcodeproj-cli.swift add-file Sources/User.swift --group Architecture/Models --targets MyApp
./xcodeproj-cli.swift add-file Sources/LoginView.swift --group Architecture/Views --targets MyApp
```

## Error Handling

The tool provides clear error messages for common issues:

- File already exists in project
- Group or target not found
- Invalid product type
- Missing required parameters
- Validation failures

## Performance

- **Fast execution** - No Xcode or Docker overhead
- **Batch processing** - Multiple operations in single run
- **Smart caching** - Reuses swift-sh dependency cache
- **Minimal dependencies** - Only requires XcodeProj library

## Comparison with Alternatives

| Feature | xcodeproj-cli | xcodeproj-mcp-server | Xcode |
|---------|---------------|---------------------|-------|
| No GUI Required | ✅ | ✅ | ❌ |
| No Docker Required | ✅ | ❌ | ✅ |
| Command Line | ✅ | ✅ | ❌ |
| Scriptable | ✅ | ✅ | ⚠️ |
| All Project Features | ✅ | ✅ | ✅ |
| Speed | Fast | Slower | Slow |
| Installation | Simple | Complex | N/A |

## Troubleshooting

### Common Issues

**swift-sh not found**
```bash
brew install swift-sh
```

**Permission denied**
```bash
chmod +x xcodeproj-cli.swift
```

**XcodeProj dependency error**
```bash
# Clear cache and retry
rm -rf ~/Library/Developer/swift-sh.cache
```

**Project file backup**
```bash
# Always backup before major changes
cp -r PhotoEditor.xcodeproj PhotoEditor.xcodeproj.backup
```

## Contributing

This tool is open for improvements! Feel free to:

1. Add new commands for specific workflows
2. Enhance error messages
3. Add more file type support
4. Improve performance
5. Add tests

## License

This tool is provided as-is for use in your projects. Feel free to modify and distribute as needed.

## Project Structure

```
xcodeproj-cli/
├── src/
│   └── xcodeproj-edit.swift   # Main tool implementation
├── test/
│   ├── test.sh                # Shell-based test runner
│   ├── TestSuite.swift        # Swift test suite
│   └── TestData/
│       └── TestProject.xcodeproj/  # Test project for validation
├── README.md                  # This file
├── EXAMPLES.md               # Usage examples and workflows
├── CHANGELOG.md              # Version history and changes
├── LICENSE                   # MIT License
├── VERSION                   # Current version number
└── install.sh               # Installation script
```

## Credits & Attribution

### Dependencies
- **[XcodeProj](https://github.com/tuist/XcodeProj)** (MIT License)
  - Created and maintained by the [Tuist](https://tuist.io) team
  - Provides the core Xcode project file manipulation capabilities
  - Version: 8.12.0+

- **[swift-sh](https://github.com/mxcl/swift-sh)** (Unlicense)
  - Created by Max Howell
  - Enables Swift scripts with package dependencies

### Inspiration
- **[xcodeproj-mcp-server](https://github.com/giginet/xcodeproj-mcp-server)** (MIT License)
  - Created by giginet
  - Inspired the comprehensive feature set and command structure
  - This tool reimplements similar functionality as a standalone Swift script

### Contributors
This tool was developed for Xcode project automation and is released under the MIT License for community use.

## Support

For issues, questions, or contributions, please visit:
https://github.com/tolo/xcodeproj-cli

## Changelog

See [CHANGELOG.md](./CHANGELOG.md) for a detailed history of changes.

---

*A comprehensive Xcode project manipulation tool*