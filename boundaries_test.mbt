///|
test "ABNF strings are literal ASCII and input remains raw bytes" {
  let p = checked(
    b"literal = %s\"a\\nb\"\r\nquote = %x22\r\nutf8 = %xC3.A9\r\n",
  )
  assert_eq(p.recognize("literal", b"a\\nb").status, @moonabnf.Matched)
  assert_eq(p.recognize("literal", b"a\nb").status, @moonabnf.NoMatch)
  assert_eq(p.recognize("quote", b"\"").status, @moonabnf.Matched)
  assert_eq(p.recognize("utf8", b"\xC3\xA9").status, @moonabnf.Matched)
  assert_eq(p.recognize("utf8", b"\xE9").status, @moonabnf.NoMatch)
  assert_true(
    @moonabnf.parse(b"x = %s\"\xC3\xA9\"\r\n") is Err(d) && d.code == "syntax",
  )
}

///|
test "all grammar rules are validated even if unused or repeated zero times" {
  assert_true(
    @moonabnf.parse(b"; only a comment\r\n") is Ok(g) && g.rules.is_empty(),
  )
  assert_true(
    @moonabnf.compile(b"; only a comment\r\n") is Err(d) && d.code == "no-rules",
  )
  assert_true(
    @moonabnf.compile(b"x = \"a\"\r\nunused = absent\r\n") is Err(d) &&
    d.code == "undefined-rule",
  )
  assert_true(
    @moonabnf.compile(b"x = \"a\"\r\nunused = unused / \"b\"\r\n") is Ok(_),
  )
  assert_true(
    @moonabnf.compile(b"x = 0absent / \"a\"\r\n") is Err(d) &&
    d.code == "undefined-rule",
  )
  assert_true(
    @moonabnf.compile(b"x = 0<external> / \"a\"\r\n") is Err(d) &&
    d.code == "prose-unsupported",
  )
}

///|
test "a discovered match does not override exhausted alternative exploration" {
  let p = checked(b"x = %s\"a\" / (%s\"a\" %s\"b\")\r\n")
  let ordinary = @moonabnf.default_match_limits()
  let report = p.recognize("x", b"a", limits={ ..ordinary, max_work: 5, })
  assert_eq(report.status, @moonabnf.BudgetExceeded("work"))
  assert_eq(report.offset, 1)
  assert_eq(report.work, 5)
  assert_eq(p.recognize("x", b"a").status, @moonabnf.Matched)
  let report = p.recognize("x", b"a", limits={ ..ordinary, max_states: 1, })
  assert_eq(report.status, @moonabnf.BudgetExceeded("states"))
  assert_eq(report.states, 1)
  assert_eq(p.recognize("x", b"a").status, @moonabnf.Matched)
}

///|
test "failure precedence and caller-owned inventory do not corrupt program" {
  let p = checked(b"x = \"\"\r\n")
  let ordinary = @moonabnf.default_match_limits()
  assert_eq(
    p.recognize("x", b"", limits={ ..ordinary, max_input_bytes: 0, }).status,
    @moonabnf.Matched,
  )
  assert_eq(
    p.recognize("absent", b"x", limits={
      ..ordinary,
      max_input_bytes: 0,
      max_work: 0,
    }).status,
    @moonabnf.InvalidLimits,
  )
  assert_eq(
    p.recognize("absent", b"x", limits={ ..ordinary, max_input_bytes: 0, }).status,
    @moonabnf.BudgetExceeded("input-bytes"),
  )
  assert_eq(p.recognize("absent", b"").status, @moonabnf.UnknownRule)
  let names = p.rule_names()
  names[0] = "caller-modified"
  assert_eq(p.recognize("ALPHA", b"A").status, @moonabnf.Matched)
  assert_eq(p.recognize("caller-modified", b"A").status, @moonabnf.UnknownRule)
}
