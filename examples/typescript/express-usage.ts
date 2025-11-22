/**
 * Express with TypeScript usage example for i18n
 * Demonstrates type-safe i18n middleware integration
 */

import express, { Request, Response, NextFunction } from 'express';
import { I18n } from '../../index';
import * as path from 'path';
import * as cookieParser from 'cookie-parser';

const app = express();

// Create i18n instance
const i18n = new I18n({
  locales: ['en', 'de', 'fr', 'es'],
  directory: path.join(__dirname, 'locales'),
  defaultLocale: 'en',
  cookie: 'locale',
  queryParameter: 'lang',
  autoReload: true,
  updateFiles: false,
  syncFiles: false,
  objectNotation: true,
  api: {
    __: 't',      // req.t() instead of req.__()
    __n: 'tn'     // req.tn() instead of req.__n()
  }
});

// Apply middleware
app.use(cookieParser());
app.use(i18n.init);

// Type-safe route handlers
app.get('/', (req: Request, res: Response) => {
  // i18n methods are available on both req and res
  const welcome: string = res.__('Welcome to our website');
  const itemCount: string = res.__n('%s item in cart', '%s items in cart', 3);

  res.send(`
    <h1>${welcome}</h1>
    <p>${itemCount}</p>
    <p>Current locale: ${req.getLocale()}</p>
  `);
});

// Route with locale switching
app.get('/locale/:locale', (req: Request, res: Response) => {
  const locale: string = req.params.locale;

  // Set locale for this request
  req.setLocale(locale);

  // Set cookie for future requests
  res.cookie('locale', locale, { maxAge: 900000, httpOnly: true });

  res.redirect('/');
});

// API endpoint returning JSON
app.get('/api/translations', (req: Request, res: Response) => {
  const catalog = req.getCatalog();
  const locales: string[] = req.getLocales();

  res.json({
    currentLocale: req.getLocale(),
    availableLocales: locales,
    translations: catalog
  });
});

// Error handler with localized messages
app.use((err: Error, req: Request, res: Response, next: NextFunction) => {
  const errorMessage: string = res.__('An error occurred: %s', err.message);
  res.status(500).json({ error: errorMessage });
});

// Template rendering with i18n
app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'views'));

app.get('/template', (req: Request, res: Response) => {
  // res.locals automatically has i18n methods
  res.render('index', {
    title: res.__('Page Title'),
    content: res.__('Page content goes here')
  });
});

// Advanced: Custom middleware with locale detection
app.use((req: Request, res: Response, next: NextFunction) => {
  // Custom logic to detect locale from subdomain, etc.
  const host: string = req.hostname;

  if (host.startsWith('de.')) {
    req.setLocale('de');
  } else if (host.startsWith('fr.')) {
    req.setLocale('fr');
  }

  next();
});

const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
  console.log(`Available locales: ${i18n.getLocales().join(', ')}`);
});

export { app, i18n };
