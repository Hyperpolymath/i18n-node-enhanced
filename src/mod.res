// SPDX-License-Identifier: MPL-2.0

/**
 * Polyglot-I18n — Multi-lingual Linguistic Analysis Engine.
 *
 * This module acts as the public API surface for the `polyglot-i18n` library.
 * It provides a suite of linguistic tools for internationalized applications,
 * ranging from basic translation catalogs to complex fuzzy-match stemming.
 *
 * KEY MODULES:
 * - `I18n`: The primary translation orchestrator with object-notation support.
 * - `RelativeTime`: Human-readable temporal formatting (e.g., "3 days ago").
 * - `FuzzyMatch`: Token-based similarity matching for translation memories.
 * - `Stemmer`: Linguistic root-word extraction for improved search accuracy.
 * - `Segmenter`: Boundary-aware text splitting (Sentence/Word level).
 */

// EXPORT MAP: Re-export internal implementations for consumer access.
module Locale = Locale
module Catalog = Catalog
module Plural = Plural
module I18n = I18n
module RelativeTime = RelativeTime
module FuzzyMatch = FuzzyMatch
module Stemmer = Stemmer
module Segmenter = Segmenter
