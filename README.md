# gulp-phraseapp

Importing Phraseapp translations as a Gulp task

```
npm install gulp-phraseapp --save-dev
```

Example:
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

### download

### upload
