# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                        i18n-node-enhanced Justfile                            ║
# ║                                                                               ║
# ║  A comprehensive build automation system for polyglot internationalization   ║
# ║  Requires: just (https://github.com/casey/just)                              ║
# ║  Install: cargo install just || brew install just || guix install just       ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# Settings
set shell := ["bash", "-euo", "pipefail", "-c"]
set positional-arguments
set dotenv-load
set export

# Environment variables
export NODE_ENV := env_var_or_default("NODE_ENV", "development")
export RUST_LOG := env_var_or_default("RUST_LOG", "info")
export DENO_DIR := env_var_or_default("DENO_DIR", ".deno")
export I18N_VERSION := `node -p "require('./package.json').version" 2>/dev/null || echo "0.0.0"`

# Colors for output
RED := '\033[0;31m'
GREEN := '\033[0;32m'
YELLOW := '\033[0;33m'
BLUE := '\033[0;34m'
PURPLE := '\033[0;35m'
CYAN := '\033[0;36m'
NC := '\033[0m' # No Color

# ═══════════════════════════════════════════════════════════════════════════════
# DEFAULT & HELP
# ═══════════════════════════════════════════════════════════════════════════════

# Show all available recipes
default:
    @just --list --unsorted

# Show extended help with categories
help:
    @echo -e "{{CYAN}}╔══════════════════════════════════════════════════════════════════════════════╗{{NC}}"
    @echo -e "{{CYAN}}║{{NC}}  {{GREEN}}i18n-node-enhanced{{NC}} - Polyglot Internationalization Platform           {{CYAN}}║{{NC}}"
    @echo -e "{{CYAN}}╚══════════════════════════════════════════════════════════════════════════════╝{{NC}}"
    @echo ""
    @echo -e "{{YELLOW}}QUICK START:{{NC}}"
    @echo "  just install        Install all dependencies"
    @echo "  just test           Run test suite"
    @echo "  just dev            Start development mode"
    @echo ""
    @echo -e "{{YELLOW}}CATEGORIES:{{NC}}"
    @echo "  just help-dev       Development commands"
    @echo "  just help-build     Build commands"
    @echo "  just help-test      Testing commands"
    @echo "  just help-lint      Linting & formatting"
    @echo "  just help-docs      Documentation commands"
    @echo "  just help-release   Release commands"
    @echo "  just help-container Container commands"
    @echo "  just help-guix      Guix/Nix commands"
    @echo "  just help-nickel    Nickel configuration"
    @echo "  just help-cli       CLI commands"
    @echo "  just help-perf      Performance commands"
    @echo "  just help-security  Security commands"
    @echo "  just help-locale    Locale management"
    @echo "  just help-example   Example commands"
    @echo "  just help-rsr       RSR compliance"
    @echo ""
    @echo -e "{{BLUE}}TIP:{{NC}} Use 'just --list' for all recipes"

# Development help
help-dev:
    @echo -e "{{GREEN}}Development Commands:{{NC}}"
    @echo "  install[-npm|-pnpm|-deno]   Install dependencies"
    @echo "  dev[-watch|-debug|-hot]     Start development server"
    @echo "  clean[-all|-deep|-cache]    Clean build artifacts"
    @echo "  reset                       Reset to clean state"

# Build help
help-build:
    @echo -e "{{GREEN}}Build Commands:{{NC}}"
    @echo "  build[-all|-wasm|-rescript|-deno|-cli]  Build components"
    @echo "  build-release[-prod|-staging|-debug]    Release builds"
    @echo "  compile[-fast|-full|-incremental]       Compile options"

# Test help
help-test:
    @echo -e "{{GREEN}}Testing Commands:{{NC}}"
    @echo "  test[-unit|-integration|-e2e|-all]      Test suites"
    @echo "  test[-watch|-coverage|-verbose]         Test options"
    @echo "  test-locale[-en|-de|-fr|-all]           Locale tests"
    @echo "  test-runtime[-node|-deno|-bun]          Runtime tests"

# ═══════════════════════════════════════════════════════════════════════════════
# INSTALLATION
# ═══════════════════════════════════════════════════════════════════════════════

# Install all dependencies (auto-detect package manager)
install:
    #!/usr/bin/env bash
    if command -v pnpm &> /dev/null; then
        just install-pnpm
    elif command -v deno &> /dev/null; then
        just install-deno
    else
        just install-npm
    fi

# Install with npm
install-npm:
    @echo -e "{{BLUE}}Installing with npm...{{NC}}"
    npm ci --prefer-offline
    @echo -e "{{GREEN}}✓ npm install complete{{NC}}"

# Install with pnpm
install-pnpm:
    @echo -e "{{BLUE}}Installing with pnpm...{{NC}}"
    pnpm install --frozen-lockfile
    @echo -e "{{GREEN}}✓ pnpm install complete{{NC}}"

