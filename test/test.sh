#!/bin/bash

# xcodeproj-cli Test Runner Script
# Builds the binary and runs comprehensive tests

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}📍 $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Change to project root directory
cd "$(dirname "$0")/.."

print_status "Building xcodeproj-cli binary..."

# Check if swift build is available
if ! command -v swift &> /dev/null; then
    print_error "Swift compiler not found. Please install Xcode command line tools."
    exit 1
fi

# Clean previous build (optional, comment out for faster iteration)
# rm -rf .build

# Build release version
if swift build -c release; then
    print_success "Binary built successfully"
else
    print_error "Failed to build binary"
    exit 1
fi

# Verify the binary exists and is executable
BINARY_PATH=".build/release/xcodeproj-cli"
if [[ -x "$BINARY_PATH" ]]; then
    print_success "Binary verified at: $BINARY_PATH"
    
    # Show binary info
    echo "$(file "$BINARY_PATH")"
    
    # Check if it's a universal binary
    if command -v lipo &> /dev/null; then
        if lipo -info "$BINARY_PATH" 2>/dev/null | grep -q "arm64"; then
            print_success "Universal binary detected"
        fi
    fi
else
    print_error "Binary not found or not executable at: $BINARY_PATH"
    exit 1
fi

# Test basic functionality
print_status "Testing basic functionality..."
if "$BINARY_PATH" --help > /dev/null 2>&1; then
    print_success "Help command works"
else
    print_error "Help command failed"
    exit 1
fi

if "$BINARY_PATH" --version > /dev/null 2>&1; then
    print_success "Version command works"
else
    print_error "Version command failed"
    exit 1
fi

# Change to test directory
cd test

# Ensure test project exists
if [[ ! -d "TestData/TestProject.xcodeproj" ]]; then
    print_warning "Test project not found. Creating..."
    if ./create_test_project.swift; then
        print_success "Test project created"
    else
        print_error "Failed to create test project"
        exit 1
    fi
fi

print_status "Running test suites..."

# Check for new test suite arguments
case "${1:-validation}" in
    "packages" | "package")
        print_status "Running Swift Package Manager tests..."
        ./PackageTests.swift
        ;;
    "build" | "build-config")
        print_status "Running Build Configuration tests..."
        ./BuildConfigTests.swift
        ;;
    "integration" | "integration-tests")
        print_status "Running Integration tests..."
        ./IntegrationTests.swift
        ;;
    "validation" | "")
        print_status "Running quick validation tests (read-only)..."
        ./TestRunner.swift validation
        ;;
    *)
        # Pass all arguments to TestRunner for backward compatibility
        ./TestRunner.swift "$@"
        ;;
esac