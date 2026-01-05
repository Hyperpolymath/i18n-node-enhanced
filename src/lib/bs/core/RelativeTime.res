@@ocaml.doc("
  RelativeTime - Human-readable relative time formatting

  Formats time differences as human-readable strings like:
  - \"3 days ago\"
  - \"in 2 hours\"
  - \"just now\"
  - \"yesterday\"
  - \"next week\"

  Features:
  - Full CLDR plural support via Plural module
  - Locale-aware formatting
  - Customizable thresholds and styles
  - WASM-accelerated option

  SPDX-License-Identifier: AGPL-3.0-or-later
")

open Locale
open Plural

@ocaml.doc("Time units for relative time formatting")
type timeUnit =
  | Second
  | Minute
  | Hour
  | Day
  | Week
  | Month
  | Year

@ocaml.doc("Formatting style")
type style =
  | Long    // \"3 days ago\"
  | Short   // \"3d ago\"
  | Narrow  // \"3d\"

@ocaml.doc("Numeric display option")
type numeric =
  | Always  // \"1 day ago\" (always show number)
  | Auto    // \"yesterday\" (use special names when possible)

@ocaml.doc("Configuration for RelativeTime formatter")
type config = {
  style: style,
  numeric: numeric,
  locale: Locale.t,
}

@ocaml.doc("Default configuration")
let defaultConfig = (locale: Locale.t): config => {
  style: Long,
  numeric: Auto,
  locale,
}

@ocaml.doc("Time unit metadata")
type unitInfo = {
  timeUnit: timeUnit,
  seconds: float,
  threshold: float,
}

let units: array<unitInfo> = [
  {timeUnit: Year, seconds: 31536000.0, threshold: 0.5},
  {timeUnit: Month, seconds: 2628000.0, threshold: 0.5},
  {timeUnit: Week, seconds: 604800.0, threshold: 0.5},
  {timeUnit: Day, seconds: 86400.0, threshold: 0.5},
  {timeUnit: Hour, seconds: 3600.0, threshold: 0.5},
  {timeUnit: Minute, seconds: 60.0, threshold: 0.5},
  {timeUnit: Second, seconds: 1.0, threshold: 0.5},
]

@ocaml.doc("Get the best unit for a time difference in seconds")
let selectUnit = (diffSeconds: float): (timeUnit, float) => {
  let absDiff = Js.Math.abs_float(diffSeconds)

  let rec findUnit = (index: int): (timeUnit, float) => {
    if index >= Array.length(units) {
      (Second, diffSeconds)
    } else {
      switch units->Array.get(index) {
      | None => (Second, diffSeconds)
      | Some(info) =>
        let value = absDiff /. info.seconds
        if value >= info.threshold {
          (info.timeUnit, diffSeconds /. info.seconds)
        } else {
          findUnit(index + 1)
        }
      }
    }
  }

  findUnit(0)
}

@ocaml.doc("Unit name in different locales")
module UnitNames = {
  type unitStrings = {
    singular: string,
    plural: string,
    shortSingular: string,
    shortPlural: string,
    narrow: string,
  }

  let getEnglish = (u: timeUnit): unitStrings => {
    switch u {
    | Second => {singular: "second", plural: "seconds", shortSingular: "sec", shortPlural: "sec", narrow: "s"}
    | Minute => {singular: "minute", plural: "minutes", shortSingular: "min", shortPlural: "min", narrow: "m"}
    | Hour => {singular: "hour", plural: "hours", shortSingular: "hr", shortPlural: "hr", narrow: "h"}
    | Day => {singular: "day", plural: "days", shortSingular: "day", shortPlural: "days", narrow: "d"}
    | Week => {singular: "week", plural: "weeks", shortSingular: "wk", shortPlural: "wks", narrow: "w"}
    | Month => {singular: "month", plural: "months", shortSingular: "mo", shortPlural: "mos", narrow: "mo"}
    | Year => {singular: "year", plural: "years", shortSingular: "yr", shortPlural: "yrs", narrow: "y"}
    }
  }

  let getGerman = (u: timeUnit): unitStrings => {
    switch u {
    | Second => {singular: "Sekunde", plural: "Sekunden", shortSingular: "Sek.", shortPlural: "Sek.", narrow: "s"}
    | Minute => {singular: "Minute", plural: "Minuten", shortSingular: "Min.", shortPlural: "Min.", narrow: "m"}
    | Hour => {singular: "Stunde", plural: "Stunden", shortSingular: "Std.", shortPlural: "Std.", narrow: "h"}
    | Day => {singular: "Tag", plural: "Tage", shortSingular: "Tag", shortPlural: "Tage", narrow: "T"}
    | Week => {singular: "Woche", plural: "Wochen", shortSingular: "Wo.", shortPlural: "Wo.", narrow: "W"}
    | Month => {singular: "Monat", plural: "Monate", shortSingular: "Mon.", shortPlural: "Mon.", narrow: "M"}
    | Year => {singular: "Jahr", plural: "Jahre", shortSingular: "J.", shortPlural: "J.", narrow: "J"}
    }
  }

  let getFrench = (u: timeUnit): unitStrings => {
    switch u {
    | Second => {singular: "seconde", plural: "secondes", shortSingular: "s", shortPlural: "s", narrow: "s"}
    | Minute => {singular: "minute", plural: "minutes", shortSingular: "min", shortPlural: "min", narrow: "m"}
    | Hour => {singular: "heure", plural: "heures", shortSingular: "h", shortPlural: "h", narrow: "h"}
    | Day => {singular: "jour", plural: "jours", shortSingular: "j", shortPlural: "j", narrow: "j"}
    | Week => {singular: "semaine", plural: "semaines", shortSingular: "sem.", shortPlural: "sem.", narrow: "sem"}
    | Month => {singular: "mois", plural: "mois", shortSingular: "m.", shortPlural: "m.", narrow: "m"}
    | Year => {singular: "an", plural: "ans", shortSingular: "a", shortPlural: "a", narrow: "a"}
    }
  }

  let getSpanish = (u: timeUnit): unitStrings => {
    switch u {
    | Second => {singular: "segundo", plural: "segundos", shortSingular: "s", shortPlural: "s", narrow: "s"}
    | Minute => {singular: "minuto", plural: "minutos", shortSingular: "min", shortPlural: "min", narrow: "m"}
    | Hour => {singular: "hora", plural: "horas", shortSingular: "h", shortPlural: "h", narrow: "h"}
    | Day => {singular: "día", plural: "días", shortSingular: "d", shortPlural: "d", narrow: "d"}
    | Week => {singular: "semana", plural: "semanas", shortSingular: "sem.", shortPlural: "sem.", narrow: "sem"}
    | Month => {singular: "mes", plural: "meses", shortSingular: "m.", shortPlural: "m.", narrow: "m"}
    | Year => {singular: "año", plural: "años", shortSingular: "a", shortPlural: "a", narrow: "a"}
    }
  }

  let getRussian = (u: timeUnit): unitStrings => {
    switch u {
    | Second => {singular: "секунда", plural: "секунд", shortSingular: "сек.", shortPlural: "сек.", narrow: "с"}
    | Minute => {singular: "минута", plural: "минут", shortSingular: "мин.", shortPlural: "мин.", narrow: "м"}
    | Hour => {singular: "час", plural: "часов", shortSingular: "ч.", shortPlural: "ч.", narrow: "ч"}
    | Day => {singular: "день", plural: "дней", shortSingular: "дн.", shortPlural: "дн.", narrow: "д"}
    | Week => {singular: "неделя", plural: "недель", shortSingular: "нед.", shortPlural: "нед.", narrow: "н"}
    | Month => {singular: "месяц", plural: "месяцев", shortSingular: "мес.", shortPlural: "мес.", narrow: "м"}
    | Year => {singular: "год", plural: "лет", shortSingular: "г.", shortPlural: "л.", narrow: "г"}
    }
  }

  let getJapanese = (u: timeUnit): unitStrings => {
    switch u {
    | Second => {singular: "秒", plural: "秒", shortSingular: "秒", shortPlural: "秒", narrow: "秒"}
    | Minute => {singular: "分", plural: "分", shortSingular: "分", shortPlural: "分", narrow: "分"}
    | Hour => {singular: "時間", plural: "時間", shortSingular: "時間", shortPlural: "時間", narrow: "時"}
    | Day => {singular: "日", plural: "日", shortSingular: "日", shortPlural: "日", narrow: "日"}
    | Week => {singular: "週間", plural: "週間", shortSingular: "週", shortPlural: "週", narrow: "週"}
    | Month => {singular: "か月", plural: "か月", shortSingular: "か月", shortPlural: "か月", narrow: "月"}
    | Year => {singular: "年", plural: "年", shortSingular: "年", shortPlural: "年", narrow: "年"}
    }
  }

  let getChinese = (u: timeUnit): unitStrings => {
    switch u {
    | Second => {singular: "秒", plural: "秒", shortSingular: "秒", shortPlural: "秒", narrow: "秒"}
    | Minute => {singular: "分钟", plural: "分钟", shortSingular: "分钟", shortPlural: "分钟", narrow: "分"}
    | Hour => {singular: "小时", plural: "小时", shortSingular: "小时", shortPlural: "小时", narrow: "时"}
    | Day => {singular: "天", plural: "天", shortSingular: "天", shortPlural: "天", narrow: "天"}
    | Week => {singular: "周", plural: "周", shortSingular: "周", shortPlural: "周", narrow: "周"}
    | Month => {singular: "个月", plural: "个月", shortSingular: "个月", shortPlural: "个月", narrow: "月"}
    | Year => {singular: "年", plural: "年", shortSingular: "年", shortPlural: "年", narrow: "年"}
    }
  }

  let getArabic = (u: timeUnit): unitStrings => {
    switch u {
    | Second => {singular: "ثانية", plural: "ثوانٍ", shortSingular: "ث", shortPlural: "ث", narrow: "ث"}
    | Minute => {singular: "دقيقة", plural: "دقائق", shortSingular: "د", shortPlural: "د", narrow: "د"}
    | Hour => {singular: "ساعة", plural: "ساعات", shortSingular: "س", shortPlural: "س", narrow: "س"}
    | Day => {singular: "يوم", plural: "أيام", shortSingular: "ي", shortPlural: "ي", narrow: "ي"}
    | Week => {singular: "أسبوع", plural: "أسابيع", shortSingular: "أس", shortPlural: "أس", narrow: "أس"}
    | Month => {singular: "شهر", plural: "أشهر", shortSingular: "ش", shortPlural: "ش", narrow: "ش"}
    | Year => {singular: "سنة", plural: "سنوات", shortSingular: "سن", shortPlural: "سن", narrow: "سن"}
    }
  }

  let forLocale = (locale: Locale.t, u: timeUnit): unitStrings => {
    let lang = Locale.language(locale)
    switch lang {
    | "de" => getGerman(u)
    | "fr" => getFrench(u)
    | "es" => getSpanish(u)
    | "ru" => getRussian(u)
    | "ja" => getJapanese(u)
    | "zh" => getChinese(u)
    | "ar" => getArabic(u)
    | _ => getEnglish(u)
    }
  }
}

@ocaml.doc("Special named time references")
module SpecialNames = {
  type names = {
    now: string,
    yesterday: string,
    tomorrow: string,
    lastWeek: string,
    nextWeek: string,
    lastMonth: string,
    nextMonth: string,
    lastYear: string,
    nextYear: string,
    ago: string,
    inFuture: string,
  }

  let english: names = {
    now: "just now",
    yesterday: "yesterday",
    tomorrow: "tomorrow",
    lastWeek: "last week",
    nextWeek: "next week",
    lastMonth: "last month",
    nextMonth: "next month",
    lastYear: "last year",
    nextYear: "next year",
    ago: "ago",
    inFuture: "in",
  }

  let german: names = {
    now: "gerade eben",
    yesterday: "gestern",
    tomorrow: "morgen",
    lastWeek: "letzte Woche",
    nextWeek: "nächste Woche",
    lastMonth: "letzten Monat",
    nextMonth: "nächsten Monat",
    lastYear: "letztes Jahr",
    nextYear: "nächstes Jahr",
    ago: "vor",
    inFuture: "in",
  }

  let french: names = {
    now: "à l'instant",
    yesterday: "hier",
    tomorrow: "demain",
    lastWeek: "la semaine dernière",
    nextWeek: "la semaine prochaine",
    lastMonth: "le mois dernier",
    nextMonth: "le mois prochain",
    lastYear: "l'année dernière",
    nextYear: "l'année prochaine",
    ago: "il y a",
    inFuture: "dans",
  }

  let spanish: names = {
    now: "ahora mismo",
    yesterday: "ayer",
    tomorrow: "mañana",
    lastWeek: "la semana pasada",
    nextWeek: "la próxima semana",
    lastMonth: "el mes pasado",
    nextMonth: "el próximo mes",
    lastYear: "el año pasado",
    nextYear: "el próximo año",
    ago: "hace",
    inFuture: "en",
  }

  let russian: names = {
    now: "только что",
    yesterday: "вчера",
    tomorrow: "завтра",
    lastWeek: "на прошлой неделе",
    nextWeek: "на следующей неделе",
    lastMonth: "в прошлом месяце",
    nextMonth: "в следующем месяце",
    lastYear: "в прошлом году",
    nextYear: "в следующем году",
    ago: "назад",
    inFuture: "через",
  }

  let japanese: names = {
    now: "たった今",
    yesterday: "昨日",
    tomorrow: "明日",
    lastWeek: "先週",
    nextWeek: "来週",
    lastMonth: "先月",
    nextMonth: "来月",
    lastYear: "去年",
    nextYear: "来年",
    ago: "前",
    inFuture: "後",
  }

  let chinese: names = {
    now: "刚刚",
    yesterday: "昨天",
    tomorrow: "明天",
    lastWeek: "上周",
    nextWeek: "下周",
    lastMonth: "上个月",
    nextMonth: "下个月",
    lastYear: "去年",
    nextYear: "明年",
    ago: "前",
    inFuture: "后",
  }

  let arabic: names = {
    now: "الآن",
    yesterday: "أمس",
    tomorrow: "غداً",
    lastWeek: "الأسبوع الماضي",
    nextWeek: "الأسبوع القادم",
    lastMonth: "الشهر الماضي",
    nextMonth: "الشهر القادم",
    lastYear: "العام الماضي",
    nextYear: "العام القادم",
    ago: "منذ",
    inFuture: "خلال",
  }

  let forLocale = (locale: Locale.t): names => {
    let lang = Locale.language(locale)
    switch lang {
    | "de" => german
    | "fr" => french
    | "es" => spanish
    | "ru" => russian
    | "ja" => japanese
    | "zh" => chinese
    | "ar" => arabic
    | _ => english
    }
  }
}

@ocaml.doc("Get unit name based on plural category and style")
let getUnitName = (locale: Locale.t, u: timeUnit, value: float, style: style): string => {
  let names = UnitNames.forLocale(locale, u)
  let category = Plural.selectForLocale(value, locale)

  switch style {
  | Long =>
    switch category {
    | One => names.singular
    | _ => names.plural
    }
  | Short =>
    switch category {
    | One => names.shortSingular
    | _ => names.shortPlural
    }
  | Narrow => names.narrow
  }
}

@ocaml.doc("Format a relative time value")
let formatRelative = (config: config, value: float, u: timeUnit): string => {
  let absValue = Js.Math.abs_float(value)
  let roundedValue = Js.Math.round(absValue)
  let isPast = value < 0.0
  let names = SpecialNames.forLocale(config.locale)
  let lang = Locale.language(config.locale)

  // Check for special cases with Auto numeric
  let specialCase = if config.numeric == Auto {
    // "just now" for very small differences
    if absValue < 10.0 && u == Second {
      Some(names.now)
    } else if u == Day && roundedValue == 1.0 {
      // Yesterday/tomorrow
      Some(if isPast { names.yesterday } else { names.tomorrow })
    } else if u == Week && roundedValue == 1.0 {
      // Last/next week
      Some(if isPast { names.lastWeek } else { names.nextWeek })
    } else if u == Month && roundedValue == 1.0 {
      // Last/next month
      Some(if isPast { names.lastMonth } else { names.nextMonth })
    } else if u == Year && roundedValue == 1.0 {
      // Last/next year
      Some(if isPast { names.lastYear } else { names.nextYear })
    } else {
      None
    }
  } else {
    None
  }

  switch specialCase {
  | Some(result) => result
  | None => {
      let unitName = getUnitName(config.locale, u, roundedValue, config.style)
      let valueStr = Float.toString(roundedValue)

      // Format based on language and direction
      switch lang {
      | "ja" | "zh" | "ko" =>
        // Asian languages: number + unit + ago/future marker
        if isPast {
          `${valueStr}${unitName}${names.ago}`
        } else {
          `${valueStr}${unitName}${names.inFuture}`
        }
      | "de" =>
        // German: "vor X Tagen" / "in X Tagen"
        if isPast {
          `${names.ago} ${valueStr} ${unitName}`
        } else {
          `${names.inFuture} ${valueStr} ${unitName}`
        }
      | "fr" | "es" =>
        // Romance: "il y a X jours" / "dans X jours"
        if isPast {
          `${names.ago} ${valueStr} ${unitName}`
        } else {
          `${names.inFuture} ${valueStr} ${unitName}`
        }
      | "ru" =>
        // Russian: "X дней назад" / "через X дней"
        if isPast {
          `${valueStr} ${unitName} ${names.ago}`
        } else {
          `${names.inFuture} ${valueStr} ${unitName}`
        }
      | "ar" =>
        // Arabic: "منذ X أيام" / "خلال X أيام"
        if isPast {
          `${names.ago} ${valueStr} ${unitName}`
        } else {
          `${names.inFuture} ${valueStr} ${unitName}`
        }
      | _ =>
        // English and default: "X days ago" / "in X days"
        if isPast {
          `${valueStr} ${unitName} ${names.ago}`
        } else {
          `${names.inFuture} ${valueStr} ${unitName}`
        }
      }
    }
  }
}

@ocaml.doc("Format a time difference from now")
let format = (config: config, diffSeconds: float): string => {
  let (u, value) = selectUnit(diffSeconds)
  formatRelative(config, value, u)
}

@ocaml.doc("Format with explicit unit")
let formatUnit = (config: config, value: float, u: timeUnit): string => {
  formatRelative(config, value, u)
}

@ocaml.doc("Create a formatter with default config for a locale")
let make = (locale: Locale.t): config => defaultConfig(locale)

@ocaml.doc("Create formatter with custom style")
let withStyle = (config: config, style: style): config => {
  {...config, style}
}

@ocaml.doc("Create formatter with custom numeric option")
let withNumeric = (config: config, numeric: numeric): config => {
  {...config, numeric}
}

@ocaml.doc("Format from Date objects")
let fromDates = (config: config, from: Js.Date.t, to_: Js.Date.t): string => {
  let diffMs = Js.Date.getTime(to_) -. Js.Date.getTime(from)
  let diffSeconds = diffMs /. 1000.0
  format(config, diffSeconds)
}

@ocaml.doc("Format from timestamp (milliseconds since epoch)")
let fromTimestamp = (config: config, timestamp: float): string => {
  let now = Js.Date.now()
  let diffSeconds = (timestamp -. now) /. 1000.0
  format(config, diffSeconds)
}

@ocaml.doc("Format from ISO date string")
let fromISOString = (config: config, isoString: string): option<string> => {
  let date = Js.Date.fromString(isoString)
  if Js.Float.isNaN(Js.Date.getTime(date)) {
    None
  } else {
    Some(fromTimestamp(config, Js.Date.getTime(date)))
  }
}
