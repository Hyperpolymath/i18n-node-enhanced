# i18n.ncl - Type-safe configuration for i18n-node-enhanced
#
# Nickel is a configuration language that provides:
# - Type contracts for validation
# - Merging and composition
# - Programmable configurations
#
# Usage:
#   nickel export config/i18n.ncl > config.json
#   nickel check config/i18n.ncl

# =============================================================================
# Type Contracts
# =============================================================================

let LocaleCode = std.contract.from_predicate (fun s =>
  std.string.length s >= 2 && std.string.length s <= 10
) in

let PositiveInt = std.contract.from_predicate (fun n =>
  std.is_number n && n > 0
) in

let Directory = std.contract.from_predicate (fun s =>
  std.is_string s && std.string.length s > 0
) in

# =============================================================================
# Schema Definitions
# =============================================================================

let CacheConfig = {
  enabled | Bool | default = true,
  maxSize | PositiveInt | default = 1000,
  ttl | PositiveInt | default = 3600,
  strategy | [| 'lru, 'fifo, 'lfu |] | default = 'lru,
} in

let WasmConfig = {
  enabled | Bool | default = false,
  module | String | default = "i18n_wasm",
  features | Array String | default = ["plural", "interpolate"],
} in

let ValidationConfig = {
  strict | Bool | default = false,
  allowMissingKeys | Bool | default = true,
  reportLevel | [| 'error, 'warn, 'info, 'debug |] | default = 'warn,
  maxKeyLength | PositiveInt | default = 256,
  allowedCharacters | String | default = "a-zA-Z0-9._-",
} in

let LoggingConfig = {
  enabled | Bool | default = true,
  level | [| 'error, 'warn, 'info, 'debug, 'trace |] | default = 'info,
  format | [| 'json, 'text, 'pretty |] | default = 'text,
  destination | [| 'stdout, 'stderr, 'file |] | default = 'stderr,
  file | String | optional,
} in

let CatalogConfig = {
  directory | Directory | default = "./locales",
  extension | String | default = ".json",
  prefix | String | default = "",
  parser | [| 'json, 'yaml, 'toml |] | default = 'json,
  autoReload | Bool | default = false,
  syncFiles | Bool | default = false,
  updateFiles | Bool | default = true,
  indent | String | default = "\t",
} in

let HttpConfig = {
  header | String | default = "accept-language",
  cookie | String | default = "locale",
  queryParameter | String | default = "lang",
  sessionKey | String | default = "locale",
} in

let RuntimeConfig = {
  wasm | WasmConfig | default = {},
  cache | CacheConfig | default = {},
  workers | PositiveInt | optional,
  timeout | PositiveInt | default = 5000,
} in

let I18nConfig = {
  # Core settings
  locales | Array LocaleCode | default = ["en"],
  defaultLocale | LocaleCode | default = "en",
  fallbacks | { _ : LocaleCode } | default = {},

  # Feature flags
  objectNotation | Bool | default = false,
  retryInDefaultLocale | Bool | default = false,
  preserveLegacyCase | Bool | default = true,

  # Mustache configuration
  mustacheConfig | { tags : Array String } | default = { tags = ["{{", "}}"] },

  # Sub-configurations
  catalog | CatalogConfig | default = {},
  http | HttpConfig | default = {},
  validation | ValidationConfig | default = {},
  logging | LoggingConfig | default = {},
  runtime | RuntimeConfig | default = {},

  # API customization
  api | { _ : String } | default = {
    "__" = "t",
    "__n" = "tn",
    "__l" = "tl",
    "__h" = "th",
    "__mf" = "tmf",
  },
} in

# =============================================================================
# Environment-specific Configurations
# =============================================================================

let development = {
  locales = ["en", "de", "fr"],
  defaultLocale = "en",
  catalog = {
    autoReload = true,
    updateFiles = true,
    syncFiles = true,
  },
  validation = {
    strict = false,
    reportLevel = 'debug,
  },
  logging = {
    level = 'debug,
    format = 'pretty,
  },
  runtime = {
    wasm = { enabled = false },
  },
} in

let production = {
  locales = ["en", "de", "fr", "es", "it", "pt", "nl", "ru", "ja", "zh"],
  defaultLocale = "en",
  catalog = {
    autoReload = false,
    updateFiles = false,
    syncFiles = false,
  },
  validation = {
    strict = true,
    reportLevel = 'error,
  },
  logging = {
    level = 'warn,
    format = 'json,
  },
  runtime = {
    wasm = { enabled = true },
    cache = {
      enabled = true,
      maxSize = 10000,
      ttl = 86400,
    },
  },
} in

let staging = production & {
  validation = {
    strict = true,
    reportLevel = 'warn,
  },
  logging = {
    level = 'info,
  },
} in

let test = {
  locales = ["en", "de"],
  defaultLocale = "en",
  catalog = {
    directory = "./test/locales",
    autoReload = false,
    updateFiles = false,
  },
  validation = {
    strict = true,
    allowMissingKeys = false,
  },
  logging = {
    enabled = false,
  },
} in

# =============================================================================
# Combinatorial Configuration Generator
# =============================================================================

let allLocales = ["en", "de", "fr", "es", "it", "pt", "nl", "ru", "ja", "zh", "ko", "ar"] in

let generateFallbacks = fun locales =>
  locales
  |> std.array.filter (fun l => l != "en")
  |> std.array.fold_left (fun acc l => acc & { "%{l}" = "en" }) {}
in

let withAllLocales = fun config =>
  config & {
    locales = allLocales,
    fallbacks = generateFallbacks allLocales,
  }
in

let withCache = fun config size ttl =>
  config & {
    runtime = config.runtime & {
      cache = {
        enabled = true,
        maxSize = size,
        ttl = ttl,
      },
    },
  }
in

let withWasm = fun config =>
  config & {
    runtime = config.runtime & {
      wasm = { enabled = true, features = ["plural", "interpolate", "validate"] },
    },
  }
in

let withStrictValidation = fun config =>
  config & {
    validation = {
      strict = true,
      allowMissingKeys = false,
      reportLevel = 'error,
    },
  }
in

# =============================================================================
# Framework-specific Presets
# =============================================================================

let express = development & {
  http = {
    header = "accept-language",
    cookie = "locale",
    queryParameter = "lang",
  },
} in

let nestjs = development & {
  http = {
    header = "accept-language",
    cookie = "i18n_locale",
  },
  objectNotation = true,
} in

let deno = development & {
  catalog = {
    parser = 'json,
    directory = "./locales",
  },
  runtime = {
    wasm = { enabled = true },
  },
} in

let serverless = production & {
  catalog = {
    autoReload = false,
    updateFiles = false,
  },
  runtime = {
    cache = {
      enabled = true,
      maxSize = 100,
      ttl = 300,
    },
  },
} in

# =============================================================================
# Exports
# =============================================================================

{
  # Type contracts
  Config = I18nConfig,
  LocaleCode = LocaleCode,

  # Environment configurations
  environments = {
    development = development & I18nConfig,
    production = production & I18nConfig,
    staging = staging & I18nConfig,
    test = test & I18nConfig,
  },

  # Framework presets
  presets = {
    express = express & I18nConfig,
    nestjs = nestjs & I18nConfig,
    deno = deno & I18nConfig,
    serverless = serverless & I18nConfig,
  },

  # Utility functions
  utils = {
    withAllLocales = withAllLocales,
    withCache = withCache,
    withWasm = withWasm,
    withStrictValidation = withStrictValidation,
    generateFallbacks = generateFallbacks,
  },

  # Default configuration (development)
  default = development & I18nConfig,
}
