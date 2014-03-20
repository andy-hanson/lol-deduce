ld = require '../js'

describe 'Logic', ->
	it 'works', ->
		proof = '''
		declare x y z ∨ ¬

		repeat a: a ⇒
			a

		xForbidsY: x → ¬y
		yesX: x

		x → ¬y		|repeat xForbidsY
		notY: ¬y	|xForbidsY yesX

		bool a: ⇒
			a ∨ ¬a

		x ∨ ¬x	|bool

		onlyOption a b: a ∨ b, ¬b ⇒
			a

		zOrY: z ∨ y

		ifX: x ⇒
			a: ¬y	|xForbidsY ifX1
			z		|onlyOption zOrY a

		xImpliesZ: x → z	|repeat ifX
		z					|xImpliesZ yesX

		'''

		ld.checkOrThrow proof
