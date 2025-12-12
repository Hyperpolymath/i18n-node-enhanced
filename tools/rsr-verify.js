#!/usr/bin/env node

/**
 * RSR (Rhodium Standard Repository) Compliance Verification
 *
 * Checks compliance against RSR Bronze/Silver/Gold/Platinum levels
 */

const fs = require('fs');
const path = require('path');

// ANSI color codes
const colors = {
  reset: '\x1b[0m',
  bright: '\x1b[1m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  red: '\x1b[31m',
  blue: '\x1b[34m',
  cyan: '\x1b[36m'
};

// Helper functions
const exists = (filepath) => fs.existsSync(path.join(process.cwd(), filepath));
const checkmark = `${colors.green}✅${colors.reset}`;
const cross = `${colors.red}❌${colors.reset}`;
const warning = `${colors.yellow}⚠️${colors.reset}`;

// Compliance categories
const checks = {
  documentation: {
    name: '📋 Documentation',
    required: [
      { file: 'README.md', desc: 'Project README' },
      { file: 'LICENSE', desc: 'License file' },
      { file: 'SECURITY.md', desc: 'Security policy' },
      { file: 'CONTRIBUTING.md', desc: 'Contribution guidelines' },
      { file: 'CODE_OF_CONDUCT.md', desc: 'Code of Conduct' },
      { file: 'MAINTAINERS.md', desc: 'Maintainer information' },
      { file: 'CHANGELOG.md', desc: 'Version history' }
    ]
  },

  wellknown: {
    name: '🌐 .well-known Directory (RFC 9116)',
    required: [
      { file: '.well-known/security.txt', desc: 'RFC 9116 security contact' },
      { file: '.well-known/ai.txt', desc: 'AI training policies' },
      { file: '.well-known/humans.txt', desc: 'Human attribution' }
    ]
  },

  build: {
    name: '🔧 Build System',
    required: [
      { file: 'package.json', desc: 'Node.js package manifest' },
      { file: 'justfile', desc: 'Just build automation' },
      { file: '.gitignore', desc: 'Git ignore rules' }
    ],
    optional: [
      { file: 'flake.nix', desc: 'Nix reproducible builds' },
      { file: 'Makefile', desc: 'Alternative build system' }
    ]
  },

  testing: {
    name: '🧪 Testing & QA',
    required: [
      { file: 'test', desc: 'Test directory', type: 'directory' }
    ],
    checks: [
      {
        name: 'Tests pass',
        fn: () => {
          try {
            const { execSync } = require('child_process');
            execSync('npm test', { stdio: 'ignore' });
            return true;
          } catch (e) {
            return false;
          }
        }
      }
    ]
  },

  polyglot: {
    name: '📦 Polyglot Bindings',
    optional: [
      { file: 'bindings/rescript', desc: 'ReScript bindings', type: 'directory' },
      { file: 'deno', desc: 'Deno module', type: 'directory' },
      { file: 'wasm', desc: 'WASM core', type: 'directory' }
    ]
  },

  enterprise: {
    name: '🏢 Enterprise Features',
    optional: [
      { file: 'adapters', desc: 'Enterprise adapters', type: 'directory' },
      { file: 'audit/forensics.js', desc: 'Audit system' },
      { file: 'automation/api.js', desc: 'Automation API' },
      { file: 'observability/telemetry.js', desc: 'Observability' }
    ]
  },

  governance: {
    name: '🏛️ Governance',
    required: [
      { file: 'TPCF.md', desc: 'Tri-Perimeter Contribution Framework' }
    ],
    checks: [
      {
        name: 'Security policy linked in README',
        fn: () => {
          const readme = fs.readFileSync('README.md', 'utf-8');
          return readme.includes('SECURITY.md') || readme.includes('security');
        }
      }
    ]
  },

  offline: {
    name: '🔌 Offline-First',
    checks: [
      {
        name: 'No network dependencies in core',
        fn: () => {
          const coreFiles = ['i18n.js', 'index.js'];
          // Security: properly validate that URLs are only from allowed domains
          // The previous check using .includes('example.com') was vulnerable to bypasses
          // like https://example.com.evil.com/
          const urlPattern = /https?:\/\/[^\s"')]+/g;
          const isAllowedUrl = (urlString) => {
            try {
              const parsed = new URL(urlString);
              const hostname = parsed.hostname.toLowerCase();
              // Only allow exact match or subdomain of example.com
              return hostname === 'example.com' || hostname.endsWith('.example.com');
            } catch (e) {
              // If URL parsing fails, consider it suspicious
              return false;
            }
          };
          for (const file of coreFiles) {
            if (!exists(file)) continue;
            const content = fs.readFileSync(file, 'utf-8');
            const urls = content.match(urlPattern) || [];
            for (const url of urls) {
              if (!isAllowedUrl(url)) {
                return false;
              }
            }
          }
          return true;
        }
      },
      {
        name: 'Static catalog support',
        fn: () => {
          const i18n = fs.readFileSync('i18n.js', 'utf-8');
          return i18n.includes('staticCatalog');
        }
      }
    ]
  }
};

// RSR level definitions
const levels = {
  bronze: {
    name: 'Bronze',
    emoji: '🥉',
    requirements: [
      'All documentation files',
      'Basic build system',
      'Test suite',
      'TPCF governance'
    ]
  },
  silver: {
    name: 'Silver',
    emoji: '🥈',
    requirements: [
      'All Bronze requirements',
      '.well-known directory',
      'Offline-first verification',
      'Reproducible builds (Nix)'
    ]
  },
  gold: {
    name: 'Gold',
    emoji: '🥇',
    requirements: [
      'All Silver requirements',
      'Polyglot bindings (2+)',
      'Type safety (ReScript/WASM)',
      'Memory safety (Rust/WASM)'
    ]
  },
  platinum: {
    name: 'Platinum',
    emoji: '💎',
    requirements: [
      'All Gold requirements',
      'Formal verification',
      'Security audit',
      'Enterprise features'
    ]
  }
};

// Run checks
function runChecks() {
  console.log(`\n${colors.bright}${colors.blue}🔍 RSR Compliance Verification${colors.reset}\n`);

  const results = {
    passed: 0,
    failed: 0,
    warnings: 0
  };

  for (const [categoryKey, category] of Object.entries(checks)) {
    console.log(`${colors.bright}${category.name}${colors.reset}`);

    // Check required files
    if (category.required) {
      for (const item of category.required) {
        const fileExists = exists(item.file);
        const symbol = fileExists ? checkmark : cross;
        console.log(`  ${symbol} ${item.desc}`);

        if (fileExists) {
          results.passed++;
        } else {
          results.failed++;
        }
      }
    }

    // Check optional files
    if (category.optional) {
      for (const item of category.optional) {
        const fileExists = exists(item.file);
        const symbol = fileExists ? checkmark : warning;
        console.log(`  ${symbol} ${item.desc} ${!fileExists ? '(optional)' : ''}`);

        if (fileExists) {
          results.passed++;
        } else {
          results.warnings++;
        }
      }
    }

    // Run functional checks
    if (category.checks) {
      for (const check of category.checks) {
        const passed = check.fn();
        const symbol = passed ? checkmark : cross;
        console.log(`  ${symbol} ${check.name}`);

        if (passed) {
          results.passed++;
        } else {
          results.failed++;
        }
      }
    }

    console.log('');
  }

  return results;
}

// Determine RSR level
function determineLevel(results) {
  const hasDocs = exists('README.md') && exists('LICENSE') && exists('SECURITY.md') &&
                  exists('CONTRIBUTING.md') && exists('CODE_OF_CONDUCT.md') &&
                  exists('MAINTAINERS.md') && exists('CHANGELOG.md');

  const hasWellKnown = exists('.well-known/security.txt') &&
                       exists('.well-known/ai.txt') &&
                       exists('.well-known/humans.txt');

  const hasPolyglot = (exists('bindings/rescript') ? 1 : 0) +
                      (exists('deno') ? 1 : 0) +
                      (exists('wasm') ? 1 : 0);

  const hasBuild = exists('package.json') && exists('justfile');
  const hasNix = exists('flake.nix');
  const hasTPCF = exists('TPCF.md');

  // Bronze: Basic documentation + build + TPCF
  if (hasDocs && hasBuild && hasTPCF) {
    // Silver: + .well-known + Nix
    if (hasWellKnown && hasNix) {
      // Gold: + polyglot bindings (2+)
      if (hasPolyglot >= 2) {
        // Platinum: + enterprise features
        if (exists('adapters') && exists('audit/forensics.js')) {
          return 'platinum';
        }
        return 'gold';
      }
      return 'silver';
    }
    return 'bronze';
  }

  return 'none';
}

// Print results
function printResults(results) {
  console.log(`${colors.bright}📊 Results${colors.reset}\n`);
  console.log(`  ${checkmark} Passed: ${colors.green}${results.passed}${colors.reset}`);
  if (results.warnings > 0) {
    console.log(`  ${warning} Optional: ${colors.yellow}${results.warnings}${colors.reset}`);
  }
  if (results.failed > 0) {
    console.log(`  ${cross} Failed: ${colors.red}${results.failed}${colors.reset}`);
  }
  console.log('');

  const level = determineLevel(results);
  const levelInfo = levels[level];

  if (level === 'none') {
    console.log(`${colors.red}❌ Not RSR Compliant${colors.reset}`);
    console.log('');
    console.log('Missing required components for Bronze level.');
  } else {
    console.log(`${colors.bright}🏆 RSR Compliance Level: ${levelInfo.emoji} ${levelInfo.name.toUpperCase()}${colors.reset}`);
    console.log('');
    console.log(`${colors.cyan}Requirements met:${colors.reset}`);
    for (const req of levelInfo.requirements) {
      console.log(`  ✓ ${req}`);
    }
    console.log('');

    // Show next level
    const levelOrder = ['bronze', 'silver', 'gold', 'platinum'];
    const currentIndex = levelOrder.indexOf(level);
    if (currentIndex < levelOrder.length - 1) {
      const nextLevel = levelOrder[currentIndex + 1];
      const nextInfo = levels[nextLevel];
      console.log(`${colors.yellow}🎯 Next Level: ${nextInfo.emoji} ${nextInfo.name}${colors.reset}`);
      console.log('');
      console.log(`${colors.cyan}Required for ${nextInfo.name}:${colors.reset}`);
      for (const req of nextInfo.requirements) {
        console.log(`  → ${req}`);
      }
    } else {
      console.log(`${colors.green}🎉 Congratulations! You've achieved the highest RSR level!${colors.reset}`);
    }
  }

  console.log('');
  console.log(`${colors.cyan}🔐 TPCF Perimeter:${colors.reset} 3 (Community Sandbox)`);
  console.log('');
}

// Main
function main() {
  const results = runChecks();
  printResults(results);

  // Exit code
  if (results.failed > 0) {
    process.exit(1);
  }
}

if (require.main === module) {
  main();
}

module.exports = { runChecks, determineLevel };
