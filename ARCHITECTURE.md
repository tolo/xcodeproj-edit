# xcodeproj-cli Architecture

**Version:** 2.0.0

## Overview

xcodeproj-cli is a modular, service-oriented command-line tool for Xcode project manipulation. The architecture emphasizes maintainability, performance, and extensibility through clear separation of concerns and established design patterns.

### Architectural Principles

- **Separation of Concerns**: Distinct layers for CLI interface, business logic, and project manipulation
- **Command Pattern**: Encapsulated operations with consistent interfaces
- **Service Layer**: Specialized services for core functionality
- **Performance Caching**: Intelligent caching of frequently accessed project elements
- **Transaction Safety**: Atomic operations with rollback capability

## System Structure

### Key Directories
- **CLI/**: Command-line interface and argument processing
- **Commands/**: Individual command implementations organized by functional area
- **Core/**: Core services including caching, transactions, and project validation
- **Models/**: Data structures and domain-specific error types
- **Utils/**: Utility functions for parsing, security, and performance monitoring

## Core Components

### CLI Layer
- **CLIRunner**: Main orchestrator handling global flags, project auto-discovery, and command routing
- **CLIInterface**: User interface providing help, version information, and consistent messaging

### Command Layer
- **Command Protocol**: Standardized interface for all operations with consistent execution patterns
- **CommandRegistry**: Central dispatch system for command registration and routing
- **Command Categories**: Organized into functional groups (File, Target, Group, Build, Package, Inspection, Path)

### Core Services
- **XcodeProjService**: Modern high-level API for project manipulation with integrated caching and transactions
- **XcodeProjUtility**: Legacy utility class maintained for backward compatibility during migration
- **CacheManager**: Multi-level caching system (groups, targets, file references, build phases) with statistics
- **TransactionManager**: Atomic operations with backup, commit/rollback semantics, and automatic cleanup
- **ProjectValidator**: Integrity validation detecting orphaned references, missing files, and broken hierarchies
- **BuildPhaseManager**: Centralized build phase manipulation and file association management

### Utility Layer
- **PerformanceProfiler**: Operation timing, memory tracking, and benchmarking capabilities
- **PathResolver**: Complex path resolution with source tree handling and validation
- **SecurityUtils**: Path sanitization and command injection prevention
- **FileTypeDetector**: Smart file classification for appropriate build phase assignment

## Design Patterns

### Command Pattern
Each CLI operation is encapsulated as a discrete command class with uniform interfaces, enabling extensibility, testability, and consistent execution patterns.

### Service Layer Pattern
Core business logic is abstracted into specialized services (XcodeProjService, CacheManager, TransactionManager, ProjectValidator) for separation of concerns and reusability.

### Registry Pattern
CommandRegistry provides centralized command dispatch with dynamic registration and introspection capabilities.

### Facade Pattern
XcodeProjUtility simplifies the complex XcodeProj library interface, providing domain-specific operations and hiding implementation details.

## Data Flow

CLI Arguments → CLIRunner → CommandRegistry → Command → Core Services → XcodeProj Library

### Dependencies
- **XcodeProj**: Core library for project file manipulation
- **PathKit**: Swift path handling utilities
- **Foundation**: Standard library functionality

## Design Decisions

### Binary-Only Distribution
**Decision**: Remove Swift script version in v2.0.0
**Rationale**: Better performance, easier distribution, no runtime dependencies
**Impact**: Breaking change but significantly improves user experience

### Modular Architecture
**Decision**: Split monolithic implementation into 55+ specialized modules
**Rationale**: Improved maintainability, testability, and extensibility
**Trade-off**: Increased structural complexity offset by better organization and clear responsibilities

### Path Traversal Protection
**Decision**: Allow single `..` for parent directory references with validation
**Rationale**: Legitimate use cases require referencing files in parent directories
**Security**: Multi-layer validation ensures safety while maintaining functionality

### Performance Caching Strategy
**Decision**: Multi-level caching system with intelligent invalidation
**Implementation**: Separate caches for groups, targets, file references, and build phases
**Benefits**: O(1) lookups, selective invalidation, performance metrics

### Transaction Safety
**Decision**: Atomic operations with automatic backup and rollback capability
**Implementation**: Project file backup before operations with commit/rollback semantics
**Benefits**: Data integrity protection and operation safety

## Performance Characteristics

### Caching Optimization
- Multi-level caching with O(1) lookups for common operations
- Selective cache invalidation minimizing rebuild overhead
- Cache hit/miss statistics for performance monitoring

### Scalability
- Tested with 1000+ file projects
- Batch operations optimized for bulk file manipulation
- Memory-efficient lazy loading and cleanup strategies

### Typical Performance
- Single file operations: < 50ms
- Batch operations (100 files): < 500ms
- Project validation: < 200ms
- Memory usage: 10-50MB depending on project size

## Testing Strategy

### Integration Testing Focus
Tests use real Xcode projects for end-to-end validation, ensuring complete command execution paths and state verification with transaction safety testing.

### Test Organization
- Feature-based organization grouped by functional area
- Independent tests with restorable state
- Coverage of both success and failure scenarios
- Performance and scalability validation

## Security Considerations

### Input Validation
- Path sanitization preventing directory traversal attacks
- Command injection prevention with proper escaping
- Comprehensive input validation before execution

### Safe Operations
- Atomic operations with automatic backup and rollback
- Project validation before and after operations
- Centralized security utilities for consistent protection

## Migration Strategy

The architecture supports a gradual migration from legacy XcodeProjUtility to modern service-oriented design:

1. **Command Migration**: Move from switch statements to Command classes
2. **Service Extraction**: Extract functionality to specialized services  
3. **API Standardization**: Consistent interfaces across services
4. **Legacy Deprecation**: Phase out legacy utility while maintaining backward compatibility

## Future Considerations

### Planned Enhancements
- Plugin architecture for custom commands
- Configuration system for project and user preferences
- Swift concurrency adoption for parallel operations
- Enhanced validation with semantic checking and linting rules

### Extensibility Design
The modular architecture supports easy addition of new file types, build phases, validators, and output formats while maintaining consistent patterns and interfaces.