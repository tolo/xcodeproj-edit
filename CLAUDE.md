# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with the xcodeproj-cli repository.

## IMPORTANT INSTRUCTIONS ⚠️
- **NEVER** say things like "you're absolutely right". Instead, **be critical and sceptical** if I say something that you disagree with. Let's discuss it first. We're trying to reduce sycophancy here.
- **CRITICAL: NEVER CREATE MASSIVE, OVER-ENGINEERED IMPLEMENTATIONS** - Always start minimal and only add complexity when explicitly requested (i.e. use a KISS, YAGNI and DRY approach).
- Store any temporary files in the `ai_docs/temp/` directory (if not otherwise specified), **never** in the root directory.
- **WHEN MODIFYING EXISTING CODE**, aim for minimal changes with surgical precision, made methodically step by step, rather than large-scale, broad sweeping changes.
- **When researching** never include an older year in web searches, i.e. prefer search patterns like "XcodeProj swift example usage" over "XcodeProj swift example usage 2024".
- **USE CURRENT DATE AND TIME** - Use `date` command for getting current date/time or timestamps information, when comparing file dates, doing research, checking log entries and in many other cases where current date/time is needed.


## Project Overview

xcodeproj-cli is a powerful command-line utility for programmatically manipulating Xcode project files (.xcodeproj) without requiring Xcode or Docker. It provides comprehensive project management capabilities including file operations, target management, build configuration, and Swift Package Manager integration.

## Key Technologies

- **Swift 5.0+** - Core implementation language
- **Swift Package Manager** - Dependency management and build system
- **XcodeProj Library** (tuist/XcodeProj v9.4.3+) - Core .xcodeproj manipulation
- **PathKit** - Swift path manipulation library
- **macOS 10.15+** - Required platform

## Quick Reference

```bash
# Always specify project (default: MyProject.xcodeproj)
xcodeproj-cli --project App.xcodeproj <command>

# Most common operations
add-file File.swift Group Target        # Add single file
add-folder /path/to/folder Group Target --recursive  # Add folder
create-groups Group/SubGroup           # Create group hierarchy
list-targets                          # Show all targets
validate                              # Check project integrity
```

## Project Structure (Essential)

```
xcodeproj-cli/
├── Sources/xcodeproj-cli/          # Main implementation
├── test/                           # Test suite and fixtures
├── Package.swift                   # SPM configuration
├── build-universal.sh              # Universal binary build
└── .github/workflows/              # CI/CD automation
```

## Core Components (Quick Reference)

- **CLIRunner** - Main orchestrator
- **CommandRegistry** - Command dispatch
- **XcodeProjService** - Project manipulation
- **CacheManager** - Performance optimization
- **TransactionManager** - Safe operations
- **ProjectValidator** - Integrity checking

> **📋 For detailed architecture information, see [ARCHITECTURE.md](./ARCHITECTURE.md)**

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


## Critical Development Guidelines and Standards

