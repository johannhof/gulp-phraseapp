baseUrl = "https://phraseapp.com/api/v2"

request     = require('request').defaults({baseUrl})
gutil       = require 'gulp-util'
merge       = require('deep-merge')((a,b) -> a)
_           = require 'highland'

# simple utility function to get the recursive number of keys in an object
keyCount = (obj) ->
  count = 0
  for own key, val of obj
    if typeof val is "object"
      count += keyCount(val)
    else
      count += 1
  count

globalCredentials = {}

getAuthRequest = (options) ->
  token = options.accessToken or globalCredentials.accessToken
  if not token? then throw new Error("A Phraseapp access token must be present")

  request.defaults(headers: 'Authorization': "token #{token}")

exports.init = (credentials={}) ->
  globalCredentials = credentials

exports.upload = (options={}) ->
  request = getAuthRequest(options)

  project = options.projectID or globalCredentials.projectID
  if not project? then throw new Error("A Phraseapp project id must be present")

  _()
    .each (vinyl) ->
      file =
        value: vinyl.contents
        options:
          filename: vinyl.relative
          contentType: 'application/octet-stream'

      request
        url: "/projects/#{project}/uploads/"
        method: 'POST'
        formData:
          file: file
          locale_id: '55f5b7c3de7d213e135ee9e624bdf9e1'
          file_format: 'nested_json'
      , (err, res) ->
        gutil.log res.statusCode

exports.download = (options={}) ->
  request = getAuthRequest(options)

  project = options.projectID or globalCredentials.projectID
  if not project? then throw new Error("A Phraseapp project id must be present")

  # prepare request for auth
  request = request.defaults(headers: 'Authorization': "token #{token}")

  # get locale list
  _(request("/projects/#{project}/locales/"))
    # concat all buffer chunks together
    .reduce1(_.add)
    # get request urls for the individual translations
    .flatMap (body) ->
      locales = JSON.parse(body.toString())
      _(for locale in locales
        code: locale.code
        url: "/projects/#{project}/locales/#{locale.code}/download"
        qs:
          file_format: 'nested_json'
          include_empty_translations: if locale.code is options.base or options.includeEmpty then "1" else "0"
      )
    # download the translations
    .map (query) ->
      _(request(query))
        # concat all buffer chunks together
        .reduce1(_.add)
        .map (body) ->
          text = JSON.parse(body.toString())
          gutil.log(
            gutil.colors.green('phraseapp'),
            "Downloaded #{query.code}.json",
            gutil.colors.cyan "#{keyCount(text)} translations"
          )
          {code: query.code, text}
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
          out = merge(text, data[options.base][0].text)

        push(null, new gutil.File(
          cwd      : ""
          base     : ""
          path     : "#{code}.json"
          contents : new Buffer JSON.stringify out, null, '  '
        ))

        next()

