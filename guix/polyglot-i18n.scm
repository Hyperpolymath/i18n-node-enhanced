;;; polyglot-i18n.scm - Guix package definition
;;; SPDX-License-Identifier: AGPL-3.0-or-later

(define-module (polyglot-i18n)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix git-download)
  #:use-module (guix build-system dune)
  #:use-module (guix build-system cargo)
  #:use-module (guix build-system trivial)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages ocaml)
  #:use-module (gnu packages rust)
  #:use-module (gnu packages rust-apps)
  #:use-module (gnu packages node)
  #:use-module (gnu packages wasm))

;; ReScript compiler (for building the core)
(define-public rescript
  (package
    (name "rescript")
    (version "11.1.0")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "https://registry.npmjs.org/rescript/-/rescript-"
                    version ".tgz"))
              (sha256
               (base32
                "0000000000000000000000000000000000000000000000000000"))))
    (build-system trivial-build-system)
    (home-page "https://rescript-lang.org/")
    (synopsis "Fast, Simple, Fully Typed JavaScript from the Future")
    (description
     "ReScript is a robustly typed language that compiles to efficient and
human-readable JavaScript.")
    (license license:lgpl3+)))

;; polyglot-i18n WASM core
(define-public polyglot-i18n-wasm
  (package
    (name "polyglot-i18n-wasm")
    (version "2.0.0-beta")
    (source (origin
              (method git-fetch)
              (uri (git-reference
                    (url "https://github.com/hyperpolymath/polyglot-i18n")
                    (commit (string-append "v" version))))
              (file-name (git-file-name name version))
              (sha256
               (base32
                "0000000000000000000000000000000000000000000000000000"))))
    (build-system cargo-build-system)
    (arguments
     `(#:cargo-inputs
       (("rust-wasm-bindgen" ,rust-wasm-bindgen)
        ("rust-serde" ,rust-serde)
        ("rust-serde-json" ,rust-serde-json))
       #:phases
       (modify-phases %standard-phases
         (add-before 'build 'change-to-wasm-dir
           (lambda _
             (chdir "wasm"))))))
    (home-page "https://github.com/hyperpolymath/polyglot-i18n")
    (synopsis "WASM core for polyglot-i18n internationalization library")
    (description
     "High-performance WASM module providing CLDR plural rules, relative time
formatting, fuzzy matching (Levenshtein), stemming, and text segmentation
for the polyglot-i18n internationalization library.")
    (license license:agpl3+)))

;; Main polyglot-i18n package
(define-public polyglot-i18n
  (package
    (name "polyglot-i18n")
    (version "2.0.0-beta")
    (source (origin
              (method git-fetch)
              (uri (git-reference
                    (url "https://github.com/hyperpolymath/polyglot-i18n")
                    (commit (string-append "v" version))))
              (file-name (git-file-name name version))
              (sha256
               (base32
                "0000000000000000000000000000000000000000000000000000"))))
    (build-system trivial-build-system)
    (arguments
     `(#:modules ((guix build utils))
       #:builder
       (begin
         (use-modules (guix build utils))
         (let* ((out (assoc-ref %outputs "out"))
                (share (string-append out "/share/polyglot-i18n")))
           (mkdir-p share)
           (copy-recursively (assoc-ref %build-inputs "source") share)
           #t))))
    (native-inputs
     `(("rescript" ,rescript)))
    (propagated-inputs
     `(("polyglot-i18n-wasm" ,polyglot-i18n-wasm)))
    (home-page "https://github.com/hyperpolymath/polyglot-i18n")
    (synopsis "ReScript-first internationalization for Deno")
    (description
     "A comprehensive internationalization library featuring:
@itemize
@item Type-safe translations with ReScript
@item CLDR-compliant plural rules (40+ languages)
@item Relative time formatting (\"yesterday\", \"in 3 days\")
@item Fuzzy matching for translation memory (agrep/Levenshtein)
@item Stemming for better fuzzy matches (English, German, French, Spanish, Russian)
@item Text segmentation (sentence/word boundaries)
@item Document extraction (Pandoc integration)
@item OCR support (Tesseract integration)
@item Language family visualization (Julia/Glottolog)
@end itemize")
    (license license:agpl3+)))

;; External tool dependencies package
(define-public polyglot-i18n-tools
  (package
    (name "polyglot-i18n-tools")
    (version "1.0.0")
    (source #f)
    (build-system trivial-build-system)
    (arguments
     `(#:modules ((guix build utils))
       #:builder
       (begin
         (use-modules (guix build utils))
         (mkdir-p (string-append (assoc-ref %outputs "out") "/bin"))
         #t)))
    (propagated-inputs
     `(("pandoc" ,(@ (gnu packages haskell-apps) pandoc))
       ("hunspell" ,(@ (gnu packages hunspell) hunspell))
       ("tesseract-ocr" ,(@ (gnu packages ocr) tesseract-ocr))))
    (home-page "https://github.com/hyperpolymath/polyglot-i18n")
    (synopsis "External tools for polyglot-i18n")
    (description
     "Meta-package providing external tool dependencies for polyglot-i18n:
Pandoc for document format conversion, Hunspell for spell checking, and
Tesseract for OCR.")
    (license license:agpl3+)))
