module.exports = (grunt) ->
	grunt.initConfig
		pkg:
			grunt.file.readJSON 'package.json'

		clean:
			pre:
				[ 'js' ]
			all:
				[ 'doc', 'js', 'node_modules' ]

		coffee:
			options:
				sourceMap: yes
			files:
				expand: yes
				cwd: 'source'
				src: [ '**/*.coffee' ]
				dest: 'js'
				ext: '.js'

		codo:
			options:
				inputs: [ 'source' ]
				output: 'doc'

		coffeelint:
			app:
				[ 'source/**/*.coffee' ]
			options:
				camel_case_classes:
					level: 'error'
				indentation:
					value: 1
					level: 'error'
				max_line_length:
					value: 80
					level: 'error'
				no_plusplus:
					level: 'error'
				no_tabs:
					level: 'ignore'
				no_throwing_strings:
					level: 'error'
				no_trailing_semicolons:
					level: 'error'
				no_trailing_whitespace:
					level: 'error'

		mochaTest:
			options:
				reporter: 'spec'
				require: 'coffee-script/register'
			src:
				'test/**/*.coffee'


	(require 'load-grunt-tasks') grunt

	grunt.registerTask 'default', [
		'clean:pre',
		'coffeelint',
		'codo',
		'coffee',
		'mochaTest'
	]
