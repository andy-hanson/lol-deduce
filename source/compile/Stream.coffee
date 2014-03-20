{ check, type } = require '../help/✔'
{ times } = require '../help/oth'
Pos = require '../Pos'

###
Pretends that a string is streaming.
###
module.exports = class Stream
	###
	@param str [String]
	  Full text (this is not a real stream).
	###
	constructor: (@_str) ->
		type @_str, String
		@_index = 0
		@_pos = Pos.start()

	isEmpty: ->
		@_index >= @_str.length

	###
	If the next character is in `charClass`, read it.
	###
	maybeTake: (charClass) ->
		type charClass, RegExp
		@readChar() if charClass.test @peek()

	###
	The next (or skip-th next) character without modifying the stream.
	###
	peek: (skip = 0) ->
		@_str[@_index + skip]

	###
	Current position in the file.
	###
	pos: ->
		@_pos

	###
	The character before `peek()`.
	###
	prev: ->
		@peek -1

	###
	Takes the next character (modifying the stream).
	###
	readChar: ->
		x = @peek()
		if x == '\n'
			@_pos = @_pos.plusLine()
		else
			@_pos = @_pos.plusColumn()
		@_index += 1
		x

	###
	Goes back `n` characters.
	(If it goes back a line, column info is destroyed,
		but that's OK since \n doesn't become an Expression.)
	###
	stepBack: (n = 1) ->
		times n, =>
			@_index -= 1
			if @peek() == '\n'
				@_pos = @_pos.minusLine()
			else
				@_pos = @_pos.minusColumn()

	###
	Reads as long as characters satisfy `condition`.
	@param condition [Function, RegExp]
	@return [String]
	###
	takeWhile: (condition) ->
		if condition instanceof RegExp
			charClass = condition
			condition = (char) ->
				charClass.test char

		start = @_index
		while @peek() and condition @peek()
			@readChar()
		@_str.slice start, @_index

	###
	Reads until a character is in `charClass`.
	###
	takeUpTo: (charClass) ->
		type charClass, RegExp
		@takeWhile (char) ->
			not charClass.test char