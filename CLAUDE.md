# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with the xcodeproj-cli repository.

## IMPORTANT INSTRUCTIONS ⚠️
- **NEVER** say things like "you're absolutely right". Instead, **be critical and sceptical** if I say something that you disagree with. Let's discuss it first. We're trying to reduce sycophancy here.
- **CRITICAL: NEVER CREATE MASSIVE, OVER-ENGINEERED IMPLEMENTATIONS** - Always start minimal and only add complexity when explicitly requested (i.e. use a KISS, YAGNI and DRY approach).
- Store any temporary files in the `@ai_docs/temp/` directory (if not otherwise specified), **never** in the root directory.
- **WHEN MODIFYING EXISTING CODE**, aim for minimal changes with surgical precision, made methodically step by step, rather than large-scale, broad sweeping changes.
- **When researching** never include an older year in web searches, i.e. prefer search patterns like "XcodeProj swift example usage" over "XcodeProj swift example usage 2024".
- **USE CURRENT DATE AND TIME** - Use `date` command for getting current date/time or timestamps information, when comparing file dates, doing research, checking log entries and in many other cases where current date/time is needed.


## Project Overview

xcodeproj-cli is a powerful command-line utility for programmatically manipulating Xcode project files (.xcodeproj) without requiring Xcode or Docker. It provides comprehensive project management capabilities including file operations, target management, build configuration, and Swift Package Manager integration.

## Key Technologies

- **Swift 5.0+** - Core implementation language
- **swift-sh** - Swift script dependency management
- **XcodeProj Library** (tuist/XcodeProj v8.12.0+) - Core .xcodeproj manipulation
- **PathKit** - Swift path manipulation library
- **macOS 10.15+** - Required platform

## Quick Reference

```bash
# Always specify project (default: MyProject.xcodeproj)
./xcodeproj-cli.swift --project App.xcodeproj <command>

# Most common operations
add-file File.swift Group Target        # Add single file
add-folder /path/to/folder Group Target --recursive  # Add folder
create-groups Group/SubGroup           # Create group hierarchy
list-targets                          # Show all targets
validate                              # Check project integrity
```

## Architecture Overview

### Project Structure
```
xcodeproj-cli/
├── src/
│   └── xcodeproj-cli.swift   # Main tool implementation (30+ commands)
├── test/
│   ├── test.sh                # Shell-based test runner
│   ├── TestSuite.swift        # Swift test suite
│   ├── create_test_project.swift # Test project generator
│   └── TestData/             # Test fixtures (SwiftUI-based)
├── README.md                  # Main documentation
├── EXAMPLES.md               # Usage examples and workflows
├── LICENSE                   # MIT License
├── VERSION                   # Version tracking
└── install.sh               # Installation script
```

### Core Components

1. **Command Parser**: Processes CLI arguments and routes to appropriate handlers
2. **Project Manipulator**: Core XcodeProj library wrapper with safety checks
3. **File Manager**: Smart file filtering and type detection
4. **Group Manager**: Hierarchical group creation and management
5. **Target Manager**: Target creation, duplication, and configuration
6. **Build Settings Manager**: Build configuration manipulation
7. **SPM Integration**: Swift Package Manager dependency management

## Development Philosophy

### Core Principles

**No Backwards Compatibility**: We prioritize clean, modern code over maintaining legacy support. Breaking changes are acceptable when improving the tool.

**Never Use Version Suffixes**: When refactoring, never use names like "v2", "New", "Enhanced", etc. Simply refactor existing implementations in place.

**Fail Fast with Clear Messages**: When errors occur, provide immediately actionable error messages that guide users to the solution.

**Direct Manipulation Over Abstraction**: Prefer direct XcodeProj API usage over creating unnecessary abstraction layers.

### Code Style
- Use Swift naming conventions (PascalCase for types, camelCase for methods)
- Prefer guard statements for early returns
- Use descriptive error messages with context
- Keep functions focused and single-purpose
- Use meaningful variable names
- Avoid code duplication - check for existing functionality first

### Error Handling
- Use custom `ProjectError` enum for domain-specific errors
- Provide actionable error messages with specific remediation steps
- Always validate inputs before operations
- Fail fast with clear error reporting
- Exit with meaningful codes (0 = success, 1 = error, specific codes for specific failures)

### Testing Philosophy
- Test suite uses real project manipulation (not mocks)
- Tests are organized by feature area
- Each test should be independent and restorable
- Use backup/restore pattern for destructive tests
- Always verify both positive and negative cases

## Important Patterns

### File Filtering
The tool automatically excludes:
- `.DS_Store`, `Thumbs.db`
- `.git`, `.gitignore`, `.gitkeep`
- Files ending with `.orig`, `.bak`, `.tmp`, `.temp`
- Hidden files (except `.h` and `.m`)

