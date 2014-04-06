
module.exports = function(grunt) {

  grunt.initConfig({

    pkg: grunt.file.readJSON('package.json'),

    jshint: {
      all: [ 'lib/**/*.js' ]
    },

    jasmine_node: {
      projectRoot: '.',
      requirejs: false,
      forceExit: true
    },

    watch: {

      src: {
        files: [ 'lib/**/*.js', 'spec/**/*.js' ],
        tasks: [ 'jshint', 'jasmine_node' ]
      }
    }
  });

  grunt.loadNpmTasks('grunt-bump');
  grunt.loadNpmTasks('grunt-contrib-jshint');
  grunt.loadNpmTasks('grunt-jasmine-node');
  grunt.loadNpmTasks('grunt-contrib-watch');

  grunt.registerTask('default', [ 'jshint', 'jasmine_node' ]);
};
