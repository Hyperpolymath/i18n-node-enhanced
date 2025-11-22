/**
 * i18n Translation Performance Benchmarks
 * Tests performance of core translation methods
 *
 * Usage: node benchmarks/translation-bench.js
 */

const { I18n } = require('../index');
const path = require('path');

class Benchmark {
  constructor(name) {
    this.name = name;
    this.iterations = 100000;
    this.results = [];
  }

  /**
   * Run a benchmark function
   */
  async run(fn) {
    // Warm-up
    for (let i = 0; i < 1000; i++) {
      fn();
    }

    // Actual benchmark
    const start = process.hrtime.bigint();

    for (let i = 0; i < this.iterations; i++) {
      fn();
    }

    const end = process.hrtime.bigint();
    const duration = Number(end - start) / 1_000_000; // Convert to ms

    const opsPerSec = (this.iterations / duration) * 1000;

    return {
      totalTime: duration.toFixed(2),
      avgTime: (duration / this.iterations).toFixed(6),
      opsPerSec: opsPerSec.toFixed(0)
    };
  }

  /**
   * Format results
   */
  formatResult(name, result) {
    console.log(`  ${name}:`);
    console.log(`    Total: ${result.totalTime}ms`);
    console.log(`    Average: ${result.avgTime}ms per operation`);
    console.log(`    Throughput: ${result.opsPerSec} ops/sec`);
    console.log('');
  }
}

async function main() {
  console.log('=== i18n Translation Performance Benchmarks ===\n');

  // Setup i18n instance
  const i18n = new I18n({
    locales: ['en', 'de', 'fr'],
    defaultLocale: 'en',
    directory: path.join(__dirname, '../locales'),
    updateFiles: false,
    autoReload: false,
    syncFiles: false,
    objectNotation: true
  });

  const bench = new Benchmark('i18n');

  // Benchmark 1: Simple translation
  console.log('1. Simple Translation (__("Hello"))');
  let result = await bench.run(() => {
    i18n.__('Hello');
  });
  bench.formatResult('Simple translation', result);

  // Benchmark 2: Translation with sprintf
  console.log('2. Translation with sprintf (__("Hello %s", "World"))');
  result = await bench.run(() => {
    i18n.__('Hello %s', 'World');
  });
  bench.formatResult('sprintf formatting', result);

  // Benchmark 3: Translation with mustache
  console.log('3. Translation with mustache (__("Hello {{name}}", {name: "World"}))');
  result = await bench.run(() => {
    i18n.__('Hello {{name}}', { name: 'World' });
  });
  bench.formatResult('Mustache formatting', result);

  // Benchmark 4: Plural translation
  console.log('4. Plural Translation (__n("%s cat", "%s cats", 3))');
  result = await bench.run(() => {
    i18n.__n('%s cat', '%s cats', 3);
  });
  bench.formatResult('Plural translation', result);

  // Benchmark 5: MessageFormat
  console.log('5. MessageFormat (__mf("{N, plural, one{# cat} other{# cats}}", {N: 3}))');
  result = await bench.run(() => {
    i18n.__mf('{N, plural, one{# cat} other{# cats}}', { N: 3 });
  });
  bench.formatResult('MessageFormat', result);

  // Benchmark 6: Object notation
  console.log('6. Object Notation (__("greeting.formal"))');
  result = await bench.run(() => {
    i18n.__('greeting.formal');
  });
  bench.formatResult('Object notation', result);

  // Benchmark 7: Locale switching
  console.log('7. Locale Switching');
  result = await bench.run(() => {
    i18n.setLocale('de');
    i18n.setLocale('en');
  });
  bench.formatResult('Locale switching', result);

  // Benchmark 8: Get catalog
  console.log('8. Get Catalog');
  result = await bench.run(() => {
    i18n.getCatalog('en');
  });
  bench.formatResult('Get catalog', result);

  // Memory usage
  const memUsage = process.memoryUsage();
  console.log('=== Memory Usage ===');
  console.log(`  RSS: ${(memUsage.rss / 1024 / 1024).toFixed(2)} MB`);
  console.log(`  Heap Used: ${(memUsage.heapUsed / 1024 / 1024).toFixed(2)} MB`);
  console.log(`  Heap Total: ${(memUsage.heapTotal / 1024 / 1024).toFixed(2)} MB`);
  console.log('');
}

main().catch(console.error);
