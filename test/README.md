# XcodeProj CLI Test Suite

This directory contains comprehensive tests for the xcodeproj-cli utility.

## Structure

```
test/
├── TestData/                    # Test data files (committed to repo)
│   ├── Sources/                 # SwiftUI source files for testing
│   │   ├── Models/             # Data model files
│   │   ├── Views/              # SwiftUI view files
│   │   └── ViewModels/         # View model files
│   ├── Resources/              # Resource files (Info.plist, etc.)
│   └── Tests/                  # Test files directory
├── TestRunner.swift           # Unified test runner with menu system
├── TestSuite.swift            # Full test suite (modifies test project)
├── SecurityTests.swift        # Security and validation tests
├── create_test_project.swift  # Creates TestProject.xcodeproj only
└── .gitignore                 # Excludes generated .xcodeproj

Note: TestProject.xcodeproj/ is generated and not committed to the repository
```

## Running Tests

### Interactive Mode (Recommended)
```bash
./TestRunner.swift
```

This presents a menu with options:
1. **Quick validation tests** - Read-only tests that verify basic functionality
2. **Full test suite** - Comprehensive tests that modify the test project
3. **Security tests** - Input validation and security checks
4. **All tests** - Runs all test suites in sequence
5. **Exit** - Quit the test runner

### Running Individual Test Suites
```bash
# Run only the full test suite
./TestSuite.swift

# Run only security tests
./SecurityTests.swift

# Create/recreate test project
./create_test_project.swift
```

### Command-Line Mode
```bash
# Run specific test suites directly
./TestRunner.swift validation   # or -v
./TestRunner.swift full        # or -f  
./TestRunner.swift security    # or -s
./TestRunner.swift all         # or -a
./TestRunner.swift help        # or -h
```

## Test Data

The `TestData/Sources/` directory contains SwiftUI files that are used for testing:
- **Models/** - Simple data models (Item.swift)
- **Views/** - SwiftUI views (ContentView.swift, ItemView.swift)
- **ViewModels/** - Observable view models (ItemViewModel.swift)

These files are committed to the repository and serve as test fixtures for:
- Recursive folder addition
- File filtering (.DS_Store, .gitignore, .bak files are excluded)
- Proper file categorization (sources vs resources)
- Group hierarchy creation

## Test Project Generation

The `create_test_project.swift` script generates only the `.xcodeproj` file, not the source files. This ensures:
1. Test data files are version controlled
2. Tests are reproducible across different environments
3. The `.xcodeproj` can be regenerated if needed

## Test Coverage

### Validation Tests (TestRunner.swift)
- Help command and usage information
- Basic listing operations (targets, groups, configs)
- Error handling for invalid arguments
- Dry-run mode functionality
- Project validation

### Full Test Suite (TestSuite.swift)
- **File Operations** - Adding, moving, removing files
- **Directory Operations** - Recursive folder addition with filtering
- **Group Operations** - Creating and managing groups
- **Target Operations** - Creating, duplicating, removing targets
- **Build Settings** - Getting and setting build configurations
- **Dependencies** - Framework and target dependencies
- **Swift Packages** - SPM integration
- **Build Phases** - Run scripts and copy files phases

### Security Tests (SecurityTests.swift)
- Path traversal protection
- Command injection prevention
- Input validation for versions and URLs
- Error handling for malformed inputs
- Boundary condition testing

## File Filtering

The tool automatically filters out these files when adding folders:
- `.DS_Store`
- `.gitignore`
- `.gitkeep`
- Files ending in `.bak`, `.orig`, `.tmp`, `.temp`
- Hidden files (except `.h` and `.m`)