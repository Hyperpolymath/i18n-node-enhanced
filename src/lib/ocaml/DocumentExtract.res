// DocumentExtract - Extract translatable text from documents
// Uses Pandoc for format conversion, Hunspell for spell checking
// SPDX-License-Identifier: AGPL-3.0-or-later

type inputFormat =
  | Markdown
  | HTML
  | DOCX
  | ODT
  | RST
  | LaTeX
  | EPUB
  | PDF

type options = {
  preserveFormatting: bool,
  extractComments: bool,
  ignoreCodeBlocks: bool,
}

let defaultOptions = {
  preserveFormatting: false,
  extractComments: true,
  ignoreCodeBlocks: true,
}

let formatToString = format => {
  switch format {
  | Markdown => "markdown"
  | HTML => "html"
  | DOCX => "docx"
  | ODT => "odt"
  | RST => "rst"
  | LaTeX => "latex"
  | EPUB => "epub"
  | PDF => "pdf"
  }
}

// Shell escape for command arguments
let shellEscape = s => {
  "'" ++ s->String.replaceAllRegExp(%re("/'/g"), "'\\''") ++ "'"
}

let getPandocCommand = (~inputPath: string, ~format: inputFormat) => {
  let formatStr = formatToString(format)
  let inputArg = shellEscape(inputPath)

  // PDF needs special handling via pdftotext
  if format == PDF {
    `pdftotext -layout ${inputArg} -`
  } else {
    `pandoc -f ${formatStr} -t plain --wrap=none ${inputArg}`
  }
}

// Deno command execution binding
@val external denoCommand: 'a = "Deno.Command"

type commandOutput = {
  code: int,
  stdout: Js.TypedArray2.Uint8Array.t,
  stderr: Js.TypedArray2.Uint8Array.t,
}

@send external output: 'a => promise<commandOutput> = "output"

// TextDecoder binding
type textDecoder
@new external createTextDecoder: unit => textDecoder = "TextDecoder"
@send external decode: (textDecoder, Js.TypedArray2.Uint8Array.t) => string = "decode"

let runCommand = async (cmd: string, args: array<string>): result<string, string> => {
  try {
    let command = %raw(`new Deno.Command(cmd, { args: args })`)
    let result = await output(command)
    let decoder = createTextDecoder()

    if result.code == 0 {
      Ok(decode(decoder, result.stdout))
    } else {
      Error(decode(decoder, result.stderr))
    }
  } catch {
  | Exn.Error(e) => Error(Exn.message(e)->Option.getOr("Command failed"))
  }
}

let extractFromFile = async (~path: string, ~format: inputFormat, ~options as _: options) => {
  if format == PDF {
    await runCommand("pdftotext", ["-layout", path, "-"])
  } else {
    let formatStr = formatToString(format)
    await runCommand("pandoc", ["-f", formatStr, "-t", "plain", "--wrap=none", path])
  }
}

let extractFromString = async (~content: string, ~format: inputFormat, ~options as _: options) => {
  // For string content, we need to pipe to pandoc
  // This is a simplified version - full implementation would use stdin
  let formatStr = formatToString(format)

  // Write to temp file (simplified - in production use Deno.makeTempFile)
  let tempPath = `/tmp/polyglot-extract-${Int.toString(Js.Math.random_int(0, 999999))}`
  try {
    // Use Deno.writeTextFile
    let _ = %raw(`await Deno.writeTextFile(tempPath, content)`)
    let result = await runCommand("pandoc", ["-f", formatStr, "-t", "plain", "--wrap=none", tempPath])
    // Clean up
    let _ = %raw(`await Deno.remove(tempPath)`)
    result
  } catch {
  | Exn.Error(e) => Error(Exn.message(e)->Option.getOr("Extraction failed"))
  }
}

// === Hunspell Integration ===

type spellResult = {
  word: string,
  suggestions: array<string>,
  isCorrect: bool,
}

let getHunspellCommand = (~locale: string) => {
  `hunspell -d ${locale} -a`
}

let spellCheck = async (~text: string, ~locale: string) => {
  // Hunspell expects words on stdin, outputs spell check results
  // Format: & word count offset: suggestion1, suggestion2...
  // or * if correct, # if no suggestions
  try {
    // Split text into words
    let words =
      text
      ->String.splitByRegExp(%re("/[\s]+/"))
      ->Array.filterMap(x => x)
      ->Array.filter(w => %re("/^[a-zA-Z]+$/")->RegExp.test(w))

    // Run hunspell (simplified - full version pipes words)
    let result = await runCommand("hunspell", ["-d", locale, "-l"])

    switch result {
    | Ok(output) => {
        let misspelled = output->String.split("\n")->Array.filter(s => s != "")
        let results = words->Array.map(word => {
          let isCorrect = !(misspelled->Array.includes(word))
          {
            word,
            suggestions: [], // Would need -a mode for suggestions
            isCorrect,
          }
        })
        Ok(results)
      }
    | Error(e) => Error(e)
    }
  } catch {
  | Exn.Error(e) => Error(Exn.message(e)->Option.getOr("Spell check failed"))
  }
}

// === Tesseract OCR ===

type ocrOptions = {
  lang: string,
  psm: int,
  oem: int,
}

let defaultOcrOptions = {
  lang: "eng",
  psm: 3, // Fully automatic page segmentation
  oem: 3, // Default, based on what is available
}

let getTesseractCommand = (~inputPath: string, ~options: ocrOptions) => {
  let path = shellEscape(inputPath)
  `tesseract ${path} stdout -l ${options.lang} --psm ${Int.toString(options.psm)} --oem ${Int.toString(options.oem)}`
}

let ocrFromFile = async (~path: string, ~options: ocrOptions) => {
  await runCommand("tesseract", [
    path,
    "stdout",
    "-l",
    options.lang,
    "--psm",
    Int.toString(options.psm),
    "--oem",
    Int.toString(options.oem),
  ])
}
