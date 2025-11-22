/**
 * Oak (Deno) example with i18n
 */

import { Application, Router } from "https://deno.land/x/oak@v12.6.1/mod.ts";
import { createI18n } from "../mod.ts";

const app = new Application();
const router = new Router();

// Create i18n instance
const i18n = createI18n({
  locales: ["en", "de", "fr", "es"],
  defaultLocale: "en",
  queryParameter: "lang",
  cookie: "locale",
  header: "accept-language",
});

// Load locales from file system
await i18n.loadLocalesFromDeno("./locales");

// Add i18n middleware
app.use(i18n.middleware());

// Routes
router.get("/", (ctx) => {
  const welcome = ctx.__("welcome");
  const description = ctx.__("description");

  ctx.response.body = {
    welcome,
    description,
    locale: ctx.getLocale(),
    availableLocales: ["en", "de", "fr", "es"],
  };
});

router.get("/locale/:locale", (ctx) => {
  const locale = ctx.params.locale;
  ctx.setLocale(locale);
  ctx.cookies.set("locale", locale, { httpOnly: true });

  ctx.response.body = {
    success: true,
    locale: ctx.getLocale(),
  };
});

router.get("/translate/:key", (ctx) => {
  const key = ctx.params.key;
  const translation = ctx.__(key);

  ctx.response.body = {
    key,
    translation,
    locale: ctx.getLocale(),
  };
});

app.use(router.routes());
app.use(router.allowedMethods());

console.log("🦕 Deno i18n server running on http://localhost:8000");
await app.listen({ port: 8000 });
