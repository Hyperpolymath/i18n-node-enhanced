// DocumentExtract - Extract translatable text from documents
// Uses Pandoc for format conversion, Hunspell for spell checking
// SPDX-License-Identifier: AGPL-3.0-or-later

// Supported input formats
type inputFormat =
  | Markdown
  | HTML
  | DOCX
  | ODT
  | RST
  | LaTeX
  | EPUB
  | PDF  // via pdftotext fallback

// Extraction options
type options = {
  preserveFormatting: bool,
  extractComments: bool,
  ignoreCodeBlocks: bool,
}

// Default options
let defaultOptions: options

// Extract text from file using Pandoc (async via Deno.Command)
let extractFromFile: (~path: string, ~format: inputFormat, ~options: options) => promise<result<string, string>>

// Extract text from string content
let extractFromString: (~content: string, ~format: inputFormat, ~options: options) => promise<result<string, string>>

// Get Pandoc command for a format
let getPandocCommand: (~inputPath: string, ~format: inputFormat) => string

// === Hunspell Integration ===

// Spell check result
type spellResult = {
  word: string,
  suggestions: array<string>,
  isCorrect: bool,
}

// Check spelling of text (requires hunspell binary)
let spellCheck: (~text: string, ~locale: string) => promise<result<array<spellResult>, string>>

// Get Hunspell command
let getHunspellCommand: (~locale: string) => string

// === Tesseract OCR ===

// OCR options
type ocrOptions = {
  lang: string,      // e.g., "eng", "deu", "fra"
  psm: int,          // Page segmentation mode (default: 3)
  oem: int,          // OCR engine mode (default: 3)
}

let defaultOcrOptions: ocrOptions

// Extract text from image using Tesseract
let ocrFromFile: (~path: string, ~options: ocrOptions) => promise<result<string, string>>

// Get Tesseract command
let getTesseractCommand: (~inputPath: string, ~options: ocrOptions) => string
