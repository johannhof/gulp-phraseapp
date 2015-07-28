request     = require 'request'
gutil       = require 'gulp-util'
merge       = require('deep-merge')((a,b) -> a)
_           = require 'highland'

baseUrl = "https://phraseapp.com/api/v2"

# simple utility function to get the recursive number of keys in an object
keyCount = (obj) ->
  count = 0
  for own key, val of obj
    if typeof val is "object"
      count += keyCount(val)
    else
      count += 1
  count

exports.download = (options) ->
  # options
  base = options.base or 'en'
  token = options.accessToken
  if not token? then throw new Error("A Phraseapp access token must be present")
  project = options.projectID
  if not project? then throw new Error("A Phraseapp project id must be present")

  # get locale list
  _(request("#{baseUrl}/projects/#{project}/locales/?access_token=#{token}"))
    # concat all buffer chunks together
    .reduce1(_.add)
    # get request urls for the individual translations
    .flatMap (body) ->
      locales = JSON.parse(body.toString())
      _(for locale in locales
        includeEmpty = if locale.code is options.base or options.includeEmpty then "1" else "0"
        {
          code: locale.code
          url: "#{baseUrl}/projects/#{project}/locales/#{locale.code}/download?file_format=nested_json&include_empty_translations=#{includeEmpty}&access_token=#{token}"
        }
      )
    # download the translations
    .map ({url, code}) ->
      _(request(url))
        # concat all buffer chunks together
        .reduce1(_.add)
        .map (body) ->
          text = JSON.parse(body.toString())
          gutil.log 'gulp-phraseapp', "Downloaded #{code}.json", gutil.colors.cyan "#{keyCount(text)} translations"
          {code, text}
    # the phraseapp api is rate-limited to 2 parallel connections
    .parallel(2)
    # transform into an object
    .group('code')
    # push to a node stream
    .consume (err, data, push, next) ->
      if err
        push(err)
        return next()

      for code, [{text}] of data
        out = text
        if options.base
          out = merge(text, data[options.base])

        push(null, new gutil.File(
          cwd      : ""
          base     : ""
          path     : "#{code}.json"
          contents : new Buffer JSON.stringify out, null, '  '
        ))

        next()

