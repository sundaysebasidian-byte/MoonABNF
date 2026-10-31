///|
test "additional round 19: node arity and integer span validation without recursive traversal" {
  let leaf : @moonabnf.InputNode = {
    kind: @moonabnf.LiteralNode,
    start: 0,
    end: 1,
    source_offset: 4,
    children: [],
  }
  for
    bad in [
      { ..leaf, kind: @moonabnf.RangeNode, end: 2, },
      { ..leaf, kind: @moonabnf.RuleNode("s"), },
      { ..leaf, kind: @moonabnf.ChoiceNode(-1), children: [1], },
      { ..leaf, kind: @moonabnf.RepeatNode(2), children: [1], },
      { ..leaf, kind: @moonabnf.SequenceNode, },
      { ..leaf, source_offset: -1, },
      { ..leaf, start: 2, end: 1, },
      { ..leaf, kind: @moonabnf.RuleNode("s"), children: [2147483647], },
    ] {
    let t : @moonabnf.InputTree = { nodes: [bad, leaf], root: 0, }
    assert_eq(t.rule_nodes_in("s", 0), None)
  }
  let epsilon : @moonabnf.InputNode = {
    kind: @moonabnf.SequenceNode,
    start: 2147483647,
    end: 2147483647,
    source_offset: 0,
    children: [],
  }
  let t : @moonabnf.InputTree = { nodes: [epsilon], root: 0, }
  assert_eq(t.rule_nodes_in("s", 0), Some([]))
  assert_eq(t.extract(b"", 0), None)
}
