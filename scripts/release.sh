#!/bin/bash
# Automated Release Script for xcodeproj-cli
# Usage: ./scripts/release.sh X.Y.Z

set -e

VERSION=$1
if [ -z "$VERSION" ]; then
    echo "Usage: ./scripts/release.sh X.Y.Z"
    echo "Example: ./scripts/release.sh 2.0.0"
    exit 1
fi

echo "🚀 Releasing xcodeproj-cli v$VERSION"
echo "======================================"

# Step 1: Update version in source
echo "📝 Updating version in source code..."
sed -i '' "s/let VERSION = \".*\"/let VERSION = \"$VERSION\"/" Sources/xcodeproj-cli/CLI/CLIInterface.swift

# Step 2: Update CHANGELOG
echo "📝 Updating CHANGELOG..."
TODAY=$(date +%Y-%m-%d)
sed -i '' "s/## \[UNRELEASED\].*/## [$VERSION] - $TODAY/" CHANGELOG.md

# Step 3: Run tests
echo "🧪 Running tests..."
swift test

# Step 4: Build universal binary
echo "🔨 Building universal binary..."
./build-universal.sh

# Step 5: Commit changes
echo "📦 Committing release changes..."
git add -A
git commit -m "Release v$VERSION" || true

# Step 6: Create and push tag
echo "🏷️ Creating tag v$VERSION..."
git tag -f "v$VERSION"
git push origin main
git push origin "v$VERSION"

echo ""
echo "✅ Release v$VERSION initiated!"
echo ""
echo "Next steps:"
echo "1. Monitor GitHub Actions: https://github.com/tolo/xcodeproj-cli/actions"
echo "2. Wait for release to complete"
echo "3. Run: ./scripts/update-homebrew.sh $VERSION <SHA256>"
echo ""
echo "The SHA256 will be shown in the GitHub Actions output."