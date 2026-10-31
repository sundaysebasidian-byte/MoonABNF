///|
test "new independent round 7: measured budget thresholds and invalid integer boundaries" {
  for g in [b"s = 3(%s\"a\" / %s\"b\")\r\n", b"s = s %s\"a\" / %s\"b\"\r\n"] {
    let p = @moonabnf.compile(g).unwrap()
    let input = if g == b"s = 3(%s\"a\" / %s\"b\")\r\n" {
      b"aba"
    } else {
      b"baa"
    }
    let normal = p.recognize("s", input)
    assert_eq(normal.status, @moonabnf.Matched)
    for n = 1; n <= normal.work + 1; n = n + 1 {
      let r = p.recognize("s", input, limits={
        ..@moonabnf.default_match_limits(),
        max_work: n,
      })
      assert_true(r.work <= n)
      if n < normal.work {
        assert_true(r.status is @moonabnf.BudgetExceeded(_))
      } else {
        assert_eq(r.status, @moonabnf.Matched)
      }
    }
    let full = p.parse_input("s", input)
    for n in [1, full.nodes - 1, full.nodes, full.nodes + 1] {
      let r = p.parse_input("s", input, limits={
        ..@moonabnf.default_input_tree_limits(),
        max_nodes: n,
      })
      assert_true(r.nodes <= n)
      if n < full.nodes {
        assert_true(r.status is @moonabnf.BudgetExceeded(_))
        assert_true(r.tree is None)
      } else {
        assert_eq(r.status, @moonabnf.Matched)
      }
    }
    for value in [-1, 0, 10000001, 2147483647] {
      let r = p.recognize("missing", b"a", limits={
        ..@moonabnf.default_match_limits(),
        max_work: value,
      })
      assert_eq(r.status, @moonabnf.InvalidLimits)
      assert_eq((r.work, r.states, r.offset), (0, 0, 0))
    }
    assert_eq(p.recognize("s", input), normal)
    assert_eq(p.parse_input("s", input), full)
  }
}
