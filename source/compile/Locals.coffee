{ check, type } = require '../help/✔'
{ cCheck } = require '../c✔'
StringMap = require '../help/StringMap'
{ last } = require '../help/list'
E = require '../Expression'

###
Keeps track of values available to proofs.
###
module.exports = class Locals
	###
	Starts out with a single empty frame.
	###
	constructor: ->
		@_names = new StringMap
		@_frames = [ [ ] ]

	###
	Runs `doInFrame` in a new frame.
	All `add`s within the frame go away after the function is done.
	###
	withFrame: (doInFrame) ->
		@_frames.push [ ]

		res = doInFrame()

		@_frames.pop().forEach (name) =>
			@_names.delete name

		res

	###
	Add a new value to this frame.
	###
	add: (name, value) ->
		type name, String, value, E.Expression
		#check not @has name
		cCheck not (@has name), value.pos(), =>
			"Name '#{name}' was already defined at #{(@get name).pos()}."
		(last @_frames).push name
		@_names.add name, value

	addProper: (name, value) ->
		check not @has name
		@_names.add name, value # and never delete it!

	###
	Add a new value to this frame that may shadow existing ones.
	###
	#addMayShadow: (name, value) ->
	#	type name, String
	#	(last @_frames).push name
	#	@_names.add name, value

	###
	Retrieve the value called `name`.
	###
	get: (name) ->
		type name, String
		@_names.get name

	###
	Whether there is any value called `name`.
	###
	has: (name) ->
		type name, String
		@_names.has name

	all: ->
		Object.keys @_names._data

	maybeAddNamed: (named) ->
		type named, E.ProofPart

		if named.name()?
			@addNamed named

	addNamed: (named) ->
		type named, E.Expression

		cCheck (not @has named.name()), named.pos(), ->
			"Already using name #{named.name()}"

		@add named.name(), named

