# Koa + i18n Example

This example demonstrates how to integrate i18n with the Koa framework.

## Features

- ✅ Koa middleware integration
- ✅ Context-based locale detection
- ✅ Query parameter, cookie, and header support
- ✅ REST API endpoints for translations
- ✅ Error handling with localized messages
- ✅ Complete test suite

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

### 1. i18n Middleware

The middleware detects locale from multiple sources:

```javascript
app.use(async (ctx, next) => {
  let locale = ctx.query.lang ||          // Query parameter
               ctx.cookies.get('locale') || // Cookie
               ctx.get('accept-language'); // Header

  i18n.setLocale(locale);

  // Bind i18n methods to context
  ctx.__ = (...args) => i18n.__(...args);
  ctx.__n = (...args) => i18n.__n(...args);

  await next();
});
```

### 2. Using Translations in Routes

```javascript
router.get('/', async (ctx) => {
  const welcome = ctx.__('welcome');
  const message = ctx.__('Hello {{name}}', { name: 'Koa' });

  ctx.body = { welcome, message };
});
```

### 3. Locale Switching

**Via Query Parameter:**
```
GET /?lang=de
```

**Via Cookie:**
```javascript
ctx.cookies.set('locale', 'de', { httpOnly: true });
```

**Via API:**
```bash
curl -X POST http://localhost:3000/api/locale \
  -H "Content-Type: application/json" \
  -d '{"locale":"fr"}'
```

## API Endpoints

### GET /api/translations

Get translation catalog for a locale.

**Request:**
```
GET /api/translations?locale=de
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
POST /api/locale
Content-Type: application/json

{
  "locale": "fr"
}
```

**Response:**
```json
{
  "success": true,
  "locale": "fr"
}
```

## Translation Files

Create JSON files in `locales/`:

**locales/en.json**:
```json
{
  "welcome": "Welcome to Koa with i18n",
  "description": "This is an example integration",
  "Hello": "Hello",
  "%s cat": {
    "one": "%s cat",
    "other": "%s cats"
  }
}
```

## Error Handling

Errors are localized using i18n:

```javascript
app.use(async (ctx, next) => {
  try {
    await next();
  } catch (err) {
    ctx.body = {
      error: ctx.__('error.occurred'),
      message: err.message
    };
  }
});
```

## Learn More

- [Koa Documentation](https://koajs.com/)
- [i18n-node Documentation](../../README.md)
