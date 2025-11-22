# i18n Development Tools

This directory contains utilities for managing and validating i18n translation files.

## Tools

### 1. Locale Validator (`locale-validator.js`)

Validates translation files for common issues like:
- Malformed JSON
- Duplicate keys (case variations)
- Suspicious values (excessive placeholders, typos)
- Invalid plural forms
- Security issues (XSS, injection)
- Formatting inconsistencies
- Untranslated strings

**Usage:**

```bash
# Basic validation
node tools/locale-validator.js

# Specify directory
node tools/locale-validator.js --dir ./my-locales

# Auto-fix issues
node tools/locale-validator.js --fix --format

# Strict mode (fail on warnings)
node tools/locale-validator.js --strict

# JSON output for CI/CD
node tools/locale-validator.js --json
```

**Options:**
- `--dir <path>` - Directory containing locale files (default: ./locales)
- `--reference <locale>` - Reference locale to compare against (default: en)
- `--fix` - Auto-fix issues where possible
- `--format` - Format JSON files
- `--strict` - Strict mode - exit with error on warnings
- `--json` - Output results as JSON

**Example Output:**

```
=== i18n Locale Validation Results ===

⚠️  WARNINGS:
  - de: Missing 3 translation(s) from reference locale
  - fr: Unclosed mustache braces in 'welcome.message'

ℹ️  INFO:
  - Found 4 locale file(s)
  - en: Translation coverage: 100% (50/50)
  - de: Translation coverage: 94% (47/50)

=== Summary ===
Errors: 0
Warnings: 2
Info: 3

✅ Validation passed!
```

### 2. Missing Translations Reporter (`missing-translations.js`)

Generates detailed reports of missing translations across locales.

**Usage:**

```bash
# Basic report
node tools/missing-translations.js

# Markdown report to file
node tools/missing-translations.js --format markdown --output report.md

# JSON report
node tools/missing-translations.js --format json --output missing.json

# CSV for spreadsheet import
node tools/missing-translations.js --format csv --output coverage.csv

# Check specific locale
node tools/missing-translations.js --locale de

# Create missing keys in locale files
node tools/missing-translations.js --locale de --create-missing
```

**Options:**
- `--dir <path>` - Directory containing locale files (default: ./locales)
- `--reference <locale>` - Reference locale (default: en)
- `--format <type>` - Output format: text|json|csv|markdown (default: text)
- `--output <file>` - Output file (default: stdout)
- `--locale <locale>` - Check specific locale only
- `--create-missing` - Create missing translation files with TODO markers

**Example Output (Markdown):**

```markdown
# Missing Translations Report

**Reference Locale:** en
**Total Keys:** 50
**Generated:** 2025-01-15T10:30:00.000Z

## Summary

| Locale | Coverage | Translated | Missing | Extra |
|--------|----------|------------|---------|-------|
| de     | 94.0%    | 47/50      | 3       | 0     |
| fr     | 88.0%    | 44/50      | 6       | 2     |

## Details

### de

**Coverage:** 94.0%

**Missing Translations:**
- `error.notFound`
- `error.serverError`
- `welcome.subtitle`
```

## CI/CD Integration

### GitHub Actions

Add to `.github/workflows/i18n-check.yml`:

```yaml
name: i18n Validation

on: [push, pull_request]

jobs:
  validate-locales:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v3

      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'

      - name: Install dependencies
        run: npm install

      - name: Validate locale files
        run: node tools/locale-validator.js --strict --json

      - name: Check translation coverage
        run: node tools/missing-translations.js --format json --output coverage.json

      - name: Upload coverage report
        uses: actions/upload-artifact@v3
        with:
          name: translation-coverage
          path: coverage.json
```

### Pre-commit Hook

Add to `.git/hooks/pre-commit`:

```bash
#!/bin/sh

# Validate locale files before commit
node tools/locale-validator.js --strict

if [ $? -ne 0 ]; then
  echo "❌ Locale validation failed. Please fix errors before committing."
  exit 1
fi

echo "✅ Locale validation passed"
```

Make executable:
```bash
chmod +x .git/hooks/pre-commit
```

### NPM Scripts

Add to `package.json`:

```json
{
  "scripts": {
    "i18n:validate": "node tools/locale-validator.js",
    "i18n:validate:strict": "node tools/locale-validator.js --strict",
    "i18n:fix": "node tools/locale-validator.js --fix --format",
    "i18n:coverage": "node tools/missing-translations.js --format markdown --output i18n-report.md",
    "i18n:missing": "node tools/missing-translations.js"
  }
}
```

Usage:
```bash
npm run i18n:validate       # Validate locales
npm run i18n:fix            # Auto-fix issues
npm run i18n:coverage       # Generate coverage report
npm run i18n:missing        # Check missing translations
```

## Best Practices

### 1. Regular Validation

Run validation regularly:
- Before every commit (pre-commit hook)
- In CI/CD pipeline
- Before releases

### 2. Coverage Monitoring

Track translation coverage over time:
```bash
# Generate weekly reports
node tools/missing-translations.js --format json --output reports/coverage-$(date +%Y-%m-%d).json
```

### 3. Collaborative Translation

Use `--create-missing` to prepare files for translators:
```bash
# Create TODO markers for missing translations
node tools/missing-translations.js --locale de --create-missing

# Send generated file to translator
# They search for [TODO: en] markers and translate
```

### 4. Security Review

Regularly audit for security issues:
```bash
# Check for XSS and injection vulnerabilities
node tools/locale-validator.js --json | jq '.errors[] | select(.severity == "high")'
```

## Development

To modify or extend these tools:

### Add New Validation Rule

Edit `locale-validator.js`:

```javascript
checkCustomRule(locale, data, path = '') {
  for (const [key, value] of Object.entries(data)) {
    const fullPath = path ? `${path}.${key}` : key;

    if (typeof value === 'string') {
      // Your validation logic
      if (/* condition */) {
        this.addWarning(
          `${locale}: Issue in '${fullPath}'`,
          { locale, key: fullPath }
        );
      }
    }
  }
}
```

Then call it in `validateLocale()`:
```javascript
validateLocale(locale, { file, data, rawContent }, allLocales) {
  // ... existing checks ...
  this.checkCustomRule(locale, data);
}
```

### Add New Report Format

Edit `missing-translations.js`:

```javascript
formatCustom(analysis) {
  // Your format logic
  return formattedOutput;
}
```

Update `formatReport()`:
```javascript
formatReport(analysis, referenceKeys) {
  switch (this.format) {
    case 'custom':
      return this.formatCustom(analysis);
    // ... existing formats ...
  }
}
```

## Troubleshooting

### "Directory not found" Error

Ensure locale directory exists:
```bash
mkdir -p locales
node tools/locale-validator.js --dir ./locales
```

### "Reference locale not found" Error

Check reference locale file exists:
```bash
ls locales/en.json
node tools/locale-validator.js --reference en
```

### Permission Denied

Make scripts executable:
```bash
chmod +x tools/locale-validator.js
chmod +x tools/missing-translations.js
```

## License

MIT - Same as i18n-node
