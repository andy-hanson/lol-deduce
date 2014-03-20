str = """

"""

# (require 'source-map-support').install()

lex = require './compile/lex'
compile = require './compile'
check = require './check'



# str = (require 'fs').readFileSync 'honey-source/test.honey', 'utf8'

expr = compile str

check expr

###

rule denialAffirms: ~A -> A => A
	1: ~A =>
		A |implies denialAffirms1
	2: ~ ~A |deniesSelf 1
	A |doubleNegative 2

rule excludedMiddle: => A . ~A
	1: ~ (A . ~A) =>
		2: A =>
			A . ~A |orL 2
		~ A |absurd 2, 1
		A . ~A
	A . ~A |denialAffirms 1

###