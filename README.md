# gulp-phraseapp [![](https://img.shields.io/npm/v/gulp-phraseapp.svg)](https://www.npmjs.com/package/gulp-phraseapp)

Importing Phraseapp translations as a Gulp task. Can run up to 2 parallel up- and downloads (limited by Phraseapp rate-limiting).

Uses the new Phraseapp API v2, which requires you to generate
an [Access Token](http://docs.phraseapp.com/api/v2/#authentication) and copy your Project ID from the project overview.

```
npm install gulp-phraseapp --save-dev
```

```js
var phraseapp = require('gulp-phraseapp');

// optional, credentials can also be passed to download/upload functions
phraseapp.init({accessToken: 'your_token', projectID: 'project_id'})

gulp.task('phraseapp:import', function () {
  phraseapp.download().pipe(gulp.dest('./locales'));
});

gulp.task('phraseapp:export', function () {
  gulp.dest('./locales').pipe(phraseapp.upload());
});
```

## Documentation

### init

Initialize with authentication/project parameters so that
they don't have to be passed to every function individually.

#### Arguments

- __accessToken__ the access token used by the Phraseapp API to authenticate
- __projectID__ the project ID to identify your project

### download

The `download` function creates a stream that downloads all translations
in your project as JSON files and can be piped into e.g. `gulp.dest` to
save the translation files.

Example:
```js
phraseapp.download().pipe(gulp.dest('./locales'));
```

Example using a base translation:
```js
phraseapp.download({base: 'en'}).pipe(gulp.dest('./locales'));
```

#### Arguments

- __accessToken__ the access token used by the Phraseapp API to authenticate
- __projectID__ the project ID to identify your project
- __base__ (optional) if you specify this, missing keys in translation files will be
filled with the translation of the specified locale

### upload

The `upload` function exposes a stream that can be piped onto to upload
translation files.

Since Phraseapp requires you to keep track of "locale IDs",
this method will make another call to the Phraseapp API requesting the
IDs for the locale files you piped into upload.

This requires your file names to follow the pattern of `{locale_name}.json`, e.g.
`en.json`, `de.json`, `fr.json`. (This is also what the `download` function will generate).

If you want to manually specify all IDs and locale files yourself, you
may pass a `file` option into `phraseapp.upload`. (see below)

Example with automagic ID fetching:
```js
gulp.dest('./locales').pipe(phraseapp.upload());
```

Example without automagic ID fetching:
```js
phraseapp.upload({
  files: {
    '2b2d778950597cdd62ab1ca89cb96817': './locales/es.json',
    'f3eee97d1a015bfb721cfe8e7bc9acaf': './locales/fr.json'
  }
});
```

#### Arguments

- __accessToken__ the access token used by the Phraseapp API to authenticate
- __projectID__ the project ID to identify your project
- __files__ (optional) a key-value map where the key is the locale ID and the file is the filename
to upload, if you follow the `{name}.json` pattern you can pipe into upload instead of this
