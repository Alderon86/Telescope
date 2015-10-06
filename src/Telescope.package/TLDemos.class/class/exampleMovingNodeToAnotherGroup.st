demos
exampleMovingNodeToAnotherGroup
	"self exampleMovingNodeToAnotherGroup"

	| visualization |
	visualization := TLVisualization new.
	visualization styleSheet nodeLabel: #asString.
	visualization > #group1
		layout: RTVerticalLineLayout;
		addNodesFromEntities: ($a to: $d);
		addInteraction: (TLMoveConnectableAction destination: visualization > #group2) onClick;
		addInteraction: (TLStyleCustomizationAction custom: [:style | style backgroundColor: Color red]) onMouseOver.
	visualization > #group2
		layout: RTVerticalLineLayout;
		addNodesFromEntities: ($e to: $h);
		addInteraction: (TLMoveConnectableAction destination: visualization > #group1) onClick;
		addInteraction: (TLStyleCustomizationAction custom: [:style | style backgroundColor: Color blue]) onMouseOver.
	visualization open.
	^ visualization