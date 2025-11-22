/**
 * Comprehensive Audit and Forensics System for i18n
 * Tracks all translation operations for compliance and debugging
 */

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

class I18nAuditSystem {
  constructor(config = {}) {
    this.config = {
      enabled: config.enabled !== false,
      logDir: config.logDir || './audit-logs',
      retention: config.retention || 90, // days
      compression: config.compression !== false,
      encryption: config.encryption || false,
      encryptionKey: config.encryptionKey,
      realtime: config.realtime !== false,
      ...config
    };

    this.sessionId = this.generateSessionId();
    this.buffer = [];
    this.bufferSize = 1000;

    if (this.config.enabled) {
      this.initializeAuditLog();
    }
  }

  generateSessionId() {
    return `${Date.now()}-${crypto.randomBytes(8).toString('hex')}`;
  }

  /**
   * Initialize audit log infrastructure
   */
  initializeAuditLog() {
    if (!fs.existsSync(this.config.logDir)) {
      fs.mkdirSync(this.config.logDir, { recursive: true });
    }

    // Create session log file
    this.currentLogFile = path.join(
      this.config.logDir,
      `audit-${new Date().toISOString().split('T')[0]}.jsonl`
    );

    // Start buffer flush interval
    if (this.config.realtime) {
      this.flushInterval = setInterval(() => this.flush(), 5000);
    }
  }

  /**
   * Log translation operation
   */
  logTranslation(event) {
    if (!this.config.enabled) return;

    const auditEntry = {
      timestamp: new Date().toISOString(),
      sessionId: this.sessionId,
      eventType: 'translation',
      operation: event.operation || '__',
      key: event.key,
      locale: event.locale,
      result: event.result,
      args: event.args,
      user: event.user || 'system',
      ip: event.ip,
      userAgent: event.userAgent,
      requestId: event.requestId,
      performance: {
        duration: event.duration,
        cacheHit: event.cacheHit
      }
    };

    this.writeAuditEntry(auditEntry);
  }

  /**
   * Log locale change
   */
  logLocaleChange(event) {
    if (!this.config.enabled) return;

    const auditEntry = {
      timestamp: new Date().toISOString(),
      sessionId: this.sessionId,
      eventType: 'locale_change',
      fromLocale: event.from,
      toLocale: event.to,
      user: event.user || 'system',
      ip: event.ip,
      reason: event.reason
    };

    this.writeAuditEntry(auditEntry);
  }

  /**
   * Log catalog modification
   */
  logCatalogModification(event) {
    if (!this.config.enabled) return;

    const auditEntry = {
      timestamp: new Date().toISOString(),
      sessionId: this.sessionId,
      eventType: 'catalog_modification',
      locale: event.locale,
      operation: event.operation, // 'add', 'update', 'delete'
      key: event.key,
      oldValue: event.oldValue,
      newValue: event.newValue,
      user: event.user || 'system',
      automated: event.automated || false
    };

    this.writeAuditEntry(auditEntry);
  }

  /**
   * Log security event
   */
  logSecurityEvent(event) {
    if (!this.config.enabled) return;

    const auditEntry = {
      timestamp: new Date().toISOString(),
      sessionId: this.sessionId,
      eventType: 'security',
      severity: event.severity, // 'low', 'medium', 'high', 'critical'
      type: event.type, // 'injection_attempt', 'xss_attempt', 'path_traversal'
      details: event.details,
      user: event.user,
      ip: event.ip,
      blocked: event.blocked || true,
      evidence: event.evidence
    };

    this.writeAuditEntry(auditEntry);

    // Immediate flush for security events
    if (event.severity === 'high' || event.severity === 'critical') {
      this.flush();
    }
  }

  /**
   * Write audit entry to buffer/file
   */
  writeAuditEntry(entry) {
    // Add checksum for integrity
    entry.checksum = this.calculateChecksum(entry);

    // Encrypt if enabled
    if (this.config.encryption && this.config.encryptionKey) {
      entry = this.encryptEntry(entry);
    }

    this.buffer.push(entry);

    // Flush if buffer full
    if (this.buffer.length >= this.bufferSize) {
      this.flush();
    }
  }

  /**
   * Flush buffer to disk
   */
  flush() {
    if (this.buffer.length === 0) return;

    const entries = this.buffer.splice(0);
    const lines = entries.map(e => JSON.stringify(e)).join('\n') + '\n';

    fs.appendFileSync(this.currentLogFile, lines, 'utf8');

    // Rotate log if needed
    this.rotateLogIfNeeded();
  }

  /**
   * Calculate checksum for integrity verification
   */
  calculateChecksum(entry) {
    const data = JSON.stringify({
      timestamp: entry.timestamp,
      eventType: entry.eventType,
      key: entry.key,
      locale: entry.locale
    });

    return crypto.createHash('sha256').update(data).digest('hex');
  }

