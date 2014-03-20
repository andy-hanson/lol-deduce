{ type } = require './help/✔'
{ read } = require './help/meta'
Pos = require './Pos'

module.exports =
	throwInvalidProof: (pos, explain) ->
		err = new Error
		err.invalidProof = new InvalidProof pos, explain

		err.name = 'InvalidProof'
		err.message = err.invalidProof.toString()

		throw err

	InvalidProof: class InvalidProof
		constructor: (@_pos, @_explain) ->

		read @, 'pos', 'explain'

		toString: ->
			"#{@pos()}: #{@explain()}"
