/**
 * Basic TypeScript usage example for i18n
 * Demonstrates type-safe translation with full IntelliSense support
 */

import { I18n, ConfigurationOptions } from '../../index';
import * as path from 'path';

// Configuration with full type safety
const config: ConfigurationOptions = {
  locales: ['en', 'de', 'fr'],
  directory: path.join(__dirname, 'locales'),
  defaultLocale: 'en',
  objectNotation: true,
  updateFiles: true,
  autoReload: false,
  syncFiles: false,
  cookie: 'language',
  queryParameter: 'lang',
  header: 'accept-language',
  indent: '  ',
  extension: '.json',
  fallbacks: {
    'nl': 'de'
  },
  retryInDefaultLocale: true
};

// Create i18n instance with configuration
const i18n = new I18n(config);

// Basic translation
const hello: string = i18n.__('Hello');
console.log(hello); // => 'Hello' (or 'Hallo' if locale is 'de')

// Translation with sprintf formatting
const greeting: string = i18n.__('Hello %s', 'World');
console.log(greeting); // => 'Hello World'

// Translation with mustache formatting
const personalGreeting: string = i18n.__('Hello {{name}}', { name: 'TypeScript' });
console.log(personalGreeting); // => 'Hello TypeScript'

// Translation with locale specification
const germanHello: string = i18n.__({ phrase: 'Hello', locale: 'de' });
console.log(germanHello); // => 'Hallo'

// Plural translations
const oneCat: string = i18n.__n('%s cat', '%s cats', 1);
console.log(oneCat); // => '1 cat'

const threeCats: string = i18n.__n('%s cat', '%s cats', 3);
console.log(threeCats); // => '3 cats'

// Plural with object notation
const pluralObject: string = i18n.__n({
  singular: '%s item',
  plural: '%s items',
  count: 5
});
console.log(pluralObject); // => '5 items'

// MessageFormat usage
const messageFormat: string = i18n.__mf('{N, plural, one{# cat} other{# cats}}', { N: 1 });
console.log(messageFormat); // => '1 cat'

// Get translation list across all locales
const translations: string[] = i18n.__l('Hello');
console.log(translations); // => ['Hello', 'Hallo', 'Bonjour']

// Get translation hash
const translationHash: Record<string, string> = i18n.__h('Hello');
console.log(translationHash); // => { en: 'Hello', de: 'Hallo', fr: 'Bonjour' }

// Locale management
const currentLocale: string = i18n.getLocale();
console.log('Current locale:', currentLocale); // => 'en'

i18n.setLocale('de');
console.log('New locale:', i18n.getLocale()); // => 'de'

// Get all configured locales
const allLocales: string[] = i18n.getLocales();
console.log('Available locales:', allLocales); // => ['en', 'de', 'fr']

// Get catalog
const catalog = i18n.getCatalog();
console.log('Full catalog:', catalog);

const englishCatalog = i18n.getCatalog('en');
console.log('English catalog:', englishCatalog);

// Add and remove locales at runtime
i18n.addLocale('es');
console.log('Locales after adding Spanish:', i18n.getLocales()); // => ['en', 'de', 'fr', 'es']

i18n.removeLocale('es');
console.log('Locales after removing Spanish:', i18n.getLocales()); // => ['en', 'de', 'fr']

// Object notation (if enabled in config)
const nestedTranslation: string = i18n.__('greeting.formal');
console.log(nestedTranslation); // => 'Good day'

// Object notation with default value
const withDefault: string = i18n.__('greeting.casual:Hey there');
console.log(withDefault); // => 'Hey there' (if not in catalog yet)

export { i18n };
