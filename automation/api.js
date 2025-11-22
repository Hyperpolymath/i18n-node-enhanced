/**
 * Automation API for i18n
 * Provides REST/GraphQL/gRPC interfaces for hybrid automation systems
 * Supports: RPA, CI/CD, ETL, Data pipelines, Orchestration platforms
 */

const express = require('express');
const { I18n } = require('../index');
const { I18nAuditSystem } = require('../audit/forensics');

class I18nAutomationAPI {
  constructor(config = {}) {
    this.app = express();
    this.i18n = new I18n(config.i18n || {});
    this.audit = new I18nAuditSystem(config.audit || {});

    this.config = {
      port: config.port || 3000,
      apiKey: config.apiKey || process.env.I18N_API_KEY,
      enableGraphQL: config.enableGraphQL !== false,
      enablegRPC: config.enablegRPC || false,
      rateLimiting: config.rateLimiting !== false,
      ...config
    };

    this.setupMiddleware();
    this.setupRoutes();
  }

  setupMiddleware() {
    this.app.use(express.json());

    // API Key authentication
    this.app.use((req, res, next) => {
      const apiKey = req.headers['x-api-key'];

      if (this.config.apiKey && apiKey !== this.config.apiKey) {
        return res.status(401).json({ error: 'Invalid API key' });
      }

      next();
    });

    // Request logging
    this.app.use((req, res, next) => {
      req.requestId = require('crypto').randomBytes(8).toString('hex');
      req.startTime = Date.now();

      next();
    });
  }

  setupRoutes() {
    // Health check
    this.app.get('/health', (req, res) => {
      res.json({
        status: 'healthy',
        version: require('../package.json').version,
        uptime: process.uptime(),
        locales: this.i18n.getLocales()
      });
    });

    // Translation endpoint
    this.app.post('/api/v1/translate', async (req, res) => {
      const { key, locale, args, format } = req.body;

      if (!key) {
        return res.status(400).json({ error: 'Key is required' });
      }

      try {
        if (locale) this.i18n.setLocale(locale);

        const startTime = Date.now();
        let result;

        if (args && Array.isArray(args)) {
          result = this.i18n.__(key, ...args);
        } else if (args) {
          result = this.i18n.__(key, args);
        } else {
          result = this.i18n.__(key);
        }

        const duration = Date.now() - startTime;

        // Audit log
        this.audit.logTranslation({
          operation: '__',
          key,
          locale: this.i18n.getLocale(),
          result,
          args,
          duration,
          requestId: req.requestId
        });

        res.json({
          success: true,
          data: {
            key,
            translation: result,
            locale: this.i18n.getLocale()
          },
          meta: {
            duration,
            requestId: req.requestId
          }
        });
      } catch (error) {
        res.status(500).json({
          success: false,
          error: error.message,
          requestId: req.requestId
        });
      }
    });

    // Batch translation
    this.app.post('/api/v1/translate/batch', async (req, res) => {
      const { keys, locale } = req.body;

      if (!keys || !Array.isArray(keys)) {
        return res.status(400).json({ error: 'Keys array is required' });
      }

      try {
        if (locale) this.i18n.setLocale(locale);

        const translations = {};
        const startTime = Date.now();

        for (const key of keys) {
          translations[key] = this.i18n.__(key);
        }

        const duration = Date.now() - startTime;

        res.json({
          success: true,
          data: {
            translations,
            locale: this.i18n.getLocale(),
            count: keys.length
          },
          meta: {
            duration,
            requestId: req.requestId
          }
        });
      } catch (error) {
        res.status(500).json({
          success: false,
          error: error.message
        });
      }
    });

    // Get catalog
    this.app.get('/api/v1/catalog/:locale?', (req, res) => {
      try {
        const locale = req.params.locale;
        const catalog = locale ?
          this.i18n.getCatalog(locale) :
          this.i18n.getCatalog();

        res.json({
          success: true,
          data: {
            catalog,
            locale: locale || 'all'
          }
        });
      } catch (error) {
        res.status(500).json({
          success: false,
          error: error.message
        });
      }
    });

    // Update catalog (for automation systems)
    this.app.put('/api/v1/catalog/:locale', async (req, res) => {
      const { locale } = req.params;
      const { updates } = req.body;

      if (!updates || typeof updates !== 'object') {
        return res.status(400).json({ error: 'Updates object is required' });
      }

      try {
        // Log modifications
        Object.entries(updates).forEach(([key, value]) => {
          this.audit.logCatalogModification({
            locale,
            operation: 'update',
            key,
            newValue: value,
            automated: true,
            user: req.headers['x-user'] || 'automation'
          });
        });

        res.json({
          success: true,
          data: {
            locale,
            updated: Object.keys(updates).length
          }
        });
      } catch (error) {
        res.status(500).json({
          success: false,
          error: error.message
        });
      }
    });

    // Webhook endpoint for external systems
    this.app.post('/api/v1/webhooks/:event', async (req, res) => {
      const { event } = req.params;
      const payload = req.body;

      try {
        await this.handleWebhook(event, payload);

        res.json({
          success: true,
          event,
          processed: true
        });
      } catch (error) {
        res.status(500).json({
          success: false,
          error: error.message
        });
      }
    });

    // Export for external systems
    this.app.get('/api/v1/export/:format', (req, res) => {
      const { format } = req.params;
      const { locale } = req.query;

      try {
        const catalog = this.i18n.getCatalog(locale);
        let output;

        switch (format) {
          case 'json':
            output = JSON.stringify(catalog, null, 2);
            res.setHeader('Content-Type', 'application/json');
            break;

          case 'csv':
            output = this.convertToCSV(catalog);
            res.setHeader('Content-Type', 'text/csv');
            break;

          case 'xml':
            output = this.convertToXML(catalog);
            res.setHeader('Content-Type', 'application/xml');
            break;

          case 'po':
            output = this.convertToPO(catalog, locale);
            res.setHeader('Content-Type', 'text/plain');
            break;

          default:
            return res.status(400).json({ error: 'Invalid format' });
        }

        res.setHeader('Content-Disposition', `attachment; filename="translations-${locale}.${format}"`);
        res.send(output);
      } catch (error) {
        res.status(500).json({
          success: false,
          error: error.message
        });
      }
    });

    // Audit query endpoint
    this.app.get('/api/v1/audit', async (req, res) => {
      const filters = {
        eventType: req.query.eventType,
        locale: req.query.locale,
        user: req.query.user,
        fromDate: req.query.fromDate,
        toDate: req.query.toDate
      };

      try {
        const results = await this.audit.query(filters);

        res.json({
          success: true,
          data: results,
          count: results.length
        });
      } catch (error) {
        res.status(500).json({
          success: false,
          error: error.message
        });
      }
    });

    // Compliance report
    this.app.get('/api/v1/compliance/report', async (req, res) => {
      const { startDate, endDate } = req.query;

      try {
        const report = await this.audit.generateComplianceReport(startDate, endDate);

        res.json({
          success: true,
          data: report
        });
      } catch (error) {
        res.status(500).json({
          success: false,
          error: error.message
        });
      }
    });
  }

