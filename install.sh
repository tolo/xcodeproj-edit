#!/bin/bash

# XcodeProj CLI Installation Script
# Can be run locally or via curl

set -e

# Define the tool URL
TOOL_URL="https://raw.githubusercontent.com/tolo/xcodeproj-cli/main/src/xcodeproj-cli.swift"
TOOL_NAME="xcodeproj-cli.swift"

echo "🔧 XcodeProj CLI Installer"
echo "=========================="
echo ""

# Check for macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "❌ Error: This tool requires macOS"
    exit 1
fi

# Check for Swift
if ! command -v swift &> /dev/null; then
    echo "❌ Error: Swift is not installed"
    echo "Please install Xcode or Xcode Command Line Tools"
    exit 1
fi

# Check Swift version
SWIFT_VERSION=$(swift --version 2>&1 | head -n 1 | sed 's/.*version \([0-9]*\.[0-9]*\).*/\1/')
REQUIRED_VERSION="5.0"

if [ "$(printf '%s\n' "$REQUIRED_VERSION" "$SWIFT_VERSION" | sort -V | head -n1)" != "$REQUIRED_VERSION" ]; then
    echo "❌ Error: Swift $REQUIRED_VERSION or higher is required (found $SWIFT_VERSION)"
    exit 1
fi

echo "✅ Swift $SWIFT_VERSION detected"

# Check for Homebrew
if ! command -v brew &> /dev/null; then
    echo "⚠️  Warning: Homebrew is not installed"
    echo ""
    echo "Would you like to install Homebrew? (required for swift-sh)"
    read -p "Install Homebrew? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "📦 Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    else
        echo "❌ Error: Homebrew is required for swift-sh"
        echo "Install it manually from https://brew.sh"
        exit 1
    fi
fi

echo "✅ Homebrew detected"

# Install swift-sh if needed
if ! command -v swift-sh &> /dev/null; then
    echo "📦 Installing swift-sh..."
    brew install swift-sh
else
    echo "✅ swift-sh already installed"
fi

# Download the tool if we're running via curl
if [ ! -f "src/xcodeproj-cli.swift" ]; then
    echo "📥 Downloading xcodeproj-cli..."
    
    # Create a clean filename
    if [ -f "$TOOL_NAME" ]; then
        echo "⚠️  $TOOL_NAME already exists in current directory"
        read -p "Overwrite? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "❌ Installation cancelled"
            exit 1
        fi
    fi
    
    # Download the tool
    if curl -fsSL "$TOOL_URL" -o "$TOOL_NAME"; then
        echo "✅ Downloaded $TOOL_NAME"
    else
        echo "❌ Error: Failed to download tool"
        echo "URL: $TOOL_URL"
        exit 1
    fi
    
    # Make it executable
    chmod +x "$TOOL_NAME"
    echo "✅ Made $TOOL_NAME executable"
    
    echo ""
    echo "✅ Installation complete!"
    echo ""
    echo "To use the tool, run:"
    echo "  ./$TOOL_NAME --help"
    echo ""
    echo "Example:"
    echo "  ./$TOOL_NAME --project MyApp.xcodeproj list-targets"
else
    # Running from cloned repository
    chmod +x src/xcodeproj-cli.swift
    echo "✅ Made src/xcodeproj-cli.swift executable"
    
    echo ""
    echo "✅ Installation complete!"
    echo ""
    echo "To use the tool, run:"
    echo "  ./src/xcodeproj-cli.swift --help"
fi

echo ""
echo "📖 For full documentation, visit:"
echo "  https://github.com/tolo/xcodeproj-cli"
echo ""
echo "🎉 Happy coding!"