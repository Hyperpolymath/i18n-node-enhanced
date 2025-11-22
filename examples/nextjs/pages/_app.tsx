/**
 * Next.js App Component with i18n Integration
 * This example shows how to integrate i18n with Next.js App Router
 */

import type { AppProps } from 'next/app';
import { I18n } from 'i18n';
import { useRouter } from 'next/router';
import { useEffect } from 'react';
import path from 'path';

// Create i18n instance
export const i18n = new I18n({
  locales: ['en', 'de', 'fr', 'es'],
  defaultLocale: 'en',
  directory: path.join(process.cwd(), 'locales'),
  updateFiles: false, // Disable in production
  autoReload: process.env.NODE_ENV === 'development',
  syncFiles: false,
  objectNotation: true,
  retryInDefaultLocale: true
});

function MyApp({ Component, pageProps }: AppProps) {
  const router = useRouter();
  const { locale } = router;

  useEffect(() => {
    // Set locale based on Next.js router locale
    if (locale) {
      i18n.setLocale(locale);
    }
  }, [locale]);

  return <Component {...pageProps} />;
}

export default MyApp;
