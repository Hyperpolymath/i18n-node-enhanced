@@ocaml.doc("
  polyglot-i18n - ReScript-first internationalization for Deno

  Usage:
    import { I18n, Locale, Catalog, Plural, RelativeTime, FuzzyMatch, Stemmer, Segmenter } from \"polyglot-i18n\"

    let i18n = I18n.fromBuilder(
      I18n.Config.make()
      ->I18n.Config.withLocales([\"en\", \"de\", \"fr\"])
      ->I18n.Config.withDefaultLocale(\"en\")
      ->I18n.Config.withObjectNotation(true)
    )

    // Relative time formatting
    let rtf = RelativeTime.make(Locale.fromString(\"en\")->Option.getOr(Locale.defaultLocale))
    rtf->RelativeTime.format(-86400.0)  // \"yesterday\" or \"1 day ago\"

    // Fuzzy matching for translation memory
    let matcher = FuzzyMatch.make()->FuzzyMatch.withThreshold(0.7)
    matcher->FuzzyMatch.findMatches(~query=\"hello\", ~corpus=[\"hallo\", \"help\", \"world\"])

    // Stemming for better fuzzy matches
    let stemmer = Stemmer.make(Stemmer.English)
    stemmer->Stemmer.stem(\"running\")  // \"run\"

    // Text segmentation
    let seg = Segmenter.fromString(\"en\")
    seg->Segmenter.segmentSentences(\"Hello. World!\")  // [\"Hello.\", \"World!\"]

  SPDX-License-Identifier: AGPL-3.0-or-later
")

// Re-export all public modules
module Locale = Locale
module Catalog = Catalog
module Plural = Plural
module I18n = I18n
module RelativeTime = RelativeTime
module FuzzyMatch = FuzzyMatch
module Stemmer = Stemmer
module Segmenter = Segmenter
