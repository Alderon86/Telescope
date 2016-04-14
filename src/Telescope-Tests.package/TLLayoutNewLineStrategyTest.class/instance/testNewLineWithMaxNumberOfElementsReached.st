tests
testNewLineWithMaxNumberOfElementsReached
	| node |
	strategy := TLLayoutNewLineMaxNumberElementsStrategy maxNumberOfElements: 1.
	node := Mock new.
	node stub dimension willReturn: 10 @ 10.
	self deny: (strategy shouldCreateNewLineFrom: 0 @ 0 currentNodeNumberOnLine: 1 forDimension: node dimension).
	self assert: (strategy shouldCreateNewLineFrom: 0 @ 0 currentNodeNumberOnLine: 2 forDimension: node dimension)