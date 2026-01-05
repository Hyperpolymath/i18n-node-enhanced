;; SPDX-License-Identifier: AGPL-3.0-or-later
;; polyglot-i18n Testing Report
;; Generated: 2025-12-29

(testing-report
  (metadata
    (project "polyglot-i18n")
    (version "2.0.0-beta")
    (test-date "2025-12-29")
    (generator "Claude Code")
    (format-version "1.0"))

  (summary
    (overall-status 'pass)
    (rescript-build 'pass)
    (wasm-build 'pass)
    (deno-check 'pass)
    (test-suite 'not-available)
    (notes "Build successful with deprecation warnings"))

  (build-results
    (rescript
      (status 'pass)
      (source-files-parsed 66)
      (modules-compiled 66)
      (warnings-count 80)
      (errors-count 0)
      (compilation-time "~30s")
      (modules
        (module (name "mod") (status 'pass))
        (module (name "Locale") (status 'pass))
        (module (name "Catalog") (status 'pass))
        (module (name "Plural") (status 'pass))
        (module (name "I18n") (status 'pass))
        (module (name "RelativeTime") (status 'pass))
        (module (name "FuzzyMatch") (status 'pass))
        (module (name "Stemmer") (status 'pass))
        (module (name "Segmenter") (status 'pass))
        (module (name "DocumentExtract") (status 'pass))))

    (wasm
      (status 'pass)
      (cargo-build-time "1m 34s")
      (wasm-pack-time "14.79s")
      (output-location "wasm/pkg/")
      (warnings
        (warning
          (type 'cfg-condition)
          (message "unexpected cfg condition value: console_error_panic_hook"))
        (warning
          (type 'dead-code)
          (message "field w is never read in PluralOperands")))))

  (issues-fixed
    (issue
      (id 1)
      (title "Array spread pattern not supported")
      (files "Locale.res" "Catalog.res" "RelativeTime.res")
      (severity 'error)
      (fix-type 'api-change)
      (description "ReScript v12 does not support array spread in pattern matching")
      (solution "Use Array.length, Array.get(0), and Array.slice instead"))

    (issue
      (id 2)
      (title "Return keyword not valid")
      (files "RelativeTime.res")
      (severity 'error)
      (fix-type 'syntax)
      (description "ReScript does not support early returns")
      (solution "Restructure using if-else with Option types"))

    (issue
      (id 3)
      (title "Built-in type conflict")
      (files "RelativeTime.res" "RelativeTime.resi")
      (severity 'error)
      (fix-type 'rename)
      (description "type unit conflicts with ReScript built-in")
      (solution "Renamed to type timeUnit"))

    (issue
      (id 4)
      (title "Array.make labeled arguments")
      (files "FuzzyMatch.res")
      (severity 'error)
      (fix-type 'api-change)
      (description "Array.make requires labeled ~length argument")
      (solution "Changed Array.make(n, v) to Array.make(~length=n, v)"))

    (issue
      (id 5)
      (title "Array indexing returns option")
      (files "FuzzyMatch.res")
      (severity 'error)
      (fix-type 'api-change)
      (description "Array subscript access returns option in v12")
      (solution "Use Array.getUnsafe and Array.setUnsafe for matrix operations"))

    (issue
      (id 6)
      (title "String.split with RegExp")
      (files "Segmenter.res" "DocumentExtract.res")
      (severity 'error)
      (fix-type 'api-change)
      (description "String.split expects string, not RegExp")
      (solution "Use String.splitByRegExp with filterMap for option handling"))

    (issue
      (id 7)
      (title "String.charCodeAt returns option")
      (files "Segmenter.res")
      (severity 'error)
      (fix-type 'api-change)
      (description "charCodeAt returns option<int> not int")
      (solution "Pattern match on Some/None"))

    (issue
      (id 8)
      (title "String.replaceRegExp callback")
      (files "I18n.res")
      (severity 'error)
      (fix-type 'api-change)
      (description "replaceRegExp does not accept callback function")
      (solution "Use String.unsafeReplaceRegExpBy1 with labeled parameters"))

    (issue
      (id 9)
      (title "Operator precedence")
      (files "I18n.res")
      (severity 'error)
      (fix-type 'syntax)
      (description "! operator binds tighter than pipe")
      (solution "Add parentheses: !(array->Array.some(...))"))

    (issue
      (id 10)
      (title "Forward type reference")
      (files "Catalog.res")
      (severity 'error)
      (fix-type 'reorder)
      (description "metadata type used before definition")
      (solution "Move type definition before usage")))

  (deprecation-warnings
    (warning-group
      (api "Js.Date")
      (replacements
        (replacement (from "Js.Date.t") (to "Date.t") (count 8))
        (replacement (from "Js.Date.now") (to "Date.now") (count 2))
        (replacement (from "Js.Date.getTime") (to "Date.getTime") (count 2))))

    (warning-group
      (api "Js.Json")
      (replacements
        (replacement (from "Js.Json.t") (to "JSON.t") (count 6))
        (replacement (from "Js.Json.classify") (to "removed-in-v13") (count 3))
        (replacement (from "Js.Json.string") (to "JSON.Encode.string") (count 8))
        (replacement (from "Js.Json.object_") (to "JSON.Encode.object") (count 2))))

    (warning-group
      (api "Js.Dict")
      (replacements
        (replacement (from "Js.Dict.t") (to "dict") (count 2))
        (replacement (from "Js.Dict.get") (to "Dict.get") (count 2))
        (replacement (from "Js.Dict.set") (to "Dict.set") (count 7))
        (replacement (from "Js.Dict.entries") (to "Dict.toArray") (count 2))
        (replacement (from "Js.Dict.empty") (to "Dict.make") (count 2))))

    (warning-group
      (api "Exn")
      (replacements
        (replacement (from "Js.Exn.raiseError") (to "JsError.throwWithMessage") (count 1))
        (replacement (from "Exn.Error") (to "JsExn") (count 3))
        (replacement (from "Exn.message") (to "JsExn.message") (count 3))))

    (warning-group
      (api "Array")
      (replacements
        (replacement (from "Array.sliceToEnd") (to "Array.slice") (count 2))))

    (warning-group
      (api "String")
      (replacements
        (replacement (from "String.unsafeReplaceRegExpBy1") (to "replaceRegExpBy1Unsafe") (count 2)))))

  (configuration-changes
    (change
      (file "src/rescript.json")
      (type 'addition)
      (description "Added mod.res to sources")
      (before
        '(("dir" "core" "subdirs" #t)
          ("dir" "runtime" "subdirs" #t)))
      (after
        '(("dir" "." "files" ("mod.res"))
          ("dir" "core" "subdirs" #t)
          ("dir" "runtime" "subdirs" #t))))

    (change
      (file "deno.json")
      (type 'fix)
      (description "Fixed export paths to correct output directory")
      (before "src/lib/es6/src/")
      (after "src/lib/es6/")))

  (test-suite-status
    (status 'not-available)
    (expected-location "tests/**/*_test.mjs")
    (actual-tests-found 0)
    (legacy-tests-location "test/*.js")
    (legacy-test-framework "mocha")
    (recommendation "Create Deno-compatible test files in tests/ directory"))

  (output-artifacts
    (rescript-output
      (directory "src/lib/es6/")
      (files
        "mod.res.mjs"
        "core/Catalog.res.mjs"
        "core/DocumentExtract.res.mjs"
        "core/FuzzyMatch.res.mjs"
        "core/I18n.res.mjs"
        "core/Locale.res.mjs"
        "core/Plural.res.mjs"
        "core/RelativeTime.res.mjs"
        "core/Segmenter.res.mjs"
        "core/Stemmer.res.mjs"))

    (wasm-output
      (directory "wasm/pkg/")
      (files
        "i18n_wasm.js"
        "i18n_wasm.d.ts"
        "i18n_wasm_bg.wasm"
        "package.json")))

  (recommendations
    (recommendation
      (priority 'high)
      (action "create-tests")
      (description "Create Deno test files in tests/ directory with *_test.mjs naming"))

    (recommendation
      (priority 'medium)
      (action "update-apis")
      (description "Run rescript-tools migrate-all to update deprecated API calls"))

    (recommendation
      (priority 'low)
      (action "fix-wasm-warnings")
      (description "Add console_error_panic_hook feature or remove conditional"))

    (recommendation
      (priority 'low)
      (action "update-docs")
      (description "Update README.adoc with correct import paths")))

  (conclusion
    (status 'ready-for-development)
    (summary "Build infrastructure is sound; all compilation targets pass")
    (blockers '())
    (action-items
      ("Create Deno test suite"
       "Address deprecation warnings before v13 migration"
       "Consider adding fuzzing for security"))))
