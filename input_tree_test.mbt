///|
fn tree_of(
  p : @moonabnf.Program,
  rule : String,
  input : Bytes,
) -> @moonabnf.InputTree raise {
  let r = p.parse_input(rule, input)
  assert_eq(r.status, @moonabnf.Matched)
  let tree = r.tree.unwrap()
  assert_eq(tree.root, 0)
  assert_eq(tree.nodes[0].start, 0)
  assert_eq(tree.nodes[0].end, input.length())
  // Independently check reachable-only tree topology and span conservation.
  let parents = Array::make(tree.nodes.length(), 0)
  for i = 0; i < tree.nodes.length(); i = i + 1 {
    let node = tree.nodes[i]
    assert_true(
      node.start >= 0 && node.start <= node.end && node.end <= input.length(),
    )
    for child in node.children {
      assert_true(child > i && child < tree.nodes.length())
      parents[child] = parents[child] + 1
    }
    match node.kind {
      @moonabnf.LiteralNode | @moonabnf.RangeNode =>
        assert_true(node.children.is_empty())
      @moonabnf.RuleNode(_) | @moonabnf.ChoiceNode(_) => {
        assert_eq(node.children.length(), 1)
        let child = tree.nodes[node.children[0]]
        assert_eq(child.start, node.start)
        assert_eq(child.end, node.end)
      }
      @moonabnf.SequenceNode | @moonabnf.RepeatNode(_) => {
        if node.kind is @moonabnf.RepeatNode(count) {
          assert_eq(node.children.length(), count)
        }
        let mut pos = node.start
        for id in node.children {
          let child = tree.nodes[id]
          assert_eq(child.start, pos)
          pos = child.end
        }
        assert_eq(pos, node.end)
      }
    }
  }
  assert_eq(parents[0], 0)
  for i = 1; i < parents.length(); i = i + 1 {
    assert_eq(parents[i], 1)
  }
  tree
}

///|
test "input tree keeps distinct endpoints and resolves equal endpoints deterministically" {
  let p = checked(
    b"s = (%s\"a\" / %s\"ab\") %s\"c\"\r\nt = a / b\r\na = %s\"x\"\r\nb = %s\"x\"\r\nt =/ %s\"xy\"\r\n",
  )
  let tree = tree_of(p, "S", b"abc")
  assert_true(tree.nodes[0].kind is @moonabnf.RuleNode("s"))
  assert_true(tree.nodes.any(n => n.kind is @moonabnf.ChoiceNode(1)))
  assert_false(tree.nodes.any(n => n.kind is @moonabnf.ChoiceNode(0)))
  let tree = tree_of(p, "t", b"x")
  assert_true(tree.nodes.any(n => n.kind is @moonabnf.RuleNode("a")))
  assert_false(tree.nodes.any(n => n.kind is @moonabnf.RuleNode("b")))
  assert_eq(p.parse_input("t", b"x").tree, p.parse_input("t", b"x").tree)
  let _ = tree_of(p, "t", b"xy")
  let r = p.parse_input("s", b"abc!")
  assert_eq(r.status, @moonabnf.NoMatch)
  assert_eq(r.offset, 3)
  assert_true(r.tree is None)
}

///|
test "input tree materializes nullable minima and finite consuming recursion" {
  let p = checked(
    b"e = 3[\"a\"]\r\nu = *[\"a\"]\r\nhuge = 1000000\"\"\r\nz = 0z\r\nx = %s\"(\" [x] %s\")\" / %s\"a\"\r\n",
  )
  let empty = tree_of(p, "e", b"")
  assert_true(
    empty.nodes.any(n => {
      n.kind is @moonabnf.RepeatNode(3) && n.children.length() == 3
    }),
  )
  for input in [b"a", b"aa", b"aaa"] {
    let _ = tree_of(p, "e", input)
  }
  assert_eq(p.parse_input("e", b"aaaa").status, @moonabnf.NoMatch)
  for input in [b"", b"aaaa"] {
    let _ = tree_of(p, "u", input)
  }
  let _ = tree_of(p, "z", b"")
  for input in [b"a", b"()", b"(a)", b"((a))"] {
    let _ = tree_of(p, "x", input)
  }
  assert_eq(p.parse_input("x", b"((a)").status, @moonabnf.NoMatch)
  assert_eq(p.recognize("huge", b"").status, @moonabnf.Matched)
  let r = p.parse_input("huge", b"")
  assert_true(r.status is @moonabnf.BudgetExceeded(_))
  assert_true(r.tree is None)
}

