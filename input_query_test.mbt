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
