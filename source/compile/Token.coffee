{ abstract, check, type, typeEach } = require '../help/✔'
{ read } = require '../help/meta'
Pos=  require '../Pos'

###
Represents a source unit.
###
class Token
	inspect: ->
		@toString()

	pos: ->
		abstract()

###
A bunch of tokens wrapped together.
May be an indented block or an expression in parentheses.
###
class Group extends Token
	###
	@param @_pos [Pos]
	@param @_kind ['(', '[', '→']
	@param @_body [Array<Token>]
	###
	constructor: (@_pos, @_kind, @_body) ->
		type @_pos, Pos
		check @_kind in [ '(', '[', '→' ]
		typeEach @_body, Token
		Object.freeze @

	read @, 'pos', 'kind', 'body'

	# @noDoc
	toString: ->
		"'#{@kind()}'<#{@body()}>"

###
A single word.
###
class Name extends Token
	constructor: (@_pos, @_kind, @_text) ->
		type @_pos, Pos, @_text, String
		check @_kind in [ 'operator', 'variable' ]
		Object.freeze @

	withText: (text) ->
		new Name @pos(), @kind(), text

	read @, 'pos', 'kind', 'text'

	# @noDoc
	toString: ->
		@text()

class Special extends Token
	constructor: (@_pos, @_kind) ->
		type @_pos, Pos, @_kind, String
		Object.freeze @

	read @, 'pos', 'kind'

	# @noDoc
	toString: ->
		k =
			if @kind() == '\n'
				'\\n'
			else
				@kind()
		"`#{k}`"

module.exports =
	Token: Token
	Group: Group
	Name: Name
	Special: Special
	isVariable: (tok) ->
		tok instanceof Name and tok.kind() == 'variable'
	isIndented: (tok) ->
		tok instanceof Group and tok.kind() == '→'
	# Creates a Function returning whether a token is a `Special` of the `kind`.
	special: (kind) -> (token) ->
		token instanceof Special and token.kind() == kind
