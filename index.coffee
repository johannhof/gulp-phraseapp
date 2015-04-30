request     = require 'request'
syncRequest = require 'sync-request'
gutil       = require 'gulp-util'
es          = require 'event-stream'
merge       = require('deep-merge')((a,b) -> a)

module.exports = (options) ->
  base = options.base or 'en'
  auth_token = options.auth_token
  # get locale list
  request("https://phraseapp.com/api/v1/locales/?auth_token=#{auth_token}")
    .pipe es.parse()
    .pipe es.through (locales) ->
      data = {}
      for locale in locales
        res = syncRequest('GET', "https://phraseapp.com/api/v1/translations/download.nested_json?locale=#{locale.code}&auth_token=#{auth_token}")
        data[locale.code] = JSON.parse(res.getBody())

      for code, text of data
        out = text
        if options.base
          out = merge(text, data[options.base])

        gutil.log 'gulp-locales', "Building #{code}.json", gutil.colors.cyan " translations"
        @emit 'data',
          new gutil.File
            cwd      : ""
            base     : ""
            path     : "#{code}.json"
            contents : new Buffer JSON.stringify out, null, '  '

      @emit 'end'