### Core Development Philosophy
- **Keep It Simple**: All design and implementations should be as simple as possible, but no simpler. Always prefer efficient and straightforward solutions over complex, over-engineered ones whenever possible. Simple solutions are easier to understand, maintain, and debug.
- **Avoid Overengineering**: Focus on simplicity and working solutions, not theoretical flexibility. Implement features only when they are needed, not when you anticipate they might be useful in the future (YAGNI).
- **Dependency Inversion**: High-level modules should not depend on low-level modules. Both should depend on abstractions. This principle enables flexibility and testability.
- **Separation of Concerns**: Each module or component should have a single responsibility. This makes the codebase easier to understand and maintain.
- **Avoid Premature Optimization**: Focus on writing clear and maintainable code first. Optimize only when performance issues are identified through profiling or established facts / best practices.
- **DRY (Don't Repeat Yourself)**: Avoid code duplication by abstracting common functionality into reusable components or services. This reduces maintenance overhead and improves code clarity. But only do this when it makes sense, and doesn't conflict with the *Avoid Overengineering* principle.

### Architectural Considerations
- Avoid major architectural changes to working features unless explicitly instructed
- When implementing features, always check existing patterns first
- Follow the modular architecture patterns documented in [ARCHITECTURE.md](./ARCHITECTURE.md)

### Workflow Patterns
- Focus only on code relevant to the task
- Only make changes that are requested or well-understood
- Preferably create tests BEFORE implementation (TDD)
- Break complex tasks into smaller, testable units
- Validate understanding before implementation
- Always use up-to-date documentation to ensure use of correct APIs
  - Use the `Context7` MCP for looking up API documentation
- Update README.md when important/major new features are added, dependencies change, or setup steps are modified.

#### Use Sub Agents for Complex Tasks
- Proactively delegate as much work as possible to the available sub agents for complex tasks, and let the main claude code agent act as an orchestrator.

### Coding Guidelines
- Log significant operations and errors
- Use descriptive variable names
- Use the simplest solution that meets the requirements
- Avoid code duplication - check for existing similar functionality first
- Never overwrite .env files without explicit confirmation
- Make absolutely sure implementations are based on the latest versions of frameworks/libraries
- Write thorough tests for all major functionality

#### Swift Code Style
- Use Swift naming conventions (PascalCase for types, camelCase for methods)
- Prefer guard statements for early returns

### Documentation Guidelines
- Never document code that is self-explanatory
- Never write full API-level documentation for application code
- For complex or non-obvious code, add concise comments explaining the purpose and logic (but only when needed)

### **COMMON PITFALLS TO AVOID**
- **NEVER** create duplicate files with version numbers or suffixes (e.g., file_v2.xyz, file_new.xyz) when refactoring or improving code
- **NEVER** modify core frameworks without explicit instruction
- **NEVER** add dependencies without checking existing alternatives
- **NEVER** create a new branch unless explicitly instructed to do so
- **ABSOLUTELY FORBIDDEN: NEVER USE `git rebase --skip` EVER** (can cause data loss and repository corruption, ask the user for help if you encounter rebase conflicts)

### **KNOWN DESIGN DECISIONS (Don't Second-Guess)**
- **Single `..` in paths is allowed** - This is intentional for parent directory access
- **XcodeProjUtility remains large** - Gradual migration planned, see ROADMAP.md
- **Binary-only distribution** - Swift script removed in v2.0.0, this is permanent
- **Homebrew as primary distribution** - Optimized for this installation method
- **No mocking in tests** - Real project manipulation is intentional for authenticity

**Mandatory Reality Check:**
Before implementing ANY feature, ask:
1. **What is the core user need?** (e.g., "validate UI looks right")
2. **What's the minimal solution?** (e.g., "screenshot comparison")
3. **Am I adding enterprise features to a simple app?** (if yes, STOP)



## Project Specific Development Philosophy

### Code Style
- Use Swift naming conventions (PascalCase for types, camelCase for methods)
- Prefer structs over classes for data models
- Prefer guard statements for early returns
- Use swift-format for consistent formatting

### Error Handling
- Use custom `ProjectError` enum for domain-specific errors
- Provide actionable error messages with specific remediation steps
- Fail fast with clear error reporting
- Exit with meaningful codes (0 = success, 1 = error, specific codes for specific failures)

### Testing Philosophy
- Test suite uses real project manipulation (not mocks)
- Tests are organized by feature area
- Each test should be independent and restorable
- Always verify both positive and negative cases


## Testing and Code Analysis Guidelines

### Code Analysis and Style (Analysis, Linting and Formatting)

```bash
# Swift code formatting (run after each task)
swift-format format --in-place --recursive Sources

# Swift code analysis and linting (run after each task)
swift-format lint --recursive Sources
```

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


## Common Tasks

### Adding a New Command
1. Add command case to main switch statement
2. Implement handler function with proper error handling
3. Add validation for required parameters
4. Update help text with new command
5. Add test coverage in TestSuite.swift or suitable test file
6. Document in README.md

### Debugging Issues
- Use `print()` statements for debug output
- Check `.xcodeproj/project.pbxproj` directly for state
- Use `validate` command to check project integrity
- Test with backup projects to avoid data loss
- Look for orphaned file references or missing build files
- Verify group hierarchy matches file system structure

## Performance Considerations

- File operations are batched when possible
- Swift Package Manager caches dependencies after first build
- Group lookups are recursive but typically fast
- Large projects (1000+ files) may need optimization

> **⚡ For detailed performance characteristics and caching strategies, see [ARCHITECTURE.md](./ARCHITECTURE.md)**

## Troubleshooting

### Common Issues and Solutions

**"Permission denied" when running tool**
```bash
# Make executable
chmod +x xcodeproj-cli
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
# Clear SPM cache and retry
rm -rf .build
swift build -c release
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
- [Swift Package Manager Documentation](https://swift.org/package-manager/)
- [Xcode Build Settings Reference](https://developer.apple.com/documentation/xcode/build-settings-reference)
- [Swift Package Manager](https://swift.org/package-manager/)

## Release Preparation

When preparing a release:
1. Follow the comprehensive checklist in [homebrew/PUBLISHING_CHECKLIST.md](./homebrew/PUBLISHING_CHECKLIST.md)
2. Ensure version consistency across all files
3. Run all tests before tagging
4. Let GitHub Actions handle the build and release
5. Update Homebrew formula after release is created

**Key files to update:**
- `Sources/xcodeproj-cli/CLI/CLIInterface.swift` - version string
- `CHANGELOG.md` - change UNRELEASED to version and date

## Repository

- **GitHub**: https://github.com/tolo/xcodeproj-cli
- **Issues**: https://github.com/tolo/xcodeproj-cli/issues
- **Changelog**: See [CHANGELOG.md](./CHANGELOG.md) for version history
- **Architecture**: See [ARCHITECTURE.md](./ARCHITECTURE.md) for detailed system design
- **Roadmap**: See [ROADMAP.md](./ROADMAP.md) for planned features and design decisions
