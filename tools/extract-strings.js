#!/usr/bin/env node

/**
 * String Extraction Utility
 * Extracts translatable strings from source code
 *
 * Usage:
 *   node tools/extract-strings.js [options]
 *
 * Options:
 *   --src <path>         Source directory to scan (default: ./src)
 *   --output <file>      Output file for extracted strings (default: ./extracted-strings.json)
 *   --patterns <...>     File patterns to match (default: **/*.js)
 *   --functions <...>    Function names to extract (default: __,__n,__mf)
 *   --format <type>      Output format: json|po|csv (default: json)
 */

const fs = require('fs');
const path = require('path');
const glob = require('glob');

class StringExtractor {
  constructor(options = {}) {
    this.src = options.src || './src';
    this.output = options.output || './extracted-strings.json';
    this.patterns = options.patterns || ['**/*.js', '**/*.jsx', '**/*.ts', '**/*.tsx'];
    this.functions = options.functions || ['__', '__n', '__mf'];
    this.format = options.format || 'json';

    this.strings = new Map();
  }

  async extract() {
    console.log('=== String Extraction ===\n');
    console.log(`Source: ${this.src}`);
    console.log(`Patterns: ${this.patterns.join(', ')}`);
    console.log(`Functions: ${this.functions.join(', ')}\n`);

    // Find all matching files
    const files = [];

    for (const pattern of this.patterns) {
      const matches = glob.sync(path.join(this.src, pattern), {
        nodir: true
      });
      files.push(...matches);
    }

    console.log(`Found ${files.length} file(s) to scan\n`);

    // Extract strings from each file
    for (const file of files) {
      this.extractFromFile(file);
    }

    console.log(`Extracted ${this.strings.size} unique string(s)\n`);

    // Write output
    this.writeOutput();

    console.log(`✅ Extraction complete. Output written to: ${this.output}\n`);
  }

  extractFromFile(filePath) {
    const content = fs.readFileSync(filePath, 'utf8');

    for (const funcName of this.functions) {
      const regex = new RegExp(`${funcName}\\s*\\(\\s*['"\`]([^'"\`]+)['"\`]`, 'g');
      let match;

      while ((match = regex.exec(content)) !== null) {
        const str = match[1];

        if (this.strings.has(str)) {
          this.strings.get(str).files.push(filePath);
        } else {
          this.strings.set(str, {
            string: str,
            function: funcName,
            files: [filePath]
          });
        }
      }
    }
  }

  writeOutput() {
    const data = Array.from(this.strings.values());

    switch (this.format) {
      case 'json':
        this.writeJSON(data);
        break;
      case 'po':
        this.writePO(data);
        break;
      case 'csv':
        this.writeCSV(data);
        break;
      default:
        throw new Error(`Unknown format: ${this.format}`);
    }
  }

  writeJSON(data) {
    const output = {
      extractedAt: new Date().toISOString(),
      totalStrings: data.length,
      strings: data
    };

    fs.writeFileSync(this.output, JSON.stringify(output, null, 2), 'utf8');
  }

  writePO(data) {
    let po = `# Extracted strings\n`;
    po += `# Generated: ${new Date().toISOString()}\n\n`;

    for (const item of data) {
      po += `#: ${item.files.join(' ')}\n`;
      po += `msgid "${item.string}"\n`;
      po += `msgstr ""\n\n`;
    }

    fs.writeFileSync(this.output, po, 'utf8');
  }

  writeCSV(data) {
    let csv = 'String,Function,Files\n';

    for (const item of data) {
      csv += `"${item.string}","${item.function}","${item.files.join(';')}"\n`;
    }

    fs.writeFileSync(this.output, csv, 'utf8');
  }
}

// CLI
if (require.main === module) {
  const args = process.argv.slice(2);
  const options = {};

  for (let i = 0; i < args.length; i++) {
    switch (args[i]) {
      case '--src':
        options.src = args[++i];
        break;
      case '--output':
        options.output = args[++i];
        break;
      case '--patterns':
        options.patterns = args[++i].split(',');
        break;
      case '--functions':
        options.functions = args[++i].split(',');
        break;
      case '--format':
        options.format = args[++i];
        break;
      case '--help':
        console.log(`
String Extraction Utility

Usage:
  node tools/extract-strings.js [options]

Options:
  --src <path>         Source directory to scan (default: ./src)
  --output <file>      Output file (default: ./extracted-strings.json)
  --patterns <...>     Comma-separated file patterns (default: **/*.js)
  --functions <...>    Comma-separated function names (default: __,__n,__mf)
  --format <type>      Output format: json|po|csv (default: json)
  --help               Show this help message

Examples:
  # Extract from default src directory
  node tools/extract-strings.js

  # Extract from custom directory
  node tools/extract-strings.js --src ./app

  # Extract to PO format
  node tools/extract-strings.js --format po --output messages.po

  # Custom functions
  node tools/extract-strings.js --functions t,translate,i18n.__
        `);
        process.exit(0);
    }
  }

  const extractor = new StringExtractor(options);
  extractor.extract().catch(console.error);
}

module.exports = StringExtractor;