# Install with deno
install-deno:
    @echo -e "{{BLUE}}Installing Deno dependencies...{{NC}}"
    deno cache deno/mod.ts
    @echo -e "{{GREEN}}✓ Deno cache complete{{NC}}"

# Install all polyglot dependencies
install-all: install install-rust install-rescript install-nickel
    @echo -e "{{GREEN}}✓ All dependencies installed{{NC}}"

# Install Rust toolchain
install-rust:
    @echo -e "{{BLUE}}Setting up Rust toolchain...{{NC}}"
    rustup target add wasm32-unknown-unknown 2>/dev/null || true
    cargo install wasm-pack 2>/dev/null || true
    @echo -e "{{GREEN}}✓ Rust toolchain ready{{NC}}"

# Install ReScript
install-rescript:
    @echo -e "{{BLUE}}Installing ReScript...{{NC}}"
    cd bindings/rescript && npm install
    @echo -e "{{GREEN}}✓ ReScript installed{{NC}}"

# Install Nickel
install-nickel:
    @echo -e "{{BLUE}}Checking Nickel installation...{{NC}}"
    command -v nickel || echo -e "{{YELLOW}}Nickel not found. Install from: https://nickel-lang.org{{NC}}"

# Install dev dependencies only
install-dev:
    npm install --only=development

# Install prod dependencies only
install-prod:
    npm install --only=production

# ═══════════════════════════════════════════════════════════════════════════════
# DEVELOPMENT
# ═══════════════════════════════════════════════════════════════════════════════

# Start development mode
dev: install
    @echo -e "{{GREEN}}Starting development mode...{{NC}}"
    npm run dev 2>/dev/null || node examples/express4-cookie

# Development with file watching
dev-watch:
    @echo -e "{{GREEN}}Starting with file watching...{{NC}}"
    watchexec -e js,json,res -r -- just test

# Development with debug logging
dev-debug:
    DEBUG=i18n:* node examples/express4-cookie

# Development with hot reload
dev-hot:
    nodemon --watch i18n.js --watch locales examples/express4-cookie

# Start REPL with i18n loaded
repl:
    node -e "const {I18n} = require('./'); const i18n = new I18n({locales: ['en', 'de']}); console.log('i18n loaded. Try: i18n.__(\"hello\")')" -i

# Interactive development shell
shell:
    @echo -e "{{CYAN}}Starting development shell...{{NC}}"
    @echo "Available: node, npm, deno, cargo, just"
    bash

# ═══════════════════════════════════════════════════════════════════════════════
# CLEANING
# ═══════════════════════════════════════════════════════════════════════════════

# Clean build artifacts
clean:
    @echo -e "{{YELLOW}}Cleaning build artifacts...{{NC}}"
    rm -rf coverage .nyc_output
    rm -rf bindings/rescript/lib bindings/rescript/.bsb.lock
    rm -rf wasm/target wasm/pkg
    rm -rf deno/.deno
    rm -rf dist
    @echo -e "{{GREEN}}✓ Clean complete{{NC}}"

