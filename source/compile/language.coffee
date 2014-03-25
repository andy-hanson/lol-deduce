# In order of low to high precedence.
@binaryOperators =
	[ '=', '↔', '⊕', '→', '∨', '∧' ]

@char =
	name: /[A-Za-z#0-9'⊥⊤]/
	# `¬` is a special operator, see lex.coffee
	operator: /[∧∨←→=⊕\-+<>]/
	special: /[\,\:\|⇒]/

@keywords =
	[ 'assert', 'declare' ]

@assertKeywords =
	[ 'decided', 'proven' ]
