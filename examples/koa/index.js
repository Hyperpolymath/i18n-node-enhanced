/**
 * Koa with i18n Example
 * Demonstrates i18n integration with Koa framework
 */

const Koa = require('koa');
const Router = require('@koa/router');
const bodyParser = require('koa-bodyparser');
const { I18n } = require('i18n');
const path = require('path');

const app = new Koa();
const router = new Router();

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

// i18n middleware for Koa
app.use(async (ctx, next) => {
  // Detect locale from query, cookie, or header
  let locale = ctx.query.lang ||
               ctx.cookies.get('locale') ||
               ctx.get('accept-language')?.split(',')[0] ||
               i18n.getLocale();

  // Validate locale
  if (!i18n.getLocales().includes(locale)) {
    locale = i18n.getLocale();
  }

  // Set locale
  i18n.setLocale(locale);

  // Bind i18n methods to context
  ctx.__ = (...args) => i18n.__(...args);
  ctx.__n = (...args) => i18n.__n(...args);
  ctx.__mf = (...args) => i18n.__mf(...args);
  ctx.__l = (...args) => i18n.__l(...args);
  ctx.__h = (...args) => i18n.__h(...args);
  ctx.getLocale = () => i18n.getLocale();
  ctx.setLocale = (loc) => i18n.setLocale(loc);
  ctx.getLocales = () => i18n.getLocales();
  ctx.getCatalog = (...args) => i18n.getCatalog(...args);

  // Also add to state for template access
  ctx.state.__ = ctx.__;
  ctx.state.__n = ctx.__n;
  ctx.state.locale = locale;

  await next();
});

// Routes
router.get('/', async (ctx) => {
  const welcome = ctx.__('welcome');
  const description = ctx.__('description');
  const currentLocale = ctx.getLocale();
  const availableLocales = ctx.getLocales();

  ctx.body = `
    <!DOCTYPE html>
    <html lang="${currentLocale}">
    <head>
      <meta charset="UTF-8">
      <title>Koa + i18n Example</title>
      <style>
        body { font-family: sans-serif; padding: 2rem; max-width: 800px; margin: 0 auto; }
        button { margin: 0.5rem; padding: 0.5rem 1rem; cursor: pointer; }
      </style>
    </head>
    <body>
      <h1>${welcome}</h1>
      <p>${description}</p>
      <p>Current locale: <strong>${currentLocale}</strong></p>

      <h2>Change Language:</h2>
      ${availableLocales.map(loc => `
        <a href="/?lang=${loc}">
          <button>${loc.toUpperCase()}</button>
        </a>
      `).join('')}

      <h2>Example Translations:</h2>
      <ul>
        <li>Simple: ${ctx.__('Hello')}</li>
        <li>With variable: ${ctx.__('Hello {{name}}', { name: 'Koa' })}</li>
        <li>Plural (1): ${ctx.__n('%s cat', '%s cats', 1)}</li>
        <li>Plural (3): ${ctx.__n('%s cat', '%s cats', 3)}</li>
      </ul>
    </body>
    </html>
  `;
});

// API endpoint - get translations
router.get('/api/translations', async (ctx) => {
  const locale = ctx.query.locale || ctx.getLocale();

  if (!i18n.getLocales().includes(locale)) {
    ctx.status = 400;
    ctx.body = { error: 'Invalid locale' };
    return;
  }

  ctx.body = {
    locale,
    catalog: i18n.getCatalog(locale),
    availableLocales: i18n.getLocales()
  };
});

// API endpoint - set locale
router.post('/api/locale', bodyParser(), async (ctx) => {
  const { locale } = ctx.request.body;

  if (!i18n.getLocales().includes(locale)) {
    ctx.status = 400;
    ctx.body = { error: 'Invalid locale' };
    return;
  }

  // Set cookie
  ctx.cookies.set('locale', locale, {
    httpOnly: true,
    maxAge: 31536000000 // 1 year
  });

  ctx.body = { success: true, locale };
});

// Error handling
app.use(async (ctx, next) => {
  try {
    await next();
  } catch (err) {
    ctx.status = err.status || 500;
    ctx.body = {
      error: ctx.__('error.occurred'),
      message: err.message
    };
    ctx.app.emit('error', err, ctx);
  }
});

app.use(bodyParser());
app.use(router.routes());
app.use(router.allowedMethods());

const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
  console.log(`Koa server running on http://localhost:${PORT}`);
  console.log(`Available locales: ${i18n.getLocales().join(', ')}`);
});

module.exports = app;
