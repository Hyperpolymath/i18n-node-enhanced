/**
 * ServiceNow Integration Adapter
 * Supports: Translated Text records, UI Messages, Catalog items, Knowledge base
 */

const { I18n } = require('../../index');
const { I18nAuditSystem } = require('../../audit/forensics');

class ServiceNowI18nAdapter {
  constructor(config = {}) {
    this.config = {
      instance: config.instance || process.env.SERVICENOW_INSTANCE,
      username: config.username || process.env.SERVICENOW_USERNAME,
      password: config.password || process.env.SERVICENOW_PASSWORD,
      apiVersion: config.apiVersion || 'v1',
      locales: config.locales || ['en', 'de', 'fr', 'es', 'ja'],
      defaultLocale: config.defaultLocale || 'en',
      auditEnabled: config.auditEnabled !== false,
      ...config
    };

    this.i18n = new I18n(config.i18n || {});

    if (this.config.auditEnabled) {
      this.audit = new I18nAuditSystem({
        enabled: true,
        logDir: config.auditLogDir || './audit-logs/servicenow'
      });
    }

    // ServiceNow language code mappings
    this.languageMapping = {
      'en-US': 'en', 'en-GB': 'en_GB', 'de-DE': 'de', 'fr-FR': 'fr',
      'es-ES': 'es', 'es-MX': 'es_MX', 'pt-BR': 'pt_BR', 'it-IT': 'it',
      'ja-JP': 'ja', 'zh-CN': 'zh', 'ko-KR': 'ko', 'nl-NL': 'nl',
      'pl-PL': 'pl', 'ru-RU': 'ru', 'sv-SE': 'sv'
    };
  }

  /**
   * Map ServiceNow language to i18n locale
   */
  mapServiceNowLanguageToI18n(snowLang) {
    const reverseMapping = Object.entries(this.languageMapping)
      .reduce((acc, [i18nLocale, snowFormat]) => {
        acc[snowFormat] = i18nLocale;
        return acc;
      }, {});

    return reverseMapping[snowLang] || this.config.defaultLocale;
  }

  /**
   * Map i18n locale to ServiceNow language
   */
  mapI18nLocaleToServiceNow(locale) {
    return this.languageMapping[locale] || 'en';
  }

  /**
   * Generate ServiceNow UI Message (sys_ui_message) record
   */
  generateUIMessage(messageKey, locale, application = 'Global') {
    this.i18n.setLocale(locale);
    const snowLang = this.mapI18nLocaleToServiceNow(locale);

    const uiMessage = {
      key: messageKey,
      language: snowLang,
      message: this.i18n.__(messageKey),
      application: application,
      active: true
    };

    if (this.audit) {
      this.audit.logEvent({
        eventType: 'export',
        system: 'ServiceNow UI Message',
        locale,
        snowLang,
        messageKey
      });
    }

    return uiMessage;
  }

  /**
   * Generate ServiceNow Translated Text (sys_translated_text) record
   */
  generateTranslatedText(tableName, fieldName, value, locale, documentKey) {
    this.i18n.setLocale(locale);
    const snowLang = this.mapI18nLocaleToServiceNow(locale);

    const translationKey = `${tableName}.${fieldName}.${documentKey}`;
    const translatedValue = this.i18n.__(translationKey, { fallback: value });

    const translatedText = {
      tablename: tableName,
      fieldname: fieldName,
      language: snowLang,
      value: translatedValue,
      label: translatedValue,
      documentkey: documentKey
    };

    if (this.audit) {
      this.audit.logTranslation({
        system: 'ServiceNow Translated Text',
        operation: 'generateTranslatedText',
        tableName,
        fieldName,
        locale,
        documentKey
      });
    }

    return translatedText;
  }

  /**
   * Generate ServiceNow Catalog Item translation
   */
  generateCatalogItemTranslation(catalogItem, locale) {
    this.i18n.setLocale(locale);
    const snowLang = this.mapI18nLocaleToServiceNow(locale);

    return {
      sys_id: catalogItem.sys_id,
      language: snowLang,
      name: this.i18n.__(`catalog.items.${catalogItem.sys_id}.name`, {
        fallback: catalogItem.name
      }),
      short_description: this.i18n__(`catalog.items.${catalogItem.sys_id}.short_description`, {
        fallback: catalogItem.short_description
      }),
      description: this.i18n__(`catalog.items.${catalogItem.sys_id}.description`, {
        fallback: catalogItem.description
      }),
      delivery_plan: this.i18n__(`catalog.items.${catalogItem.sys_id}.delivery_plan`, {
        fallback: catalogItem.delivery_plan || ''
      })
    };
  }

