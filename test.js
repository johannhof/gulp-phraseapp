var gulp = require('gulp');
var phraseapp = require('./dist/index.js');

gulp.task('default', function () {
  phraseapp.download({base: 'en', accessToken: process.env.TOKEN, projectID: process.env.PROJECT})
  .pipe(gulp.dest('./tmp'));
});

gulp.task('upload', function () {
  gulp.src('./tmp/en.json').pipe(phraseapp.upload({accessToken: process.env.TOKEN, projectID: process.env.PROJECT}));
});