### Build Phase Assignment
- Source files (`.swift`, `.m`, `.mm`, `.c`, `.cpp`) → Sources build phase
- Resources (`.xib`, `.storyboard`, `.xcassets`, `.strings`) → Resources build phase
- Frameworks (`.framework`, `.dylib`) → Frameworks build phase

### Group Path Resolution
- Groups are searched recursively through the project hierarchy
- Both `path` and `name` properties are checked for matches
- Parent groups are created automatically if needed

## Command Categories

### File Operations
- `add-file`, `add-files`, `add-folder`, `add-sync-folder`
- `move-file`, `remove-file`

### Target Operations
- `add-target`, `duplicate-target`, `remove-target`
- `add-dependency`

### Build Configuration
- `set-build-setting`, `get-build-settings`
- `list-build-configs`

### Dependencies
- `add-framework`
- `add-swift-package`, `remove-swift-package`, `list-swift-packages`

### Project Structure
- `create-groups`, `list-groups`
- `list-files`, `list-targets`
- `validate`

## Testing Guidelines

### Running Tests
```bash
# Quick validation tests (read-only)
cd test && ./test.sh

# Full test suite (modifies test project)
cd test && ./TestSuite.swift

# Create fresh test project
cd test && ./create_test_project.swift
```

### Adding New Tests
1. Add test method to appropriate category in TestSuite.swift
2. Use `test("description") { ... }` helper
3. Return boolean for success/failure
4. Ensure test is restorable (doesn't permanently modify test project)

## Important Instructions for AI Agents

### Critical Rules
- **NEVER modify production projects without backups** - Always create `.backup` before changes
- **NEVER create duplicate files** - No "Fixed", "New", "v2" suffixes. Fix files in place
- **ALWAYS validate after bulk operations** - Run `validate` command after major changes
- **ALWAYS use --project flag in examples** - Don't assume default project names

### When Working with This Tool
1. **Check current directory**: Ensure you're in the right location before running commands
2. **Verify project exists**: Check for `.xcodeproj` file before attempting operations
3. **Use proper escaping**: Quote file paths with spaces or special characters
4. **Chain commands carefully**: Some operations depend on others (create group before adding files)

## Common Tasks

### Adding a New Command
1. Add command case to main switch statement
2. Implement handler function with proper error handling
3. Add validation for required parameters
4. Update help text with new command
5. Add test coverage in TestSuite.swift
6. Document in README.md and EXAMPLES.md

### Debugging Issues
- Use `print()` statements for debug output
- Check `.xcodeproj/project.pbxproj` directly for state
- Use `validate` command to check project integrity
- Test with backup projects to avoid data loss
- Look for orphaned file references or missing build files
- Verify group hierarchy matches file system structure

## Performance Considerations

- File operations are batched when possible
- swift-sh caches dependencies after first run
- Group lookups are recursive but typically fast
- Large projects (1000+ files) may need optimization

## Troubleshooting

### Common Issues and Solutions

**"swift-sh not found"**
```bash
# Install via Homebrew
brew install swift-sh
```

**"Permission denied" when running tool**
```bash
# Make executable
chmod +x xcodeproj-cli.swift
```

**"File already exists" errors**
- Check if file was already added to project
- Use `list-files` to see current files
- Remove file first if replacing: `remove-file path/to/file`

**"Group not found" errors**
- Create parent group first: `create-groups ParentGroup`
- Use `list-groups` to see available groups
- Check for typos in group names

**"Target not found" errors**
- Use `list-targets` to see available targets
- Check exact target name spelling
- Ensure target exists before adding dependencies

**XcodeProj dependency errors**
```bash
# Clear cache and retry
rm -rf ~/Library/Developer/swift-sh.cache
```

**Project corruption after operations**
```bash
# Restore from backup
cp -r MyProject.xcodeproj.backup MyProject.xcodeproj
```

### Recovery Procedures

**Before Major Changes**:
```bash
# Always backup first
cp -r MyProject.xcodeproj MyProject.xcodeproj.backup

# Verify backup
ls -la *.xcodeproj.backup
```

**After Failed Operations**:
1. Check error message for specific issue
2. Run `validate` to identify problems
3. Restore from backup if needed
4. Try operation again with corrected parameters

## Security Considerations

- Never execute arbitrary scripts from project files
- Validate all file paths to prevent directory traversal
- Don't expose sensitive build settings
- Be cautious with build phase scripts
- Sanitize user input in generated build scripts

## Useful Resources

- [XcodeProj Documentation](https://github.com/tuist/XcodeProj)
- [swift-sh Documentation](https://github.com/mxcl/swift-sh)
- [Xcode Build Settings Reference](https://developer.apple.com/documentation/xcode/build-settings-reference)
- [Swift Package Manager](https://swift.org/package-manager/)

## Repository

- **GitHub**: https://github.com/tolo/xcodeproj-cli
- **Issues**: https://github.com/tolo/xcodeproj-cli/issues
- **License**: MIT
- **Changelog**: See [CHANGELOG.md](./CHANGELOG.md) for version history