#!/bin/bash

# XcodeProj CLI Installation Script
# Can be run locally or via curl

set -e

echo "🔧 XcodeProj CLI Installer"
echo "=========================="
echo ""
echo "Two installation methods available:"
echo "  1. Homebrew (recommended) - Pre-built binary, no dependencies"
echo "  2. Swift Script - Requires swift-sh, runs from source"
echo ""

# Check for macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "❌ Error: This tool requires macOS"
    exit 1
fi

echo "📦 Installing xcodeproj-cli via Homebrew..."
echo ""

# Check for Homebrew
if ! command -v brew &> /dev/null; then
    echo "⚠️  Homebrew is not installed"
    echo ""
    echo "Would you like to install Homebrew?"
    read -p "Install Homebrew? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "📦 Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    else
        echo "❌ Error: Homebrew is required for installation"
        echo "Install it manually from https://brew.sh"
        exit 1
    fi
fi

echo "✅ Homebrew detected"

# Add tap and install
echo "📦 Adding xcodeproj-cli tap..."
brew tap tolo/xcodeproj || true

echo "📦 Installing xcodeproj-cli..."
brew install xcodeproj-cli

echo ""
echo "✅ Installation complete!"
echo ""
echo "The tool is now available as 'xcodeproj-cli' in your PATH:"
echo "  xcodeproj-cli --help"
echo ""
echo "Example:"
echo "  xcodeproj-cli --project MyApp.xcodeproj list-targets"
echo ""
echo "📖 For full documentation, visit:"
echo "  https://github.com/tolo/xcodeproj-cli"
echo ""
echo "💡 Pro tip: The Homebrew version is faster and has no dependencies!"
echo ""
echo "🎉 Happy coding!"