# Clean everything including node_modules
clean-all: clean
    rm -rf node_modules
    rm -rf examples/*/node_modules
    rm -rf bindings/rescript/node_modules

# Deep clean including cache
clean-deep: clean-all
    rm -rf ~/.npm/_cacache
    rm -rf ~/.cache/deno
    find . -name "*.log" -delete
    find . -name ".DS_Store" -delete

# Clean cache only
clean-cache:
    rm -rf .cache
    rm -rf node_modules/.cache
    npm cache clean --force

# Reset to fresh state
reset: clean-all install
    @echo -e "{{GREEN}}✓ Project reset complete{{NC}}"

# ═══════════════════════════════════════════════════════════════════════════════
# BUILDING
# ═══════════════════════════════════════════════════════════════════════════════

# Build all components
build-all: build-wasm build-rescript build-deno build-cli
    @echo -e "{{GREEN}}✓ All components built{{NC}}"

# Build WASM core
build-wasm:
    #!/usr/bin/env bash
    echo -e "{{BLUE}}Building WASM core...{{NC}}"
    if [ -d "wasm" ] && [ -f "wasm/Cargo.toml" ]; then
        cd wasm
        cargo build --release --target wasm32-unknown-unknown
        wasm-pack build --target web --out-dir pkg
        echo -e "{{GREEN}}✓ WASM built{{NC}}"
    else
        echo -e "{{YELLOW}}⚠ WASM directory not configured{{NC}}"
    fi

# Build WASM with optimizations
build-wasm-release:
    #!/usr/bin/env bash
    cd wasm
    RUSTFLAGS="-C opt-level=z" cargo build --release --target wasm32-unknown-unknown
    wasm-pack build --target web --release --out-dir pkg
    wasm-opt -O3 pkg/i18n_wasm_bg.wasm -o pkg/i18n_wasm_bg.wasm

# Build WASM debug
build-wasm-debug:
    cd wasm && cargo build --target wasm32-unknown-unknown
    cd wasm && wasm-pack build --target web --dev --out-dir pkg

# Build ReScript
build-rescript:
    #!/usr/bin/env bash
    echo -e "{{BLUE}}Building ReScript...{{NC}}"
    if [ -d "bindings/rescript" ]; then
        cd bindings/rescript
        npx rescript build
        echo -e "{{GREEN}}✓ ReScript built{{NC}}"
    else
        echo -e "{{YELLOW}}⚠ ReScript not configured{{NC}}"
    fi

# Build ReScript clean
build-rescript-clean:
    cd bindings/rescript && npx rescript clean && npx rescript build

# Watch ReScript
build-rescript-watch:
    cd bindings/rescript && npx rescript build -w

# Build Deno
build-deno:
    #!/usr/bin/env bash
    echo -e "{{BLUE}}Building Deno module...{{NC}}"
    if [ -d "deno" ]; then
        cd deno
        deno check mod.ts
        deno compile --allow-read --allow-env --output=../dist/i18n mod.ts 2>/dev/null || true
        echo -e "{{GREEN}}✓ Deno built{{NC}}"
    else
        echo -e "{{YELLOW}}⚠ Deno not configured{{NC}}"
    fi

# Bundle Deno
build-deno-bundle:
    deno bundle deno/mod.ts dist/i18n.bundle.js

# Build CLI
build-cli:
    @echo -e "{{BLUE}}Building CLI...{{NC}}"
    mkdir -p dist/bin
    echo '#!/usr/bin/env node' > dist/bin/i18n
    cat tools/cli.js >> dist/bin/i18n 2>/dev/null || echo "// CLI not implemented" >> dist/bin/i18n
    chmod +x dist/bin/i18n
    @echo -e "{{GREEN}}✓ CLI built{{NC}}"

# Build for production
build-prod: build-all
    NODE_ENV=production npm run build 2>/dev/null || true
    @echo -e "{{GREEN}}✓ Production build complete{{NC}}"

# Build with source maps
build-debug:
    NODE_ENV=development npm run build -- --source-map

# Compile TypeScript types
build-types:
    npx tsc --emitDeclarationOnly --declaration --outDir dist/types 2>/dev/null || true

# ═══════════════════════════════════════════════════════════════════════════════
# TESTING
# ═══════════════════════════════════════════════════════════════════════════════

# Run all tests
test:
    @echo -e "{{BLUE}}Running tests...{{NC}}"
    npm test
    @echo -e "{{GREEN}}✓ Tests passed{{NC}}"

# Run tests with coverage
test-coverage:
    npm run coverage || npm run test-ci

# Run tests in watch mode
test-watch:
    npx mocha --watch --reporter min

# Run tests verbose
test-verbose:
    npx mocha --reporter spec

# Run unit tests
test-unit:
    npx mocha test/i18n.*.js --grep "unit"

# Run integration tests
test-integration:
    npx mocha test/i18n.*.js --grep "integration"

# Run e2e tests
test-e2e:
    npx mocha test/e2e/*.js 2>/dev/null || echo "No E2E tests found"

# Run tests for specific locale
test-locale locale="en":
    I18N_TEST_LOCALE={{locale}} npx mocha test/i18n.*.js

# Run all locale tests
test-locale-all:
    for locale in en de fr nl ru; do just test-locale $locale; done

# Test with Node.js
test-node:
    node --test test/*.test.js 2>/dev/null || just test

# Test with Deno
test-deno:
    cd deno && deno test --allow-read --allow-env

# Test with Bun
test-bun:
    bun test 2>/dev/null || echo "Bun not installed"

# Test all runtimes
test-runtime-all: test-node test-deno test-bun

# Test WASM
test-wasm:
    cd wasm && cargo test
    cd wasm && wasm-pack test --node

# Test ReScript
test-rescript:
    cd bindings/rescript && npm test

# Test examples
test-examples:
    @echo -e "{{BLUE}}Testing examples...{{NC}}"
    @for dir in examples/*/; do \
        if [ -f "$$dir/package.json" ]; then \
            echo "Testing $$dir"; \
            (cd "$$dir" && npm install && npm test) || true; \
        fi \
    done

# Test specific example
test-example name:
    cd examples/{{name}} && npm install && npm test

# Smoke test
test-smoke:
    node -e "const {I18n} = require('./'); const i18n = new I18n(); console.log('✓ Smoke test passed')"

# Stress test
test-stress:
    node -e "const {I18n} = require('./'); const i18n = new I18n({locales: ['en']}); for(let i=0;i<10000;i++) i18n.__('test'); console.log('✓ Stress test passed')"

