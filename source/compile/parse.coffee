{ check, fail, type, typeEach, typeExist } = require '../help/✔'
{ isEmpty, last, rightTail } = require '../help/list'
{ cCheck, cFail } = require '../c✔'
{ rightUnCons, splitWhere, trySplitOnceWhere, tail } = require '../help/list'
E = require '../Expression'
T = require './Token'
{ assertKeywords, binaryOperators } = require './language'
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
	@return [E.ProofPart, null]
	###
	any: (tokens) ->
		@pos = tokens[0].pos()

		[ beforeBlock, body ] = @maybeTakeLastBlock tokens
		if body == null
			if (T.special 'declare') tokens[0]
				@declare tail tokens
			else if (T.special 'assert') tokens[0]
				@assert tail tokens
			else
				@line tokens
		else
			@rule (rightTail tokens), body

	assert: (tokens) ->
		# TODO: assert only 1 token before colon
		[ beforeColon, _, logicsTokens ] =
			(trySplitOnceWhere tokens, T.special ':') ?
			cFail @pos, "Assert must have colon"
		kind = @nameText beforeColon[0]

		cCheck kind in assertKeywords, @pos, ->
			keys = "{ #{assertKeywords.join ', '} }"
			"`assert` must be followed by one of #{keys}, not #{kind}"

		logics = (splitWhere logicsTokens, T.special ',').map (lTokens) =>
			@logic lTokens
		new E.Assert @pos, kind, logics

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
			dec = new E.AtomDeclare d.pos(), @nameText d
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
						@logic tok0.body()
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


	nameText: (name) ->
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

			preArrow = rightTail tokens

			{ name, newAtoms, premisesTokens } =
				if (split = trySplitOnceWhere preArrow, T.special ':')?
					[ beforeColon, _, premisesTokens ] = split

					newAtomsTokens = tail beforeColon

					name: @nameText beforeColon[0]
					newAtoms:
						newAtomsTokens.map (x) =>
							atomName = @nameText x
							newAtom = new E.AtomDeclare x.pos(), atomName
							@locals.add atomName, newAtom
							newAtom
					premisesTokens: premisesTokens

				else
					name: null
					newAtoms: []
					premisesTokens: preArrow


			premises =
				(splitWhere premisesTokens, T.special ',').map (toks) =>
					@logic toks

			if name?
				for premise, index in premises
					premiseName = "#{name}##{index + 1}"
					@locals.add premiseName, new E.Line @pos, premiseName, premise

			proof =
				@block proofTokens

			new E.Rule @pos, name, newAtoms, premises, proof

		@locals.addNamed rule
		rule


module.exports = parse = (tokens) ->
	typeEach tokens, T.Token
	(new Parser).block tokens
