#!/bin/bash
# WASM Compilation Script for i18n core
# Compiles minimal JavaScript to WASM for maximum performance

set -e

echo "🔧 Building i18n WASM module..."

# Install wasm-pack if not present
if ! command -v wasm-pack &> /dev/null; then
    echo "Installing wasm-pack..."
    curl https://rustwasm.github.io/wasm-pack/installer/init.sh -sSf | sh
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
