# Performance Benchmarks

This directory contains performance benchmarks for i18n to help optimize and monitor performance.

## Available Benchmarks

### 1. Translation Benchmarks (`translation-bench.js`)

Tests performance of core translation methods:

- Simple translation
- sprintf formatting
- Mustache formatting
- Plural translations
- MessageFormat
- Object notation
- Locale switching
- Catalog retrieval

**Run:**
```bash
node benchmarks/translation-bench.js
```

**Example Output:**
```
=== i18n Translation Performance Benchmarks ===

1. Simple Translation (__("Hello"))
  Simple translation:
    Total: 45.23ms
    Average: 0.000452ms per operation
    Throughput: 2,210,884 ops/sec

2. Translation with sprintf (__("Hello %s", "World"))
  sprintf formatting:
    Total: 123.45ms
    Average: 0.001235ms per operation
    Throughput: 809,717 ops/sec
...
```

### 2. Configuration Comparison (`comparison-bench.js`)

Compares performance impact of different configurations:

- `updateFiles` ON vs OFF
- `objectNotation` ON vs OFF
- `staticCatalog` vs file-based
- Number of locales (1 vs 3 vs 10)
- Mustache enabled vs disabled

**Run:**
```bash
node benchmarks/comparison-bench.js
```

**Example Output:**
```
=== i18n Configuration Comparison Benchmarks ===

Results:
────────────────────────────────────────────────────────────────────────────────
Configuration                              Ops/sec        Avg Time
────────────────────────────────────────────────────────────────────────────────
staticCatalog (preloaded)               2,345,678    0.000426ms
updateFiles: false                      1,987,543    0.000503ms
updateFiles: true                         234,567    0.004263ms
...

Fastest: staticCatalog (preloaded)
Slowest: updateFiles: true
Speedup: 10.0x
```

## Performance Optimization Tips

Based on benchmark results, here are recommended configurations for different scenarios:

### 1. Production (High Performance)

```javascript
const i18n = new I18n({
  staticCatalog: {
    en: require('./locales/en.json'),
    de: require('./locales/de.json')
  },
  defaultLocale: 'en',
  updateFiles: false,    // Disable file writes
  autoReload: false,     // Disable file watching
  syncFiles: false       // Disable sync
});
```

**Benefits:**
- 10x faster than file-based
- No disk I/O during runtime
- Minimal memory overhead
- Predictable performance

### 2. Development (Convenience)

```javascript
const i18n = new I18n({
  locales: ['en', 'de'],
  directory: './locales',
  updateFiles: true,     // Auto-add new keys
  autoReload: true,      // Hot-reload on changes
  objectNotation: true   // Nested keys
});
```

**Benefits:**
- Automatically adds new translations
- Hot-reloads during development
- Easy to manage hierarchical keys

### 3. Balanced (Production + Updates)

```javascript
const i18n = new I18n({
  locales: ['en', 'de'],
  directory: './locales',
  updateFiles: false,    // No writes in production
  autoReload: false,
  objectNotation: true,
  retryInDefaultLocale: true
});
```

**Benefits:**
- Good performance
- Flexibility for runtime locale changes
- Fallback to default locale

## Interpreting Results

### Throughput (ops/sec)

Higher is better. Indicates how many operations per second can be performed.

- **> 1,000,000 ops/sec**: Excellent
- **500,000 - 1,000,000 ops/sec**: Good
- **100,000 - 500,000 ops/sec**: Acceptable
- **< 100,000 ops/sec**: Needs optimization

### Average Time (ms)

Lower is better. Time taken per single operation.

- **< 0.001ms**: Excellent (< 1 microsecond)
- **0.001 - 0.01ms**: Good (1-10 microseconds)
- **0.01 - 0.1ms**: Acceptable (10-100 microseconds)
- **> 0.1ms**: Slow (> 100 microseconds)

### Memory Usage

Monitor memory usage to prevent memory leaks:

- **< 10 MB**: Excellent for single locale
- **10-50 MB**: Normal for multiple locales
- **> 50 MB**: Check for memory leaks

## Running Benchmarks in CI/CD

Add to your CI/CD pipeline to monitor performance regressions:

```yaml
# .github/workflows/benchmarks.yml
name: Performance Benchmarks

on:
  pull_request:
    branches: [ main ]

jobs:
  benchmark:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v3

      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'

      - name: Install dependencies
        run: npm install

      - name: Run benchmarks
        run: |
          node benchmarks/translation-bench.js > benchmark-results.txt
          node benchmarks/comparison-bench.js >> benchmark-results.txt

      - name: Upload results
        uses: actions/upload-artifact@v3
        with:
          name: benchmark-results
          path: benchmark-results.txt
```

## Custom Benchmarks

Create your own benchmarks:

```javascript
const { I18n } = require('i18n');

async function customBench() {
  const i18n = new I18n({ /* config */ });

  const iterations = 100000;
  const start = process.hrtime.bigint();

  for (let i = 0; i < iterations; i++) {
    // Your operation here
    i18n.__('test');
  }

  const end = process.hrtime.bigint();
  const duration = Number(end - start) / 1_000_000;

  console.log(`Duration: ${duration}ms`);
  console.log(`Throughput: ${(iterations / duration * 1000).toFixed(0)} ops/sec`);
}

customBench();
```

## Profiling

For detailed profiling, use Node.js built-in profiler:

```bash
# CPU profiling
node --prof benchmarks/translation-bench.js
node --prof-process isolate-*.log > profile.txt

# Heap profiling
node --inspect benchmarks/translation-bench.js
# Open chrome://inspect in Chrome
```

## Continuous Monitoring

Track performance over time:

```bash
# Store benchmark results with timestamp
node benchmarks/translation-bench.js > "results-$(date +%Y%m%d).txt"

# Compare with previous results
diff results-20250101.txt results-20250115.txt
```

## Performance Tips

### 1. Cache Translations

If using same translation repeatedly:

```javascript
// Slow
for (let i = 0; i < 1000; i++) {
  console.log(__('Welcome'));
}

// Fast
const welcome = __('Welcome');
for (let i = 0; i < 1000; i++) {
  console.log(welcome);
}
```

### 2. Use Static Catalog

Pre-load translations in production:

```javascript
const i18n = new I18n({
  staticCatalog: {
    en: require('./locales/en.json'),
    de: require('./locales/de.json')
  }
});
```

### 3. Disable Unnecessary Features

Turn off features you don't need:

```javascript
const i18n = new I18n({
  updateFiles: false,
  autoReload: false,
  syncFiles: false,
  objectNotation: false,  // If not using dot notation
  mustacheConfig: { disable: true }  // If only using sprintf
});
```

### 4. Minimize Locale Switching

Locale switching has overhead. Set once per request:

```javascript
// Slow
req.setLocale('en');
__('Welcome');
req.setLocale('de');
__('Welcome');

// Fast
req.setLocale('en');
const enWelcome = __('Welcome');
// ... use enWelcome multiple times
```

## Contributing

When adding features or fixing bugs:

1. Run benchmarks before and after changes
2. Document performance impact in PR
3. Optimize if performance degrades > 10%

## License

MIT - Same as i18n-node