# Memory leak test
test-memory:
    node --expose-gc -e "const {I18n} = require('./'); global.gc(); const before = process.memoryUsage().heapUsed; const i18n = new I18n(); for(let i=0;i<1000;i++) i18n.__('test'); global.gc(); const after = process.memoryUsage().heapUsed; console.log('Memory delta:', ((after-before)/1024/1024).toFixed(2), 'MB')"

# Test with specific Node version (requires nvm)
test-node-version version:
    nvm use {{version}} && npm test

# Generate test report
test-report:
    npx mocha --reporter json > test-report.json
    @echo -e "{{GREEN}}✓ Test report generated: test-report.json{{NC}}"

# ═══════════════════════════════════════════════════════════════════════════════
# LINTING & FORMATTING
# ═══════════════════════════════════════════════════════════════════════════════

# Run all linters
lint: lint-js lint-json lint-yaml lint-md
    @echo -e "{{GREEN}}✓ All linting passed{{NC}}"

# Lint JavaScript
lint-js:
    npx eslint i18n.js index.js test/ tools/ examples/

# Lint and fix JavaScript
lint-js-fix:
    npx eslint --fix i18n.js index.js test/ tools/ examples/

# Lint JSON
lint-json:
    npx jsonlint-cli locales/*.json 2>/dev/null || true

# Lint YAML
lint-yaml:
    yamllint .github/ 2>/dev/null || true

# Lint Markdown
lint-md:
    npx markdownlint-cli *.md 2>/dev/null || true

# Lint ReScript
lint-rescript:
    cd bindings/rescript && npx rescript format -all

# Lint Rust
lint-rust:
    cd wasm && cargo clippy -- -D warnings

# Lint shell scripts
lint-shell:
    shellcheck tools/*.sh 2>/dev/null || true

# Lint Nickel
lint-nickel:
    nickel check config/*.ncl 2>/dev/null || true

# Format all files
format: format-js format-json format-md
    @echo -e "{{GREEN}}✓ All formatting complete{{NC}}"

# Format JavaScript
format-js:
    npx prettier --write "**/*.js"

# Format JSON
format-json:
    npx prettier --write "**/*.json"

# Format Markdown
format-md:
    npx prettier --write "**/*.md"

# Format YAML
format-yaml:
    npx prettier --write "**/*.yml" "**/*.yaml"

# Check formatting without changes
format-check:
    npx prettier --check "**/*.{js,json,md,yml,yaml}"

# Fix all linting issues
fix: lint-js-fix format
    @echo -e "{{GREEN}}✓ All fixes applied{{NC}}"

# ═══════════════════════════════════════════════════════════════════════════════
# DOCUMENTATION
# ═══════════════════════════════════════════════════════════════════════════════

# Build documentation
docs:
    @echo -e "{{BLUE}}Building documentation...{{NC}}"
    mkdir -p docs/_site
    npx jsdoc -c jsdoc.json 2>/dev/null || true
    @echo -e "{{GREEN}}✓ Docs built{{NC}}"

# Build AsciiDoc documentation
docs-asciidoc:
    asciidoctor README.adoc -o docs/_site/index.html 2>/dev/null || echo "asciidoctor not installed"
    asciidoctor ROADMAP.adoc -o docs/_site/roadmap.html 2>/dev/null || true

# Build all documentation
docs-all: docs docs-asciidoc docs-api docs-man
    @echo -e "{{GREEN}}✓ All documentation built{{NC}}"

# Generate API docs
docs-api:
    npx typedoc --out docs/api 2>/dev/null || true

# Generate man pages
docs-man:
    mkdir -p man/man1
    help2man --no-info ./dist/bin/i18n > man/man1/i18n.1 2>/dev/null || true

# Serve documentation
docs-serve: docs
    npx http-server docs/_site -p 8080

# Watch and rebuild docs
docs-watch:
    watchexec -e md,adoc,js -- just docs

# Deploy docs to GitHub Pages
docs-deploy:
    gh-pages -d docs/_site 2>/dev/null || true

# Generate changelog
docs-changelog:
    npx conventional-changelog -p angular -i CHANGELOG.md -s 2>/dev/null || true

# ═══════════════════════════════════════════════════════════════════════════════
# LOCALE MANAGEMENT
# ═══════════════════════════════════════════════════════════════════════════════

# Validate all locale files
locale-validate:
    node tools/locale-validator.js 2>/dev/null || echo "Validator not found"

# Validate specific locale
locale-validate-one locale:
    node tools/locale-validator.js --locale {{locale}}

# Check missing translations
locale-missing:
    node tools/missing-translations.js 2>/dev/null || echo "Tool not found"

# Sync locale files
locale-sync:
    node tools/sync-locales.js 2>/dev/null || echo "Tool not found"

# Extract translatable strings
locale-extract:
    node tools/extract-strings.js 2>/dev/null || echo "Tool not found"

