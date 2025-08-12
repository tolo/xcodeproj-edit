#!/bin/bash

# Build Universal Binary Script for xcodeproj-cli
# Creates a universal binary compatible with both Intel and Apple Silicon Macs

set -e  # Exit on any error

echo "🔨 Building xcodeproj-cli universal binary..."

# Clean any previous builds
echo "🧹 Cleaning previous builds..."
swift package clean

# Build for arm64 (Apple Silicon)
echo "🍎 Building for Apple Silicon (arm64)..."
swift build -c release --arch arm64

# Build for x86_64 (Intel)
echo "💻 Building for Intel (x86_64)..."
swift build -c release --arch x86_64

# Create universal binary
echo "🔗 Creating universal binary..."
lipo -create \
    .build/arm64-apple-macosx/release/xcodeproj-cli \
    .build/x86_64-apple-macosx/release/xcodeproj-cli \
    -output xcodeproj-cli

# Strip debug symbols to reduce size
echo "✂️ Stripping debug symbols..."
strip xcodeproj-cli

# Code sign the binary (with ad-hoc signature)
echo "🔏 Code signing..."
codesign -s - xcodeproj-cli

# Verify the binary architecture
echo "✅ Verifying binary architecture..."
file xcodeproj-cli
lipo -info xcodeproj-cli

# Test the binary
echo "🧪 Testing binary..."
./xcodeproj-cli --version

echo "🎉 Universal binary built successfully: xcodeproj-cli"
echo "📦 Binary size: $(du -h xcodeproj-cli | cut -f1)"