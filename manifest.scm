;;; manifest.scm --- Development manifest for i18n-node-enhanced
;;;
;;; Copyright (C) 2024-2025 i18n-node-enhanced contributors
;;; SPDX-License-Identifier: MIT
;;;
;;; This manifest defines the complete development environment for
;;; i18n-node-enhanced, including all toolchains and utilities.
;;;
;;; Usage:
;;;   guix shell -m manifest.scm
;;;   guix time-machine -C channels.scm -- shell -m manifest.scm

(specifications->manifest
 '(;; ═══════════════════════════════════════════════════════════════
   ;; Core Runtime Environments
   ;; ═══════════════════════════════════════════════════════════════

   ;; Deno - Primary runtime
   "deno"

   ;; Node.js - Compatibility runtime
   "node-lts"
   "node-lts:npm"

   ;; Bun - Alternative runtime (if available)
   ;; "bun"

   ;; ═══════════════════════════════════════════════════════════════
   ;; Language Toolchains
   ;; ═══════════════════════════════════════════════════════════════

   ;; Rust - For WASM compilation
   "rust"
   "rust:cargo"
   "rust-analyzer"
   "rustfmt"
   "clippy"

   ;; WebAssembly tooling
   "wasm-pack"
   "wabt"           ; WebAssembly binary toolkit
   "binaryen"       ; WebAssembly optimizer

   ;; ReScript (installed via npm in project)
   ;; Managed separately due to npm-based distribution

   ;; ═══════════════════════════════════════════════════════════════
   ;; Configuration Languages
   ;; ═══════════════════════════════════════════════════════════════

   ;; Nickel - Type-safe configuration
   "nickel"

   ;; Dhall - Alternative configuration
   "dhall"
   "dhall-json"

   ;; ═══════════════════════════════════════════════════════════════
   ;; Build & Task Automation
   ;; ═══════════════════════════════════════════════════════════════

   "just"           ; Modern task runner
   "make"           ; Traditional make
   "meson"          ; Build system (for native extensions)
   "ninja"          ; Fast build tool

   ;; ═══════════════════════════════════════════════════════════════
   ;; Documentation
   ;; ═══════════════════════════════════════════════════════════════

   "asciidoctor"    ; AsciiDoc processor
   "ruby-asciidoctor-pdf"  ; PDF generation
   "pandoc"         ; Document conversion
   "graphviz"       ; Diagram generation
   "plantuml"       ; UML diagrams

   ;; Man page generation
   "help2man"
   "txt2man"

   ;; ═══════════════════════════════════════════════════════════════
   ;; Testing & Quality
   ;; ═══════════════════════════════════════════════════════════════

   ;; Code quality
   "shellcheck"     ; Shell script analysis
   "yamllint"       ; YAML linting
   "jsonlint"       ; JSON linting

   ;; Security scanning
   "trivy"          ; Container/dependency scanning
   "grype"          ; Vulnerability scanner

   ;; ═══════════════════════════════════════════════════════════════
   ;; Container & Deployment
   ;; ═══════════════════════════════════════════════════════════════

   ;; Container tools
   "podman"         ; Daemonless containers
   "buildah"        ; Container building
   "skopeo"         ; Container image operations

   ;; Kubernetes tools (optional)
   ;; "kubectl"
   ;; "helm"

   ;; ═══════════════════════════════════════════════════════════════
   ;; Version Control & Collaboration
   ;; ═══════════════════════════════════════════════════════════════

   "git"
   "git-lfs"        ; Large file storage
   "gh"             ; GitHub CLI
   "pre-commit"     ; Git hooks framework

   ;; ═══════════════════════════════════════════════════════════════
   ;; Shell & Utilities
   ;; ═══════════════════════════════════════════════════════════════

   "bash"
   "zsh"
   "fish"

   ;; Modern CLI tools
   "ripgrep"        ; Fast grep
   "fd"             ; Fast find
   "bat"            ; Better cat
   "exa"            ; Better ls
   "jq"             ; JSON processor
   "yq"             ; YAML processor
   "fzf"            ; Fuzzy finder
   "direnv"         ; Directory environments
   "watchexec"      ; File watcher

   ;; Compression
   "gzip"
   "bzip2"
   "xz"
   "zstd"

   ;; Networking
   "curl"
   "wget"
   "httpie"

   ;; ═══════════════════════════════════════════════════════════════
   ;; Editors & Development
   ;; ═══════════════════════════════════════════════════════════════

   ;; Language servers
   "typescript-language-server"
   "yaml-language-server"
   "bash-language-server"

   ;; Optional: editors (uncomment as needed)
   ;; "emacs"
   ;; "neovim"
   ;; "helix"
   ))

;;; Extended manifest with additional options
;;;
;;; For a minimal development environment:
;;; (specifications->manifest
;;;  '("deno" "node-lts" "just" "git"))
;;;
;;; For WASM development only:
;;; (specifications->manifest
;;;  '("rust" "rust:cargo" "wasm-pack" "wabt" "binaryen"))
;;;
;;; For documentation only:
;;; (specifications->manifest
;;;  '("asciidoctor" "pandoc" "graphviz" "plantuml"))
