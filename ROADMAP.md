# xcodeproj-cli Roadmap

## Current Status: v2.0.0 (In Development)

Major release featuring complete service-based architecture, comprehensive scheme management, workspace support, and 35+ new commands. See [Issue #6](https://github.com/tolo/xcodeproj-cli/issues/6) for full implementation details.

### v2.0.0 Feature Completeness
- [ ] Complete migration from XcodeProjUtility to specialized services
- [ ] Scheme management (create, configure, test coverage)
- [ ] Workspace support with cross-project references
- [ ] Enhanced build phases (headers, copy destinations, run scripts)
- [ ] Build configuration management with .xcconfig support
- [ ] Localization and variant groups
- [ ] Extended target types (aggregate, extensions)

---

## Future Releases

### Advanced Build & Testing
See [Issue #7](https://github.com/tolo/xcodeproj-cli/issues/7) for full details.

- [ ] Xcode 11+ test plans with full configuration
- [ ] Custom build rules with patterns and scripts
- [ ] Advanced scheme actions (Profile, Analyze, Archive)
- [ ] Core Data model versioning
- [ ] Pre/post action scripts for all scheme actions
- [ ] ~40 new commands

### Analysis & Optimization
See [Issue #8](https://github.com/tolo/xcodeproj-cli/issues/8) for full details.

- [ ] Comprehensive project health analysis
- [ ] Find unused resources, duplicates, missing files
- [ ] Swift version and deployment target migration
- [ ] Batch operations and project templates
- [ ] Automated project optimization
- [ ] Dependency graph generation
- [ ] ~50 new commands

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

*Last updated: 2025-08-13*
