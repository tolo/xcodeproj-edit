# Homebrew Tap for xcodeproj-cli

This is the official Homebrew tap for [xcodeproj-cli](https://github.com/tolo/xcodeproj-cli), a powerful command-line tool for manipulating Xcode project files.

## Installation

```bash
brew tap tolo/xcodeproj
brew install xcodeproj-cli
```

## Quick Start

After installation, you can use xcodeproj-cli:

```bash
# Show help
xcodeproj-cli --help

# List targets in a project
xcodeproj-cli --project MyApp.xcodeproj list-targets

# Add a file to a project
xcodeproj-cli --project MyApp.xcodeproj add-file Source.swift --group Sources --targets MyApp
```

## Updating

To update to the latest version:

```bash
brew update
brew upgrade xcodeproj-cli
```

## Uninstalling

To remove xcodeproj-cli:

```bash
brew uninstall xcodeproj-cli
brew untap tolo/xcodeproj
```

## Features

- 🚀 **Fast**: Pre-compiled universal binary (Intel + Apple Silicon)
- 🔧 **Powerful**: 30+ commands for project manipulation
- 🔒 **Secure**: Built with comprehensive security protections
- 📦 **No Dependencies**: Standalone binary with everything included
- ⚡ **Performance**: Intelligent caching and batch operations

## Documentation

For full documentation, examples, and command reference, visit:
https://github.com/tolo/xcodeproj-cli

## License

MIT License - See [LICENSE](https://github.com/tolo/xcodeproj-cli/blob/main/LICENSE) for details.

## Support

For issues or questions:
- [GitHub Issues](https://github.com/tolo/xcodeproj-cli/issues)
- [Discussions](https://github.com/tolo/xcodeproj-cli/discussions)