var gulp = require('gulp');
var phraseapp = require('./dist/index.js');

gulp.task('default', function () {
  phraseapp.download({accessToken: process.env.TOKEN, projectID: process.env.PROJECT})
  .pipe(gulp.dest('./tmp'));
});
