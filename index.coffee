request     = require 'request'
syncRequest = require 'sync-request'
gutil       = require 'gulp-util'
es          = require 'event-stream'
merge       = require('deep-merge')((a,b) -> a)

module.exports = (auth_token) ->
  # get locale list
  request("https://phraseapp.com/api/v1/locales/?auth_token=#{auth_token}")
    .pipe es.parse()
    .pipe es.through (locales) ->
      data = {}
      for locale in locales
        res = syncRequest('GET', "https://phraseapp.com/api/v1/translations/download.nested_json?locale=#{locale.code}&auth_token=#{auth_token}")
        data[locale.code] = JSON.parse(res.getBody())

      res = syncRequest('GET', "https://phraseapp.com/api/v1/translations/download.nested_json?locale=en&include_empty_translations=1&auth_token=#{auth_token}")
      data["en"] = JSON.parse(res.getBody())

      descriptions = {}
      for code, text of data
        out = merge(text, data["en"])
        descriptions[code] =
          name: if text.name? then text.name else data["en"].name
          description: if text.description? then text.description else data["en"].description

        gutil.log 'gulp-locales', "Building #{code}.json", gutil.colors.cyan " translations"
        @emit 'data',
          new gutil.File
            cwd      : ""
            base     : ""
            path     : "#{code}.json"
            contents : new Buffer JSON.stringify out, null, '  '

      @emit 'data',
        new gutil.File
          cwd      : ""
          base     : ""
          path     : "descriptions.json"
          contents : new Buffer JSON.stringify descriptions, null, '  '

      @emit 'end'

