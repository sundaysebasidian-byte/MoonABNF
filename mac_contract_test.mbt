///|
test "Mac audit: later branch depth exhaustion discards an earlier full witness" {
  let p = checked(b"s = %s\"a\" / (%s\"a\" [s])\r\n")
  let limits = @moonabnf.default_input_tree_limits()
  let r = p.parse_input("s", b"a", limits={
    ..limits,
    matching: { ..limits.matching, max_depth: 2, },
  })
  assert_eq(r.status, @moonabnf.BudgetExceeded("depth"))
  assert_eq(r.offset, 1)
  assert_true(r.tree is None)
  let _ = tree_of(p, "s", b"a")
  assert_eq(p.recognize("s", b"a").status, @moonabnf.Matched)
}

///|
test "Mac audit: every deterministic allocation threshold preserves status and no partial tree" {
  for
    (grammar, input) in [
      (b"s = a / b\r\na = %s\"x\"\r\nb = %s\"x\"\r\n", b"x"),
      (b"s = 2*4[\"a\"] *2\"b\"\r\n", b"aab"),
      (b"s = %s\"a\" [s] / %s\"\"\r\n", b"aaa"),
    ] {
    let p = checked(grammar)
    let base = @moonabnf.default_input_tree_limits()
    let expected = p.parse_input("s", input)
    assert_eq(expected.status, @moonabnf.Matched)
    assert_true(expected.work < 5000)
    for budget = 1; budget <= expected.work; budget = budget + 1 {
      let r = p.parse_input("s", input, limits={
        ..base,
        matching: { ..base.matching, max_work: budget, },
      })
      assert_true(r.work <= budget)
      if budget == expected.work {
        assert_eq(r.status, @moonabnf.Matched)
        assert_eq(r.tree, expected.tree)
      } else {
        assert_eq(r.status, @moonabnf.BudgetExceeded("work"))
        assert_true(r.tree is None)
      }
    }
    for budget = 1; budget <= expected.nodes; budget = budget + 1 {
      let r = p.parse_input("s", input, limits={ ..base, max_nodes: budget, })
      assert_true(r.nodes <= budget)
      if budget == expected.nodes {
        assert_eq(r.tree, expected.tree)
        assert_eq(r.status, @moonabnf.Matched)
      } else {
        assert_eq(r.status, @moonabnf.BudgetExceeded("tree-nodes"))
        assert_true(r.tree is None)
      }
    }
    for budget = 1; budget <= expected.edges; budget = budget + 1 {
      let r = p.parse_input("s", input, limits={ ..base, max_edges: budget, })
      assert_true(r.edges <= budget)
      if budget == expected.edges {
        assert_eq(r.tree, expected.tree)
        assert_eq(r.status, @moonabnf.Matched)
      } else {
        assert_eq(r.status, @moonabnf.BudgetExceeded("tree-edges"))
        assert_true(r.tree is None)
      }
    }
    for budget = 1; budget <= expected.states; budget = budget + 1 {
      let r = p.parse_input("s", input, limits={
        ..base,
        matching: { ..base.matching, max_states: budget, },
      })
      assert_true(r.states <= budget)
      if budget == expected.states {
        assert_eq(r.tree, expected.tree)
        assert_eq(r.status, @moonabnf.Matched)
      } else {
        assert_eq(r.status, @moonabnf.BudgetExceeded("states"))
        assert_true(r.tree is None)
      }
    }
  }
}

///|
test "Mac audit: compile diagnostics, long recursion and oversized input remain distinct" {
  for
    grammar in [
      b"s = s %s\"a\" / %s\"\"\r\n", b"s = [\"x\"] t\r\nt = s / \"y\"\r\n",
    ] {
    assert_true(@moonabnf.compile(grammar) is Ok(_))
  }
  assert_true(@moonabnf.compile(b"s = %s\"a\" s\r\n") is Ok(_))
  let p = checked(b"r = %s\"a\" [r]\r\ne = %s\"\"\r\n")
  let deep = Bytes::from_array(Array::make(128, b'a'))
  let r = p.parse_input("r", deep)
  assert_eq(r.status, @moonabnf.BudgetExceeded("depth"))
  assert_true(r.tree is None)
  let _ = tree_of(p, "r", b"aaa")
  let base = @moonabnf.default_input_tree_limits()
  let zero = p.parse_input("e", b"", limits={
    ..base,
    matching: { ..base.matching, max_input_bytes: 0, },
  })
  assert_eq(zero.status, @moonabnf.Matched)
  assert_eq(zero.tree.unwrap().nodes[0].end, 0)
  let huge = Bytes::from_array(Array::make(65537, b'a'))
  let r = p.parse_input("absent", huge)
  assert_eq(r.status, @moonabnf.BudgetExceeded("input-bytes"))
  assert_true(r.tree is None)
  assert_eq(r.work, 0)
  assert_eq(r.states, 0)
  assert_eq(r.nodes, 0)
  assert_eq(r.edges, 0)
  assert_eq(
    p.parse_input("absent", huge, limits={ ..base, max_nodes: 100001, }).status,
    @moonabnf.InvalidLimits,
  )
}
