#!/usr/bin/env node

/**
 * i18n Locale Validator
 * Validates translation files for common issues
 *
 * Usage:
 *   node tools/locale-validator.js [options]
 *
 * Options:
 *   --dir <path>        Directory containing locale files (default: ./locales)
 *   --reference <locale> Reference locale to compare against (default: en)
 *   --fix               Auto-fix issues where possible
 *   --format            Format JSON files
 *   --strict            Strict mode - fail on warnings
 *   --json              Output results as JSON
 */

const fs = require('fs');
const path = require('path');

class LocaleValidator {
  constructor(options = {}) {
    this.dir = options.dir || './locales';
    this.reference = options.reference || 'en';
    this.fix = options.fix || false;
    this.format = options.format || false;
    this.strict = options.strict || false;
    this.jsonOutput = options.json || false;

    this.errors = [];
    this.warnings = [];
    this.info = [];
  }

  /**
   * Run validation
   */
  async validate() {
    try {
      if (!fs.existsSync(this.dir)) {
        this.addError(`Directory not found: ${this.dir}`);
        return this.getResults();
      }

      const files = fs.readdirSync(this.dir).filter(f => f.endsWith('.json'));

      if (files.length === 0) {
        this.addWarning('No JSON locale files found');
        return this.getResults();
      }

      this.addInfo(`Found ${files.length} locale file(s)`);

      // Load all locales
      const locales = {};
      for (const file of files) {
        const locale = path.basename(file, '.json');
        const filePath = path.join(this.dir, file);

        try {
          const content = fs.readFileSync(filePath, 'utf8');
          locales[locale] = {
            file: filePath,
            data: JSON.parse(content),
            rawContent: content
          };
        } catch (err) {
          this.addError(`Failed to parse ${file}: ${err.message}`);
        }
      }

      // Validate each locale
      for (const [locale, data] of Object.entries(locales)) {
        this.validateLocale(locale, data, locales);
      }

      // Cross-locale validation
      if (locales[this.reference]) {
        this.validateTranslationCoverage(locales);
      } else {
        this.addWarning(`Reference locale '${this.reference}' not found`);
      }

      // Auto-fix if requested
      if (this.fix) {
        this.applyFixes(locales);
      }

      return this.getResults();
    } catch (err) {
      this.addError(`Validation failed: ${err.message}`);
      return this.getResults();
    }
  }

  /**
   * Validate a single locale file
   */
  validateLocale(locale, { file, data, rawContent }, allLocales) {
    // Check for empty files
    if (Object.keys(data).length === 0) {
      this.addWarning(`${locale}: File is empty`, { locale, file });
    }

    // Check for duplicate keys (case-insensitive)
    this.checkDuplicateKeys(locale, data);

    // Check for suspicious values
    this.checkSuspiciousValues(locale, data);

    // Check for malformed plural forms
    this.checkPluralForms(locale, data);

    // Check for HTML/XSS risks
    this.checkSecurityIssues(locale, data);

    // Check formatting consistency
    this.checkFormatting(locale, rawContent, file);

    // Check for untranslated strings (values === keys)
    this.checkUntranslated(locale, data);
  }

  /**
   * Check for duplicate keys (case variations)
   */
  checkDuplicateKeys(locale, data, prefix = '') {
    const keys = {};

    const checkObj = (obj, path = '') => {
      for (const [key, value] of Object.entries(obj)) {
        const fullPath = path ? `${path}.${key}` : key;
        const lowerKey = fullPath.toLowerCase();

        if (keys[lowerKey] && keys[lowerKey] !== fullPath) {
          this.addWarning(
            `${locale}: Potential duplicate key (case variation): '${fullPath}' vs '${keys[lowerKey]}'`,
            { locale, key: fullPath, duplicate: keys[lowerKey] }
          );
        }

        keys[lowerKey] = fullPath;

        if (typeof value === 'object' && value !== null && !Array.isArray(value)) {
          checkObj(value, fullPath);
        }
      }
    };

    checkObj(data);
  }

