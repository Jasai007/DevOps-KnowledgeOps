#!/bin/bash

# Build script for Lambda functions

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

print_status "Building Lambda functions..."

# Install dependencies if needed
if [ ! -d "node_modules" ]; then
    print_status "Installing dependencies..."
    npm install
fi

# Build all TypeScript files
print_status "Compiling TypeScript..."
npx tsc

# Build individual Lambda functions
LAMBDA_DIRS=("actions" "chat-processor" "session" "memory" "bedrock" "utils")

for dir in "${LAMBDA_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        print_status "Building $dir..."
        cd "$dir"
        
        # Install function-specific dependencies
        if [ -f "package.json" ]; then
            npm install --production
        fi
        
        # Compile TypeScript if tsconfig exists
        if [ -f "tsconfig.json" ]; then
            npx tsc
        fi
        
        cd ..
        print_success "$dir built successfully"
    fi
done

print_success "All Lambda functions built successfully!"

# Create deployment packages
print_status "Creating deployment packages..."

for dir in "${LAMBDA_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        print_status "Packaging $dir..."
        cd "$dir"
        
        # Create zip file for deployment
        zip -r "../${dir}.zip" . -x "*.ts" "tsconfig.json" "node_modules/.cache/*" "*.test.*" "*.spec.*"
        
        cd ..
        print_success "$dir packaged as ${dir}.zip"
    fi
done

print_success "🎉 All Lambda functions are ready for deployment!"
echo ""
echo "📦 Deployment packages created:"
for dir in "${LAMBDA_DIRS[@]}"; do
    if [ -f "${dir}.zip" ]; then
        echo "  • ${dir}.zip"
    fi
done