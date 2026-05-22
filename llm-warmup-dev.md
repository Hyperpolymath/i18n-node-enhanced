# SPDX-License-Identifier: MPL-2.0
# (MPL-2.0 preferred; MPL-2.0 required for npm ecosystem compatibility)
# LLM Warmup: polyglot-i18n (Developer Guide)

## Project Identity

**Name:** polyglot-i18n
**Type:** JavaScript/ReScript library (npm package)
**Primary language:** ReScript (migration in progress from JavaScript)
**Secondary languages:** Rust (WASM), JavaScript (legacy), Nickel (config)
**License:** MPL-2.0 (MPL-2.0 preferred)
**Author:** Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
**Origin:** Fork of i18n-node by Marcus Spiegel (MIT)

## What This Does

An i18n library that:
1. Manages translation catalogs (JSON files per locale)
2. Provides translation functions: `__()`, `__n()`, `__mf()`, `__l()`, `__h()`
3. Detects locale from query params, cookies, Accept-Language header
4. Handles CLDR plural rules for 9+ languages
5. Supports MessageFormat (ICU), Mustache templates, sprintf interpolation
6. Integrates as middleware with Express, Fastify, Hono, Koa, NestJS
7. Offers NLP features: fuzzy matching, stemming, segmentation, OCR

## Architecture

### Module Map

```
src/core/
  I18n.res          Main API (config builder, translate, locale management)
  Catalog.res       Immutable translation catalogs with structural sharing
  Locale.res        BCP 47 locale parsing, validation, fallback chains
  Plural.res        CLDR plural rules (9+ langs), optional WASM delegate
  FuzzyMatch.res    Levenshtein, Damerau-Levenshtein, n-gram similarity
  Stemmer.res       Porter stemmer (8 languages)
  Segmenter.res     Sentence/word boundary detection (CJK + Western)
  RelativeTime.res  Human-readable relative time ("3 days ago")
  DocumentExtract.res  Pandoc, Hunspell, Tesseract integration
```

### Data Flow

```
Configure(options)
  -> Load locale JSONs from directory
  -> Build immutable Catalog (with structural sharing)
  -> Bind API to request/response (middleware) or global

Translate(key, args)
  -> Look up key in current locale catalog
  -> If missing: try fallback locale, then default locale
  -> Interpolate: sprintf -> mustache -> MessageFormat
  -> Return translated string
```

### Instance vs Singleton

```javascript
// Instance (recommended for concurrent requests)
const i18n = new I18n({ locales: ['en', 'de'] });

// Singleton (legacy, binds to global)
const i18n = require('polyglot-i18n');
i18n.configure({ locales: ['en', 'de'] });
```

## Build System

### Primary: Guix

```bash
guix shell -m manifest.scm   # dev environment
guix build -f guix.scm       # build package
```

### Fallback: Nix

```bash
nix develop                   # dev shell
nix build                     # build package
```

### npm (Legacy)

```bash
npm ci                        # install
npm test                      # test
```

### WASM (Rust)

```bash
cd wasm/
cargo build --release --target wasm32-unknown-unknown
wasm-pack build --target web --out-dir pkg
```

## Testing

```bash
just test              # Mocha test suite
just test-coverage     # NYC coverage report
just test-watch        # watch mode
just test-locale en    # test specific locale
just test-runtime deno # test on Deno runtime
```

Test files: `test/*.test.js`
Framework: Mocha + Should.js
Coverage: NYC (Istanbul)

Test categories:
- Translation method tests (`__`, `__n`, `__mf`)
- Locale file I/O
- Plural form correctness per language
- Object notation (dot paths)
- Fallback chain resolution
- Express middleware integration
- MessageFormat parsing

## Configuration

### Nickel (type-safe)

```bash
just nickel-export development > config.json
just nickel-check              # validate
```

Config presets: development, staging, production, test.
Located in `config/i18n.ncl`.

### JavaScript (runtime)

```javascript
{
  locales: ['en', 'de'],
  fallbacks: { nl: 'de' },
  defaultLocale: 'en',
  directory: './locales',
  objectNotation: false,
  updateFiles: true,      // write new keys to JSON files
  syncFiles: false,       // sync keys across all locale files
  autoReload: false,      // watch for file changes
  cookie: 'locale',       // cookie name for locale detection
  header: 'accept-language',
  queryParameter: 'lang',
  indent: '\t',
  extension: '.json',
  prefix: '',
  parser: JSON            // can swap for YAML parser
}
```

## Dependencies

### Runtime

| Dep | Purpose |
|-----|---------|
| `@messageformat/core` | ICU MessageFormat formatting |
| `debug` | Debug logging infrastructure |
| `fast-printf` | sprintf-style string formatting |
| `make-plural` | CLDR plural rule functions |
| `math-interval-parser` | Interval notation for plural ranges |
| `mustache` | Template interpolation |

### Development

| Dep | Purpose |
|-----|---------|
| `mocha` | Test runner |
| `nyc` | Code coverage |
| `eslint` + `prettier` | Linting and formatting |
| `express` + `supertest` | Integration test server |

## ReScript Migration Status

The project is migrating from `i18n.js` (legacy JavaScript) to ReScript.

