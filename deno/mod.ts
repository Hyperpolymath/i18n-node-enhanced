/**
 * Deno module for i18n
 * ESM-first, TypeScript-free, WASM-ready
 */

// Import from npm: for Node.js compatibility
import { createRequire } from "https://deno.land/std@0.208.0/node/module.ts";
const require = createRequire(import.meta.url);

// Re-export I18n class
export const { I18n } = require("../../index.js");

// Deno-specific utilities
export class DenoI18n {
  private i18n: any;
  private config: any;

  constructor(config: any) {
    this.config = config;
    this.i18n = new I18n(config);
  }

  /**
   * Load locale files from Deno's file system
   */
  async loadLocalesFromDeno(directory: string): Promise<void> {
    const locales: Record<string, any> = {};

    for await (const entry of Deno.readDir(directory)) {
      if (entry.isFile && entry.name.endsWith(".json")) {
        const locale = entry.name.replace(".json", "");
        const content = await Deno.readTextFile(`${directory}/${entry.name}`);
        locales[locale] = JSON.parse(content);
      }
    }

    this.config.staticCatalog = locales;
    this.i18n.configure(this.config);
  }

  /**
   * Deno HTTP middleware
   */
  middleware() {
    return async (ctx: any, next: () => Promise<void>) => {
      // Detect locale from headers, cookies, or query
      const locale =
        ctx.request.url.searchParams.get(this.config.queryParameter) ||
        ctx.cookies.get(this.config.cookie) ||
        ctx.request.headers.get(this.config.header)?.split(",")[0] ||
        this.config.defaultLocale;

      // Set locale on context
      ctx.i18n = this.i18n;
      ctx.locale = locale;
      ctx.__ = (...args: any[]) => this.i18n.__(...args);
      ctx.__n = (...args: any[]) => this.i18n.__n(...args);
      ctx.__mf = (...args: any[]) => this.i18n.__mf(...args);
      ctx.setLocale = (loc: string) => this.i18n.setLocale(loc);
      ctx.getLocale = () => this.i18n.getLocale();

      await next();
    };
  }

  /**
   * Get underlying i18n instance
   */
  getInstance() {
    return this.i18n;
  }
}

// Export convenience functions
export function createI18n(config: any): DenoI18n {
  return new DenoI18n(config);
}

export default {
  I18n,
  DenoI18n,
  createI18n,
};
