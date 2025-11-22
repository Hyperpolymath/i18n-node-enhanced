# Hono Integration Example

Ultrafast framework integration that works with Node.js, Bun, Deno, and Edge Runtimes.

## Features

- Ultrafast performance (3x-4x faster than Express)
- Works on multiple runtimes: Node.js, Bun, Deno, Cloudflare Workers
- Lightweight middleware
- Automatic locale detection
- Context-based i18n helpers
- Edge runtime compatible

## Setup

```bash
npm install
```

## Run

### Node.js
```bash
npm run dev
```

### Bun
```bash
npm run dev:bun
# or
bun --hot index.js
```

### Deno
```bash
deno run --allow-net --allow-read index.js
```

## Test

```bash
npm test
```

## Usage

### Basic Middleware

```javascript
const i18nMiddleware = async (c, next) => {
  const locale = c.req.query('locale') || 'en';
  i18n.setLocale(locale);

  c.set('__', (...args) => i18n.__(...args));
  await next();
};

app.use('*', i18nMiddleware);
```

### Route Handler

```javascript
app.get('/greetings/:name', (c) => {
  const __ = c.get('__');
  const name = c.req.param('name');

  return c.json({
    greeting: __('greeting', name)
  });
});
```

## API Endpoints

- `GET /` - Welcome message
- `GET /greetings/:name` - Get localized greeting
- `GET /plural/:count` - Plural form example
- `GET /catalog` - Get translation catalog
- `GET /locales` - List available locales

## Performance

Hono is designed for edge computing and offers exceptional performance:

- 3-4x faster than Express
- ~50KB bundle size
- Works on Cloudflare Workers, Fastly Compute@Edge
- Native support for WebAssembly
