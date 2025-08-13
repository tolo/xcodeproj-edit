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

## Architecture Overview

### Project Structure
```
xcodeproj-cli/
├── Sources/
│   └── xcodeproj-cli/
│       └── main.swift              # Main tool implementation (30+ commands)
├── Package.swift                   # Swift Package Manager configuration
├── build-universal.sh              # Universal binary build script
├── .github/
│   └── workflows/
│       └── release.yml             # Automated release workflow
├── test/
│   ├── TestSuite.swift            # Main Swift test suite
│   ├── TestRunner.swift           # Test runner utility
│   ├── AdditionalTests.swift      # Additional test cases
│   ├── SecurityTests.swift        # Security-focused tests
│   ├── create_test_project.swift  # Test project generator
│   ├── README.md                  # Test documentation
│   └── TestData/                  # Test fixtures
├── README.md                      # Main documentation
├── CLAUDE.md                      # Claude AI guidance
├── CHANGELOG.md                   # Version history
├── LICENSE                        # MIT License
├── install.sh                     # Installation script
```

### Core Components

1. **Command Parser**: Processes CLI arguments and routes to appropriate handlers
2. **Project Manipulator**: Core XcodeProj library wrapper with safety checks
3. **File Manager**: Smart file filtering and type detection
4. **Group Manager**: Hierarchical group creation and management
5. **Target Manager**: Target creation, duplication, and configuration
6. **Build Settings Manager**: Build configuration manipulation
7. **SPM Integration**: Swift Package Manager dependency management

### Command Categories

#### File Operations
- `add-file`, `add-files`, `add-folder`, `add-sync-folder`
- `move-file`, `remove-file`

#### Target Operations
- `add-target`, `duplicate-target`, `remove-target`
- `add-dependency`

#### Build Configuration
- `set-build-setting`, `get-build-settings`
- `list-build-configs`

#### Dependencies
- `add-framework`
- `add-swift-package`, `remove-swift-package`, `list-swift-packages`

#### Project Structure
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

#### Use CUPID for Architectural Decision-Making
CUPID properties (https://cupid.dev/) focus on creating architectures that are "joyful" to work with. CUPID emphasizes properties rather than rigid rules for architectural design.

- **C - Composable Architecture**: Design system components that harmonize cohesively with minimal dependencies / coupling and clear interfaces / API contracts, framework-agnostic design where possible.
- **U - Unix Philosophy for Systems**: Apply the Unix philosophy to system boundaries and service design, meaning each service/component does one thing well (single responsibility), appropriate granularity, clear separation between different system concerns, well-defined system boundaries
- **P - Predictable System Behavior**: Ensure system behavior is consistent and unsurprising, with predictable performance characteristics, well-defined failure modes, clear data flow and state management, and observable and debuggable behavior.
- **I - Idiomatic Architecture**: Use architecture patterns that are familiar and reduce cognitive load for the development team, including industry-standard architectural patterns, consistent technology choices across the system, familiar deployment and operational patterns, team-appropriate technology selections, and convention-over-configuration approaches.
- **D - Domain-Aligned Architecture**: Ensure the architecture clearly expresses business concepts and aligns with domain boundaries, including domain-driven design principles, clear separation of business logic from infrastructure concerns, and alignment with business processes and terminology.

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

#### Swft Code Style
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
swift-format format --in-place --recursive Pomaddoro

# Swift code analysis and linting (run after each task)
swift-format lint --recursive Pomaddoro
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

### Path Traversal Design Decision
**Single `..` is intentionally allowed** in path validation for legitimate use cases where files need to be referenced from parent directories (e.g., shared code between projects). This is a deliberate design decision with multiple security layers:
- Path normalization prevents bypass attempts
- URL-encoded sequences are decoded and validated
- Critical system directories are blocked
- Maximum path length limits prevent resource exhaustion
- See `PathUtils.sanitizePath()` for implementation details

## Useful Resources

- [XcodeProj Documentation](https://github.com/tuist/XcodeProj)
- [Swift Package Manager Documentation](https://swift.org/package-manager/)
- [Xcode Build Settings Reference](https://developer.apple.com/documentation/xcode/build-settings-reference)
- [Swift Package Manager](https://swift.org/package-manager/)

## Release Preparation Procedures

### Pre-Release Checklist

Before creating a release, **ALWAYS** complete these steps:

#### 1. Build Verification
```bash
# Clean build directory
rm -rf .build

# Build release version
swift build -c release

# Test the binary works
.build/release/xcodeproj-cli --version
.build/release/xcodeproj-cli --help

# Build universal binary
./build-universal.sh

# Verify universal binary architectures
lipo -info xcodeproj-cli
# Expected output: "Architectures in the fat file: xcodeproj-cli are: x86_64 arm64"

# Test universal binary
./xcodeproj-cli --version
```

#### 2. Test Suite Execution
```bash
# Run test suite (when available)
swift test

# Run manual smoke tests
./xcodeproj-cli --project test/TestData/TestProject.xcodeproj list-targets
./xcodeproj-cli --project test/TestData/TestProject.xcodeproj validate
```

#### 3. GitHub Actions Release Workflow Testing
```bash
# Test the release workflow locally using act (if installed)
# Install act: brew install act
act -n -P ubuntu-latest=ghcr.io/catthehacker/ubuntu:act-latest \
    --secret GITHUB_TOKEN=$GITHUB_TOKEN \
    -W .github/workflows/release.yml

# Or manually verify the workflow file
cat .github/workflows/release.yml | grep -E "swift build|lipo|tar|shasum"
```

#### 4. Version Consistency Check
```bash
# Ensure version is updated in all locations:
grep -n "version.*=.*\"" Sources/xcodeproj-cli/main.swift
grep "## \[" CHANGELOG.md | head -1
# Both should show the same version number
```

#### 5. Documentation Review
- Ensure README.md is up to date with any new features
- Update CHANGELOG.md with all changes for the release
- Verify installation instructions still work

### Release Process

1. **Update Version**
   ```bash
   # Update version in Sources/xcodeproj-cli/main.swift
   # Update CHANGELOG.md with release date
   ```

2. **Final Build Test**
   ```bash
   swift build -c release
   ./build-universal.sh
   ```

3. **Commit Changes**
   ```bash
   git add -A
   git commit -m "Release v2.0.0"
   git push origin main
   ```

4. **Create Release Tag**
   ```bash
   git tag v2.0.0
   git push origin v2.0.0
   ```

5. **Monitor GitHub Actions**
   - Watch the release workflow at: https://github.com/tolo/xcodeproj-cli/actions
   - Verify the release was created with binary attached
   - Check the SHA256 hash in the workflow output

6. **Update Homebrew Formula**
   - Copy SHA256 from GitHub Actions output
   - Update formula in homebrew-xcodeproj repository
   - Test installation: `brew upgrade xcodeproj-cli`

### Post-Release Verification

```bash
# Test Homebrew installation
brew update
brew upgrade xcodeproj-cli
xcodeproj-cli --version  # Should show new version

# Test direct binary download
curl -L "https://github.com/tolo/xcodeproj-cli/releases/latest/download/xcodeproj-cli-v2.0.0-macos.tar.gz" -o test.tar.gz
tar -xzf test.tar.gz
./xcodeproj-cli --version
rm test.tar.gz xcodeproj-cli
```

## Repository

- **GitHub**: https://github.com/tolo/xcodeproj-cli
- **Issues**: https://github.com/tolo/xcodeproj-cli/issues
- **Changelog**: See [CHANGELOG.md](./CHANGELOG.md) for version history
- **Roadmap**: See [ROADMAP.md](./ROADMAP.md) for planned features and design decisions
