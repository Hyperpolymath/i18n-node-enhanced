# Fastify + i18n Example

This example demonstrates how to integrate i18n with the Fastify framework.

## Features

- ✅ Fastify decorators for i18n methods
- ✅ Request hooks for automatic locale detection
- ✅ Cookie-based locale persistence
- ✅ JSON Schema validation
- ✅ RESTful API endpoints
- ✅ Error handling with localized messages
- ✅ Health check endpoint
- ✅ Complete test suite with Fastify's inject API

## Setup

```bash
npm install
```

## Development

```bash
npm run dev
```

Visit http://localhost:3000

## Production

```bash
npm start
```

## Testing

```bash
npm test
```

## How It Works

### 1. Request Decorators

i18n methods are added to Fastify request objects:

```javascript
fastify.decorateRequest('__', function(phrase, ...args) {
  return i18n.__(phrase, ...args);
});

fastify.decorateRequest('setLocale', function(locale) {
  this.locale = locale;
  i18n.setLocale(locale);
});
```

### 2. PreHandler Hook

Locale detection happens before each request:

```javascript
fastify.addHook('preHandler', async (request, reply) => {
  let locale = request.query.lang ||
               request.cookies.locale ||
               request.headers['accept-language'];

  request.setLocale(locale);
});
```

### 3. Using in Routes

```javascript
fastify.get('/', async (request, reply) => {
  const welcome = request.__('welcome');
  const message = request.__('Hello {{name}}', { name: 'Fastify' });

  return { welcome, message };
});
```

### 4. JSON Schema Validation

Fastify's schema validation ensures type safety:

```javascript
const schema = {
  body: {
    type: 'object',
    required: ['locale'],
    properties: {
      locale: { type: 'string', pattern: '^[a-z]{2}$' }
    }
  }
};

fastify.post('/api/locale', { schema }, async (request, reply) => {
  // Validated body
  const { locale } = request.body;
});
```

## API Endpoints

### GET /

Home page with locale switcher and translation examples.

### GET /api/translations

Get translation catalog for a locale.

**Request:**
```bash
curl http://localhost:3000/api/translations?locale=de
```

**Response:**
```json
{
  "locale": "de",
  "catalog": {
    "welcome": "Willkommen",
    "description": "Dies ist eine Beispielanwendung"
  },
  "availableLocales": ["en", "de", "fr", "es"]
}
```

### POST /api/locale

Set user's locale preference (saves to cookie).

**Request:**
```bash
curl -X POST http://localhost:3000/api/locale \
  -H "Content-Type: application/json" \
  -d '{"locale":"fr"}'
```

**Response:**
```json
{
  "success": true,
  "locale": "fr"
}
```

### GET /api/translate/:key

Translate a specific key.

**Request:**
```bash
curl http://localhost:3000/api/translate/Hello?locale=de
```

**Response:**
```json
{
  "key": "Hello",
  "locale": "de",
  "translation": "Hallo"
}
```

### GET /health

Health check endpoint.

**Response:**
```json
{
  "status": "ok",
  "locales": ["en", "de", "fr", "es"],
  "version": "0.15.3"
}
```

## Locale Switching

**Via Query Parameter:**
```
GET /?lang=de
```

**Via Cookie:**
```javascript
reply.setCookie('locale', 'de', { httpOnly: true });
```

**Via Accept-Language Header:**
```bash
curl -H "Accept-Language: de" http://localhost:3000/
```

## Translation Files

Create JSON files in `locales/`:

**locales/en.json**:
```json
{
  "welcome": "Welcome to Fastify with i18n",
  "description": "This demonstrates Fastify integration",
  "Hello": "Hello",
  "%s cat": {
    "one": "%s cat",
    "other": "%s cats"
  },
  "error": {
    "occurred": "An error occurred"
  }
}
```

## Error Handling

Errors are localized using i18n:

```javascript
fastify.setErrorHandler((error, request, reply) => {
  const errorMessage = request.__('error.occurred');

  reply.status(error.statusCode || 500).send({
    error: errorMessage,
    message: error.message
  });
});
```

## Performance

Fastify is one of the fastest Node.js frameworks. This example leverages:

- **Request decorators** for minimal overhead
- **preHandler hooks** for efficient locale detection
- **Schema validation** for fast request parsing
- **Cookie-based** locale persistence

## Learn More

- [Fastify Documentation](https://www.fastify.io/)
- [Fastify Decorators](https://www.fastify.io/docs/latest/Reference/Decorators/)
- [Fastify Hooks](https://www.fastify.io/docs/latest/Reference/Hooks/)
- [i18n-node Documentation](../../README.md)
