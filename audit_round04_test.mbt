///|
test "new independent round 4: result graph mutation cannot poison later parses" {
  for
    grammar in [
      b"s = item item\r\nitem = %s\"a\" / %s\"b\"\r\n", b"s = s item / item\r\nitem = %s\"a\" / %s\"b\"\r\n",
    ] {
    let p = @moonabnf.compile(grammar).unwrap()
    let first = p.parse_input("s", b"ab").tree.unwrap()
    let ids = first.rule_nodes_in("item", first.root).unwrap()
    assert_eq(ids.map(i => first.extract(b"ab", i)), [Some(b"a"), Some(b"b")])
    let root = first.nodes[first.root]
    first.nodes.push({
      kind: @moonabnf.RuleNode("unused"),
      start: -1,
      end: -2,
      source_offset: -1,
      children: [2147483647],
    })
    assert_eq(first.rule_nodes_in("item", first.root), Some(ids))
    first.nodes[first.root] = { ..root, children: [first.root], }
    assert_eq(first.rule_nodes_in("item", first.root), None)
    let fresh = p.parse_input("s", b"ab").tree.unwrap()
    assert_eq(
      fresh
      .rule_nodes_in("item", fresh.root)
      .unwrap()
      .map(i => fresh.extract(b"ab", i)),
      [Some(b"a"), Some(b"b")],
    )
    assert_eq(fresh.span(-1), None)
    assert_eq(fresh.span(2147483647), None)
    assert_eq(fresh.extract(b"a", fresh.root), None)
    // Input identity is explicitly caller responsibility, not a validation promise.
    assert_eq(fresh.extract(b"xy", fresh.root), Some(b"xy"))
  }
  let p = @moonabnf.compile_scalar(
    b"s = item item\r\nitem = %x1F600 / %x4E2D\r\n",
  ).unwrap()
  let input = [0x1F600, 0x4E2D]
  let a = p.parse_input("s", input).unwrap().tree.unwrap()
  let extracted = a.extract(input, a.root).unwrap()
  extracted[0] = 65
  assert_eq(input, [0x1F600, 0x4E2D])
  a.nodes.clear()
  let fresh = p.parse_input("s", input).unwrap().tree.unwrap()
  assert_eq(fresh.extract(input, fresh.root), Some(input))
}
