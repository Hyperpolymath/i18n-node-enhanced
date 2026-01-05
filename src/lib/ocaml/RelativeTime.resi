// RelativeTime - Human-readable relative time formatting
// SPDX-License-Identifier: AGPL-3.0-or-later

// Time units for relative time formatting
type timeUnit =
  | Second
  | Minute
  | Hour
  | Day
  | Week
  | Month
  | Year

// Formatting style
type style =
  | Long    // "3 days ago"
  | Short   // "3d ago"
  | Narrow  // "3d"

// Numeric display option
type numeric =
  | Always  // "1 day ago" (always show number)
  | Auto    // "yesterday" (use special names when possible)

// Configuration for RelativeTime formatter
type config

// Create a formatter with default config for a locale
let make: Locale.t => config

// Create formatter with custom style
let withStyle: (config, style) => config

// Create formatter with custom numeric option
let withNumeric: (config, numeric) => config

// Format a time difference (in seconds) from now
// Positive = future, negative = past
let format: (config, float) => string

// Format with explicit unit
let formatUnit: (config, float, timeUnit) => string

// Format from Date objects
let fromDates: (config, Js.Date.t, Js.Date.t) => string

// Format from timestamp (milliseconds since epoch)
let fromTimestamp: (config, float) => string

// Format from ISO date string
let fromISOString: (config, string) => option<string>

// Get the best unit for a time difference in seconds
let selectUnit: float => (timeUnit, float)
