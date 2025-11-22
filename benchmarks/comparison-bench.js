/**
 * i18n Configuration Comparison Benchmarks
 * Compares performance of different configuration options
 *
 * Usage: node benchmarks/comparison-bench.js
 */

const { I18n } = require('../index');
const path = require('path');

class ComparisonBench {
  constructor() {
    this.iterations = 10000;
  }

  async benchmark(name, setupFn, testFn) {
    const instance = setupFn();

    // Warm-up
    for (let i = 0; i < 100; i++) {
      testFn(instance);
    }

    // Benchmark
    const start = process.hrtime.bigint();

    for (let i = 0; i < this.iterations; i++) {
      testFn(instance);
    }

    const end = process.hrtime.bigint();
    const duration = Number(end - start) / 1_000_000;

    return {
      name,
      totalTime: duration.toFixed(2),
      avgTime: (duration / this.iterations).toFixed(6),
      opsPerSec: ((this.iterations / duration) * 1000).toFixed(0)
    };
  }

  printResults(results) {
    console.log('\nResults:');
    console.log('─'.repeat(80));
    console.log('Configuration'.padEnd(40), 'Ops/sec'.padStart(15), 'Avg Time'.padStart(15));
    console.log('─'.repeat(80));

    results.forEach(r => {
      console.log(
        r.name.padEnd(40),
        r.opsPerSec.padStart(15),
        (r.avgTime + 'ms').padStart(15)
      );
    });

    console.log('─'.repeat(80));

    // Find fastest and slowest
    const sorted = [...results].sort((a, b) => parseFloat(b.opsPerSec) - parseFloat(a.opsPerSec));
    const fastest = sorted[0];
    const slowest = sorted[sorted.length - 1];

    console.log(`\nFastest: ${fastest.name}`);
    console.log(`Slowest: ${slowest.name}`);

    const speedup = parseFloat(fastest.opsPerSec) / parseFloat(slowest.opsPerSec);
    console.log(`Speedup: ${speedup.toFixed(2)}x\n`);
  }
}

async function main() {
  console.log('=== i18n Configuration Comparison Benchmarks ===\n');

  const bench = new ComparisonBench();
  const results = [];

  // Test 1: updateFiles ON vs OFF
  console.log('1. Comparing updateFiles configuration...');

  results.push(await bench.benchmark(
    'updateFiles: true',
    () => new I18n({
      locales: ['en'],
      directory: path.join(__dirname, '../locales'),
      updateFiles: true,
      autoReload: false
    }),
    (i18n) => i18n.__('Hello')
  ));

  results.push(await bench.benchmark(
    'updateFiles: false',
    () => new I18n({
      locales: ['en'],
      directory: path.join(__dirname, '../locales'),
      updateFiles: false,
      autoReload: false
    }),
    (i18n) => i18n.__('Hello')
  ));

  // Test 2: Object notation ON vs OFF
  console.log('2. Comparing objectNotation configuration...');

  results.push(await bench.benchmark(
    'objectNotation: true',
    () => new I18n({
      locales: ['en'],
      directory: path.join(__dirname, '../locales'),
      objectNotation: true,
      updateFiles: false
    }),
    (i18n) => i18n.__('greeting.formal')
  ));

  results.push(await bench.benchmark(
    'objectNotation: false',
    () => new I18n({
      locales: ['en'],
      directory: path.join(__dirname, '../locales'),
      objectNotation: false,
      updateFiles: false
    }),
    (i18n) => i18n.__('greeting.formal')
  ));

  // Test 3: Static catalog vs file-based
  console.log('3. Comparing staticCatalog vs file-based...');

  results.push(await bench.benchmark(
    'staticCatalog (preloaded)',
    () => new I18n({
      staticCatalog: {
        en: { Hello: 'Hello', 'Hello %s': 'Hello %s' }
      },
      defaultLocale: 'en'
    }),
    (i18n) => i18n.__('Hello')
  ));

  results.push(await bench.benchmark(
    'File-based (disk I/O)',
    () => new I18n({
      locales: ['en'],
      directory: path.join(__dirname, '../locales'),
      updateFiles: false
    }),
    (i18n) => i18n.__('Hello')
  ));

  // Test 4: Single locale vs multiple locales
  console.log('4. Comparing number of locales...');

  results.push(await bench.benchmark(
    '1 locale',
    () => new I18n({
      locales: ['en'],
      directory: path.join(__dirname, '../locales'),
      updateFiles: false
    }),
    (i18n) => i18n.__('Hello')
  ));

  results.push(await bench.benchmark(
    '3 locales',
    () => new I18n({
      locales: ['en', 'de', 'fr'],
      directory: path.join(__dirname, '../locales'),
      updateFiles: false
    }),
    (i18n) => i18n.__('Hello')
  ));

  results.push(await bench.benchmark(
    '10 locales',
    () => new I18n({
      locales: ['en', 'de', 'fr', 'es', 'it', 'pt', 'ru', 'ja', 'zh', 'ar'],
      directory: path.join(__dirname, '../locales'),
      updateFiles: false
    }),
    (i18n) => i18n.__('Hello')
  ));

  // Test 5: Mustache enabled vs disabled
  console.log('5. Comparing mustache configuration...');

  results.push(await bench.benchmark(
    'Mustache enabled',
    () => new I18n({
      locales: ['en'],
      directory: path.join(__dirname, '../locales'),
      updateFiles: false,
      mustacheConfig: { disable: false }
    }),
    (i18n) => i18n.__('Hello {{name}}', { name: 'World' })
  ));

  results.push(await bench.benchmark(
    'Mustache disabled',
    () => new I18n({
      locales: ['en'],
      directory: path.join(__dirname, '../locales'),
      updateFiles: false,
      mustacheConfig: { disable: true }
    }),
    (i18n) => i18n.__('Hello {{name}}', { name: 'World' })
  ));

  bench.printResults(results);

  // Memory comparison
  console.log('\n=== Memory Usage Comparison ===\n');

  const memTests = [
    {
      name: 'Single locale',
      config: { locales: ['en'], directory: path.join(__dirname, '../locales'), updateFiles: false }
    },
    {
      name: '10 locales',
      config: { locales: ['en', 'de', 'fr', 'es', 'it', 'pt', 'ru', 'ja', 'zh', 'ar'], directory: path.join(__dirname, '../locales'), updateFiles: false }
    },
    {
      name: 'Static catalog',
      config: { staticCatalog: { en: { test: 'test' } }, defaultLocale: 'en' }
    }
  ];

  for (const test of memTests) {
    const before = process.memoryUsage().heapUsed;
    const instance = new I18n(test.config);

    // Force some operations
    for (let i = 0; i < 100; i++) {
      instance.__('Hello');
    }

    const after = process.memoryUsage().heapUsed;
    const diff = (after - before) / 1024;

    console.log(`${test.name}:`.padEnd(20), `${diff.toFixed(2)} KB`);
  }

  console.log('');
}

main().catch(console.error);
