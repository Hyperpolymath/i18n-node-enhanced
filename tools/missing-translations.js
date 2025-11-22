#!/usr/bin/env node

/**
 * Missing Translations Reporter
 * Generates reports of missing translations across locales
 *
 * Usage:
 *   node tools/missing-translations.js [options]
 *
 * Options:
 *   --dir <path>         Directory containing locale files (default: ./locales)
 *   --reference <locale>  Reference locale (default: en)
 *   --format <type>      Output format: text|json|csv|markdown (default: text)
 *   --output <file>      Output file (default: stdout)
 *   --locale <locale>    Check specific locale only
 *   --create-missing     Create missing translation files with keys
 */

const fs = require('fs');
const path = require('path');

class MissingTranslationsReporter {
  constructor(options = {}) {
    this.dir = options.dir || './locales';
    this.reference = options.reference || 'en';
    this.format = options.format || 'text';
    this.output = options.output || null;
    this.targetLocale = options.locale || null;
    this.createMissing = options.createMissing || false;
  }

  /**
   * Generate report
   */
  async generate() {
    try {
      // Load all locales
      const locales = this.loadLocales();

      if (!locales[this.reference]) {
        throw new Error(`Reference locale '${this.reference}' not found`);
      }

      // Get reference keys
      const referenceKeys = this.extractKeys(locales[this.reference]);

      // Analyze each locale
      const analysis = {};

      for (const [locale, data] of Object.entries(locales)) {
        if (locale === this.reference) continue;
        if (this.targetLocale && locale !== this.targetLocale) continue;

        const localeKeys = this.extractKeys(data);
        const missing = referenceKeys.filter(k => !localeKeys.has(k));
        const extra = Array.from(localeKeys).filter(k => !referenceKeys.has(k));

        analysis[locale] = {
          total: referenceKeys.size,
          translated: referenceKeys.size - missing.length,
          missing: missing,
          extra: extra,
          coverage: ((referenceKeys.size - missing.length) / referenceKeys.size * 100).toFixed(1)
        };

        // Create missing translations if requested
        if (this.createMissing && missing.length > 0) {
          this.createMissingKeys(locale, data, missing, referenceKeys);
        }
      }

      // Generate output
      const report = this.formatReport(analysis, referenceKeys);

      // Write output
      if (this.output) {
        fs.writeFileSync(this.output, report, 'utf8');
        console.log(`Report written to: ${this.output}`);
      } else {
        console.log(report);
      }

      return analysis;

    } catch (err) {
      console.error(`Error: ${err.message}`);
      process.exit(1);
    }
  }

  /**
   * Load all locale files
   */
  loadLocales() {
    if (!fs.existsSync(this.dir)) {
      throw new Error(`Directory not found: ${this.dir}`);
    }

    const files = fs.readdirSync(this.dir).filter(f => f.endsWith('.json'));

    if (files.length === 0) {
      throw new Error('No JSON locale files found');
    }

    const locales = {};

    for (const file of files) {
      const locale = path.basename(file, '.json');
      const filePath = path.join(this.dir, file);

      try {
        locales[locale] = JSON.parse(fs.readFileSync(filePath, 'utf8'));
      } catch (err) {
        console.error(`Warning: Failed to parse ${file}: ${err.message}`);
      }
    }

    return locales;
  }

  /**
   * Extract all keys from nested object
   */
  extractKeys(obj, prefix = '', keys = new Set()) {
    for (const [key, value] of Object.entries(obj)) {
      const fullKey = prefix ? `${prefix}.${key}` : key;

      if (this.isPluralForm(value)) {
        keys.add(fullKey);
      } else if (typeof value === 'object' && value !== null) {
        this.extractKeys(value, fullKey, keys);
      } else {
        keys.add(fullKey);
      }
    }

    return keys;
  }

  /**
   * Check if value is a plural form
   */
  isPluralForm(value) {
    if (typeof value !== 'object' || value === null) return false;

    const keys = Object.keys(value);
    const pluralKeys = ['zero', 'one', 'two', 'few', 'many', 'other'];

    return keys.some(k => pluralKeys.includes(k));
  }

  /**
   * Format report based on output type
   */
  formatReport(analysis, referenceKeys) {
    switch (this.format) {
      case 'json':
        return this.formatJSON(analysis);
      case 'csv':
        return this.formatCSV(analysis);
      case 'markdown':
        return this.formatMarkdown(analysis, referenceKeys);
      default:
        return this.formatText(analysis, referenceKeys);
    }
  }

