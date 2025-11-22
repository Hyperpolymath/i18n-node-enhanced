/** @type {import('next').NextConfig} */
const nextConfig = {
  i18n: {
    // These locales should match i18n configuration
    locales: ['en', 'de', 'fr', 'es'],
    defaultLocale: 'en',
    localeDetection: true
  },
  reactStrictMode: true,
};

module.exports = nextConfig;
