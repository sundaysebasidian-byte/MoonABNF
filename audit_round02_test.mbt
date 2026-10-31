///|
test "new independent round 2: linking case folding and unreachable semantic errors" {
  let p = @moonabnf.compile(
    b"s = DiGiT\r\nDIGIT = %s\"x\"\r\ndigit =/ %s\"Y\"\r\n",
  ).unwrap()
  for input in [b"x", b"Y"] {
    assert_eq(p.recognize("S", input).status, @moonabnf.Matched)
  }
  for input in [b"1", b"y", b"X"] {
    assert_eq(p.recognize("s", input).status, @moonabnf.NoMatch)
  }
  let q = @moonabnf.compile(b"s = digit\r\nDIGIT =/ %s\"x\"\r\n").unwrap()
  for input in [b"0", b"9", b"x"] {
    assert_eq(q.recognize("s", input).status, @moonabnf.Matched)
  }
  assert_true(
    @moonabnf.compile(b"s = \"a\"\r\nS = \"b\"\r\n") is Err(d) &&
    d.code == "duplicate-rule",
  )
  assert_true(
    @moonabnf.compile(b"s =/ \"a\"\r\ns = \"b\"\r\n") is Err(d) &&
    d.code == "increment-without-base",
  )
  assert_true(
    @moonabnf.compile(b"s = \"a\"\r\nunused = 0missing\r\n") is Err(d) &&
    d.code == "undefined-rule",
  )
  assert_true(
    @moonabnf.compile(b"s = \"a\"\r\nunused = 0<p>\r\n") is Err(d) &&
    d.code == "prose-unsupported",
  )
  let names = q.rule_names()
  names.clear()
  assert_true(!q.rule_names().is_empty())
  assert_eq(q.recognize("s", b"9").status, @moonabnf.Matched)
}