///|
test "input tree reports raw byte spans and preserves source AST distinction" {
  let source = b"frame = head payload %xFF\r\nhead = %x00\r\npayload = 2OCTET\r\n"
  let p = checked(source)
  let input = b"\x00\xC3\xA9\xFF"
  let tree = tree_of(p, "frame", input)
  let mut found : @moonabnf.InputNode? = None
  for node in tree.nodes {
    if node.kind is @moonabnf.RuleNode("payload") {
      found = Some(node)
    }
  }
  let payload = found.unwrap()
  assert_eq(payload.start, 1)
  assert_eq(payload.end, 3)
  assert_eq(input[payload.start:payload.end].to_owned(), b"\xC3\xA9")
  assert_true(payload.source_offset > 0)
  let ast = @moonabnf.parse(source).unwrap()
  assert_eq(ast.rules.length(), 3)
  tree.nodes[0].children.clear()
  assert_eq(p.recognize("frame", input).status, @moonabnf.Matched)
  let _ = tree_of(p, "frame", input)
}

///|
test "tree allocations and matching budgets fail without returning a partial tree" {
  let p = checked(
    b"s = %s\"a\" / (%s\"a\" %s\"b\")\r\ne = %s\"a\"\r\nr = %s\"a\" [r]\r\n",
  )
  let base = @moonabnf.default_input_tree_limits()
  let matching = base.matching
  let small = p.parse_input("e", b"a")
  assert_eq(small.nodes, 4)
  assert_eq(small.edges, 2)
  assert_eq(small.work, 10)
  assert_eq(small.tree.unwrap().nodes.length(), 2)
  let r = p.parse_input("e", b"a", limits={
    ..base,
    matching: { ..matching, max_work: 9, },
  })
  assert_eq(r.status, @moonabnf.BudgetExceeded("work"))
  assert_true(r.tree is None)
  for
    limits in [
      { ..base, matching: { ..matching, max_work: 1, }, },
      { ..base, matching: { ..matching, max_states: 1, }, },
      { ..base, max_nodes: 1, },
      { ..base, max_edges: 1, },
    ] {
    let r = p.parse_input("s", b"a", limits~)
    assert_true(r.status is @moonabnf.BudgetExceeded(_))
    assert_true(r.tree is None)
    assert_true(r.work <= limits.matching.max_work)
    assert_true(r.states <= limits.matching.max_states)
    assert_true(r.nodes <= limits.max_nodes)
    assert_true(r.edges <= limits.max_edges)
  }
  // Leaf + root require two arena nodes plus two compacted nodes.
  let r = p.parse_input("e", b"a", limits={ ..base, max_nodes: 3, })
  assert_eq(r.status, @moonabnf.BudgetExceeded("tree-nodes"))
  assert_eq(r.nodes, 3)
  assert_true(r.tree is None)
  let r = p.parse_input("e", b"a", limits={ ..base, max_edges: 1, })
  assert_eq(r.status, @moonabnf.BudgetExceeded("tree-edges"))
  assert_true(r.tree is None)
  assert_eq(
    p.parse_input("r", b"aaaaaaaa", limits={
      ..base,
      matching: { ..matching, max_depth: 3, },
    }).status,
    @moonabnf.BudgetExceeded("depth"),
  )
  assert_eq(p.parse_input("absent", b"").status, @moonabnf.UnknownRule)
  assert_eq(
    p.parse_input("absent", b"x", limits={
      ..base,
      matching: { ..matching, max_input_bytes: 0, },
    }).status,
    @moonabnf.BudgetExceeded("input-bytes"),
  )
  for
    limits in [
      { ..base, max_nodes: 0, },
      { ..base, max_nodes: 100001, },
      { ..base, max_edges: 0, },
      { ..base, max_edges: 200001, },
      { ..base, matching: { ..matching, max_depth: 129, }, },
    ] {
    assert_eq(
      p.parse_input("absent", b"x", limits~).status,
      @moonabnf.InvalidLimits,
    )
  }
  let _ = tree_of(p, "e", b"a")
}