  /**
   * Generate ServiceNow Knowledge Article translation
   */
  generateKnowledgeArticleTranslation(article, locale) {
    this.i18n.setLocale(locale);
    const snowLang = this.mapI18nLocaleToServiceNow(locale);

    return {
      sys_id: article.sys_id,
      language: snowLang,
      short_description: this.i18n__(`knowledge.${article.number}.short_description`, {
        fallback: article.short_description
      }),
      text: this.i18n__(`knowledge.${article.number}.text`, {
        fallback: article.text
      }),
      topic: this.i18n__(`knowledge.${article.number}.topic`, {
        fallback: article.topic || ''
      }),
      article_type: article.article_type,
      workflow_state: article.workflow_state
    };
  }

  /**
   * Generate ServiceNow Portal Widget translation
   */
  generatePortalWidgetTranslation(widgetId, locale, widgetData) {
    this.i18n.setLocale(locale);
    const snowLang = this.mapI18nLocaleToServiceNow(locale);

    return {
      widget_id: widgetId,
      language: snowLang,
      name: this.i18n.__(`portal.widgets.${widgetId}.name`, {
        fallback: widgetData.name
      }),
      description: this.i18n__(`portal.widgets.${widgetId}.description`, {
        fallback: widgetData.description
      }),
      option_schema: widgetData.option_schema ? JSON.stringify(
        this.translateWidgetOptions(widgetData.option_schema, widgetId)
      ) : ''
    };
  }

  /**
   * Translate widget option schema
   */
  translateWidgetOptions(optionSchema, widgetId) {
    try {
      const schema = typeof optionSchema === 'string' ?
        JSON.parse(optionSchema) : optionSchema;

      if (Array.isArray(schema)) {
        return schema.map(option => ({
          ...option,
          label: this.i18n.__(`portal.widgets.${widgetId}.options.${option.name}.label`, {
            fallback: option.label
          }),
          hint: option.hint ? this.i18n.__(`portal.widgets.${widgetId}.options.${option.name}.hint`, {
            fallback: option.hint
          }) : undefined
        }));
      }

      return schema;
    } catch (e) {
      return optionSchema;
    }
  }

  /**
   * Generate ServiceNow Update Set for translations
   */
  generateUpdateSet(locale, translationType, records) {
    const snowLang = this.mapI18nLocaleToServiceNow(locale);

    const updateSet = {
      name: `i18n_translations_${snowLang}_${translationType}_${Date.now()}`,
      description: `Translation update set for ${locale} (${translationType})`,
      state: 'build',
      release_date: new Date().toISOString(),
      application: 'Global',
      updates: records.map((record, index) => ({
        name: `${translationType}_${index}`,
        action: 'INSERT_OR_UPDATE',
        type: translationType,
        target_name: translationType,
        payload: record
      }))
    };

    if (this.audit) {
      this.audit.logEvent({
        eventType: 'export',
        system: 'ServiceNow Update Set',
        locale,
        translationType,
        recordCount: records.length
      });
    }

    return updateSet;
  }

  /**
   * Export UI Messages for bulk import
   */
  exportUIMessagesForImport(locale) {
    const catalog = this.i18n.getCatalog(locale);
    const snowLang = this.mapI18nLocaleToServiceNow(locale);

    const uiMessages = [];

    const flatten = (obj, prefix = '') => {
      Object.entries(obj).forEach(([key, value]) => {
        const fullKey = prefix ? `${prefix}.${key}` : key;

        if (typeof value === 'object' && value !== null && !Array.isArray(value)) {
          flatten(value, fullKey);
        } else {
          uiMessages.push({
            key: fullKey,
            language: snowLang,
            message: String(value),
            application: 'Global',
            active: 'true'
          });
        }
      });
    };

    flatten(catalog);

    return uiMessages;
  }