  /**
   * Encrypt audit entry
   */
  encryptEntry(entry) {
    const iv = crypto.randomBytes(16);
    const cipher = crypto.createCipheriv(
      'aes-256-gcm',
      Buffer.from(this.config.encryptionKey, 'hex'),
      iv
    );

    const encrypted = Buffer.concat([
      cipher.update(JSON.stringify(entry), 'utf8'),
      cipher.final()
    ]);

    const authTag = cipher.getAuthTag();

    return {
      encrypted: true,
      iv: iv.toString('hex'),
      authTag: authTag.toString('hex'),
      data: encrypted.toString('hex')
    };
  }

  /**
   * Query audit logs
   */
  async query(filters = {}) {
    const results = [];
    const files = this.getAuditLogFiles();

    for (const file of files) {
      const lines = fs.readFileSync(file, 'utf8').split('\n').filter(Boolean);

      for (const line of lines) {
        const entry = JSON.parse(line);

        // Decrypt if needed
        if (entry.encrypted) {
          continue; // Skip encrypted entries in basic query
        }

        // Apply filters
        if (this.matchesFilters(entry, filters)) {
          results.push(entry);
        }
      }
    }

    return results;
  }

  matchesFilters(entry, filters) {
    if (filters.eventType && entry.eventType !== filters.eventType) return false;
    if (filters.locale && entry.locale !== filters.locale) return false;
    if (filters.user && entry.user !== filters.user) return false;
    if (filters.fromDate && new Date(entry.timestamp) < new Date(filters.fromDate)) return false;
    if (filters.toDate && new Date(entry.timestamp) > new Date(filters.toDate)) return false;

    return true;
  }

  /**
   * Generate compliance report
   */
  async generateComplianceReport(startDate, endDate) {
    const entries = await this.query({
      fromDate: startDate,
      toDate: endDate
    });

    const report = {
      period: { start: startDate, end: endDate },
      summary: {
        totalEvents: entries.length,
        translationOperations: 0,
        localeChanges: 0,
        catalogModifications: 0,
        securityEvents: 0
      },
      byEventType: {},
      byLocale: {},
      byUser: {},
      securityIncidents: [],
      integrityVerification: {
        total: entries.length,
        verified: 0,
        failed: 0
      }
    };

    entries.forEach(entry => {
      // Count by event type
      report.byEventType[entry.eventType] = (report.byEventType[entry.eventType] || 0) + 1;

      // Count by locale
      if (entry.locale) {
        report.byLocale[entry.locale] = (report.byLocale[entry.locale] || 0) + 1;
      }

      // Count by user
      if (entry.user) {
        report.byUser[entry.user] = (report.byUser[entry.user] || 0) + 1;
      }

      // Collect security incidents
      if (entry.eventType === 'security') {
        report.summary.securityEvents++;
        if (entry.severity === 'high' || entry.severity === 'critical') {
          report.securityIncidents.push(entry);
        }
      }

      // Verify integrity
      const expectedChecksum = this.calculateChecksum(entry);
      if (entry.checksum === expectedChecksum) {
        report.integrityVerification.verified++;
      } else {
        report.integrityVerification.failed++;
      }
    });

    return report;
  }

  /**
   * Rotate log files
   */
  rotateLogIfNeeded() {
    const stats = fs.statSync(this.currentLogFile);
    const maxSize = 100 * 1024 * 1024; // 100MB

    if (stats.size > maxSize) {
      const timestamp = Date.now();
      const rotatedFile = this.currentLogFile.replace('.jsonl', `-${timestamp}.jsonl`);

      fs.renameSync(this.currentLogFile, rotatedFile);

      if (this.config.compression) {
        // Compress rotated file
        this.compressLogFile(rotatedFile);
      }
    }
  }

  compressLogFile(file) {
    // Placeholder for compression logic
  }

  getAuditLogFiles() {
    return fs.readdirSync(this.config.logDir)
      .filter(f => f.startsWith('audit-') && f.endsWith('.jsonl'))
      .map(f => path.join(this.config.logDir, f));
  }

  /**
   * Cleanup old logs based on retention policy
   */
  cleanup() {
    const files = this.getAuditLogFiles();
    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - this.config.retention);

    files.forEach(file => {
      const stats = fs.statSync(file);
      if (stats.mtime < cutoffDate) {
        fs.unlinkSync(file);
      }
    });
  }

  /**
   * Shutdown audit system gracefully
   */
  shutdown() {
    if (this.flushInterval) {
      clearInterval(this.flushInterval);
    }

    this.flush();
  }
}

module.exports = { I18nAuditSystem };
