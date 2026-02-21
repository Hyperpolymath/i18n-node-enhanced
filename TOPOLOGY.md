<!-- SPDX-License-Identifier: PMPL-1.0-or-later -->
<!-- TOPOLOGY.md — Project architecture map and completion dashboard -->
<!-- Last updated: 2026-02-19 -->

# polyglot-i18n — Project Topology

## System Architecture

```
                        ┌─────────────────────────────────────────┐
                        │              ENTERPRISE APP             │
                        │        (Deno, Node, Bun, Edge)          │
                        └───────────────────┬─────────────────────┘
                                            │ translate / sync
                                            ▼
                        ┌─────────────────────────────────────────┐
                        │           POLYGLOT-I18N CORE            │
                        │  ┌───────────┐  ┌───────────────────┐  │
                        │  │ ReScript  │  │  WASM             │  │
                        │  │ Core Mods │  │  Acceleration     │  │
                        │  └─────┬─────┘  └────────┬──────────┘  │
                        │        │                 │              │
                        │  ┌─────▼─────┐  ┌────────▼──────────┐  │
                        │  │ NLP Engine│  │  Enterprise       │  │
                        │  │ (Stem/Seg)│  │  Adapters         │  │
                        │  └─────┬─────┘  └────────┬──────────┘  │
                        └────────│─────────────────│──────────────┘
                                 │                 │
                                 ▼                 ▼
                        ┌─────────────────────────────────────────┐
                        │           EXTERNAL SYSTEMS              │
                        │  ┌───────────┐  ┌───────────┐  ┌───────┐│
                        │  │ ERP (SAP) │  │ CRM (SFDC)│  │ AIS   ││
                        │  └───────────┘  └───────────┘  └───────┘│
                        └─────────────────────────────────────────┘

                        ┌─────────────────────────────────────────┐
                        │          REPO INFRASTRUCTURE            │
                        │  Justfile Automation  .machine_readable/  │
                        │  Observability Hub    0-AI-MANIFEST.a2ml  │
                        └─────────────────────────────────────────┘
```

## Completion Dashboard

```
COMPONENT                          STATUS              NOTES
─────────────────────────────────  ──────────────────  ─────────────────────────────────
CORE MODULES (RESCRIPT)
  I18n Main API                     ██████████ 100%    Config builder stable
  Catalog (Immutable)               ██████████ 100%    Structural sharing active
  Locale (BCP 47)                   ██████████ 100%    Validation verified
  RelativeTime / Fuzzy              ██████████ 100%    CLDR rules verified

NLP & ACCELERATION
  WASM Plural Rules                 ██████████ 100%    10x speedup verified
  Stemmer / Segmenter               ██████████ 100%    CJK support verified
  Document Extraction               ████████░░  80%    OCR integration refining

ADAPTERS & DEVOPS
  Enterprise Adapters               ████████░░  80%    SAP/Salesforce verified
  Audit / Forensics                 ██████████ 100%    JSONL logging stable
  Observability (OTEL)              ██████████ 100%    Prometheus metrics verified

REPO INFRASTRUCTURE
  Justfile Automation               ██████████ 100%    Standard build/bench tasks
  .machine_readable/                ██████████ 100%    STATE tracking active
  Benchmark Suite                   ██████████ 100%    2.3M ops/sec verified

─────────────────────────────────────────────────────────────────────────────
OVERALL:                            █████████░  ~95%   Enterprise ready framework
```

## Key Dependencies

```
Catalog Source ──► ReScript Core ──────► WASM Plural ──────► Translation
     │                 │                   │                 │
     ▼                 ▼                   ▼                 ▼
Locale Spec ────► NLP Stemmer ──────► Enterprise Sync ───► SAP / SFDC
```

## Update Protocol

This file is maintained by both humans and AI agents. When updating:

1. **After completing a component**: Change its bar and percentage
2. **After adding a component**: Add a new row in the appropriate section
3. **After architectural changes**: Update the ASCII diagram
4. **Date**: Update the `Last updated` comment at the top of this file

Progress bars use: `█` (filled) and `░` (empty), 10 characters wide.
Percentages: 0%, 10%, 20%, ... 100% (in 10% increments).
