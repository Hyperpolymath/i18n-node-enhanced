// Stemmer - Word root extraction for translation memory
// SPDX-License-Identifier: AGPL-3.0-or-later

// Supported stemming locales
type locale =
  | English
  | German
  | French
  | Spanish
  | Italian
  | Portuguese
  | Dutch
  | Russian

// Stemmer configuration
type t

// Create stemmer for a locale
let make: locale => t

// Create stemmer from locale string (falls back to English)
let fromString: string => t

// Stem a single word
let stem: (t, string) => string

// Stem multiple words
let stemWords: (t, array<string>) => array<string>

// Stem all words in text (preserves non-words)
let stemText: (t, string) => string

// Get supported locales
let supportedLocales: array<string>
