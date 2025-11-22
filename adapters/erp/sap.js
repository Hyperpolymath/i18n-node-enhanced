/**
 * SAP ERP Integration Adapter for i18n
 * Supports: SAP S/4HANA, SAP ECC, SAP Business One
 */

const { I18n } = require('../../index');

class SAPI18nAdapter {
  constructor(config = {}) {
    this.sapConfig = {
      host: config.host || process.env.SAP_HOST,
      client: config.client || process.env.SAP_CLIENT,
      user: config.user || process.env.SAP_USER,
      password: config.password || process.env.SAP_PASSWORD,
      language: config.language || 'EN',
      ...config
    };

    this.i18n = new I18n({
      locales: config.locales || ['EN', 'DE', 'FR', 'ES', 'ZH', 'JA'],
      defaultLocale: 'EN',
      directory: config.directory || './locales',
      updateFiles: false,
      staticCatalog: config.staticCatalog || {},
      objectNotation: true
    });

    this.fieldMappings = config.fieldMappings || this.getDefaultFieldMappings();
  }

  getDefaultFieldMappings() {
    return {
      'MANDT': 'client',
      'SPRAS': 'language',
      'BTEXT': 'description',
      'LTEXT': 'longText',
      'STEXT': 'shortText'
    };
  }

  /**
   * Translate SAP text elements
   */
  async translateSAPText(textKey, sapLang = null) {
    const locale = this.mapSAPLanguageToLocale(sapLang || this.sapConfig.language);
    this.i18n.setLocale(locale);
    return this.i18n.__(textKey);
  }

  /**
   * Map SAP language codes to i18n locales
   */
  mapSAPLanguageToLocale(sapLang) {
    const mapping = {
      'E': 'EN', 'D': 'DE', 'F': 'FR', 'S': 'ES',
      'P': 'PT', 'I': 'IT', 'J': 'JA', '1': 'ZH',
      'K': 'KO', 'R': 'RU', 'A': 'AR', 'T': 'TR'
    };
    return mapping[sapLang] || mapping[sapLang.charAt(0)] || 'EN';
  }

  /**
   * Translate SAP table data
   */
  async translateTableData(tableName, data, textFields = []) {
    const translated = [];

    for (const row of data) {
      const translatedRow = { ...row };

      for (const field of textFields) {
        if (row[field]) {
          const key = `${tableName}.${field}.${row[field]}`;
          translatedRow[field] = await this.translateSAPText(key, row.SPRAS);
        }
      }

      translated.push(translatedRow);
    }

    return translated;
  }

  /**
   * Generate RFC-compatible locale bundle
   */
  generateRFCLocaleBundle(locale) {
    const catalog = this.i18n.getCatalog(locale);
    const rfcBundle = {};

    // Convert to SAP text table format
    Object.entries(catalog).forEach(([key, value]) => {
      const parts = key.split('.');
      const table = parts[0];
      const field = parts[1];

      if (!rfcBundle[table]) rfcBundle[table] = [];

      rfcBundle[table].push({
        SPRAS: this.mapLocaleToSAPLanguage(locale),
        FIELD: field,
        TEXT: value
      });
    });

    return rfcBundle;
  }

  mapLocaleToSAPLanguage(locale) {
    const mapping = {
      'EN': 'E', 'DE': 'D', 'FR': 'F', 'ES': 'S',
      'PT': 'P', 'IT': 'I', 'JA': 'J', 'ZH': '1',
      'KO': 'K', 'RU': 'R', 'AR': 'A', 'TR': 'T'
    };
    return mapping[locale.toUpperCase()] || 'E';
  }

  /**
   * Middleware for SAP Fiori applications
   */
  fioriMiddleware() {
    return async (req, res, next) => {
      // Detect SAP language from headers or session
      const sapLang = req.headers['sap-language'] ||
                     req.session?.sapLanguage ||
                     this.sapConfig.language;

      const locale = this.mapSAPLanguageToLocale(sapLang);
      this.i18n.setLocale(locale);

      // Bind to request
      req.i18n = this.i18n;
      req.__ = (...args) => this.i18n.__(...args);
      req.sapLocale = sapLang;

      // Add SAP-specific helpers
      req.translateSAPText = (key) => this.translateSAPText(key, sapLang);

      next();
    };
  }

  /**
   * Export translations to SAP text table format
   */
  exportToSAPTextTable(locale, tableName = 'ZI18N_TEXT') {
    const catalog = this.i18n.getCatalog(locale);
    const sapLang = this.mapLocaleToSAPLanguage(locale);

    const textTable = [];
    let lineNo = 0;

    Object.entries(catalog).forEach(([key, value]) => {
      textTable.push({
        MANDT: this.sapConfig.client,
        SPRAS: sapLang,
        TEXTKEY: key,
        LINENO: String(lineNo++).padStart(6, '0'),
        TEXT: value.substring(0, 255), // SAP max line length
        TABNAME: tableName
      });
    });

    return textTable;
  }
}

module.exports = { SAPI18nAdapter };