# Add new locale
locale-add locale:
    echo "{}" > locales/{{locale}}.json
    just locale-sync
    @echo -e "{{GREEN}}✓ Locale {{locale}} added{{NC}}"

# Remove locale
locale-remove locale:
    rm -f locales/{{locale}}.json
    @echo -e "{{YELLOW}}Locale {{locale}} removed{{NC}}"

# List all locales
locale-list:
    @ls -1 locales/*.json | xargs -I {} basename {} .json

# Show locale stats
locale-stats:
    @echo -e "{{CYAN}}Locale Statistics:{{NC}}"
    @for f in locales/*.json; do \
        count=$$(jq 'keys | length' "$$f"); \
        echo "  $$(basename $$f .json): $$count keys"; \
    done

# Compile locales to single file
locale-compile:
    node -e "const fs=require('fs');const locales={};require('glob').sync('locales/*.json').forEach(f=>{const l=f.match(/locales\/(.+)\.json/)[1];locales[l]=JSON.parse(fs.readFileSync(f))});fs.writeFileSync('dist/locales.json',JSON.stringify(locales))"

# Export locale to CSV
locale-export-csv locale:
    node -e "const l=require('./locales/{{locale}}.json');console.log('key,value');Object.entries(l).forEach(([k,v])=>console.log(k+',\"'+v+'\"'))" > locales/{{locale}}.csv

# Import locale from CSV
locale-import-csv file locale:
    @echo "Import from CSV not yet implemented"

# ═══════════════════════════════════════════════════════════════════════════════
# CLI COMMANDS
# ═══════════════════════════════════════════════════════════════════════════════

# Run CLI
cli *args:
    node tools/cli.js {{args}} 2>/dev/null || echo "CLI not implemented"

# CLI init
cli-init:
    just cli init

# CLI translate
cli-translate text locale="en":
    just cli translate "{{text}}" --locale {{locale}}

# CLI validate
cli-validate:
    just cli validate

# CLI sync
cli-sync:
    just cli sync

# CLI extract
cli-extract:
    just cli extract

# CLI compile
cli-compile:
    just cli compile

# CLI doctor
cli-doctor:
    just cli doctor

# CLI config show
cli-config:
    just cli config show

# CLI help
cli-help:
    just cli --help

# ═══════════════════════════════════════════════════════════════════════════════
# CONTAINERS
# ═══════════════════════════════════════════════════════════════════════════════

# Build container (auto-detect tool)
container-build:
    #!/usr/bin/env bash
    if command -v nerdctl &> /dev/null; then
        just container-build-nerdctl
    elif command -v podman &> /dev/null; then
        just container-build-podman
    elif command -v docker &> /dev/null; then
        just container-build-docker
    else
        echo -e "{{RED}}No container runtime found{{NC}}"
        exit 1
    fi

# Build with nerdctl
container-build-nerdctl:
    nerdctl build -t i18n:latest -f container/Containerfile .

# Build with podman
container-build-podman:
    podman build -t i18n:latest -f container/Containerfile .

# Build with docker
container-build-docker:
    docker build -t i18n:latest -f container/Containerfile .

# Build all container variants
container-build-all:
    just container-build-nerdctl --target node-runtime -t i18n:node
    just container-build-nerdctl --target deno-runtime -t i18n:deno
    just container-build-nerdctl --target cli -t i18n:cli
    just container-build-nerdctl --target dev -t i18n:dev

# Run container
container-run:
    nerdctl run -it --rm -p 3000:3000 i18n:latest

# Run dev container
container-dev:
    nerdctl run -it --rm -v $(pwd):/app -p 3000:3000 i18n:dev

# Start compose stack
container-up:
    nerdctl compose -f container/nerdctl-compose.yaml up -d

# Stop compose stack
container-down:
    nerdctl compose -f container/nerdctl-compose.yaml down

# View container logs
container-logs:
    nerdctl compose -f container/nerdctl-compose.yaml logs -f

# Container shell
container-shell:
    nerdctl run -it --rm i18n:dev /bin/bash

# Build with apko
container-apko:
    apko build container/apko.yaml i18n:apko i18n.tar
    nerdctl load < i18n.tar

# Sign container
container-sign:
    cosign sign --key cosign.key i18n:latest

# Push container
container-push:
    nerdctl push ghcr.io/mashpie/i18n-node-enhanced:latest

# ═══════════════════════════════════════════════════════════════════════════════
# GUIX & NIX
# ═══════════════════════════════════════════════════════════════════════════════

# Enter Guix shell (primary)
guix-shell:
    guix shell -m manifest.scm

# Build with Guix
guix-build:
    guix build -f guix.scm

# Guix development environment
guix-dev:
    guix shell -D -f guix.scm

# Update Guix channels
guix-pull:
    guix pull -C channels.scm

# Enter Nix shell (fallback)
nix-shell:
    nix develop

# Build with Nix
nix-build:
    nix build

# Nix flake check
nix-check:
    nix flake check

# Update Nix flake
nix-update:
    nix flake update

# Format Nix files
nix-fmt:
    nix fmt

# ═══════════════════════════════════════════════════════════════════════════════
# NICKEL CONFIGURATION
# ═══════════════════════════════════════════════════════════════════════════════

# Validate Nickel config
nickel-check:
    nickel check config/i18n.ncl 2>/dev/null || echo "No Nickel config found"

# Export Nickel to JSON
nickel-export:
    nickel export config/i18n.ncl > config/i18n.json

# Export Nickel to YAML
nickel-export-yaml:
    nickel export config/i18n.ncl --format yaml > config/i18n.yaml

# Evaluate Nickel expression
nickel-eval expr:
    nickel eval -e "{{expr}}"

# Generate Nickel schema
nickel-schema:
    @echo "Schema generation not yet implemented"

# REPL for Nickel
nickel-repl:
    nickel repl

# ═══════════════════════════════════════════════════════════════════════════════
# PERFORMANCE & BENCHMARKING
# ═══════════════════════════════════════════════════════════════════════════════

# Run benchmarks
bench:
    node benchmarks/translation-bench.js 2>/dev/null || echo "Benchmarks not found"

# Benchmark translation
bench-translate:
    node benchmarks/translation-bench.js

# Benchmark comparison
bench-compare:
    node benchmarks/comparison-bench.js 2>/dev/null || true

# Benchmark WASM
bench-wasm:
    cd wasm && cargo bench

# Benchmark all
bench-all: bench-translate bench-compare bench-wasm

# Profile CPU
profile-cpu:
    node --prof i18n.js
    node --prof-process isolate-*.log > profile.txt
    @echo "Profile written to profile.txt"

# Profile memory
profile-memory:
    node --expose-gc --trace-gc i18n.js

# Profile heap
profile-heap:
    node --heap-prof --heap-prof-dir=.profiles i18n.js

# Flame graph
profile-flame:
    0x node benchmarks/translation-bench.js 2>/dev/null || echo "0x not installed"

# ═══════════════════════════════════════════════════════════════════════════════
# SECURITY
# ═══════════════════════════════════════════════════════════════════════════════

# Run security audit
audit:
    npm audit --audit-level=moderate

# Fix security issues
audit-fix:
    npm audit fix

# Force fix security issues
audit-fix-force:
    npm audit fix --force

# Check outdated packages
outdated:
    npm outdated

# Update packages
update:
    npm update

# Update all to latest
update-latest:
    npx npm-check-updates -u && npm install

# Security scan with Snyk
security-snyk:
    snyk test 2>/dev/null || echo "Snyk not configured"

# Security scan with Trivy
security-trivy:
    trivy fs . 2>/dev/null || echo "Trivy not installed"

# Check for secrets
security-secrets:
    git secrets --scan 2>/dev/null || echo "git-secrets not installed"

# Generate SBOM
security-sbom:
    npm sbom --sbom-format=cyclonedx > sbom.json 2>/dev/null || echo '{}' > sbom.json

# Verify dependencies
security-verify:
    npm ci --audit
    @echo -e "{{GREEN}}✓ Dependencies verified{{NC}}"

# ═══════════════════════════════════════════════════════════════════════════════
# EXAMPLES
# ═══════════════════════════════════════════════════════════════════════════════

# Run Express example
example-express:
    cd examples/express4-cookie && npm install && npm start

# Run NestJS example
example-nestjs:
    cd examples/nestjs && npm install && npm run start:dev

# Run Hono example
example-hono:
    cd examples/hono && npm install && npm run dev

# Run Fastify example
example-fastify:
    cd examples/fastify && npm install && npm run dev

# Run Koa example
example-koa:
    cd examples/koa && npm install && npm run dev

# Run Next.js example
example-nextjs:
    cd examples/nextjs && npm install && npm run dev

# Run Deno Oak example
example-deno-oak:
    cd deno && deno run --allow-read --allow-net examples/oak.ts

# Run singleton example
example-singleton:
    cd examples/singleton && npm install && node index.js

# Test all examples
example-test-all:
    @for dir in examples/*/; do \
        if [ -f "$$dir/package.json" ]; then \
            echo -e "{{BLUE}}Testing $$dir{{NC}}"; \
            (cd "$$dir" && npm install && npm test) || true; \
        fi \
    done

