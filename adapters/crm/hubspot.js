/**
 * HubSpot CRM Integration Adapter
 * Supports: Content API, Email templates, Landing pages, CMS Hub
 */

const { I18n } = require('../../index');
const { I18nAuditSystem } = require('../../audit/forensics');

class HubSpotI18nAdapter {
  constructor(config = {}) {
    this.config = {
      apiKey: config.apiKey || process.env.HUBSPOT_API_KEY,
      accessToken: config.accessToken || process.env.HUBSPOT_ACCESS_TOKEN,
      portalId: config.portalId || process.env.HUBSPOT_PORTAL_ID,
      apiVersion: config.apiVersion || 'v3',
      locales: config.locales || ['en', 'de', 'fr', 'es', 'ja'],
      defaultLocale: config.defaultLocale || 'en',
      auditEnabled: config.auditEnabled !== false,
      ...config
    };

    this.i18n = new I18n(config.i18n || {});

    if (this.config.auditEnabled) {
      this.audit = new I18nAuditSystem({
        enabled: true,
        logDir: config.auditLogDir || './audit-logs/hubspot'
      });
    }

    // HubSpot language code mappings
    this.languageMapping = {
      'en-US': 'en', 'en-GB': 'en-gb', 'de-DE': 'de', 'fr-FR': 'fr',
      'es-ES': 'es', 'es-MX': 'es-mx', 'pt-BR': 'pt-br', 'it-IT': 'it',
      'ja-JP': 'ja', 'zh-CN': 'zh-cn', 'zh-TW': 'zh-tw', 'ko-KR': 'ko',
      'nl-NL': 'nl', 'pl-PL': 'pl', 'ru-RU': 'ru', 'sv-SE': 'sv'
    };
  }

  /**
   * Map HubSpot language to i18n locale
   */
  mapHubSpotLanguageToI18n(hubspotLang) {
    const reverseMapping = Object.entries(this.languageMapping)
      .reduce((acc, [i18nLocale, hubspotFormat]) => {
        acc[hubspotFormat] = i18nLocale;
        return acc;
      }, {});

    return reverseMapping[hubspotLang] || this.config.defaultLocale;
  }

  /**
   * Map i18n locale to HubSpot language
   */
  mapI18nLocaleToHubSpot(locale) {
    return this.languageMapping[locale] || 'en';
  }

  /**
   * Translate HubSpot landing page content
   */
  async translateLandingPage(page, locale) {
    this.i18n.setLocale(locale);
    const hubspotLang = this.mapI18nLocaleToHubSpot(locale);

    const translated = {
      id: page.id,
      language: hubspotLang,
      name: this.i18n.__(`pages.${page.id}.name`, { fallback: page.name }),
      htmlTitle: this.i18n.__(`pages.${page.id}.html_title`, {
        fallback: page.htmlTitle
      }),
      metaDescription: this.i18n.__(`pages.${page.id}.meta_description`, {
        fallback: page.metaDescription || ''
      }),
      widgets: page.widgets ? this.translateWidgets(page.widgets, page.id, locale) : {},
      translations: {}
    };

    if (this.audit) {
      this.audit.logTranslation({
        system: 'HubSpot Landing Page',
        operation: 'translateLandingPage',
        pageId: page.id,
        locale
      });
    }

    return translated;
  }

  /**
   * Translate HubSpot email template
   */
  async translateEmailTemplate(template, locale) {
    this.i18n.setLocale(locale);
    const hubspotLang = this.mapI18nLocaleToHubSpot(locale);

    const translated = {
      id: template.id,
      language: hubspotLang,
      name: this.i18n.__(`email.templates.${template.id}.name`, {
        fallback: template.name
      }),
      subject: this.i18n.__(`email.templates.${template.id}.subject`, {
        fallback: template.subject
      }),
      htmlBody: this.translateEmailBody(template.htmlBody, template.id),
      textBody: this.i18n.__(`email.templates.${template.id}.text_body`, {
        fallback: template.textBody || ''
      })
    };

    if (this.audit) {
      this.audit.logTranslation({
        system: 'HubSpot Email Template',
        operation: 'translateEmailTemplate',
        templateId: template.id,
        locale
      });
    }

    return translated;
  }

