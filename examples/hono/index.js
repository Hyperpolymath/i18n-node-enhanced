/**
 * Hono Ultrafast Framework Integration Example
 * Works with Node.js, Bun, Deno, and Edge Runtimes
 */

const { Hono } = require('hono');
const { I18n } = require('i18n');

// Create Hono app
const app = new Hono();

// Configure i18n
const i18n = new I18n({
  locales: ['en', 'de', 'fr', 'es', 'ja'],
  defaultLocale: 'en',
  directory: './locales',
  updateFiles: false,
  autoReload: false,
  objectNotation: true
});

// I18n middleware for Hono
const i18nMiddleware = async (c, next) => {
  // Detect locale from query, header, or use default
  const locale = c.req.query('locale') ||
                 c.req.query('lang') ||
                 c.req.header('Accept-Language')?.split(',')[0]?.split('-')[0] ||
                 'en';

  i18n.setLocale(locale);

  // Add i18n helpers to context
  c.set('i18n', i18n);
  c.set('locale', locale);
  c.set('__', (...args) => i18n.__(...args));
  c.set('__n', (...args) => i18n.__n(...args));

  await next();
};

// Apply middleware globally
app.use('*', i18nMiddleware);

// Routes
app.get('/', (c) => {
  const __ = c.get('__');
  const locale = c.get('locale');

  return c.json({
    message: __('welcome.message'),
    locale,
    timestamp: new Date().toISOString()
  });
});

app.get('/greetings/:name?', (c) => {
  const __ = c.get('__');
  const locale = c.get('locale');
  const name = c.req.param('name') || 'World';

  return c.json({
    greeting: __('greeting', name),
    locale
  });
});

app.get('/plural/:count', (c) => {
  const __n = c.get('__n');
  const locale = c.get('locale');
  const count = parseInt(c.req.param('count'), 10);

  return c.json({
    message: __n('%s item', '%s items', count),
    count,
    locale
  });
});

app.get('/catalog', (c) => {
  const i18nInstance = c.get('i18n');
  const locale = c.get('locale');

  return c.json({
    catalog: i18nInstance.getCatalog(locale),
    locale
  });
});

app.get('/locales', (c) => {
  const i18nInstance = c.get('i18n');

  return c.json({
    locales: i18nInstance.getLocales(),
    current: c.get('locale')
  });
});

// Error handler
app.onError((err, c) => {
  console.error('Error:', err);
  return c.json({
    error: err.message,
    stack: process.env.NODE_ENV === 'development' ? err.stack : undefined
  }, 500);
});

// Export for different runtimes
module.exports = app;

// Start server if running directly (not imported)
if (require.main === module) {
  const port = process.env.PORT || 3000;

  console.log(`
🔥 Hono i18n Example Server Running!

   Port: ${port}
   URL:  http://localhost:${port}

   Endpoints:
   - GET  /
   - GET  /greetings/:name
   - GET  /plural/:count
   - GET  /catalog
   - GET  /locales

   Try:
   - http://localhost:${port}/greetings/Claude?locale=de
   - http://localhost:${port}/plural/5?locale=fr
   - http://localhost:${port}/catalog?locale=es
  `);

  // For Node.js
  if (typeof Bun === 'undefined') {
    const { serve } = require('@hono/node-server');
    serve({
      fetch: app.fetch,
      port
    });
  }
  // For Bun
  else {
    Bun.serve({
      fetch: app.fetch,
      port
    });
  }
}