  /**
   * Check for suspicious values
   */
  checkSuspiciousValues(locale, data, path = '') {
    for (const [key, value] of Object.entries(data)) {
      const fullPath = path ? `${path}.${key}` : key;

      if (typeof value === 'string') {
        // Check for placeholder mismatches
        const sprintfCount = (value.match(/%[sd]/g) || []).length;
        const mustacheCount = (value.match(/\{\{[^}]+\}\}/g) || []).length;

        if (sprintfCount > 5) {
          this.addWarning(
            `${locale}: Excessive sprintf placeholders (${sprintfCount}) in '${fullPath}'`,
            { locale, key: fullPath, count: sprintfCount }
          );
        }

        // Check for common typos in placeholders
        if (value.includes('%S') || value.includes('%D')) {
          this.addWarning(
            `${locale}: Incorrect placeholder case in '${fullPath}': use %s or %d (lowercase)`,
            { locale, key: fullPath }
          );
        }

        // Check for unclosed mustache braces
        if ((value.match(/\{\{/g) || []).length !== (value.match(/\}\}/g) || []).length) {
          this.addError(
            `${locale}: Unclosed mustache braces in '${fullPath}'`,
            { locale, key: fullPath }
          );
        }

        // Check for very long values (potential copy-paste errors)
        if (value.length > 500) {
          this.addWarning(
            `${locale}: Very long translation (${value.length} chars) in '${fullPath}'`,
            { locale, key: fullPath, length: value.length }
          );
        }

        // Check for leading/trailing whitespace
        if (value !== value.trim()) {
          this.addWarning(
            `${locale}: Leading/trailing whitespace in '${fullPath}'`,
            { locale, key: fullPath }
          );
        }

      } else if (typeof value === 'object' && value !== null) {
        this.checkSuspiciousValues(locale, value, fullPath);
      }
    }
  }

  /**
   * Check plural forms
   */
  checkPluralForms(locale, data, path = '') {
    const validPluralKeys = ['zero', 'one', 'two', 'few', 'many', 'other'];

    for (const [key, value] of Object.entries(data)) {
      const fullPath = path ? `${path}.${key}` : key;

      if (typeof value === 'object' && value !== null && !Array.isArray(value)) {
        const keys = Object.keys(value);

        // Check if this looks like a plural form object
        const isPluralForm = keys.some(k => validPluralKeys.includes(k));

        if (isPluralForm) {
          // Validate plural keys
          const invalidKeys = keys.filter(k => !validPluralKeys.includes(k) && k !== 'default');

          if (invalidKeys.length > 0) {
            this.addWarning(
              `${locale}: Invalid plural form keys in '${fullPath}': ${invalidKeys.join(', ')}`,
              { locale, key: fullPath, invalidKeys }
            );
          }

          // Check for missing 'other' (required fallback)
          if (!value.other) {
            this.addWarning(
              `${locale}: Missing 'other' plural form in '${fullPath}' (required fallback)`,
              { locale, key: fullPath }
            );
          }
        } else {
          // Recurse into nested objects
          this.checkPluralForms(locale, value, fullPath);
        }
      }
    }
  }

  /**
   * Check for security issues (XSS, injection)
   */
  checkSecurityIssues(locale, data, path = '') {
    for (const [key, value] of Object.entries(data)) {
      const fullPath = path ? `${path}.${key}` : key;

      if (typeof value === 'string') {
        // Check for script tags
        if (/<script/i.test(value)) {
          this.addError(
            `${locale}: Potential XSS - <script> tag in '${fullPath}'`,
            { locale, key: fullPath, severity: 'high' }
          );
        }

        // Check for event handlers
        if (/on\w+\s*=/i.test(value)) {
          this.addWarning(
            `${locale}: Potential XSS - event handler in '${fullPath}'`,
            { locale, key: fullPath, severity: 'medium' }
          );
        }

        // Check for javascript: protocol
        if (/javascript:/i.test(value)) {
          this.addError(
            `${locale}: Potential XSS - javascript: protocol in '${fullPath}'`,
            { locale, key: fullPath, severity: 'high' }
          );
        }

        // Check for unescaped mustache (triple braces)
        if (/\{\{\{[^}]+\}\}\}/.test(value)) {
          this.addInfo(
            `${locale}: Unescaped mustache in '${fullPath}' - ensure content is trusted`,
            { locale, key: fullPath }
          );
        }

      } else if (typeof value === 'object' && value !== null) {
        this.checkSecurityIssues(locale, value, fullPath);
      }
    }
  }

  /**
   * Check JSON formatting
   */
  checkFormatting(locale, content, file) {
    try {
      const data = JSON.parse(content);
      const formatted = JSON.stringify(data, null, 2);

      if (content.trim() !== formatted) {
        this.addInfo(`${locale}: Inconsistent formatting`, { locale, file });

        if (this.format || this.fix) {
          fs.writeFileSync(file, formatted + '\n', 'utf8');
          this.addInfo(`${locale}: Formatted file`, { locale, file });
        }
      }
    } catch (err) {
      // Already caught in main validation
    }
  }

  /**
   * Check for untranslated strings
   */
  checkUntranslated(locale, data, path = '') {
    for (const [key, value] of Object.entries(data)) {
      const fullPath = path ? `${path}.${key}` : key;

      if (typeof value === 'string') {
        // Check if value is same as key (common for untranslated strings)
        if (value === fullPath || value === key) {
          this.addWarning(
            `${locale}: Potentially untranslated - value equals key in '${fullPath}'`,
            { locale, key: fullPath }
          );
        }

      } else if (typeof value === 'object' && value !== null) {
        this.checkUntranslated(locale, value, fullPath);
      }
    }
  }

  /**
   * Validate translation coverage across locales
   */
  validateTranslationCoverage(locales) {
    const referenceData = locales[this.reference].data;
    const referenceKeys = this.getAllKeys(referenceData);

    for (const [locale, { data }] of Object.entries(locales)) {
      if (locale === this.reference) continue;

      const localeKeys = this.getAllKeys(data);

      // Find missing keys
      const missing = referenceKeys.filter(k => !localeKeys.includes(k));
      const extra = localeKeys.filter(k => !referenceKeys.includes(k));

      if (missing.length > 0) {
        this.addWarning(
          `${locale}: Missing ${missing.length} translation(s) from reference locale`,
          { locale, missingCount: missing.length, missing: missing.slice(0, 10) }
        );
      }

      if (extra.length > 0) {
        this.addInfo(
          `${locale}: Has ${extra.length} extra translation(s) not in reference`,
          { locale, extraCount: extra.length, extra: extra.slice(0, 10) }
        );
      }

      // Calculate coverage
      const coverage = referenceKeys.length > 0
        ? ((referenceKeys.length - missing.length) / referenceKeys.length * 100).toFixed(1)
        : 100;

      this.addInfo(
        `${locale}: Translation coverage: ${coverage}% (${referenceKeys.length - missing.length}/${referenceKeys.length})`,
        { locale, coverage: parseFloat(coverage), translated: referenceKeys.length - missing.length, total: referenceKeys.length }
      );
    }
  }

  /**
   * Get all keys from nested object
   */
  getAllKeys(obj, prefix = '') {
    let keys = [];

    for (const [key, value] of Object.entries(obj)) {
      const fullKey = prefix ? `${prefix}.${key}` : key;

      if (typeof value === 'object' && value !== null && !this.isPluralForm(value)) {
        keys = keys.concat(this.getAllKeys(value, fullKey));
      } else {
        keys.push(fullKey);
      }
    }

    return keys;
  }

  /**
   * Check if object is a plural form
   */
  isPluralForm(obj) {
    const keys = Object.keys(obj);
    const pluralKeys = ['zero', 'one', 'two', 'few', 'many', 'other'];
    return keys.some(k => pluralKeys.includes(k));
  }

  /**
   * Apply automatic fixes
   */
  applyFixes(locales) {
    this.addInfo('Applying automatic fixes...');

    for (const [locale, { file, data }] of Object.entries(locales)) {
      let modified = false;

      // Trim whitespace from values
      const trimmed = this.trimValues(data);

      if (JSON.stringify(data) !== JSON.stringify(trimmed)) {
        fs.writeFileSync(file, JSON.stringify(trimmed, null, 2) + '\n', 'utf8');
        modified = true;
      }

      if (modified) {
        this.addInfo(`${locale}: Applied fixes`, { locale, file });
      }
    }
  }

  /**
   * Trim whitespace from all string values
   */
  trimValues(obj) {
    if (typeof obj === 'string') {
      return obj.trim();
    }

    if (typeof obj === 'object' && obj !== null) {
      const result = Array.isArray(obj) ? [] : {};

      for (const [key, value] of Object.entries(obj)) {
        result[key] = this.trimValues(value);
      }

      return result;
    }

    return obj;
  }

  /**
   * Add error
   */
  addError(message, data = {}) {
    this.errors.push({ message, ...data });
  }

  /**
   * Add warning
   */
  addWarning(message, data = {}) {
    this.warnings.push({ message, ...data });
  }

  /**
   * Add info
   */
  addInfo(message, data = {}) {
    this.info.push({ message, ...data });
  }

  /**
   * Get results
   */
  getResults() {
    const hasErrors = this.errors.length > 0;
    const hasWarnings = this.warnings.length > 0;
    const exitCode = hasErrors ? 2 : (this.strict && hasWarnings ? 1 : 0);

    return {
      success: exitCode === 0,
      exitCode,
      errors: this.errors,
      warnings: this.warnings,
      info: this.info,
      summary: {
        errors: this.errors.length,
        warnings: this.warnings.length,
        info: this.info.length
      }
    };
  }

  /**
   * Print results to console
   */
  printResults(results) {
    if (this.jsonOutput) {
      console.log(JSON.stringify(results, null, 2));
      return;
    }

    console.log('\n=== i18n Locale Validation Results ===\n');

    // Errors
    if (results.errors.length > 0) {
      console.log('❌ ERRORS:');
      results.errors.forEach(err => {
        console.log(`  - ${err.message}`);
      });
      console.log('');
    }

    // Warnings
    if (results.warnings.length > 0) {
      console.log('⚠️  WARNINGS:');
      results.warnings.forEach(warn => {
        console.log(`  - ${warn.message}`);
      });
      console.log('');
    }

    // Info
    if (results.info.length > 0 && !this.jsonOutput) {
      console.log('ℹ️  INFO:');
      results.info.forEach(info => {
        console.log(`  - ${info.message}`);
      });
      console.log('');
    }

    // Summary
    console.log('=== Summary ===');
    console.log(`Errors: ${results.summary.errors}`);
    console.log(`Warnings: ${results.summary.warnings}`);
    console.log(`Info: ${results.summary.info}`);
    console.log('');

    if (results.success) {
      console.log('✅ Validation passed!\n');
    } else {
      console.log('❌ Validation failed!\n');
    }
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
      case '--fix':
        options.fix = true;
        break;
      case '--format':
        options.format = true;
        break;
      case '--strict':
        options.strict = true;
        break;
      case '--json':
        options.json = true;
        break;
      case '--help':
        console.log(`
i18n Locale Validator

Usage:
  node tools/locale-validator.js [options]

Options:
  --dir <path>        Directory containing locale files (default: ./locales)
  --reference <locale> Reference locale to compare against (default: en)
  --fix               Auto-fix issues where possible
  --format            Format JSON files
  --strict            Strict mode - exit with error on warnings
  --json              Output results as JSON
  --help              Show this help message

Examples:
  node tools/locale-validator.js
  node tools/locale-validator.js --dir ./locales --reference en
  node tools/locale-validator.js --fix --format
  node tools/locale-validator.js --strict --json
        `);
        process.exit(0);
    }
  }

  const validator = new LocaleValidator(options);

  validator.validate().then(results => {
    validator.printResults(results);
    process.exit(results.exitCode);
  });
}

module.exports = LocaleValidator;