  /**
   * Translate email body with token replacement
   */
  translateEmailBody(htmlBody, templateId) {
    if (!htmlBody) return '';

    // Replace HubSpot tokens while preserving them
    let translated = htmlBody;

    // Extract text between tags and translate
    const textRegex = />([^<>{}]+)</g;

    translated = translated.replace(textRegex, (match, text) => {
      // Skip if text only contains tokens or whitespace
      if (!text.trim() || text.includes('{{') || text.includes('}}')) {
        return match;
      }

      const translationKey = `email.templates.${templateId}.content.${this.sanitizeKey(text)}`;
      const translatedText = this.i18n.__(translationKey, { fallback: text });

      return `>${translatedText}<`;
    });

    return translated;
  }

  /**
   * Translate HubSpot blog post
   */
  async translateBlogPost(post, locale) {
    this.i18n.setLocale(locale);
    const hubspotLang = this.mapI18nLocaleToHubSpot(locale);

    return {
      id: post.id,
      language: hubspotLang,
      name: this.i18n.__(`blog.posts.${post.id}.name`, {
        fallback: post.name
      }),
      htmlTitle: this.i18n.__(`blog.posts.${post.id}.html_title`, {
        fallback: post.htmlTitle
      }),
      postBody: this.i18n.__(`blog.posts.${post.id}.body`, {
        fallback: post.postBody
      }),
      postSummary: this.i18n.__(`blog.posts.${post.id}.summary`, {
        fallback: post.postSummary || ''
      }),
      metaDescription: this.i18n.__(`blog.posts.${post.id}.meta_description`, {
        fallback: post.metaDescription || ''
      }),
      tagList: post.tagList || []
    };
  }

  /**
   * Generate HubSpot CMS multi-language variant
   */
  generateCMSVariant(contentId, contentType, locale, originalContent) {
    this.i18n.setLocale(locale);
    const hubspotLang = this.mapI18nLocaleToHubSpot(locale);

    const variant = {
      language: hubspotLang,
      primaryLanguage: this.config.defaultLocale,
      masterId: contentId,
      translatedFromId: contentId
    };

    // Translate based on content type
    if (contentType === 'landing-page' || contentType === 'site-page') {
      variant.name = this.i18n.__(`${contentType}.${contentId}.name`, {
        fallback: originalContent.name
      });
      variant.htmlTitle = this.i18n__(`${contentType}.${contentId}.html_title`, {
        fallback: originalContent.htmlTitle
      });
    } else if (contentType === 'blog-post') {
      variant.name = this.i18n__(`blog.posts.${contentId}.name`, {
        fallback: originalContent.name
      });
      variant.postBody = this.i18n__(`blog.posts.${contentId}.body`, {
        fallback: originalContent.postBody
      });
    }

    if (this.audit) {
      this.audit.logEvent({
        eventType: 'export',
        system: 'HubSpot CMS',
        contentType,
        contentId,
        locale,
        format: 'CMS_Variant'
      });
    }

    return variant;
  }

  /**
   * Translate HubSpot form
   */
  translateForm(form, locale) {
    this.i18n.setLocale(locale);
    const hubspotLang = this.mapI18nLocaleToHubSpot(locale);

    return {
      guid: form.guid,
      language: hubspotLang,
      name: this.i18n.__(`forms.${form.guid}.name`, {
        fallback: form.name
      }),
      submitText: this.i18n.__(`forms.${form.guid}.submit_text`, {
        fallback: form.submitText
      }),
      formFieldGroups: form.formFieldGroups ? form.formFieldGroups.map(group => ({
        ...group,
        fields: group.fields.map(field => ({
          ...field,
          label: this.i18n.__(`forms.${form.guid}.fields.${field.name}.label`, {
            fallback: field.label
          }),
          placeholder: this.i18n.__(`forms.${form.guid}.fields.${field.name}.placeholder`, {
            fallback: field.placeholder || ''
          }),
          helpText: field.helpText ? this.i18n__(`forms.${form.guid}.fields.${field.name}.help_text`, {
            fallback: field.helpText
          }) : ''
        }))
      })) : []
    };
  }

  /**
   * Translate HubSpot CTA (Call-to-Action)
   */
  translateCTA(cta, locale) {
    this.i18n.setLocale(locale);
    const hubspotLang = this.mapI18nLocaleToHubSpot(locale);

    return {
      id: cta.id,
      language: hubspotLang,
      name: this.i18n.__(`ctas.${cta.id}.name`, {
        fallback: cta.name
      }),
      buttonText: this.i18n.__(`ctas.${cta.id}.button_text`, {
        fallback: cta.buttonText
      }),
      altText: this.i18n.__(`ctas.${cta.id}.alt_text`, {
        fallback: cta.altText || ''
      })
    };
  }

