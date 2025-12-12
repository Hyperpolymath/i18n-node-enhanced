/**
 * Fastify with i18n Example
 * Demonstrates i18n integration with Fastify framework
 */

const fastify = require('fastify')({ logger: true });
const path = require('path');
const { I18n } = require('i18n');

// Create i18n instance
const i18n = new I18n({
  locales: ['en', 'de', 'fr', 'es'],
  defaultLocale: 'en',
  directory: path.join(__dirname, 'locales'),
  autoReload: process.env.NODE_ENV === 'development',
  updateFiles: false,
  syncFiles: false,
  objectNotation: true,
  queryParameter: 'lang',
  header: 'accept-language',
  cookie: 'locale'
});

// Register cookie plugin
fastify.register(require('@fastify/cookie'));

// i18n decorator - adds i18n methods to request
fastify.decorateRequest('__', function(phrase, ...args) {
  return i18n.__(phrase, ...args);
});

fastify.decorateRequest('__n', function(...args) {
  return i18n.__n(...args);
});

fastify.decorateRequest('__mf', function(...args) {
  return i18n.__mf(...args);
});

fastify.decorateRequest('__l', function(...args) {
  return i18n.__l(...args);
});

fastify.decorateRequest('__h', function(...args) {
  return i18n.__h(...args);
});

fastify.decorateRequest('getLocale', function() {
  return this.locale || i18n.getLocale();
});

fastify.decorateRequest('setLocale', function(locale) {
  this.locale = locale;
  i18n.setLocale(locale);
  return locale;
});

fastify.decorateRequest('getLocales', function() {
  return i18n.getLocales();
});

fastify.decorateRequest('getCatalog', function(...args) {
  return i18n.getCatalog(...args);
});

// Hook to detect and set locale before each request
fastify.addHook('preHandler', async (request, reply) => {
  // Detect locale from query, cookie, or header
  let locale = request.query.lang ||
               request.cookies.locale ||
               request.headers['accept-language']?.split(',')[0] ||
               i18n.getLocale();

  // Validate locale
  if (!i18n.getLocales().includes(locale)) {
    locale = i18n.getLocale();
  }

  // Set locale on request
  request.setLocale(locale);

  // Also decorate reply for convenience
  reply.__ = (...args) => request.__(...args);
  reply.__n = (...args) => request.__n(...args);
  reply.getLocale = () => request.getLocale();
});

// Routes
fastify.get('/', async (request, reply) => {
  const welcome = request.__('welcome');
  const description = request.__('description');
  const currentLocale = request.getLocale();
  const availableLocales = request.getLocales();

  reply.type('text/html');
  return `
    <!DOCTYPE html>
    <html lang="${currentLocale}">
    <head>
      <meta charset="UTF-8">
      <title>Fastify + i18n Example</title>
      <style>
        body { font-family: sans-serif; padding: 2rem; max-width: 800px; margin: 0 auto; }
        button { margin: 0.5rem; padding: 0.5rem 1rem; cursor: pointer; }
        .code { background: #f4f4f4; padding: 1rem; border-radius: 4px; }
      </style>
    </head>
    <body>
      <h1>${welcome}</h1>
      <p>${description}</p>
      <p>Current locale: <strong>${currentLocale}</strong></p>

      <h2>Change Language:</h2>
      ${availableLocales.map(loc => `
        <a href="/?lang=${loc}">
          <button style="${currentLocale === loc ? 'font-weight: bold; background: #0066cc; color: white;' : ''}">${loc.toUpperCase()}</button>
        </a>
      `).join('')}

      <h2>Example Translations:</h2>
      <ul>
        <li>Simple: ${request.__('Hello')}</li>
        <li>With variable: ${request.__('Hello {{name}}', { name: 'Fastify' })}</li>
        <li>Plural (1): ${request.__n('%s cat', '%s cats', 1)}</li>
        <li>Plural (3): ${request.__n('%s cat', '%s cats', 3)}</li>
      </ul>

      <h2>API Examples:</h2>
      <div class="code">
        <p>GET <a href="/api/translations?locale=de">/api/translations?locale=de</a></p>
        <p>POST /api/locale with { "locale": "fr" }</p>
      </div>
    </body>
    </html>
  `;
});

// API Routes

// Schema for validation
const translationsSchema = {
  querystring: {
    type: 'object',
    properties: {
      locale: { type: 'string', pattern: '^[a-z]{2}(-[A-Z]{2})?$' }
    }
  },
  response: {
    200: {
      type: 'object',
      properties: {
        locale: { type: 'string' },
        catalog: { type: 'object' },
        availableLocales: { type: 'array', items: { type: 'string' } }
      }
    }
  }
};

const setLocaleSchema = {
  body: {
    type: 'object',
    required: ['locale'],
    properties: {
      locale: { type: 'string', pattern: '^[a-z]{2}(-[A-Z]{2})?$' }
    }
  },
  response: {
    200: {
      type: 'object',
      properties: {
        success: { type: 'boolean' },
        locale: { type: 'string' }
      }
    }
  }
};

// GET /api/translations - Get translation catalog
fastify.get('/api/translations', {
  schema: translationsSchema
}, async (request, reply) => {
  const locale = request.query.locale || request.getLocale();

  if (!i18n.getLocales().includes(locale)) {
    return reply.code(400).send({ error: 'Invalid locale' });
  }

  return {
    locale,
    catalog: i18n.getCatalog(locale),
    availableLocales: i18n.getLocales()
  };
});

// POST /api/locale - Set locale preference
fastify.post('/api/locale', {
  schema: setLocaleSchema
}, async (request, reply) => {
  const { locale } = request.body;

  if (!i18n.getLocales().includes(locale)) {
    return reply.code(400).send({ error: 'Invalid locale' });
  }

  // Set cookie
  reply.setCookie('locale', locale, {
    httpOnly: true,
    maxAge: 31536000, // 1 year in seconds
    path: '/'
  });

  return { success: true, locale };
});

// GET /api/translate/:key - Translate a specific key
fastify.get('/api/translate/:key', async (request, reply) => {
  const { key } = request.params;
  const locale = request.query.locale || request.getLocale();

  i18n.setLocale(locale);

  return {
    key,
    locale,
    translation: i18n.__(key)
  };
});

// Error handler with localized errors
fastify.setErrorHandler((error, request, reply) => {
  request.log.error(error);

  const errorMessage = request.__('error.occurred') || 'An error occurred';

  reply.status(error.statusCode || 500).send({
    error: errorMessage,
    message: error.message,
    statusCode: error.statusCode || 500
  });
});

// Health check
fastify.get('/health', async () => {
  return {
    status: 'ok',
    locales: i18n.getLocales(),
    version: require('../../package.json').version
  };
});

// Start server
const start = async () => {
  try {
    const PORT = process.env.PORT || 3000;
    const HOST = process.env.HOST || '0.0.0.0';

    await fastify.listen({ port: PORT, host: HOST });

    console.log(`Fastify server running on https://${HOST}:${PORT}`);
    console.log(`Available locales: ${i18n.getLocales().join(', ')}`);
  } catch (err) {
    fastify.log.error(err);
    process.exit(1);
  }
};

// Handle graceful shutdown
process.on('SIGINT', async () => {
  await fastify.close();
  process.exit(0);
});

if (require.main === module) {
  start();
}

module.exports = fastify;
