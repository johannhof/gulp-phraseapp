request = require('request')
gutil   = require 'gulp-util'
merge   = require('deep-merge')((a,b) -> a)
_       = require 'highland'
fs      = require 'fs'

baseUrl = "https://phraseapp.com/api/v2/projects/"

log = (args...) ->
  gutil.log.apply(gutil, [gutil.colors.green('phraseapp')].concat(args))

error = (args...) ->
  gutil.log.apply(gutil, [gutil.colors.red('phraseapp')].concat(args))

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

  project = options.projectID or globalCredentials.projectID
  if not project? then throw new Error("A Phraseapp project id must be present")

  request.defaults(
    baseUrl: baseUrl + project
    headers:
      'Authorization': "token #{token}"
  )

exports.init = (credentials={}) ->
  globalCredentials = credentials

exports.upload = (options={}) ->
  request = getAuthRequest(options)

  if options.files
    for id, path of options.files
      do (id, path) ->
        request
          url: "/uploads"
          method: 'POST'
          formData:
            file: fs.createReadStream(path)
            locale_id: id
            file_format: 'nested_json'
        , (err, res) ->
          if res.statusCode is 201
            log "Uploaded #{path} (#{id})"
          else
            error "Upload of #{path} failed. Server responded with", res.statusCode
  else
    _.pipeline(
      _.reduce({}, (acc, file) ->
        acc[file.relative.split('.')[0]] = file
        acc
      ),
      _.flatMap((files) ->
        _(request "/locales")
          .reduce1(_.add)
          .flatMap (res) ->
            locales = JSON.parse(res)
            _([files[name], id] for {id, name} in locales when files[name])
      ),
      _.each(([vinyl, id]) ->
        request
          url: "/uploads"
          method: 'POST'
          formData:
            file:
              value: vinyl.contents
              options:
                filename: vinyl.relative
              contentType: 'application/octet-stream'
            locale_id: id
            file_format: 'nested_json'
        , (err, res) ->
          if res.statusCode is 201
            log "Uploaded #{vinyl.relative} (#{id})"
          else
            error "Upload of #{vinyl.relative} failed. Server responded with", res.statusCode
      ),
      _.parallel(2)
    )

exports.download = (options={}) ->
  request = getAuthRequest(options)

  # get locale list
  _(request("/locales"))
    # concat all buffer chunks together
    .reduce1(_.add)
    # get request urls for the individual translations
    .flatMap (body) ->
      locales = JSON.parse(body.toString())
      _(for locale in locales
        code: locale.code
        url: "/locales/#{locale.code}/download"
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
          log "Downloaded #{query.code}.json", gutil.colors.cyan "#{keyCount(text)} translations"
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

