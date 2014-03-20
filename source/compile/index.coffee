lex = require './lex'
parse = require './parse'

###
Produce a Block from input text.
@param str [String]
###
module.exports = (code) ->
	parse lex code
