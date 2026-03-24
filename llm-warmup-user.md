# SPDX-License-Identifier: MPL-2.0
# (PMPL-1.0-or-later preferred; MPL-2.0 required for npm ecosystem compatibility)
# LLM Warmup: polyglot-i18n (User Guide)

## What This Project Does

polyglot-i18n is an internationalization (i18n) library for JavaScript and
ReScript applications. It provides translation functions (`__`, `__n`, `__mf`),
locale management, plural rules, and MessageFormat support.

It is a modernised fork of i18n-node by Marcus Spiegel, with a ReScript-first
architecture and optional WASM acceleration.

## Who Uses This

Any developer building a multi-language web application. It integrates with
Express, Fastify, Hono, Koa, NestJS, and works standalone.

## How to Get Started

```bash
# As a dependency in your project
npm install polyglot-i18n

# From source
git clone https://github.com/hyperpolymath/polyglot-i18n
cd polyglot-i18n
just install && just test
```

## Basic Usage

```javascript
const { I18n } = require('polyglot-i18n');
const i18n = new I18n({
  locales: ['en', 'de', 'fr'],
  directory: './locales',
  defaultLocale: 'en'
});

i18n.__('Hello');                // "Hello" (or translated equivalent)
i18n.__n('%s cat', '%s cats', 3); // "3 cats"
i18n.__mf('{N, plural, one{# item} other{# items}}', { N: 7 });
```

## Key Commands

| Command | What It Does |
|---------|-------------|
| `just install` | Install dependencies (auto-detects npm/deno) |
| `just test` | Run Mocha test suite |
| `just dev` | Start example Express server |
| `just build-wasm` | Build Rust WASM acceleration module |
| `just doctor` | Diagnose environment problems |
| `just heal` | Attempt automatic repair |
| `just tour` | Guided walkthrough of the codebase |
| `just help-me` | Interactive help menu (pick what you need) |
| `just lint` | ESLint + Prettier checks |
| `just rsr-check` | Verify RSR compliance |

## Architecture at a Glance

- **ReScript core** (`src/core/`) -- type-safe i18n modules
- **Legacy JS** (`i18n.js`) -- original implementation being migrated
- **WASM** (`wasm/`) -- Rust-compiled plural rules and interpolation
- **Locales** (`locales/`) -- JSON translation files per language
- **Examples** (`examples/`) -- integrations for 6 web frameworks

## Translation File Format

JSON files in `locales/`, one per language:

```json
// locales/en.json
{ "Hello": "Hello", "greeting.formal": "Good day" }

// locales/de.json
{ "Hello": "Hallo", "greeting.formal": "Guten Tag" }
```

## NLP Features

- **FuzzyMatch** -- Levenshtein/Damerau-Levenshtein distance for typo-tolerant lookups
- **Stemmer** -- Porter stemmer for 8 languages
- **Segmenter** -- sentence/word boundary detection (CJK + Western)
- **RelativeTime** -- "3 days ago", "yesterday" formatting
- **DocumentExtract** -- text extraction via Pandoc, OCR via Tesseract

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| Missing translations show key name | Check file exists in `locales/` and locale is listed in config |
| Plural forms incorrect | Verify CLDR rules for your language in `Plural.res` |
| `objectNotation` not working | Set `objectNotation: true` in config |
| WASM module not loading | Build it first: `just build-wasm` (requires Rust) |
| Everything feels broken | Run `just doctor` then `just heal` |

## What You Can Ask an LLM to Help With

- "How do I add a new locale to my project?"
- "How do I set up fallback languages?"
- "How do I use MessageFormat for complex plurals?"
- "How do I enable object notation for nested translations?"
- "How do I use the WASM-accelerated plural rules?"
- "How do I integrate with Express/Fastify/Hono?"

## What to Avoid Changing

- Do not modify CLDR plural rules without referencing the CLDR spec.
- Do not remove the legacy JS bridge -- it provides backward compatibility.
- Do not introduce TypeScript -- ReScript is the migration target.
- Do not remove SPDX headers from source files.

## License

MPL-2.0 (PMPL-1.0-or-later preferred; MPL-2.0 for npm ecosystem).
Original i18n-node code: MIT by Marcus Spiegel.