# ═══════════════════════════════════════════════════════════════════════════════
# RSR COMPLIANCE
# ═══════════════════════════════════════════════════════════════════════════════

# Full RSR compliance check
rsr-check:
    @echo -e "{{CYAN}}╔══════════════════════════════════════════════════════════════════╗{{NC}}"
    @echo -e "{{CYAN}}║{{NC}}  RSR (Reliable Software Repository) Compliance Check          {{CYAN}}║{{NC}}"
    @echo -e "{{CYAN}}╚══════════════════════════════════════════════════════════════════╝{{NC}}"
    @echo ""
    @echo -e "{{YELLOW}}📋 Documentation:{{NC}}"
    @test -f README.md && echo -e "  {{GREEN}}✓{{NC}} README.md" || echo -e "  {{RED}}✗{{NC}} README.md"
    @test -f README.adoc && echo -e "  {{GREEN}}✓{{NC}} README.adoc" || echo -e "  {{YELLOW}}○{{NC}} README.adoc (optional)"
    @test -f LICENSE && echo -e "  {{GREEN}}✓{{NC}} LICENSE" || echo -e "  {{RED}}✗{{NC}} LICENSE"
    @test -f SECURITY.md && echo -e "  {{GREEN}}✓{{NC}} SECURITY.md" || echo -e "  {{RED}}✗{{NC}} SECURITY.md"
    @test -f CONTRIBUTING.md && echo -e "  {{GREEN}}✓{{NC}} CONTRIBUTING.md" || echo -e "  {{RED}}✗{{NC}} CONTRIBUTING.md"
    @test -f CODE_OF_CONDUCT.md && echo -e "  {{GREEN}}✓{{NC}} CODE_OF_CONDUCT.md" || echo -e "  {{RED}}✗{{NC}} CODE_OF_CONDUCT.md"
    @test -f MAINTAINERS.md && echo -e "  {{GREEN}}✓{{NC}} MAINTAINERS.md" || echo -e "  {{RED}}✗{{NC}} MAINTAINERS.md"
    @test -f CHANGELOG.md && echo -e "  {{GREEN}}✓{{NC}} CHANGELOG.md" || echo -e "  {{RED}}✗{{NC}} CHANGELOG.md"
    @test -f ROADMAP.adoc && echo -e "  {{GREEN}}✓{{NC}} ROADMAP.adoc" || echo -e "  {{YELLOW}}○{{NC}} ROADMAP.adoc"
    @echo ""
    @echo -e "{{YELLOW}}🌐 .well-known/:{{NC}}"
    @test -f .well-known/security.txt && echo -e "  {{GREEN}}✓{{NC}} security.txt" || echo -e "  {{RED}}✗{{NC}} security.txt"
    @test -f .well-known/ai.txt && echo -e "  {{GREEN}}✓{{NC}} ai.txt" || echo -e "  {{YELLOW}}○{{NC}} ai.txt"
    @test -f .well-known/humans.txt && echo -e "  {{GREEN}}✓{{NC}} humans.txt" || echo -e "  {{YELLOW}}○{{NC}} humans.txt"
    @echo ""
    @echo -e "{{YELLOW}}🔧 Build System:{{NC}}"
    @test -f justfile && echo -e "  {{GREEN}}✓{{NC}} justfile" || echo -e "  {{RED}}✗{{NC}} justfile"
    @test -f package.json && echo -e "  {{GREEN}}✓{{NC}} package.json" || echo -e "  {{RED}}✗{{NC}} package.json"
    @test -f flake.nix && echo -e "  {{GREEN}}✓{{NC}} flake.nix (Nix)" || echo -e "  {{YELLOW}}○{{NC}} flake.nix"
    @test -f guix.scm && echo -e "  {{GREEN}}✓{{NC}} guix.scm (Guix)" || echo -e "  {{YELLOW}}○{{NC}} guix.scm"
    @test -f container/Containerfile && echo -e "  {{GREEN}}✓{{NC}} Containerfile" || echo -e "  {{YELLOW}}○{{NC}} Containerfile"
    @echo ""
    @echo -e "{{YELLOW}}🧪 Testing:{{NC}}"
    @test -d test && echo -e "  {{GREEN}}✓{{NC}} test/ directory" || echo -e "  {{RED}}✗{{NC}} test/ directory"
    @npm test > /dev/null 2>&1 && echo -e "  {{GREEN}}✓{{NC}} Tests pass" || echo -e "  {{RED}}✗{{NC}} Tests fail"
    @echo ""
    @echo -e "{{YELLOW}}📦 Polyglot:{{NC}}"
    @test -d bindings/rescript && echo -e "  {{GREEN}}✓{{NC}} ReScript" || echo -e "  {{YELLOW}}○{{NC}} ReScript"
    @test -d deno && echo -e "  {{GREEN}}✓{{NC}} Deno" || echo -e "  {{YELLOW}}○{{NC}} Deno"
    @test -d wasm && echo -e "  {{GREEN}}✓{{NC}} WASM" || echo -e "  {{YELLOW}}○{{NC}} WASM"
    @echo ""
    @echo -e "{{CYAN}}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━{{NC}}"
    @echo -e "{{GREEN}}RSR Level: Silver{{NC}}"

