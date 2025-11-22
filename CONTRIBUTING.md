# Contributing to i18n-node

First off, thank you for considering contributing to i18n! It's people like you that make i18n such a great tool. 🎉

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [How Can I Contribute?](#how-can-i-contribute)
- [Development Setup](#development-setup)
- [Development Workflow](#development-workflow)
- [Coding Standards](#coding-standards)
- [Testing Guidelines](#testing-guidelines)
- [Documentation](#documentation)
- [Submitting Changes](#submitting-changes)
- [Release Process](#release-process)

## Code of Conduct

This project and everyone participating in it is governed by our Code of Conduct. By participating, you are expected to uphold this code. Please report unacceptable behavior to the maintainers.

### Our Standards

- Be respectful and inclusive
- Welcome newcomers and help them get started
- Focus on what is best for the community
- Show empathy towards other community members
- Accept constructive criticism gracefully

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check existing issues to avoid duplicates. When creating a bug report, include as many details as possible using our [bug report template](.github/ISSUE_TEMPLATE/bug_report.yml).

**Good bug reports include:**

- Clear, descriptive title
- Exact steps to reproduce
- Expected vs actual behavior
- Code samples
- Your environment (OS, Node.js version, i18n version)
- Error messages and stack traces

### Suggesting Features

Feature requests are welcome! Please use our [feature request template](.github/ISSUE_TEMPLATE/feature_request.yml) and provide:

- Clear use case and problem statement
- Proposed API design
- Example code showing how it would be used
- Why existing features can't solve your problem

### Improving Documentation

Documentation improvements are always appreciated:

- Fix typos, grammar, or unclear explanations
- Add missing examples
- Improve API documentation
- Translate documentation
- Add tutorials or guides

Use the [documentation issue template](.github/ISSUE_TEMPLATE/documentation.yml).

### Security Vulnerabilities

**Do NOT report security vulnerabilities publicly!**

Please use GitHub Security Advisory or contact maintainers privately. See [SECURITY.md](SECURITY.md) for details.

## Development Setup

### Prerequisites

- Node.js >= 10 (we recommend using [nvm](https://github.com/nvm-sh/nvm))
- npm >= 6
- Git

### Initial Setup

1. **Fork the repository** on GitHub

2. **Clone your fork:**

   ```bash
   git clone https://github.com/YOUR-USERNAME/i18n-node.git
   cd i18n-node
   ```

3. **Add upstream remote:**

   ```bash
   git remote add upstream https://github.com/mashpie/i18n-node.git
   ```

4. **Install dependencies:**

   ```bash
   npm install
   ```

5. **Verify setup:**

   ```bash
   npm test
   npm run lint
   ```

### Project Structure

```
i18n-node/
├── i18n.js                 # Main implementation
├── index.js                # Module entry point
├── index.d.ts              # TypeScript definitions
├── locales/                # Default locale files
├── examples/               # Usage examples
│   ├── express4-cookie/
│   ├── koa/
│   ├── fastify/
│   ├── nextjs/
│   └── typescript/
├── test/                   # Test suite
├── tools/                  # Development tools
│   ├── locale-validator.js
│   └── missing-translations.js
└── .github/                # GitHub configuration
```

## Development Workflow

### Creating a Branch

Create a branch for your work:

```bash
git checkout -b feature/your-feature-name
# or
git checkout -b fix/your-bug-fix
```

**Branch naming conventions:**

- `feature/description` - New features
- `fix/description` - Bug fixes
- `docs/description` - Documentation changes
- `refactor/description` - Code refactoring
- `test/description` - Test improvements
- `chore/description` - Build/tooling changes

### Making Changes

1. **Make your changes** in logical commits
2. **Test your changes** thoroughly
3. **Update documentation** if needed
4. **Add/update tests** to cover your changes

### Running Tests

```bash
# Run all tests
npm test

# Run tests with coverage
npm run test-ci

# Generate coverage report
npm run coverage

# Run specific test file
npx mocha test/i18n.configure.js

# Run with debugging
DEBUG=i18n:* npm test
```

### Linting

```bash
# Check linting
npx eslint i18n.js test/

# Auto-fix linting issues
npx eslint --fix i18n.js test/

# Run in watch mode during development
npx eslint --fix --watch i18n.js
```

### Validation

Before committing, validate locale files:

```bash
# Validate locales
node tools/locale-validator.js

# Check for missing translations
node tools/missing-translations.js

# Auto-fix and format
node tools/locale-validator.js --fix --format
```

## Coding Standards

### JavaScript Style

We use [ESLint](https://eslint.org/) with [Standard](https://standardjs.com/) + [Prettier](https://prettier.io/) configuration.

**Key points:**

- Use `const` and `let`, not `var`
- Use semicolons
- 2 spaces for indentation
- Single quotes for strings
- Trailing commas in multiline objects/arrays
- Max line length: 120 characters

**Example:**

```javascript
const exampleFunction = (param1, param2) => {
  if (param1 === null) {
    throw new Error('param1 is required');
  }

  return {
    result: param1 + param2,
    timestamp: Date.now()
  };
};
```

### Code Organization

- **Keep functions small and focused** - Each function should do one thing well
- **Avoid deep nesting** - Refactor complex nested code
- **Use descriptive names** - Variables and functions should be self-documenting
- **Add comments for complex logic** - Explain "why", not "what"
- **Handle errors appropriately** - Don't swallow errors silently

### Backward Compatibility

- **Maintain backward compatibility** in minor/patch versions
- **Mark deprecated features** properly:

  ```javascript
  // @deprecated since version 0.15.0, use newMethod() instead
  function oldMethod() {
    logWarnFn('oldMethod() is deprecated, use newMethod()');
    return newMethod();
  }
  ```

- **Breaking changes** require major version bump and migration guide

## Testing Guidelines

### Test Structure

We use [Mocha](https://mochajs.org/) and [Should.js](https://shouldjs.github.io/).

**Test file naming:**

- `i18n.feature.js` - Test for specific feature
- Use descriptive test names

**Example:**

```javascript
const should = require('should');
const { I18n } = require('../i18n');

describe('Feature Name', () => {
  let i18n;

  beforeEach(() => {
    i18n = new I18n({
      locales: ['en', 'de'],
      directory: './test/locales'
    });
  });

  afterEach(() => {
    // Cleanup
  });

  it('should do something specific', () => {
    const result = i18n.__('test');
    should.exist(result);
    result.should.equal('expected value');
  });

  it('should handle edge case', () => {
    should(() => {
      i18n.__invalidOperation();
    }).throw();
  });
});
```

### Coverage Requirements

- **Minimum coverage:** 90% for new code
- **Test all code paths:** Including error conditions
- **Test edge cases:** Null, undefined, empty strings, etc.

### Test Categories

1. **Unit Tests** - Test individual functions
2. **Integration Tests** - Test interactions between components
3. **Example Tests** - Ensure examples work correctly

## Documentation

### Code Documentation

Use JSDoc comments for functions and classes:

```javascript
/**
 * Translates a phrase
 * @param {string|Object} phrase - The phrase to translate or options object
 * @param {...*} args - sprintf-style or mustache replacements
 * @returns {string} Translated string
 * @example
 * __('Hello') // => 'Hello'
 * __('Hello %s', 'World') // => 'Hello World'
 * __({ phrase: 'Hello', locale: 'de' }) // => 'Hallo'
 */
function translate(phrase, ...args) {
  // Implementation
}
```

### README Updates

Update README.md when adding:

- New features
- New configuration options
- Breaking changes
- API changes

### Changelog

Update CHANGELOG.md following [Keep a Changelog](https://keepachangelog.com/) format:

```markdown
## [Unreleased]

### Added
- New feature description (#PR-number)

### Changed
- Updated behavior description (#PR-number)

### Deprecated
- Feature marked for removal (#PR-number)

### Removed
- Removed feature description (#PR-number)

### Fixed
- Bug fix description (#PR-number)

### Security
- Security improvement description (#PR-number)
```

## Submitting Changes

### Before Submitting

**Checklist:**

- [ ] Tests pass (`npm test`)
- [ ] Linting passes (`npm run lint`)
- [ ] Documentation updated
- [ ] CHANGELOG.md updated (if applicable)
- [ ] Locale files validated
- [ ] No security vulnerabilities introduced
- [ ] Commits are logical and well-described

### Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

**Types:**

- `feat:` - New feature
- `fix:` - Bug fix
- `docs:` - Documentation only
- `style:` - Code style (formatting, whitespace)
- `refactor:` - Code refactoring
- `test:` - Adding/updating tests
- `chore:` - Maintenance tasks

**Examples:**

```
feat: add async API for translations

Implements async versions of translation methods to support
non-blocking file I/O in high-traffic applications.

Closes #123
```

```
fix: prevent XSS in mustache templates

Ensure all mustache variables are HTML-escaped by default
to prevent XSS attacks.

BREAKING CHANGE: Triple-mustache syntax required for unescaped HTML
```

### Creating Pull Request

1. **Push your branch:**

   ```bash
   git push origin feature/your-feature-name
   ```

2. **Create Pull Request** on GitHub

3. **Fill out PR template** completely

4. **Link related issues**

5. **Wait for review** and respond to feedback

### Code Review Process

1. **Automated checks** must pass (tests, linting)
2. **At least one maintainer** will review your PR
3. **Address feedback** promptly
4. **Maintainer approves** and merges

**Review timeline:**

- Small PRs: 1-3 days
- Medium PRs: 3-7 days
- Large PRs: 1-2 weeks

## Release Process

*For maintainers only*

### Version Numbering

We follow [Semantic Versioning](https://semver.org/):

- **MAJOR** - Breaking changes
- **MINOR** - New features (backward compatible)
- **PATCH** - Bug fixes (backward compatible)

### Release Steps

1. Update version in `package.json`
2. Update CHANGELOG.md
3. Create git tag: `git tag -a v0.15.4 -m "Release v0.15.4"`
4. Push tag: `git push origin v0.15.4`
5. Create GitHub Release
6. Publish to npm: `npm publish`

## Getting Help

- **Questions?** Open a [Discussion](https://github.com/mashpie/i18n-node/discussions)
- **Stuck?** Ask on [Stack Overflow](https://stackoverflow.com/questions/tagged/i18n-node)
- **Chat** Join our community channels (if available)

## Recognition

Contributors are recognized in:

- GitHub contributors page
- Release notes
- CHANGELOG.md

Significant contributions may earn you commit access to the repository.

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

**Thank you for contributing to i18n! 🙏**

Happy coding! 🚀
