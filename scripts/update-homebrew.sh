#!/bin/bash
# Update Homebrew Formula Script
# Usage: ./scripts/update-homebrew.sh X.Y.Z SHA256

set -e

VERSION=$1
SHA256=$2

if [ -z "$VERSION" ] || [ -z "$SHA256" ]; then
    echo "Usage: ./scripts/update-homebrew.sh X.Y.Z SHA256"
    echo "Example: ./scripts/update-homebrew.sh 2.0.0 abc123def456..."
    exit 1
fi

echo "🍺 Updating Homebrew formula for v$VERSION"
echo "=========================================="

# Update the local formula
echo "📝 Updating formula..."
FORMULA="homebrew/xcodeproj-cli.rb"
sed -i '' "s/version \".*\"/version \"$VERSION\"/" $FORMULA
sed -i '' "s|url \".*\"|url \"https://github.com/tolo/xcodeproj-cli/releases/download/v$VERSION/xcodeproj-cli-v$VERSION-macos.tar.gz\"|" $FORMULA
sed -i '' "s/sha256 \".*\"/sha256 \"$SHA256\"/" $FORMULA

echo "✅ Formula updated!"
echo ""
echo "Next steps:"
echo "1. Copy formula to your tap repository:"
echo "   cp $FORMULA /path/to/homebrew-xcodeproj/Formula/"
echo ""
echo "2. In the tap repository:"
echo "   cd /path/to/homebrew-xcodeproj"
echo "   git add Formula/xcodeproj-cli.rb"
echo "   git commit -m \"Update xcodeproj-cli to v$VERSION\""
echo "   git push"
echo ""
echo "3. Test installation:"
echo "   brew tap tolo/xcodeproj"
echo "   brew upgrade xcodeproj-cli"