# ReScript Bindings for i18n

Type-safe ReScript bindings for i18n with zero-cost abstractions.

## Installation

```bash
npm install @i18n/rescript-bindings i18n
```

## Configuration

Add to your `bsconfig.json`:

```json
{
  "bs-dependencies": ["@i18n/rescript-bindings"]
}
```

## Usage

### Basic Configuration

```rescript
open I18n

let config = I18nConfig.make(
  ~locales=["en", "de", "fr"],
  ~defaultLocale="en",
  ~directory="./locales",
  ~objectNotation=true,
  ()
)

let i18n = I18n.make(config)
```

### Simple Translation

```rescript
let greeting = i18n->I18n.__("Hello")
// => "Hello" or "Hallo" depending on locale
```

### Translation with Arguments

```rescript
let message = i18n->I18n.__WithArgs("Hello %s", ["World"])
// => "Hello World"
```

### Plural Forms

```rescript
let catMessage = i18n->I18n.__n("%s cat", "%s cats", 3)
// => "3 cats"
```

### MessageFormat

```rescript
let formatted = i18n->I18n.__mf(
  "{N, plural, one{# item} other{# items}}",
  Js.Dict.fromArray([("N", 5)])
)
// => "5 items"
```

### Locale Management

```rescript
// Set locale
let newLocale = i18n->I18n.setLocale("de")

// Get current locale
let current = i18n->I18n.getLocale()

// Get all available locales
let locales = i18n->I18n.getLocales()
```

### Get Translation Catalog

```rescript
// Get all catalogs
let allCatalogs = i18n->I18n.getCatalog()

// Get specific locale catalog
let deCatalog = i18n->I18n.getCatalogForLocale("de")
```

## Express Integration

```rescript
open I18n

let i18n = I18n.make(config)

// Use as middleware
let middleware = (req, res, next) => {
  i18n->I18n.init(req, res, next)
}
```

## Type Safety

ReScript provides compile-time type safety:

```rescript
// ✓ Correct
let msg = i18n->I18n.__("greeting")

// ✗ Compile error - wrong type
let msg = i18n->I18n.__(123)
```

## Advanced Patterns

### Pipe-first API

```rescript
let translation =
  i18n
  ->I18n.setLocale("de")
  ->I18n.__("Welcome")
```

### Pattern Matching

```rescript
let getGreeting = (locale: string): string => {
  switch locale {
  | "en" => i18n->I18n.__("Hello")
  | "de" => i18n->I18n.__("Hallo")
  | "fr" => i18n->I18n.__("Bonjour")
  | _ => i18n->I18n.__("Hello")
  }
}
```

### Option Handling

```rescript
let config = I18nConfig.make(
  ~locales=["en", "de"],
  ~cookie=Some("locale"),
  ~queryParameter=Some("lang"),
  ()
)
```

## Performance

ReScript bindings compile to zero-cost JavaScript with:
- No runtime overhead
- Inline function calls
- Dead code elimination
- Tree shaking support

## Best Practices

1. **Type Everything**: Leverage ReScript's type system
2. **Use Pipe-first**: More readable with `->` operator
3. **Pattern Match**: Handle all locale cases explicitly
4. **Immutability**: ReScript enforces immutability by default

## Examples

See `examples/` directory for:
- Basic usage
- Express integration
- React integration
- Advanced patterns

## License

MIT
