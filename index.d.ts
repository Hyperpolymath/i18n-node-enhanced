// Type definitions for i18n 0.15.3
// Project: https://github.com/mashpie/i18n-node
// Definitions by: Claude AI (Anthropic)
// TypeScript Version: 4.0+

/// <reference types="node" />

import { Request, Response, NextFunction } from 'express';

declare namespace i18n {
  /**
   * Configuration options for i18n
   */
  export interface ConfigurationOptions {
    /**
     * Setup supported locales - locales will silently fall back to defaultLocale
     * @default ['en']
     * @example ['en', 'de', 'fr']
     */
    locales?: string[];

    /**
     * Fallback configuration for locales
     * @example { nl: 'de', 'de-*': 'de' }
     */
    fallbacks?: Record<string, string>;

    /**
     * Default locale
     * @default 'en'
     */
    defaultLocale?: string;

    /**
     * Will return translation from defaultLocale in case current locale doesn't provide it
     * @default false
     */
    retryInDefaultLocale?: boolean;

    /**
     * Custom cookie name to parse locale settings from
     * @default null
     */
    cookie?: string | null;

    /**
     * Custom header name to read language preference from
     * @default 'accept-language'
     */
    header?: string;

    /**
     * Query parameter to switch locale (e.g., /home?lang=en)
     * @default null
     */
    queryParameter?: string | null;

    /**
     * Directory where locale JSON files are stored
     * @default './locales'
     */
    directory?: string;

    /**
     * Control mode on directory creation
     * @default null (uses process umask)
     * @example '755'
     */
    directoryPermissions?: string | null;

    /**
     * Watch for changes in JSON files to reload locale on updates
     * @default false
     */
    autoReload?: boolean;

    /**
     * Whether to write new locale information to disk
     * @default true
     */
    updateFiles?: boolean;

    /**
     * Sync locale information across all files
     * @default false
     */
    syncFiles?: boolean;

    /**
     * Indentation unit for JSON files
     * @default '\t'
     */
    indent?: string;

    /**
     * Extension of JSON files
     * @default '.json'
     */
    extension?: string;

    /**
     * Prefix for JSON file names
     * @default ''
     * @example 'webapp-' (produces webapp-en.json instead of en.json)
     */
    prefix?: string;

    /**
     * Enable object notation - allows using dot notation in translation keys
     * @default false
     * @example true or '.' or any custom delimiter
     */
    objectNotation?: boolean | string;

    /**
     * Custom debug logging function
     * @default require('debug')('i18n:debug')
     */
    logDebugFn?: (msg: string) => void;

    /**
     * Custom warning logging function
     * @default require('debug')('i18n:warn')
     */
    logWarnFn?: (msg: string) => void;

    /**
     * Custom error logging function
     * @default require('debug')('i18n:error')
     */
    logErrorFn?: (msg: string) => void;

    /**
     * Function to handle missing translation keys
     * @default returns the key itself
     */
    missingKeyFn?: (locale: string, key: string) => string;

    /**
     * Object or array of objects to bind i18n API to
     * @default null
     * @example global (for CLI usage)
     */
    register?: object | object[] | null;

    /**
     * Custom aliases for i18n API methods
     * @example { __: 't', __n: 'tn' }
     */
    api?: Partial<Record<keyof LocaleAPI, string>>;

    /**
     * Downcase locale when passed via queryParam
     * @default true
     */
    preserveLegacyCase?: boolean;

    /**
     * Static catalog - overrides file-based locales
     * @example { de: require('./de.json'), en: require('./en.json') }
     */
    staticCatalog?: Record<string, object>;

    /**
     * Mustache configuration
     */
    mustacheConfig?: {
      /**
       * Custom mustache tags
       * @default ['{{', '}}']
       */
      tags?: [string, string];
      /**
       * Disable mustache parsing
       * @default false
       */
      disable?: boolean;
    };

    /**
     * Custom parser for locale files (e.g., YAML)
     * Must have parse() and stringify() methods
     * @default JSON
     */
    parser?: {
      parse: (text: string) => any;
      stringify: (obj: any) => string;
    };
  }

  /**
   * Translation replacements - can be string, number, or object with named parameters
   */
  export type Replacements = Record<string, any>;

  /**
   * Phrase with locale specification
   */
  export interface PhraseWithOptions {
    phrase: string;
    locale?: string;
  }

  /**
   * Plural phrase with locale specification
   */
  export interface PluralPhraseWithOptions {
    singular: string;
    plural: string;
    count?: number;
    locale?: string;
  }

  /**
   * Translation catalog - nested object of translations
   */
  export type Catalog = Record<string, any>;

  /**
   * Core i18n API methods available on request/response objects
   */
  export interface LocaleAPI {
    /**
     * Translates a single phrase and adds it to locales if unknown
     * @param phrase - The phrase to translate (or object with phrase and locale)
     * @param replacements - Optional sprintf-style or mustache replacements
     * @returns Translated and formatted string
     * @example
     * __('Hello') // => 'Hello' or 'Hallo' depending on locale
     * __('Hello %s', 'World') // => 'Hello World'
     * __('Hello {{name}}', { name: 'World' }) // => 'Hello World'
     * __({ phrase: 'Hello', locale: 'de' }) // => 'Hallo'
     */
    __(phrase: string | PhraseWithOptions, ...replacements: any[]): string;

