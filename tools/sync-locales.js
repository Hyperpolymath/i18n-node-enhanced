#!/usr/bin/env node

/**
 * Locale Synchronization Utility
 * Syncs keys across all locale files based on a reference locale
 *
 * Usage:
 *   node tools/sync-locales.js [options]
 *
 * Options:
 *   --dir <path>         Directory containing locale files (default: ./locales)
 *   --reference <locale>  Reference locale (default: en)
 *   --add-missing        Add missing keys to other locales
 *   --remove-extra       Remove keys not in reference locale
 *   --dry-run            Preview changes without modifying files
 *   --backup             Create backups before modifying
 */

const fs = require('fs');
const path = require('path');

class LocaleSync {
  constructor(options = {}) {
    this.dir = options.dir || './locales';
    this.reference = options.reference || 'en';
    this.addMissing = options.addMissing || false;
    this.removeExtra = options.removeExtra || false;
    this.dryRun = options.dryRun || false;
    this.backup = options.backup || false;
  }

  async sync() {
    try {
      console.log('=== Locale Synchronization ===\n');

      // Load all locale files
      const locales = this.loadLocales();

      if (!locales[this.reference]) {
        throw new Error(`Reference locale '${this.reference}' not found`);
      }

      const referenceData = locales[this.reference];
      const referenceKeys = this.getAllKeys(referenceData);

      console.log(`Reference locale: ${this.reference}`);
      console.log(`Total keys in reference: ${referenceKeys.size}\n`);

      // Sync each locale
      for (const [locale, data] of Object.entries(locales)) {
        if (locale === this.reference) continue;

        console.log(`--- Processing ${locale} ---`);

        const localeKeys = this.getAllKeys(data);
        const missing = Array.from(referenceKeys).filter(k => !localeKeys.has(k));
        const extra = Array.from(localeKeys).filter(k => !referenceKeys.has(k));

        console.log(`Missing keys: ${missing.length}`);
        console.log(`Extra keys: ${extra.length}`);

        if (this.addMissing && missing.length > 0) {
          console.log(`Adding ${missing.length} missing key(s)...`);

          missing.forEach(key => {
            const value = this.getValue(referenceData, key);
            this.setValue(data, key, `[TODO: Translate from ${this.reference}] ${value}`);
          });
        }

        if (this.removeExtra && extra.length > 0) {
          console.log(`Removing ${extra.length} extra key(s)...`);

          extra.forEach(key => {
            this.deleteValue(data, key);
          });
        }

        // Write changes
        if ((this.addMissing || this.removeExtra) && !this.dryRun) {
          const filePath = path.join(this.dir, `${locale}.json`);

          if (this.backup) {
            const backupPath = `${filePath}.backup`;
            fs.copyFileSync(filePath, backupPath);
            console.log(`Created backup: ${backupPath}`);
          }

          fs.writeFileSync(filePath, JSON.stringify(data, null, 2) + '\n', 'utf8');
          console.log(`Updated ${locale}.json`);
        } else if (this.dryRun) {
          console.log('[DRY RUN] No changes made');
        }

        console.log('');
      }

      if (this.dryRun) {
        console.log('✅ Dry run completed. Use --add-missing and/or --remove-extra to apply changes.\n');
      } else {
        console.log('✅ Synchronization completed.\n');
      }

    } catch (err) {
      console.error(`Error: ${err.message}`);
      process.exit(1);
    }
  }

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

  getAllKeys(obj, prefix = '', keys = new Set()) {
    for (const [key, value] of Object.entries(obj)) {
      const fullKey = prefix ? `${prefix}.${key}` : key;

      if (this.isPluralForm(value)) {
        keys.add(fullKey);
      } else if (typeof value === 'object' && value !== null) {
        this.getAllKeys(value, fullKey, keys);
      } else {
        keys.add(fullKey);
      }
    }

    return keys;
  }

  getValue(obj, keyPath) {
    const keys = keyPath.split('.');
    let current = obj;

    for (const key of keys) {
      if (current[key] === undefined) return undefined;
      current = current[key];
    }

    return current;
  }

  setValue(obj, keyPath, value) {
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

  deleteValue(obj, keyPath) {
    const keys = keyPath.split('.');
    const lastKey = keys.pop();

    let current = obj;

    for (const key of keys) {
      if (!current[key]) return;
      current = current[key];
    }

    delete current[lastKey];

    // Clean up empty parent objects
    this.cleanupEmptyObjects(obj);
  }

  cleanupEmptyObjects(obj) {
    for (const [key, value] of Object.entries(obj)) {
      if (typeof value === 'object' && value !== null && !Array.isArray(value)) {
        this.cleanupEmptyObjects(value);

        if (Object.keys(value).length === 0) {
          delete obj[key];
        }
      }
    }
  }

  isPluralForm(value) {
    if (typeof value !== 'object' || value === null) return false;

    const keys = Object.keys(value);
    const pluralKeys = ['zero', 'one', 'two', 'few', 'many', 'other'];

    return keys.some(k => pluralKeys.includes(k));
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
      case '--add-missing':
        options.addMissing = true;
        break;
      case '--remove-extra':
        options.removeExtra = true;
        break;
      case '--dry-run':
        options.dryRun = true;
        break;
      case '--backup':
        options.backup = true;
        break;
      case '--help':
        console.log(`
Locale Synchronization Utility

Usage:
  node tools/sync-locales.js [options]

Options:
  --dir <path>         Directory containing locale files (default: ./locales)
  --reference <locale>  Reference locale (default: en)
  --add-missing        Add missing keys to other locales
  --remove-extra       Remove keys not in reference locale
  --dry-run            Preview changes without modifying files
  --backup             Create backups before modifying
  --help               Show this help message

Examples:
  # Preview changes
  node tools/sync-locales.js --dry-run

  # Add missing keys
  node tools/sync-locales.js --add-missing

  # Full sync with backup
  node tools/sync-locales.js --add-missing --remove-extra --backup

  # Sync from German as reference
  node tools/sync-locales.js --reference de --add-missing
        `);
        process.exit(0);
    }
  }

  const sync = new LocaleSync(options);
  sync.sync();
}

module.exports = LocaleSync;
