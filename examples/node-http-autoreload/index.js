/**
 * This example is intended to show a basic plain vanilla setup and
 * also to be run as integration test for concurrency issues.
 *
 * Please remove setTimeout(), if you intend to use it as a blueprint!
 *
 */

// require modules
var http = require('http')
var i18n = require('../..') // require('i18n')
var url = require('url')
var path = require('path')
var app

// minimal config
i18n.configure({
  locales: ['en', 'de'],
  directory: path.join(__dirname, 'locales'),
  updateFiles: false,
  autoReload: true
})

// simple server
app = http.createServer(function (req, res) {
  var delay = app.getDelay(req, res)
  if (delay < 0) {
    // getDelay already handled response for invalid delay
    return;
  }

  // init & guess
  i18n.init(req, res)

  // delay a response to simulate a long running process,
  // while another request comes in with altered language settings
  setTimeout(function () {
    res.end(res.__('Hello'))
  }, delay)
})

// simple param parsing
// Security: limit max delay to prevent resource exhaustion attacks (reduced to 1000ms)
var MAX_DELAY_MS = 1000
app.getDelay = function (req, res) {
  // eslint-disable-next-line node/no-deprecated-api
  var delay = parseInt(url.parse(req.url, true).query.delay, 10) || 0
  if (delay > MAX_DELAY_MS) {
    res.statusCode = 400;
    res.end('Bad request: delay exceeds limit.');
    return -1; // caller should check for -1 return value
  }
  return Math.max(0, delay)
}

// startup
app.listen(3000, '127.0.0.1')

// export for testing
module.exports = app