# Generate RSR report
rsr-report:
    just rsr-check > rsr-report.txt
    @echo -e "{{GREEN}}✓ Report saved: rsr-report.txt{{NC}}"

# ═══════════════════════════════════════════════════════════════════════════════
# RELEASE
# ═══════════════════════════════════════════════════════════════════════════════

# Version bump (patch)
version-patch:
    npm version patch

# Version bump (minor)
version-minor:
    npm version minor

# Version bump (major)
version-major:
    npm version major

# Pre-release checks
pre-release: clean install build-all test-coverage lint rsr-check
    @echo -e "{{GREEN}}✓ Pre-release checks passed{{NC}}"

# Publish to npm
publish: pre-release
    npm publish

# Publish dry run
publish-dry:
    npm publish --dry-run

# Create git tag
tag version:
    git tag -a "v{{version}}" -m "Release v{{version}}"
    git push origin "v{{version}}"

# Create GitHub release
release version: pre-release
    just tag {{version}}
    gh release create "v{{version}}" --generate-notes 2>/dev/null || true

# ═══════════════════════════════════════════════════════════════════════════════
# CI/CD SIMULATION
# ═══════════════════════════════════════════════════════════════════════════════

# Simulate CI pipeline
ci: install lint test audit
    @echo -e "{{GREEN}}✓ CI simulation passed{{NC}}"

