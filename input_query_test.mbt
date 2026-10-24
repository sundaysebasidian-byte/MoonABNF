///|
test "named captures expose byte spans and copied binary bytes" {
  let input = b"\x00\xFF"
  let tree = checked(
    b"frame = item item tail\r\nitem = OCTET\r\ntail = \"\"\r\n",
  ).parse_input("frame", input).tree.unwrap()
  let ids = tree.rule_nodes("ITEM")
  assert_eq(ids.length(), 2)
  assert_eq(tree.span(ids[0]), Some((0, 1)))
  assert_eq(tree.span(ids[1]), Some((1, 2)))
  assert_eq(tree.extract(input, ids[0]), Some(b"\x00"))
  assert_eq(tree.extract(input, ids[1]), Some(b"\xFF"))
  assert_eq(tree.extract(input, tree.rule_nodes("tail")[0]), Some(b""))
  assert_eq(tree.rule_nodes("absent"), [])
  assert_eq(tree.extract(b"", ids[1]), None)
  assert_eq(tree.extract(input, -1), None)
  assert_eq(tree.span(tree.nodes.length()), None)
  assert_eq(tree.rule_nodes("FRAME"), [0])
}

///|
test "query helpers bound malformed public trees without following cycles" {
  let node : @moonabnf.InputNode = {
    kind: @moonabnf.RuleNode("S"),
    start: -1,
    end: 2,
    source_offset: 0,
    children: [0],
  }
  let tree : @moonabnf.InputTree = { nodes: [node], root: 0, }
  assert_eq(tree.rule_nodes("s"), [0])
  assert_eq(tree.span(0), None)
  assert_eq(tree.extract(b"abc", 0), None)
  tree.nodes[0] = { ..node, start: 2, end: 1, }
  assert_eq(tree.extract(b"abc", 0), None)
  tree.nodes[0] = { ..node, start: 0, end: 4, }
  assert_eq(tree.extract(b"abc", 0), None)
}

///|
test "subtree captures use derivation order rather than breadth-first storage" {
  let input = b"ab"
  let tree = checked(
    b"s = wrap item\r\nwrap = inner\r\ninner = item\r\nitem = OCTET\r\n",
  ).parse_input("s", input).tree.unwrap()
  let stored = tree.rule_nodes("item")
  assert_eq(stored.map(id => tree.extract(input, id)), [Some(b"b"), Some(b"a")])
  let ordered = tree.rule_nodes_in("ITEM", tree.root).unwrap()
  assert_eq(ordered.map(id => tree.extract(input, id)), [Some(b"a"), Some(b"b")])
  let wrap = tree.rule_nodes("wrap")[0]
  assert_eq(tree.rule_nodes_in("item", wrap), Some([ordered[0]]))
  assert_eq(tree.rule_nodes_in("WRAP", wrap), Some([wrap]))
  assert_eq(tree.rule_nodes_in("missing", wrap), Some([]))
  let recursive = checked(b"n = %s\"a\" [n]\r\n").parse_input("n", b"aaa").tree.unwrap()
  let ids = recursive.rule_nodes_in("n", recursive.root).unwrap()
  assert_eq(ids.map(id => recursive.span(id)), [
    Some((0, 3)),
    Some((1, 3)),
    Some((2, 3)),
  ])
}

///|
test "empty captures differ from absent captures and extraction does not authenticate input" {
  let tree = checked(
    b"s = empty [absent] empty\r\nempty = \"\"\r\nabsent = \"x\"\r\n",
  ).parse_input("s", b"").tree.unwrap()
  let ids = tree.rule_nodes_in("empty", tree.root).unwrap()
  assert_eq(ids.length(), 2)
  assert_eq(ids.map(id => tree.span(id)), [Some((0, 0)), Some((0, 0))])
  assert_eq(ids.map(id => tree.extract(b"", id)), [Some(b""), Some(b"")])
  assert_eq(tree.rule_nodes_in("absent", tree.root), Some([]))
  let tree = checked(b"s = %x00.FF\r\n").parse_input("s", b"\x00\xFF").tree.unwrap()
  assert_eq(tree.extract(b"ab", 0), Some(b"ab"))
  assert_eq(tree.extract(b"abc", 0), Some(b"ab"))
  assert_eq(tree.extract(b"a", 0), None)
  let owned = tree.extract(b"\x00\xFF", 0).unwrap()
  tree.nodes.clear()
  assert_eq(owned, b"\x00\xFF")
}