///|
test "input tree and recognizer agree on exhaustive small ambiguous inputs" {
  for
    grammar in [
      b"s = (\"a\" / \"ab\") *(\"b\" / \"\")\r\n", b"s = 2*4[\"a\"] *2\"b\"\r\n",
      b"s = \"a\" [s] / \"b\" [s]\r\n", b"s = (a / b) [a]\r\na = \"a\"\r\nb = \"a\" / \"b\"\r\n",
      b"s = 0*3(atom) [tail]\r\natom = %x61-62 / %s\"c\"\r\ntail = %i\"A\"\r\n",
    ] {
    let p = checked(grammar)
    let rules : Map[String, @moonabnf.Expr] = Map([])
    for rule in @moonabnf.parse(grammar).unwrap().rules {
      rules[rule.name] = rule.expression
    }
    for length = 0; length <= 5; length = length + 1 {
      let mut combinations = 1
      for i = 0; i < length; i = i + 1 {
        combinations = combinations * 3
      }
      for code = 0; code < combinations; code = code + 1 {
        let bytes : Array[Byte] = []
        let mut value = code
        for i = 0; i < length; i = i + 1 {
          bytes.push((97 + value % 3).to_byte())
          value = value / 3
        }
        let input = Bytes::from_array(bytes)
        let r = p.parse_input("s", input)
        assert_eq(r.status, p.recognize("s", input).status)
        if r.status is @moonabnf.Matched {
          let tree = tree_of(p, "s", input)
          replay(tree, tree.nodes[0].children[0], rules["s"], rules, input)
        } else {
          assert_true(r.tree is None)
        }
      }
    }
  }
}

///|
test "input tree byte offsets inside UTF8-looking data and trailing bytes" {
  // These are byte grammars. The first alternative can consume a single byte
  // that would be an incomplete UTF-8 code point; neither runner decodes it.
  let p = checked(b"s = (%xC3 / %xC3.A9) %x21\r\n")
  let first = tree_of(p, "s", b"\xC3!")
  assert_true(first.nodes.any(n => n.kind is @moonabnf.ChoiceNode(0)))
  let second = tree_of(p, "s", b"\xC3\xA9!")
  assert_true(second.nodes.any(n => n.kind is @moonabnf.ChoiceNode(1)))
  assert_eq(second.nodes[0].end, 3)
  for
    (input, offset) in [
      (b"", 0),
      (b"\xC3", 1),
      (b"\xC3\xA8!", 1),
      (b"\xC3\xA9", 2),
      (b"\xC3\xA9!\x00", 3),
    ] {
    let r = p.parse_input("s", input)
    assert_eq(r.status, @moonabnf.NoMatch)
    assert_eq(r.offset, offset)
    assert_true(r.tree is None)
    let recognized = p.recognize("s", input)
    assert_eq(recognized.status, @moonabnf.NoMatch)
    assert_eq(recognized.offset, offset)
  }
  assert_eq(p.parse_input("s", b"\xC3\xA9!").tree, Some(second))
}

///|
test "empty ambiguous input has a real zero-width witness and rejects trailing NUL" {
  let p = checked(b"s = a / b\r\na = 2\"\"\r\nb = \"\"\r\n")
  let tree = tree_of(p, "s", b"")
  assert_eq(tree.nodes[0].start, 0)
  assert_eq(tree.nodes[0].end, 0)
  assert_true(tree.nodes.any(n => n.kind is @moonabnf.RuleNode("a")))
  assert_false(tree.nodes.any(n => n.kind is @moonabnf.RuleNode("b")))
  assert_true(
    tree.nodes.any(n => {
      n.kind is @moonabnf.RepeatNode(2) && n.children.length() == 2
    }),
  )
  let rejected = p.parse_input("s", b"\x00")
  assert_eq(rejected.status, @moonabnf.NoMatch)
  assert_eq(rejected.offset, 0)
  assert_true(rejected.tree is None)
  let limited = p.parse_input("s", b"", limits={
    ..@moonabnf.default_input_tree_limits(),
    max_nodes: 1,
  })
  assert_true(limited.status is @moonabnf.BudgetExceeded(_))
  assert_true(limited.tree is None)
  assert_eq(p.parse_input("s", b"").tree, Some(tree))
}
