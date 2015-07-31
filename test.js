var gulp = require('gulp');
var phraseapp = require('./dist/index.js');

phraseapp.init({accessToken: process.env.TOKEN, projectID: process.env.PROJECT});

gulp.task('default', function () {
  phraseapp.download({base: 'en'})
  .pipe(gulp.dest('./tmp'));
});

gulp.task('upload', function () {
  gulp.src('./tmp/*.json').pipe(phraseapp.upload());
});

gulp.task('upload-specific', function () {
  phraseapp.upload({
    files: {
      '2b2d778950597cdd62ab1ca89cb96817': './tmp/es.json',
      'f3eee97d1a015bfb721cfe8e7bc9acaf': './tmp/fr.json'
    }
  });
});
