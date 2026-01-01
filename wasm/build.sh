#!/bin/bash
# WASM Compilation Script for i18n core
# Compiles minimal JavaScript to WASM for maximum performance

set -e

echo "🔧 Building i18n WASM module..."

# Install wasm-pack if not present (using cargo for security - no curl|sh)
if ! command -v wasm-pack &> /dev/null; then
    echo "Installing wasm-pack via cargo..."
    cargo install wasm-pack --locked
fi

# Build WASM module
echo "Compiling to WASM..."
wasm-pack build --target web --out-dir pkg

# Optimize WASM binary
echo "Optimizing WASM..."
wasm-opt -Oz -o pkg/i18n_bg_opt.wasm pkg/i18n_bg.wasm

# Generate TypeScript-free bindings
echo "Generating bindings..."
node generate-bindings.js

echo "✅ WASM build complete!"
echo "Output: wasm/pkg/"
echo "Size: $(du -h pkg/i18n_bg_opt.wasm | cut -f1)"
