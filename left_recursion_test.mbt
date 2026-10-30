///|
test "left recursion direct indirect nullable and ambiguous finite witnesses" {
  for
    (g, yes, no) in [
      (b"s = s %s\"a\" / %s\"a\"\r\n", b"aaaa", b"aaab"),
      (b"s = t %s\"a\" / %s\"b\"\r\nt = s %s\"c\" / %s\"d\"\r\n", b"bca", b"bc"),
      (b"s = [s] %s\"a\" / %s\"\"\r\n", b"aaa", b"b"),
      (b"s = s s / %s\"a\"\r\n", b"aaaa", b"ab"),
      (b"s = s / %s\"\"\r\n", b"", b"a"),
    ] {
    let p = @moonabnf.compile(g).unwrap()
    assert_eq(p.recognize("s", yes).status, @moonabnf.Matched)
    assert_eq(p.recognize("s", no).status, @moonabnf.NoMatch)
    let r = p.parse_input("s", yes)
    assert_eq(r.status, @moonabnf.Matched)
    assert_true(r.tree is Some(_))
    let tree = r.tree.unwrap()
    assert_eq(tree.nodes[0].start, 0)
    assert_eq(tree.nodes[0].end, yes.length())
    assert_eq(r.tree, p.parse_input("s", yes).tree)
    // finish() emits parents before children, proving no cyclic witness.
    for i = 0; i < tree.nodes.length(); i = i + 1 {
      for child in tree.nodes[i].children {
        assert_true(child > i && child < tree.nodes.length())
      }
    }
  }
}

///|
test "left recursion remains budgeted and cannot invent diagnostic evidence" {
  let p = @moonabnf.compile(b"s = s \"a\" / \"\"\r\n").unwrap()
  let limits = { ..@moonabnf.default_match_limits(), max_work: 1, }
  assert_true(
    p.recognize("s", b"a", limits~).status is @moonabnf.BudgetExceeded(_),
  )
  let d = p.diagnose_input("s", b"b")
  assert_eq(d.report.status, @moonabnf.NoMatch)
  assert_eq(d.explanation_status, "generalized-explanation-unavailable")
  assert_true(d.failure is None)
}

///|
test "closed nonproductive rules compile and denote empty languages" {
  for grammar in [b"s = s\r\n", b"s = t\r\nt = s\r\n", b"s = \"a\" s\r\n"] {
    let p = @moonabnf.compile(grammar).unwrap()
    for input in [b"", b"a", b"aaa"] {
      assert_eq(p.recognize("s", input).status, @moonabnf.NoMatch)
      let tree = p.parse_input("s", input)
      assert_eq(tree.status, @moonabnf.NoMatch)
      assert_true(tree.tree is None)
      assert_eq(
        p.diagnose_input("s", input).explanation_status,
        "empty-language",
      )
    }
  }
  let p = @moonabnf.compile(
    b"s = dead / \"a\"\r\ndead = dead\r\nempty = 0dead\r\n",
  ).unwrap()
  assert_eq(p.recognize("s", b"a").status, @moonabnf.Matched)
  assert_eq(p.parse_input("s", b"a").status, @moonabnf.Matched)
  assert_eq(p.recognize("empty", b"").status, @moonabnf.Matched)
  assert_eq(p.parse_input("empty", b"").status, @moonabnf.Matched)
  let unused = @moonabnf.compile(b"s = \"ok\"\r\ndead = \"a\" dead\r\n").unwrap()
  assert_eq(unused.recognize("s", b"ok").status, @moonabnf.Matched)
}
