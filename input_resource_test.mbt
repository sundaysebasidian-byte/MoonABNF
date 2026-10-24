///|
test "wide binary captures stay bounded and budget failure does not poison reuse" {
  let p = checked(b"s = 4096octet\r\nlarge = 8192octet\r\n")
  let input = Bytes::make(4096, 0xFF)
  let r = p.parse_input("s", input)
  assert_eq(r.status, @moonabnf.Matched)
  let tree = r.tree.unwrap()
  let ids = tree.rule_nodes_in("OCTET", tree.root).unwrap()
  assert_eq(ids.length(), 4096)
  for i, id in ids {
    assert_eq(tree.span(id), Some((i, i + 1)))
    assert_eq(tree.extract(input, id), Some(b"\xFF"))
  }
  let base = @moonabnf.default_input_tree_limits()
  assert_true(r.work <= base.matching.max_work)
  assert_true(r.nodes <= base.max_nodes)
  assert_true(r.edges <= base.max_edges)
  let large = Bytes::make(8192, 0x00)
  let limited = p.parse_input("large", large)
  assert_eq(limited.status, @moonabnf.BudgetExceeded("tree-nodes"))
  assert_eq(limited.tree, None)
  assert_eq(limited.nodes, base.max_nodes)
  let expanded = p.parse_input("large", large, limits={
    ..base,
    max_nodes: 40000,
    max_edges: 60000,
  })
  assert_eq(expanded.status, @moonabnf.Matched)
  assert_eq(
    expanded.tree.unwrap().rule_nodes_in("octet", 0).unwrap().length(),
    8192,
  )
  assert_eq(p.parse_input("s", input).tree, Some(tree))
}

///|
test "subtree capture walk is iterative for deep caller-built trees" {
  let nodes : Array[@moonabnf.InputNode] = []
  for i = 0; i < 8192; i = i + 1 {
    nodes.push({
      kind: @moonabnf.RuleNode("nested"),
      start: 0,
      end: 0,
      source_offset: 0,
      children: [i + 1],
    })
  }
  nodes.push({
    kind: @moonabnf.LiteralNode,
    start: 0,
    end: 0,
    source_offset: 0,
    children: [],
  })
  let tree : @moonabnf.InputTree = { nodes, root: 0, }
  let ids = tree.rule_nodes_in("NESTED", 0).unwrap()
  assert_eq(ids.length(), 8192)
  assert_eq(ids[0], 0)
  assert_eq(ids[8191], 8191)
  nodes[8192] = { ..nodes[0], children: [0], }
  assert_eq(tree.rule_nodes_in("nested", 0), None)
}

///|
test "repeat ambiguity retains the earliest actual count and decomposition" {
  for
    (source, expected_count) in [
      (b"s = 1*2(%s\"a\" / %s\"aa\") %s\"b\"\r\n", 1),
      (b"s = 2(%s\"\" / %s\"a\")\r\n", 2),
    ] {
    let input = if expected_count == 1 { b"aab" } else { b"a" }
    let p = checked(source)
    let tree = tree_of(p, "s", input)
    let rules : Map[String, @moonabnf.Expr] = Map([])
    for rule in @moonabnf.parse(source).unwrap().rules {
      rules[rule.name] = rule.expression
    }
    replay(tree, tree.nodes[0].children[0], rules["s"], rules, input)
    let repeats = tree.nodes.filter(n => n.kind is @moonabnf.RepeatNode(_))
    assert_eq(repeats.length(), 1)
    assert_eq(repeats[0].kind, @moonabnf.RepeatNode(expected_count))
    let spans = repeats[0].children.map(id => tree.span(id))
    assert_eq(
      spans,
      if expected_count == 1 {
        [Some((0, 2))]
      } else {
        [Some((0, 0)), Some((0, 1))]
      },
    )
    assert_eq(p.parse_input("s", input).tree, Some(tree))
  }
}