  /**
   * Generate ServiceNow Import Set payload
   */
  generateImportSetPayload(locale, tableName, stagingTable, records) {
    const snowLang = this.mapI18nLocaleToServiceNow(locale);

    return {
      u_import_set_id: require('crypto').randomBytes(16).toString('hex'),
      u_staging_table: stagingTable,
      u_target_table: tableName,
      u_language: snowLang,
      u_records: records.map(record => ({
        ...record,
        u_action: 'INSERT_OR_UPDATE',
        u_language: snowLang
      }))
    };
  }

  /**
   * Translate ServiceNow Form Section
   */
  translateFormSection(formName, sectionName, locale) {
    this.i18n.setLocale(locale);

    return {
      form: formName,
      section: sectionName,
      caption: this.i18n.__(`forms.${formName}.sections.${sectionName}.caption`),
      language: this.mapI18nLocaleToServiceNow(locale)
    };
  }

  /**
   * Batch translate ServiceNow table records
   */
  async batchTranslateTableRecords(tableName, records, locale, fieldsToTranslate) {
    this.i18n.setLocale(locale);
    const snowLang = this.mapI18nLocaleToServiceNow(locale);

    const translatedRecords = records.map(record => {
      const translated = { ...record, language: snowLang };

      fieldsToTranslate.forEach(field => {
        const translationKey = `${tableName}.${record.sys_id}.${field}`;
        translated[field] = this.i18n.__(translationKey, {
          fallback: record[field]
        });
      });

      return translated;
    });

    if (this.audit) {
      this.audit.logEvent({
        eventType: 'batch_translation',
        system: 'ServiceNow',
        tableName,
        locale,
        recordCount: records.length,
        fieldsTranslated: fieldsToTranslate.length
      });
    }

    return translatedRecords;
  }

  /**
   * Import translations from ServiceNow XML export
   */
  async importFromServiceNowXML(xmlContent, locale) {
    // Note: In production, use a proper XML parser
    const updates = {};

    // Simplified XML parsing (use xml2js or similar in production)
    const messageRegex = /<key>([^<]+)<\/key>[\s\S]*?<message>([^<]+)<\/message>/g;
    let match;

    while ((match = messageRegex.exec(xmlContent)) !== null) {
      const key = match[1];
      const message = match[2];
      updates[key] = message;
    }

    if (this.audit) {
      this.audit.logCatalogModification({
        locale,
        operation: 'import',
        source: 'ServiceNow XML',
        keysUpdated: Object.keys(updates).length
      });
    }

    return {
      locale,
      imported: Object.keys(updates).length,
      updates
    };
  }

  /**
   * Express middleware for ServiceNow integrations
   */
  serviceNowMiddleware() {
    return (req, res, next) => {
      // Detect locale from ServiceNow user session or header
      const snowLang = req.headers['x-userpreferences'] ?
        this.parseUserPreferences(req.headers['x-userpreferences']).language :
        (req.query.sysparm_language || this.config.defaultLocale);

      const locale = this.mapServiceNowLanguageToI18n(snowLang);
      this.i18n.setLocale(req, locale);

      // Add ServiceNow-specific helpers
      req.snowLanguage = snowLang;
      req.generateUIMessage = (key, app) =>
        this.generateUIMessage(key, locale, app);
      req.generateTranslatedText = (table, field, value, docKey) =>
        this.generateTranslatedText(table, field, value, locale, docKey);

      res.locals.snowLanguage = snowLang;
      res.locals.i18nLocale = locale;

      next();
    };
  }

  /**
   * Parse ServiceNow user preferences header
   */
  parseUserPreferences(userPrefsHeader) {
    try {
      return JSON.parse(userPrefsHeader);
    } catch (e) {
      return { language: this.config.defaultLocale };
    }
  }

  /**
   * Validate ServiceNow payload
   */
  validateServiceNowPayload(payload, type) {
    const errors = [];

    if (!payload.language) {
      errors.push('Missing language');
    }

    if (type === 'ui_message' && !payload.key) {
      errors.push('Missing key for UI Message');
    }

    if (type === 'translated_text') {
      if (!payload.tablename) errors.push('Missing tablename');
      if (!payload.fieldname) errors.push('Missing fieldname');
      if (!payload.documentkey) errors.push('Missing documentkey');
    }

    return {
      valid: errors.length === 0,
      errors
    };
  }
}

module.exports = { ServiceNowI18nAdapter };
