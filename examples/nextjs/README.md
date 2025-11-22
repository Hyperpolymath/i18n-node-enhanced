# Next.js + i18n Example

This example demonstrates how to integrate i18n with Next.js for internationalization.

## Features

- ✅ Server-side rendering (SSR) with i18n
- ✅ Static generation (SSG) with i18n
- ✅ API routes with translation support
- ✅ Client-side locale switching
- ✅ Next.js i18n routing integration
- ✅ TypeScript support

## Setup

```bash
npm install
```

## Development

```bash
npm run dev
```

Visit http://localhost:3000

## Locale Switching

The example supports locale switching via:

1. **URL path**: `/en`, `/de`, `/fr`, `/es`
2. **Browser detection**: Automatic locale detection
3. **UI buttons**: Click language buttons to switch

## Project Structure

```
nextjs/
├── pages/
│   ├── _app.tsx          # App component with i18n setup
│   ├── index.tsx         # Home page with translations
│   └── api/
│       └── translations.ts # API endpoint for translations
├── locales/              # Translation files
│   ├── en.json
│   ├── de.json
│   ├── fr.json
│   └── es.json
├── next.config.js        # Next.js i18n configuration
└── package.json
```

## How It Works

### 1. i18n Configuration (_app.tsx)

```typescript
const i18n = new I18n({
  locales: ['en', 'de', 'fr', 'es'],
  defaultLocale: 'en',
  directory: path.join(process.cwd(), 'locales')
});
```

### 2. Server-Side Rendering (getStaticProps)

```typescript
export const getStaticProps: GetStaticProps = async ({ locale }) => {
  i18n.setLocale(locale);

  return {
    props: {
      translations: {
        title: i18n.__('home.title'),
        welcome: i18n.__('home.welcome')
      }
    }
  };
};
```

### 3. API Routes

```typescript
export default function handler(req: NextApiRequest, res: NextApiResponse) {
  const { locale = 'en' } = req.query;
  i18n.setLocale(locale as string);

  const catalog = i18n.getCatalog(locale as string);
  res.status(200).json({ locale, catalog });
}
```

## Translation Files

Create JSON files in `locales/`:

**locales/en.json**:
```json
{
  "home": {
    "title": "Welcome to Next.js with i18n",
    "welcome": "Hello World",
    "description": "This is an example of Next.js with i18n integration",
    "changeLanguage": "Change Language"
  }
}
```

## API Endpoints

### Get All Translations

```
GET /api/translations?locale=de
```

Response:
```json
{
  "locale": "de",
  "catalog": { ... }
}
```

### Get Specific Translation

```
GET /api/translations?locale=de&key=home.title
```

Response:
```json
{
  "key": "home.title",
  "locale": "de",
  "translation": "Willkommen bei Next.js mit i18n"
}
```

## Production Deployment

For production, disable file updates:

```typescript
const i18n = new I18n({
  updateFiles: false,
  autoReload: false,
  syncFiles: false
});
```

## Learn More

- [Next.js i18n Documentation](https://nextjs.org/docs/advanced-features/i18n-routing)
- [i18n-node Documentation](../../README.md)