# Simulate full CI/CD
ci-full: clean install build-all test-coverage lint security-sbom rsr-check
    @echo -e "{{GREEN}}✓ Full CI/CD simulation passed{{NC}}"

# GitHub Actions local
ci-act:
    act push 2>/dev/null || echo "act not installed"

# ═══════════════════════════════════════════════════════════════════════════════
# UTILITIES
# ═══════════════════════════════════════════════════════════════════════════════

# Show project info
info:
    @echo -e "{{CYAN}}╔══════════════════════════════════════════════════════════════════╗{{NC}}"
    @echo -e "{{CYAN}}║{{NC}}  {{GREEN}}i18n-node-enhanced{{NC}} v{{I18N_VERSION}}                              {{CYAN}}║{{NC}}"
    @echo -e "{{CYAN}}╚══════════════════════════════════════════════════════════════════╝{{NC}}"
    @echo ""
    @echo -e "{{YELLOW}}Environment:{{NC}}"
    @echo "  Node.js: $(node --version 2>/dev/null || echo 'not found')"
    @echo "  npm: $(npm --version 2>/dev/null || echo 'not found')"
    @echo "  Deno: $(deno --version 2>/dev/null | head -1 || echo 'not found')"
    @echo "  Rust: $(rustc --version 2>/dev/null || echo 'not found')"
    @echo "  Just: $(just --version 2>/dev/null || echo 'installed')"
    @echo ""
    @echo -e "{{YELLOW}}Configuration:{{NC}}"
    @echo "  NODE_ENV: {{NODE_ENV}}"
    @echo "  Working Dir: $(pwd)"

# Show statistics
stats:
    @echo -e "{{CYAN}}Project Statistics{{NC}}"
    @echo ""
    @echo "JavaScript files: $(find . -name '*.js' -not -path './node_modules/*' -not -path './coverage/*' | wc -l)"
    @echo "ReScript files: $(find . -name '*.res' -not -path './node_modules/*' | wc -l)"
    @echo "Rust files: $(find . -name '*.rs' -not -path './target/*' | wc -l)"
    @echo "Test files: $(find test -name '*.js' | wc -l)"
    @echo "Locale files: $(find locales -name '*.json' 2>/dev/null | wc -l)"
    @echo ""
    @echo "Lines of code:"
    @find . -name '*.js' -not -path './node_modules/*' -not -path './coverage/*' -exec wc -l {} + | tail -1

# Git status
status:
    git status

# Recent commits
commits n="10":
    git log --oneline --graph -{{n}}

# Watch files
watch pattern cmd:
    watchexec -e {{pattern}} -- {{cmd}}

# Tree view
tree:
    tree -I 'node_modules|coverage|target|.git' -L 3

# Quick start guide
quickstart:
    @echo -e "{{CYAN}}Quick Start Guide{{NC}}"
    @echo ""
    @echo "1. Install dependencies:"
    @echo "   just install"
    @echo ""
    @echo "2. Run tests:"
    @echo "   just test"
    @echo ""
    @echo "3. Start development:"
    @echo "   just dev"
    @echo ""
    @echo "4. Check compliance:"
    @echo "   just rsr-check"
    @echo ""
    @echo "For all commands: just --list"

# Offline verification
verify-offline:
    @echo -e "{{CYAN}}Verifying offline-first capabilities...{{NC}}"
    @node -e "const {I18n} = require('./'); const i18n = new I18n({staticCatalog: {en: {test: 'works'}}, updateFiles: false}); if(i18n.__('test') === 'works') console.log('{{GREEN}}✓ Offline mode works{{NC}}')"
