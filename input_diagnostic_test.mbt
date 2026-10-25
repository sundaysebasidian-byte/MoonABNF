///|
test "diagnostic replay preserves match result, local source byte and EOF" {
  let p = checked(b"s = %s\"abc\"\r\n")
  for
    (input, offset, actual) in [
      (b"abX", 2, Some(88)),
      (b"ab", 2, None),
      (b"abc!", 3, Some(33)),
    ] {
    let d = p.diagnose_input("s", input)
    assert_eq(d.report, p.recognize("s", input))
    let f = d.failure.unwrap()
    assert_eq(f.offset, offset)
    assert_eq(f.actual, actual)
    assert_true(!f.expected.is_empty())
    if input == b"abc!" {
      assert_eq(f.expected[0].expectation, @moonabnf.EndOfInput)
      assert_eq(f.expected[0].grammar_offset, None)
    } else {
      assert_eq(f.expected[0].grammar_offset, Some(4))
    }
  }
}

///|
test "success and match budget are never overwritten; explanation has a separate bound" {
  let p = checked(b"s = %s\"abc\" / %s\"a\"\r\n")
  let good = p.diagnose_input("s", b"a")
  assert_eq(good.report.status, @moonabnf.Matched)
  assert_true(good.failure is None)
  let tiny = p.diagnose_input("s", b"x", diagnostic_limits={
    max_work: 1,
    max_expectations: 1,
  })
  assert_eq(tiny.report.status, @moonabnf.NoMatch)
  assert_true(tiny.explanation_status.has_prefix("budget-exceeded:"))
  assert_true(tiny.explanation_work <= 1)
  let unknown = p.diagnose_input("s", b"x", limits={
    ..@moonabnf.default_match_limits(),
    max_work: 1,
  })
  assert_true(unknown.report.status is @moonabnf.BudgetExceeded(_))
  assert_true(unknown.failure is None)
  assert_eq(p.parse_input("s", b"a").status, @moonabnf.Matched)
}

///|
test "bounded expectation list and synthetic core positions" {
  let p = checked(b"s = %s\"a\" / %s\"b\" / DIGIT\r\n")
  let d = p.diagnose_input("s", b"x", diagnostic_limits={
    max_work: 1000,
    max_expectations: 1,
  })
  assert_true(d.failure.unwrap().truncated)
  assert_eq(d.failure.unwrap().expected.length(), 1)
  let core = checked(b"s = DIGIT\r\n").diagnose_input("s", b"x")
  assert_eq(core.failure.unwrap().expected[0].grammar_offset, None)
}
