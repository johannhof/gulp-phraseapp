# gulp-phraseapp

Importing Phraseapp translations as a Gulp task

```
npm install gulp-phraseapp --save-dev
```

```
var phraseapp = require('gulp-phraseapp');
```

```
gulp.task('phraseapp:import', function () {
  phraseapp.download({accessToken: 'your_token', projectID: 'project_id'})
  .pipe(gulp.dest('./locales'));
});
```
