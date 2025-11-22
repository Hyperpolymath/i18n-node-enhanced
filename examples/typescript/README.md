# TypeScript Usage Examples

This directory contains comprehensive TypeScript examples for using i18n with full type safety and IntelliSense support.

## Prerequisites

```bash
npm install
```

## Examples

### 1. Basic Usage (`basic-usage.ts`)

Demonstrates core i18n features with TypeScript:
- Configuration with type safety
- Basic translations
- Plural forms
- MessageFormat
- Locale management
- Object notation

**Run:**
```bash
npm start
```

### 2. Express Integration (`express-usage.ts`)

Shows how to integrate i18n with Express using TypeScript:
- Middleware setup
- Type-safe request/response handlers
- Cookie-based locale switching
- API endpoints with i18n
- Template rendering
- Custom middleware

**Run:**
```bash
npm run start:express
```

Then visit:
- `http://localhost:3000/` - Main page
- `http://localhost:3000/locale/de` - Switch to German
- `http://localhost:3000/api/translations` - View translation catalog

## Type Safety Features

The TypeScript definitions provide:

1. **Configuration Type Safety**: Full autocomplete for all configuration options
2. **Method Signatures**: Proper typing for all translation methods
3. **Return Types**: Correct return types (string, string[], Record<string, string>)
4. **Overload Support**: Multiple method signatures for flexible API usage
5. **Express Integration**: Extended Request/Response types with i18n methods
6. **IntelliSense**: Full IDE support with documentation

## Building

Compile TypeScript to JavaScript:

```bash
npm run build
```

Output will be in `./dist` directory.

## Type Checking

TypeScript will catch common errors:

```typescript
// ✗ Error: Argument of type 'number' is not assignable to parameter of type 'string'
i18n.setLocale(123);

// ✓ Correct
i18n.setLocale('en');

// ✗ Error: Property 'invalidOption' does not exist on type 'ConfigurationOptions'
const i18n = new I18n({ invalidOption: true });

// ✓ Correct
const i18n = new I18n({ autoReload: true });
```

## Learn More

- See [index.d.ts](../../index.d.ts) for complete type definitions
- Check [README.md](../../README.md) for API documentation
- Visit [examples/](../) for more usage patterns