///|
test "subtree query rejects malformed topology and spans without panicking" {
  let leaf : @moonabnf.InputNode = {
    kind: @moonabnf.LiteralNode,
    start: 0,
    end: 1,
    source_offset: 0,
    children: [],
  }
  let root : @moonabnf.InputNode = {
    ..leaf,
    kind: @moonabnf.RuleNode("s"),
    children: [1],
  }
  let valid : @moonabnf.InputTree = { nodes: [root, leaf], root: 0, }
  assert_eq(valid.rule_nodes_in("s", 0), Some([0]))
  assert_eq(valid.rule_nodes_in("s", -1), None)
  assert_eq(valid.rule_nodes_in("s", 2), None)
  for
    bad in [
      { ..root, children: [0], },
      { ..root, children: [2], },
      { ..root, children: [-1], },
      { ..root, children: [2147483647], },
      { ..root, children: [], },
      { ..root, kind: @moonabnf.SequenceNode, children: [1, 1], },
      { ..root, kind: @moonabnf.RepeatNode(2), },
      { ..root, kind: @moonabnf.ChoiceNode(-1), },
      { ..root, source_offset: -1, },
      { ..root, start: -1, },
      { ..root, start: 2, },
      { ..root, end: 0, },
      { ..root, end: 2, },
    ] {
    let tree : @moonabnf.InputTree = { nodes: [bad, leaf], root: 0, }
    assert_eq(tree.rule_nodes_in("s", 0), None)
    // Only the requested subtree is checked; a valid leaf stays queryable.
    assert_eq(tree.rule_nodes_in("s", 1), Some([]))
  }
  for
    bad in [
      { ..leaf, kind: @moonabnf.RangeNode, end: 0, },
      { ..leaf, kind: @moonabnf.RepeatNode(0), },
      { ..leaf, kind: @moonabnf.SequenceNode, },
      { ..leaf, children: [0], },
      { ..leaf, start: 1, end: 0, },
      { ..leaf, end: 2, },
    ] {
    let tree : @moonabnf.InputTree = { nodes: [root, bad], root: 0, }
    assert_eq(tree.rule_nodes_in("s", 0), None)
  }
  // A cycle of individually plausible zero-width sequence nodes.
  let a : @moonabnf.InputNode = {
    ..root,
    kind: @moonabnf.SequenceNode,
    end: 0,
  }
  let b : @moonabnf.InputNode = { ..a, children: [0], }
  let cycle : @moonabnf.InputTree = { nodes: [a, b], root: 0, }
  assert_eq(cycle.rule_nodes_in("s", 0), None)
}

///|
test "subtree traversal accepts arbitrary storage order and rejects shared descendants" {
  let leaf : @moonabnf.InputNode = {
    kind: @moonabnf.LiteralNode,
    start: 0,
    end: 0,
    source_offset: 0,
    children: [],
  }
  let item : @moonabnf.InputNode = {
    ..leaf,
    kind: @moonabnf.RuleNode("item"),
    children: [0],
  }
  let root : @moonabnf.InputNode = {
    ..item,
    kind: @moonabnf.RuleNode("s"),
    children: [1],
  }
  let reordered : @moonabnf.InputTree = { nodes: [leaf, item, root], root: 2, }
  assert_eq(reordered.rule_nodes_in("item", reordered.root), Some([1]))
  assert_eq(reordered.rule_nodes_in("s", reordered.root), Some([2]))
  let parent : @moonabnf.InputNode = { ..item, children: [3], }
  let diamond : @moonabnf.InputTree = {
    nodes: [
      { ..leaf, kind: @moonabnf.SequenceNode, children: [1, 2], },
      parent,
      parent,
      leaf,
    ],
    root: 0,
  }
  assert_eq(diamond.rule_nodes_in("item", 0), None)
  assert_eq(diamond.rule_nodes_in("item", 1), Some([1]))
}