    /**
     * Plural translation of a single phrase
     * @param singular - Singular form (or object with singular/plural/count)
     * @param plural - Plural form (optional if using object notation)
     * @param count - Count to determine plural form (or replacements if using object)
     * @param replacements - Additional sprintf-style or mustache replacements
     * @returns Translated plural string
     * @example
     * __n('%s cat', '%s cats', 1) // => '1 cat'
     * __n('%s cat', '%s cats', 3) // => '3 cats'
     * __n({ singular: '%s cat', plural: '%s cats', count: 1 }) // => '1 cat'
     */
    __n(
      singular: string | PluralPhraseWithOptions,
      plural?: string | number,
      count?: number | string | Replacements,
      ...replacements: any[]
    ): string;

    /**
     * MessageFormat translation with ICU MessageFormat syntax
     * @param phrase - MessageFormat string
     * @param replacements - MessageFormat parameters
     * @returns Formatted MessageFormat string
     * @example
     * __mf('{N, plural, one{# cat} other{# cats}}', { N: 1 }) // => '1 cat'
     * __mf('Hello {name}', { name: 'World' }) // => 'Hello World'
     */
    __mf(phrase: string | PhraseWithOptions, ...replacements: any[]): string;

    /**
     * Returns a list of translations for a given phrase in all locales
     * @param phrase - The phrase to get translations for
     * @returns Array of translations across locales
     * @example
     * __l('Hello') // => ['Hello', 'Hallo', 'Bonjour']
     */
    __l(phrase: string): string[];

    /**
     * Returns a hash of translations for a given phrase in each locale
     * @param phrase - The phrase to get translations for
     * @returns Object mapping locales to translations
     * @example
     * __h('Hello') // => { en: 'Hello', de: 'Hallo', fr: 'Bonjour' }
     */
    __h(phrase: string): Record<string, string>;

    /**
     * Get current locale
     * @returns Current locale string
     * @example
     * getLocale() // => 'en'
     */
    getLocale(): string;

    /**
     * Set current locale
     * @param locale - Locale to set
     * @returns Updated locale string
     * @example
     * setLocale('de') // Sets locale to German
     */
    setLocale(locale: string): string;

    /**
     * Get translation catalog
     * @param locale - Optional specific locale to get catalog for
     * @returns Translation catalog object
     * @example
     * getCatalog() // => { en: {...}, de: {...} }
     * getCatalog('en') // => { Hello: 'Hello', ... }
     */
    getCatalog(locale?: string): Catalog;

    /**
     * Get list of all configured locales
     * @returns Array of locale strings
     * @example
     * getLocales() // => ['en', 'de', 'fr']
     */
    getLocales(): string[];

    /**
     * Add a new locale at runtime
     * @param locale - Locale code to add
     * @example
     * addLocale('es') // Adds Spanish locale
     */
    addLocale(locale: string): void;

    /**
     * Remove a locale at runtime
     * @param locale - Locale code to remove
     * @example
     * removeLocale('de') // Removes German locale
     */
    removeLocale(locale: string): void;

    /**
     * Current locale code
     */
    locale?: string;
  }

  /**
   * Extended Request interface with i18n methods
   */
  export interface I18nRequest extends Request, LocaleAPI {
    /**
     * Detected/set language for this request
     */
    language?: string;

    /**
     * Detected/set region for this request
     */
    region?: string;

    /**
     * Nested locals object
     */
    locals?: LocaleAPI & { locale?: string };
  }

  /**
   * Extended Response interface with i18n methods
   */
  export interface I18nResponse extends Response, LocaleAPI {
    /**
     * Express locals - contains i18n methods
     */
    locals: LocaleAPI & { locale?: string };
  }

  /**
   * Main i18n class for instance usage
   */
  export class I18n implements LocaleAPI {
    /**
     * Create a new i18n instance
     * @param config - Optional configuration options
     * @example
     * const i18n = new I18n({ locales: ['en', 'de'], directory: './locales' })
     */
    constructor(config?: ConfigurationOptions);

    /**
     * i18n version
     */
    version: string;

    /**
     * Configure i18n
     * @param config - Configuration options
     * @example
     * i18n.configure({ locales: ['en', 'de'], directory: './locales' })
     */
    configure(config: ConfigurationOptions): void;

    /**
     * Initialize i18n for Express middleware
     * @param request - Express request object
     * @param response - Express response object
     * @param next - Express next function
     * @example
     * app.use(i18n.init)
     */
    init(
      request: Request,
      response: Response,
      next?: NextFunction
    ): void;

    // LocaleAPI methods
    __(phrase: string | PhraseWithOptions, ...replacements: any[]): string;
    __n(
      singular: string | PluralPhraseWithOptions,
      plural?: string | number,
      count?: number | string | Replacements,
      ...replacements: any[]
    ): string;
    __mf(phrase: string | PhraseWithOptions, ...replacements: any[]): string;
    __l(phrase: string): string[];
    __h(phrase: string): Record<string, string>;
    getLocale(): string;
    setLocale(locale: string): string;
    /**
     * Set locale on specific object(s)
     * @param objects - Object or array of objects to set locale on
     * @param locale - Locale to set
     * @param skipImplicitObjects - Skip setting on implicit child objects
     */
    setLocale(
      objects: object | object[],
      locale: string,
      skipImplicitObjects?: boolean
    ): string;
    /**
     * Get locale from specific object
     * @param object - Object to get locale from
     */
    getLocale(object: object): string;
    getCatalog(locale?: string): Catalog;
    /**
     * Get catalog for specific object
     * @param object - Object to get catalog from
     * @param locale - Optional specific locale
     */
    getCatalog(object: object, locale?: string): Catalog;
    getLocales(): string[];
    addLocale(locale: string): void;
    removeLocale(locale: string): void;
  }
}

/**
 * Default singleton instance
 */
declare const i18n: i18n.I18n;

export = i18n;
export as namespace i18n;
