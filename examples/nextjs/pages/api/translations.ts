/**
 * Next.js API Route for dynamic translations
 */

import type { NextApiRequest, NextApiResponse } from 'next';
import { i18n } from '../_app';

export default function handler(req: NextApiRequest, res: NextApiResponse) {
  const { locale = 'en', key } = req.query;

  // Validate locale
  if (!i18n.getLocales().includes(locale as string)) {
    return res.status(400).json({ error: 'Invalid locale' });
  }

  // Set locale
  i18n.setLocale(locale as string);

  if (key) {
    // Get specific translation
    const translation = i18n.__(key as string);
    res.status(200).json({ key, locale, translation });
  } else {
    // Get full catalog
    const catalog = i18n.getCatalog(locale as string);
    res.status(200).json({ locale, catalog });
  }
}
