{ check, type, typeEach } = require '../help/✔'
{ last } = require '../help/list'
{ cCheck, cFail } = require '../c✔'
{ char, keywords, specialChars } = require './language'
Stream = require './Stream'
T = require './Token'

###
@param stream [Stream]
@param inside [String, Int]
  Context of lexing.
  Are we in an indented block (an int), or in parentheses ('(')?
@return [Array<Token>]
  If this is a 0-indented block, `stream` should now be empty.
###
tokenize = (stream, inside = 0) ->
	type stream, Stream

	out = [ ]

	match = (regex) ->
		regex.test ch
	maybeTake = (regex) ->
		stream.maybeTake regex

	finish = { }

	while ch = stream.peek()
		pos = stream.pos()

		takeName = (charType, kind) ->
			name = stream.takeWhile charType
			if name in keywords
				new T.Special pos, name
			else
				new T.Name pos, kind, name

		token =
			switch
				when match /\\/
					stream.takeUpTo /\n/
					[ ]
				when maybeTake char.special
					new T.Special pos, ch
				when match char.name
					takeName char.name, 'variable'
				when maybeTake /¬/
					new T.Name pos, 'operator', '¬'
				when match char.operator
					takeName char.operator, 'operator'
				when maybeTake /[\(]/
					new T.Group pos, ch, tokenize stream, ch
				when maybeTake /[\)]/
					#match = switch inside
					#	when '('
					#		')'
					#	when '['
					#		']'
					#	else cFail "Unexpected '#{ch}'"
					#cCheck match == ch, pos, ->
					#	"Could not match '#{inside}' with '#{ch}'"
					finish
				when maybeTake /[ \t]/
					[ ]
				when maybeTake /\n/
					cCheck (Object inside) instanceof Number, pos, 'Unexpected newline'
					cCheck stream.prev() != ' ', pos, 'Line ends in a space.'
					# Skip through blank lines.
					stream.takeWhile /\n/
					old = inside
					now = (stream.takeWhile /\t/).length
					cCheck stream.peek() != ' ', stream.pos(),
						'Line begins with a space.'
					indent = now
					if now == old
						new T.Special pos, '\n'
					else if now < old
						stream.stepBack now + 1
						check stream.peek() == '\n'
						finish
					else if now == old + 1
						new T.Group stream.pos(), '→', tokenize stream, now
					else
						cFail pos, 'Line is indented more than once.'
				else
					cFail pos, "Unexpected character '#{ch}'"

		if token == finish
			return out
		else if token instanceof Array
			typeEach token, T.Token
			out.push token...
		else
			type token, T.Token
			out.push token

	out

###
@param str [String]
@return [Array<Token>]
###
module.exports = lex = (str) ->
	type str, String
	stream = new Stream str
	tokens = tokenize stream
	check stream.isEmpty()
	tokens