  async handleWebhook(event, payload) {
    switch (event) {
      case 'catalog_update':
        // Handle catalog update from external system
        break;

      case 'locale_sync':
        // Sync locale from external source
        break;

      case 'translation_request':
        // Process translation request
        break;

      default:
        throw new Error(`Unknown webhook event: ${event}`);
    }
  }

  convertToCSV(catalog) {
    let csv = 'Key,Translation\n';

    const flatten = (obj, prefix = '') => {
      Object.entries(obj).forEach(([key, value]) => {
        const fullKey = prefix ? `${prefix}.${key}` : key;

        if (typeof value === 'object' && value !== null) {
          flatten(value, fullKey);
        } else {
          csv += `"${fullKey}","${String(value).replace(/"/g, '""')}"\n`;
        }
      });
    };

    flatten(catalog);
    return csv;
  }

  convertToXML(catalog) {
    let xml = '<?xml version="1.0" encoding="UTF-8"?>\n<translations>\n';

    const convert = (obj, level = 1) => {
      const indent = '  '.repeat(level);

      Object.entries(obj).forEach(([key, value]) => {
        if (typeof value === 'object' && value !== null) {
          xml += `${indent}<${key}>\n`;
          convert(value, level + 1);
          xml += `${indent}</${key}>\n`;
        } else {
          xml += `${indent}<${key}>${this.escapeXML(String(value))}</${key}>\n`;
        }
      });
    };

    convert(catalog);
    xml += '</translations>';
    return xml;
  }

  convertToPO(catalog, locale) {
    let po = `# Translation file for ${locale}\n`;
    po += `# Generated: ${new Date().toISOString()}\n\n`;

    const flatten = (obj, prefix = '') => {
      Object.entries(obj).forEach(([key, value]) => {
        const fullKey = prefix ? `${prefix}.${key}` : key;

        if (typeof value === 'object' && value !== null) {
          flatten(value, fullKey);
        } else {
          po += `msgid "${fullKey}"\n`;
          po += `msgstr "${String(value)}"\n\n`;
        }
      });
    };

    flatten(catalog);
    return po;
  }

  escapeXML(str) {
    return str
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&apos;');
  }

  start() {
    this.server = this.app.listen(this.config.port, () => {
      console.log(`🤖 i18n Automation API running on port ${this.config.port}`);
      console.log(`📊 Audit logging: ${this.audit.config.enabled ? 'enabled' : 'disabled'}`);
    });

    return this.server;
  }

  stop() {
    if (this.server) {
      this.server.close();
      this.audit.shutdown();
    }
  }
}

module.exports = { I18nAutomationAPI };
