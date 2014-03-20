{ check, fail, type, typeEach, typeExist } = require '../help/✔'
{ isEmpty, last, rightTail } = require '../help/list'
{ cCheck, cFail } = require '../c✔'
{ rightUnCons, splitWhere, trySplitOnceWhere, tail } = require '../help/list'
E = require '../Expression'
T = require './Token'
{ binaryOperators } = require './language'
Pos = require '../Pos'
Locals = require './Locals'

###
Class exists only for holding parsing data temporarily.
@private
###
class Parser
	###
	Starts off with `@pos` at the beginning and empty `@locals`.
	###
	constructor: ->
		@pos = Pos.start()
		@locals = new Locals
		E.AllAutoDeclares.forEach (declare) =>
			@locals.addNamed declare



	###
	A single part of a block.
	@return [E.BlockElement, null]
	###
	any: (tokens) ->
		[ beforeBlock, body ] = @maybeTakeLastBlock tokens
		if body == null
			if (T.special 'declare') tokens[0]
				@declare tail tokens
			else
				@line tokens
		else
			@rule (rightTail tokens), body

		###
		if (T.special '⇒') last tokens
			@rule rightTail tokens
		#if (T.special 'rule') tokens[0]
		#	@rule tail tokens
		else if (T.special 'declare') tokens[0]
			@declare tail tokens
		else
			@line tokens
			#[ before, body ] = @maybeTakeLastBlock tokens
			#if body?
			#	@supposition before, body
			#else
			#	@line tokens
		###

	###
	An entire block.
	@return [Array<E.BlockElement>]
	###
	block: (tokens) ->
		parts =
			(splitWhere tokens, T.special '\n').map (part) =>
				unless isEmpty part
					@pos = part[0].pos()
					@any part
			.filter (part) -> part?

		parts

	declare: (tokens) ->
		tokens.forEach (d) =>
			cCheck d instanceof T.Name, d.pos(), "Expected name, not #{d}"
			dec = new E.AtomDeclare d.pos(), d.text()
			@locals.addNamed dec

	###
	References the value called `name`.
	If `type` exists, makes sure the value is of that type.
	###
	get: (name, tipe) ->
		typeExist tipe, Function

		cCheck name instanceof T.Name, name.pos(), ->
			"Expected name, got #{name}"

		#if name.kind() != 'variable' and not @locals.has name.text()
		#	a = new E.Atom name.pos(), name.text()
		#	@locals.addProper name.text(), a
		#	a
		#else

		cCheck (@locals.has name.text()), name.pos(), ->
			"Name #{name.text()} refers to nothing."
		got = @locals.get name.text()
		if got instanceof E.AtomDeclare
			got = new E.AtomReference name.pos(), got
		if tipe?
			cCheck got instanceof tipe, name.pos(), ->
				"Expected a #{tipe.name}, got #{got} (a #{got.constructor.name})."
		got

	###
	e.g. `|implies in1, 1->3`
	@todo 1->3
	###
	justification: (tokens) ->
		cCheck tokens.length > 0, @pos, "Expected justification, got nothing"

		justifier = @get tokens[0], E.ProofPart
		new E.Justification @pos, justifier, (tail tokens).map (token) =>
			@get token, E.BlockElement

	###
	A single line in a block.
	Added to `@locals` if if is labeled.
	###
	line: (tokens) ->
		[ name, rest ] = @maybeTakeLabel tokens
		br = trySplitOnceWhere rest, T.special '|'
		[ exprTokens, justification ] =
			if br?
				[ e, _, j ] = br
				[ e, @justification j ]
			else
				[ rest, null ]

		line = new E.Line @pos, name, (@logic exprTokens), justification
		@locals.maybeAddNamed line
		line

	###
	A logic expression.
	@return [E.Logic]
	###
	logic: (tokens) ->
		type tokens, Array
		cCheck tokens.length > 0, @pos, "Expected expression, got nothing"

		for operator in binaryOperators
			parts = trySplitOnceWhere tokens, (tok) ->
				tok instanceof T.Name and tok.text() == operator
			if parts?
				[ before, em, after ] = parts
				return new E.Fun em.pos(), (@get em), [ before, after ].map (sub) =>
					@logic sub

		@logicPlain tokens

	###
	A logic expression with no binary operators.
	###
	logicPlain: (tokens) ->
		tok0 = tokens[0]
		pos = tok0.pos()
		type tok0, T.Token

		switch tok0.constructor
			when T.Group
				switch tok0.kind()
					when '('
						cCheck tokens.length == 1, tok0.pos(), ->
							"Nothing can follow complex expression #{tok0}"
						@logic tok0.content()
					when '→'
						cFail pos, 'Did not expect indented block'
			when T.Name
				text = tok0.text()
				if text == '¬'
					cCheck tokens.length > 1, pos, ->
						"Expected something after #{tok0}"
					new E.Fun pos, (@get tok0.withText '¬'),
						[ (@logicPlain (tail tokens)) ]
				else
					if tokens.length == 1
						@get tok0
					else
						new E.Fun pos, (@get tok0), (tail tokens).map (token) =>
							@logicPlain [ token ]
			when T.Special
				cFail pos, "Did not expect #{tok0}"
			else
				fail()

	###
	Might read a name from the front of `tokens`.
	@return [([String, null], Array)]
	###
	maybeTakeLabel: (tokens) ->
		if (T.special ':') tokens[1]
			cCheck (T.isVariable tokens[0]), tokens[0].pos(), 'Expected variable name'
			[ tokens[0].text(), tokens.slice 2 ]
		else
			[ null, tokens ]

	###
	Might take a block off of the end of `tokens`.
	@return [ beforeBlock, Array<Token>? ]
	###
	maybeTakeLastBlock: (tokens) ->
		[ before, block ] = rightUnCons tokens
		if T.isIndented block
			[ before, block.body() ]
		else
			[ tokens, null ]


	mustBeName: (name) ->
		cCheck name instanceof T.Name, @pos, ->
			"Expected name, got #{name}"
		name.text()

	###
	A full rule.
	Added to `@locals` if it is labeled.
	E.g. `implies a, b: a -> b, a =>`
	###
	rule: (tokens, proofTokens) ->
		rule = @locals.withFrame =>
			cCheck ((T.special '⇒') last tokens), @pos, 'Rule must end in ⇒'

			#cCheck ((T.special '⇒') last tokens), @pos, 'Rule must end in
			#pc = trySplitOnceWhere ruleDef, T.special '⇒'
			#cCheck pc?, rest[0].pos(), 'Rule must have ⇒'
			#[ preArrow, _, conclusionTokens ] = pc

			preArrow = rightTail tokens
			[ beforeColon, _, premisesTokens ] =
				trySplitOnceWhere preArrow, T.special ':'

			name = @mustBeName beforeColon[0]

			newAtomsTokens = tail beforeColon

			newAtoms =
				newAtomsTokens.map (x) =>
					atomName = @mustBeName x
					newAtom = new E.AtomDeclare x.pos(), atomName
					@locals.add atomName, newAtom
					newAtom

			premises =
				(splitWhere premisesTokens, T.special ',').map (toks) =>
					@logic toks

			for premise, index in premises
				pName = "#{name}#{index + 1}"
				@locals.add pName, new E.Line @pos, pName, premise

			proof =
				@block proofTokens

			new E.Rule @pos, name, newAtoms, premises, proof

		@locals.addNamed rule
		rule

	###
	supposition: (tokens, body) ->
		s = @locals.withFrame =>
			[ before, arrow ] = rightUnCons tokens
			@pos = arrow.pos()
			cCheck ((T.special '=>') arrow), @pos,
				"Supposition must end in '=>'"
			[ name, rest ] = @maybeTakeLabel before
			supposed = @logic rest
			supposedLine = new E.Line arrow.pos(), name, supposed
			@locals.maybeAddNamed supposedLine
			derived = @block body
			imply = @get new T.Name @pos, 'operator', '->'
			new E.Supposition @pos, name, supposed, derived, imply

		@locals.maybeAddNamed s
		s
	###


module.exports = parse = (tokens) ->
	typeEach tokens, T.Token
	(new Parser).block tokens