**Complete (in `src/core/`):**
- I18n.res (main API)
- Catalog.res (immutable catalogs)
- Locale.res (BCP 47 handling)
- Plural.res (CLDR rules)
- FuzzyMatch.res (distance algorithms)
- Stemmer.res (Porter stemmer, 8 langs)
- Segmenter.res (boundary detection)
- RelativeTime.res (relative time formatting)
- DocumentExtract.res (Pandoc/Hunspell/Tesseract)

**Remaining:**
- Express/Fastify/Hono/Koa/NestJS middleware adapters
- File I/O layer (locale JSON read/write)
- Full singleton-to-instance refactor

## WASM Acceleration

Located in `wasm/` (Rust):
- Plural rule evaluation (hot path)
- String interpolation
- MessageFormat parsing

Compiled to `wasm32-unknown-unknown`, packaged via `wasm-pack`.
Falls back to pure JS when WASM unavailable.

## Container Workflows

```bash
just container-build      # Chainguard Wolfi image
just container-run        # run with nerdctl/podman
just container-dev        # dev shell in container
just container-compose-up # full stack
```

Uses `container/Containerfile` (multi-stage) and `container/apko.yaml`
(declarative minimal image).

## Development Workflow

```bash
# Daily cycle
just install              # install/update deps
just dev                  # start example Express server
just test                 # run full test suite
just lint                 # eslint + prettier
just assail               # panic-attacker pre-commit scan

# Diagnostics
just doctor               # check all tools and files
just heal                 # auto-fix stale dirs, missing deps
just tour                 # guided codebase walkthrough
just help-me              # interactive help menu

# ReScript work
just build-rescript       # compile ReScript modules
just test                 # verify integration

# WASM work
just build-wasm           # compile Rust to WASM
just test                 # verify WASM integration

# Before release
just rsr-check            # RSR compliance
just test-coverage        # ensure coverage thresholds
just build-all            # build all targets
```

## Contractile System

| File | Role |
|------|------|
| `contractiles/must/Mustfile` | Hard invariants |
| `.machine_readable/MUST.contractile` | Structural invariants |
| `.machine_readable/TRUST.contractile` | AI permission boundaries |
| `.machine_readable/INTENT.contractile` | Project purpose and scope |
| `.machine_readable/ADJUST.contractile` | Accessibility + i18n requirements |

## AI Manifest

Read `0-AI-MANIFEST.a2ml` first. It defines:
- **Context tiers** (tier-0: orientation, tier-1: development, tier-2: deep-dive)
- **Canonical file locations** (where things live)
- **Critical invariants** (what must never be violated)
- **Lifecycle hooks** (what to do on session enter/exit)

## Machine-Readable Metadata

All in `.machine_readable/6a2/`:
- `STATE.a2ml` -- current progress, blockers, next actions
- `META.a2ml` -- architecture decisions
- `ECOSYSTEM.a2ml` -- position in hyperpolymath ecosystem
- `AGENTIC.a2ml` -- AI agent interaction patterns
- `NEUROSYM.a2ml` -- neurosymbolic config
- `PLAYBOOK.a2ml` -- operational runbook

## Common Pitfalls

1. **npm vs Deno** -- The project has both `package.json` (legacy) and
   `deno.json`. Deno is preferred for new work. npm is kept for backward
   compat.
2. **Locale file mutation** -- `updateFiles: true` writes new keys to disk.
   Disable in production or with `staticCatalog`.
3. **Plural rule coverage** -- Only 9 languages have full CLDR rules in
   `Plural.res`. Others fall back to English (singular/plural).
4. **WASM build** -- Requires `wasm-pack` and `wasm32-unknown-unknown` target.
   Not needed for development -- the JS fallback works.
5. **ReScript build** -- `cd bindings/rescript && npm install && npx rescript`.
   Separate from the main npm install.
6. **Test locale files** -- Tests create temporary locale directories
   (`testlocalesauto*`). Run `just heal` to clean them up if they linger.

## Ecosystem Position

- **Standalone repo** (not in a monorepo)
- **Origin:** Fork of i18n-node (MIT, Marcus Spiegel)
- **Related:** developer-ecosystem (ReScript ecosystem tools), proven (Idris2
  formal verification), panic-attacker (pre-commit security),
  standards/lol (multilingual NLP corpus for 1500+ languages)
- **Downstream:** Any JS/ReScript application needing i18n
- **npm:** Published as `polyglot-i18n`

## What Not to Do

- Do not introduce TypeScript -- ReScript is the target language
- Do not remove the legacy `i18n.js` -- it is the current runtime bridge
- Do not modify CLDR plural rules without referencing Unicode CLDR
- Do not commit real locale files with PII or proprietary translations
- Do not add Node.js-only APIs -- maintain Deno compatibility
- Do not weaken tests (no `skip`, no lowering coverage thresholds)
- Do not remove SPDX headers from source files
- Do not use Python/Go -- see language policy in CLAUDE.md

## License

MPL-2.0 (MPL-2.0 preferred; MPL-2.0 required for npm ecosystem).
Original i18n-node code: MIT by Marcus Spiegel.
Copyright 2024-2026 Jonathan D.A. Jewell.