  /**
   * Translate HubSpot workflow emails
   */
  translateWorkflowEmail(workflowId, emailId, locale, emailData) {
    this.i18n.setLocale(locale);
    const hubspotLang = this.mapI18nLocaleToHubSpot(locale);

    return {
      workflowId,
      emailId,
      language: hubspotLang,
      subject: this.i18n.__(`workflows.${workflowId}.emails.${emailId}.subject`, {
        fallback: emailData.subject
      }),
      body: this.i18n__(`workflows.${workflowId}.emails.${emailId}.body`, {
        fallback: emailData.body
      }),
      preheader: emailData.preheader ? this.i18n__(`workflows.${workflowId}.emails.${emailId}.preheader`, {
        fallback: emailData.preheader
      }) : ''
    };
  }

  /**
   * Generate HubSpot API translation batch request
   */
  generateBatchTranslationRequest(items, itemType, locale) {
    const hubspotLang = this.mapI18nLocaleToHubSpot(locale);

    const inputs = items.map(item => {
      let translationMethod;

      switch (itemType) {
        case 'landing-page':
          translationMethod = this.translateLandingPage.bind(this);
          break;
        case 'email':
          translationMethod = this.translateEmailTemplate.bind(this);
          break;
        case 'blog-post':
          translationMethod = this.translateBlogPost.bind(this);
          break;
        default:
          throw new Error(`Unknown item type: ${itemType}`);
      }

      return translationMethod(item, locale);
    });

    return {
      inputs: inputs.map(input => ({
        id: input.id,
        properties: input
      }))
    };
  }

  /**
   * Translate widget content
   */
  translateWidgets(widgets, pageId, locale) {
    const translated = {};

    Object.entries(widgets).forEach(([widgetId, widget]) => {
      if (widget.body && widget.body.html) {
        translated[widgetId] = {
          ...widget,
          body: {
            ...widget.body,
            html: this.i18n.__(`pages.${pageId}.widgets.${widgetId}.html`, {
              fallback: widget.body.html
            })
          }
        };
      }
    });

    return translated;
  }

  /**
   * Export translations for HubSpot import
   */
  exportForHubSpotImport(locale, contentType) {
    const catalog = this.i18n.getCatalog(locale);
    const hubspotLang = this.mapI18nLocaleToHubSpot(locale);

    const exportData = {
      language: hubspotLang,
      contentType: contentType,
      translations: []
    };

    const prefix = contentType.replace('-', '.');

    Object.entries(catalog).forEach(([key, value]) => {
      if (key.startsWith(prefix)) {
        exportData.translations.push({
          key: key,
          value: value,
          context: contentType
        });
      }
    });

    return exportData;
  }

  /**
   * Express middleware for HubSpot webhook integrations
   */
  hubspotMiddleware() {
    return (req, res, next) => {
      // Detect locale from HubSpot contact or default
      const hubspotLang = req.body?.contact?.properties?.hs_language ||
                         req.query.language ||
                         this.config.defaultLocale;

      const locale = this.mapHubSpotLanguageToI18n(hubspotLang);
      this.i18n.setLocale(req, locale);

      // Add HubSpot-specific helpers
      req.hubspotLanguage = hubspotLang;
      req.translatePage = (page) => this.translateLandingPage(page, locale);
      req.translateEmail = (template) => this.translateEmailTemplate(template, locale);

      res.locals.hubspotLanguage = hubspotLang;
      res.locals.i18nLocale = locale;

      next();
    };
  }

  /**
   * Sanitize text for use as translation key
   */
  sanitizeKey(text) {
    return text
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, '_')
      .replace(/^_+|_+$/g, '')
      .substring(0, 50);
  }

  /**
   * Validate HubSpot payload
   */
  validateHubSpotPayload(payload, contentType) {
    const errors = [];

    if (!payload.language) {
      errors.push('Missing language');
    }

    if (contentType === 'landing-page' && !payload.name) {
      errors.push('Missing name for landing page');
    }

    if (contentType === 'email' && !payload.subject) {
      errors.push('Missing subject for email');
    }

    return {
      valid: errors.length === 0,
      errors
    };
  }
}

module.exports = { HubSpotI18nAdapter };