  /**
   * Format as plain text
   */
  formatText(analysis, referenceKeys) {
    let output = '=== Missing Translations Report ===\n\n';
    output += `Reference Locale: ${this.reference}\n`;
    output += `Total Keys: ${referenceKeys.size}\n\n`;

    for (const [locale, data] of Object.entries(analysis)) {
      output += `--- ${locale} ---\n`;
      output += `Coverage: ${data.coverage}% (${data.translated}/${data.total})\n`;
      output += `Missing: ${data.missing.length}\n`;
      output += `Extra: ${data.extra.length}\n`;

      if (data.missing.length > 0) {
        output += `\nMissing Keys:\n`;
        data.missing.forEach(key => {
          output += `  - ${key}\n`;
        });
      }

      if (data.extra.length > 0) {
        output += `\nExtra Keys:\n`;
        data.extra.forEach(key => {
          output += `  + ${key}\n`;
        });
      }

      output += '\n';
    }

    return output;
  }

  /**
   * Format as JSON
   */
  formatJSON(analysis) {
    return JSON.stringify({
      reference: this.reference,
      locales: analysis,
      timestamp: new Date().toISOString()
    }, null, 2);
  }

  /**
   * Format as CSV
   */
  formatCSV(analysis) {
    let csv = 'Locale,Total,Translated,Missing,Extra,Coverage\n';

    for (const [locale, data] of Object.entries(analysis)) {
      csv += `${locale},${data.total},${data.translated},${data.missing.length},${data.extra.length},${data.coverage}%\n`;
    }

    return csv;
  }

  /**
   * Format as Markdown
   */
  formatMarkdown(analysis, referenceKeys) {
    let md = '# Missing Translations Report\n\n';
    md += `**Reference Locale:** ${this.reference}\n`;
    md += `**Total Keys:** ${referenceKeys.size}\n`;
    md += `**Generated:** ${new Date().toISOString()}\n\n`;

    md += '## Summary\n\n';
    md += '| Locale | Coverage | Translated | Missing | Extra |\n';
    md += '|--------|----------|------------|---------|-------|\n';

    for (const [locale, data] of Object.entries(analysis)) {
      md += `| ${locale} | ${data.coverage}% | ${data.translated}/${data.total} | ${data.missing.length} | ${data.extra.length} |\n`;
    }

    md += '\n## Details\n\n';

    for (const [locale, data] of Object.entries(analysis)) {
      md += `### ${locale}\n\n`;
      md += `**Coverage:** ${data.coverage}%\n\n`;

      if (data.missing.length > 0) {
        md += '**Missing Translations:**\n\n';
        data.missing.forEach(key => {
          md += `- \`${key}\`\n`;
        });
        md += '\n';
      }

      if (data.extra.length > 0) {
        md += '**Extra Keys (not in reference):**\n\n';
        data.extra.forEach(key => {
          md += `- \`${key}\`\n`;
        });
        md += '\n';
      }
    }

    return md;
  }

  /**
   * Create missing translation keys in locale file
   */
  createMissingKeys(locale, data, missingKeys, referenceKeys) {
    const updated = { ...data };

    for (const key of missingKeys) {
      this.setNestedKey(updated, key, `[TODO: ${this.reference}] ${key}`);
    }

    const filePath = path.join(this.dir, `${locale}.json`);
    fs.writeFileSync(filePath, JSON.stringify(updated, null, 2) + '\n', 'utf8');

    console.log(`Created ${missingKeys.length} missing key(s) in ${locale}.json`);
  }

  /**
   * Set nested key in object
   */
  setNestedKey(obj, keyPath, value) {
    const keys = keyPath.split('.');
    const lastKey = keys.pop();

    let current = obj;

    for (const key of keys) {
      if (!current[key]) {
        current[key] = {};
      }
      current = current[key];
    }

    current[lastKey] = value;
  }
}

// CLI
if (require.main === module) {
  const args = process.argv.slice(2);
  const options = {};

  for (let i = 0; i < args.length; i++) {
    switch (args[i]) {
      case '--dir':
        options.dir = args[++i];
        break;
      case '--reference':
        options.reference = args[++i];
        break;
      case '--format':
        options.format = args[++i];
        break;
      case '--output':
        options.output = args[++i];
        break;
      case '--locale':
        options.locale = args[++i];
        break;
      case '--create-missing':
        options.createMissing = true;
        break;
      case '--help':
        console.log(`
Missing Translations Reporter

Usage:
  node tools/missing-translations.js [options]

Options:
  --dir <path>         Directory containing locale files (default: ./locales)
  --reference <locale>  Reference locale (default: en)
  --format <type>      Output format: text|json|csv|markdown (default: text)
  --output <file>      Output file (default: stdout)
  --locale <locale>    Check specific locale only
  --create-missing     Create missing translation files with keys
  --help               Show this help message

Examples:
  node tools/missing-translations.js
  node tools/missing-translations.js --format markdown --output report.md
  node tools/missing-translations.js --locale de --create-missing
  node tools/missing-translations.js --format json --output missing.json
        `);
        process.exit(0);
    }
  }

  const reporter = new MissingTranslationsReporter(options);
  reporter.generate();
}

module.exports = MissingTranslationsReporter;
