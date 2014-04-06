exec = require('child_process').exec

module.exports = (grunt) ->
  grunt.initConfig
    pkg: grunt.file.readJSON('package.json')

    config:
      srcDir: 'src',
      specDir: 'spec'
      releaseDir: 'release'

    browserify:
      server:
        files:
          '<%=config.releaseDir%>/server.js': ['server.coffee', '<%=config.srcDir%>/**/*.coffee']
        options:
          #debug: true
          external: ['fs', 'path', 'child_process', 'connect', 'coffee-script', 'stylus', 'nib', 'fsevents']
          transform: ['coffeeify']
          detectGlobals: false
      client:
        files:
          '<%=config.releaseDir%>/public/main.js': ['client.coffee', '<%=config.srcDir%>/**/*.coffee']
        options:
          #debug: true
          ignore: ['connect', 'fs', 'path', 'child_process', 'chokidar', 'coffee-script', 'stylus', 'nib', 'minimist']
          transform: ['coffeeify']
          detectGlobals: false
      specs:
        files:
          '<%=config.specDir%>/frontend_specs.js': ['<%=config.specDir%>/frontend/**/*_spec.coffee']
        options:
          ignore: ['stylus', 'nib']
          transform: ['coffeeify']
          detectGlobals: false

    watch:
      scripts:
        files: [
          '<%=config.srcDir%>/css/**/*.styl',
          '<%=config.srcDir%>/**/*.coffee',
          'client.coffee',
          'server.coffee',
          '<%=config.specDir%>/**/*_spec.coffee'
        ]
        tasks: ['spec','release']

    uglify:
      build:
        files: [{
          expand: true
          cwd: '<%=config.buildDir%>/'
          src: ['*.js']
          dest: '<%=config.releaseDir%>/'
          ext: '.js'
        }]

    jasmine:
      src: '<%=config.srcDir%>/public/*.js',
      options:
        specs: '<%=config.specDir%>/frontend_specs.js'
        vendor: '<%=config.specDir%>/vendor/*.js'
        build: true


  # load plugins
  grunt.loadNpmTasks 'grunt-browserify'
  grunt.loadNpmTasks 'grunt-contrib-watch'
  grunt.loadNpmTasks 'grunt-contrib-jasmine'

  # tasks
  grunt.task.registerTask 'jasmine:fs', 'execs specs on the local filesystem', ->
    done = @async() # :(
    exec 'npm test', (err, stdout, stderr) ->
      if err
        grunt.log.error stdout
        grunt.log.error stderr
      else
        grunt.log.write stdout
      done()

  grunt.registerTask 'spec', ['jasmine:fs', 'browserify:specs', 'jasmine']
  grunt.registerTask 'release', ['browserify:server', 'browserify:client']
  grunt.registerTask 'default', ['spec', 'release', 'watch']
