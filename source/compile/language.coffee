# In order of low to high precedence.
@binaryOperators =
	[ '=', '↔', '⊕', '→', '∨', '∧' ]

@char =
	name: /[A-Za-z0-9]/
	operator: /[∧∨¬→↔⊕⇒\-+<>]/
	special: /[\,\:\|]/

@keywords =
	[ 'declare', 'rule', '⇒' ]
