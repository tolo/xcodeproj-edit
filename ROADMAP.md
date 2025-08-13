# xcodeproj-cli Roadmap

## Current Version: 2.0.0

Major architectural refactoring with modular structure, security enhancements, and performance optimizations.

---

## v2.1.0 (Q1 2025)

### Core Improvements
- [ ] Complete migration of XcodeProjUtility to specialized services
- [ ] Enhanced error context with file:line information
- [ ] Expose cache metrics in verbose mode output

### Features
- [ ] Add `--config` flag for per-project configuration files
- [ ] Support for workspace (.xcworkspace) manipulation
- [ ] Batch operations for build settings

### Developer Experience
- [ ] Interactive mode for complex operations
- [ ] Undo/redo functionality with operation history
- [ ] Better progress indicators for long operations

---

## v2.2.0 (Q2 2025)

### Architecture
- [ ] Plugin system for custom commands
- [ ] Swift concurrency adoption for parallel operations
- [ ] Async/await for file operations

### Features
- [ ] Template system for common project structures
- [ ] Project diff/merge capabilities
- [ ] Build configuration inheritance visualization

### Integration
- [ ] GitHub Actions for common CI/CD workflows
- [ ] Fastlane integration examples
- [ ] VS Code extension support

---

## v3.0.0 (Future)

### Major Features
- [ ] GUI companion app for visual project management
- [ ] Cloud sync for project templates and configurations
- [ ] AI-assisted project optimization suggestions
- [ ] Multi-project batch operations

### Platform Expansion
- [ ] Linux support (where applicable)
- [ ] Web API for remote project manipulation
- [ ] Docker container with pre-configured environment

---

## Completed Features (v2.0.0)

### ✅ Architecture
- Modular architecture (55+ specialized modules)
- Command pattern implementation
- Service-oriented design
- Performance caching system

### ✅ Security
- Comprehensive path traversal protection
- Command injection prevention
- Input validation and sanitization
- Transaction safety with rollback

### ✅ Developer Experience
- Verbose mode with performance metrics
- Enhanced test coverage (140+ tests)
- Comprehensive documentation (ARCHITECTURE.md)
- Homebrew distribution support

---

## Design Decisions

### Path Traversal Protection
- **Decision**: Allow single `..` for parent directory references
- **Rationale**: Legitimate use cases require referencing files in parent directories
- **Security**: Multi-layer validation ensures safety while maintaining functionality

### Binary-Only Distribution
- **Decision**: Remove Swift script version in v2.0.0
- **Rationale**: Better performance, easier distribution, no runtime dependencies
- **Impact**: Breaking change but improves user experience

### Modular Architecture
- **Decision**: Split monolithic file into 55+ modules
- **Rationale**: Maintainability, testability, extensibility
- **Trade-off**: Increased complexity offset by better organization

---

## Contributing

We welcome contributions! Priority areas:
1. Test coverage improvements
2. Documentation enhancements
3. Performance optimizations
4. New command implementations

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

---

## Feedback

Have ideas for the roadmap? Please:
- Open an issue with the `enhancement` label
- Start a discussion in GitHub Discussions
- Submit a PR with roadmap updates

---

*Last updated: 2025-08-12*