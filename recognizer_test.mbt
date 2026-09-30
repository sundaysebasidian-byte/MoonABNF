fn checked(g : Bytes) -> @moonabnf.Program raise {
  match @moonabnf.compile(g) { Ok(p) => p; Err(d) => fail(d.message) }
}

test "all alternatives, case modes and exact numeric sequences" {
  let p = checked(b"x = (\"a\" / \"ab\") \"c\"\r\ns = %s\"aBc\"\r\ni = %i\"aBc\"\r\nn = %x61.62.63\r\n")
  for input in [b"ac", b"abc", b"ABC"] { assert_eq(p.recognize("X", input).status, @moonabnf.Matched) }
  assert_eq(p.recognize("x", b"ab").status, @moonabnf.NoMatch)
  assert_eq(p.recognize("s", b"aBc").status, @moonabnf.Matched)
  assert_eq(p.recognize("s", b"abc").status, @moonabnf.NoMatch)
  assert_eq(p.recognize("i", b"ABC").status, @moonabnf.Matched)
  assert_eq(p.recognize("n", b"abc").status, @moonabnf.Matched)
  assert_eq(p.recognize("n", b"ABC").status, @moonabnf.NoMatch)
  assert_eq(p.recognize("missing", b"").status, @moonabnf.UnknownRule)
}

test "nullable repeats, exact counts, incremental choices and endpoints" {
  let p = checked(b"x = 2*3[\"a\"] \"b\"\r\nx =/ %s\"other\"\r\ne = 1000000\"\"\r\nz = 0z\r\nr = 1*DIGIT\r\n")
  for input in [b"b", b"ab", b"aab", b"aaab", b"other"] { assert_eq(p.recognize("x", input).status, @moonabnf.Matched) }
  assert_eq(p.recognize("x", b"aaaab").status, @moonabnf.NoMatch)
  assert_eq(p.recognize("e", b"").status, @moonabnf.Matched)
  assert_eq(p.recognize("z", b"").status, @moonabnf.Matched)
  assert_eq(p.recognize("r", b"").status, @moonabnf.NoMatch)
  assert_eq(p.recognize("r", b"123").status, @moonabnf.Matched)
  let report = p.recognize("r", b"12x")
  assert_eq(report.status, @moonabnf.NoMatch)
  assert_eq(report.offset, 2)
}

test "resource exhaustion is distinct from non-match" {
  let p = checked(b"x = *OCTET\r\nr = \"a\" [r]\r\n")
  let ordinary = @moonabnf.default_match_limits()
  assert_true(p.recognize("x", b"123", limits={ ..ordinary, max_input_bytes: 2 }).status is @moonabnf.BudgetExceeded("input-bytes"))
  let tiny = { ..ordinary, max_work: 8 }
  let report = p.recognize("x", b"123456789", limits=tiny)
  assert_true(report.status is @moonabnf.BudgetExceeded("work"))
  assert_true(report.work <= tiny.max_work)
  let report = p.recognize("x", b"123", limits={ ..ordinary, max_states: 1 })
  assert_true(report.status is @moonabnf.BudgetExceeded("states"))
  assert_eq(report.states, 1)
  assert_true(p.recognize("r", b"aaaaaaaaaa", limits={ ..ordinary, max_depth: 4 }).status is @moonabnf.BudgetExceeded("depth"))
  assert_eq(p.recognize("x", b"", limits={ ..ordinary, max_work: 0 }).status, @moonabnf.InvalidLimits)
  assert_eq(p.recognize("x", b"", limits={ ..ordinary, max_depth: 1000 }).status, @moonabnf.InvalidLimits)
  let big = Bytes::from_array(Array::make(65537, b'a'))
  assert_true(p.recognize("x", big).status is @moonabnf.BudgetExceeded("input-bytes"))
}

test "consuming recursion and furthest real byte locations" {
  let p = checked(b"x = %s\"(\" [x] %s\")\" / %s\"a\"\r\ns = %s\"abc\"\r\n")
  for input in [b"a", b"()", b"(a)", b"((a))"] { assert_eq(p.recognize("x", input).status, @moonabnf.Matched) }
  assert_eq(p.recognize("x", b"((a)").status, @moonabnf.NoMatch)
  assert_eq(p.recognize("s", b"abZsuffix").offset, 2)
  assert_eq(p.recognize("s", b"ab").offset, 2)
  assert_eq(p.recognize("s", b"abcx").offset, 3)
}

test "all 256 byte boundaries against independent core predicates" {
  let p = checked(b"x = OCTET\r\n")
  for b = 0; b < 256; b = b + 1 {
    let input = Bytes::from_array([b.to_byte()])
    for (name, expected) in [
      ("OCTET", true), ("CHAR", b > 0 && b < 128),
      ("CTL", b < 32 || b == 127), ("ALPHA", (b >= 65 && b <= 90) || (b >= 97 && b <= 122)),
      ("DIGIT", b >= 48 && b <= 57), ("BIT", b == 48 || b == 49),
      ("HEXDIG", (b >= 48 && b <= 57) || (b >= 65 && b <= 70) || (b >= 97 && b <= 102)),
      ("VCHAR", b >= 33 && b <= 126), ("WSP", b == 32 || b == 9),
      ("SP", b == 32), ("HTAB", b == 9), ("CR", b == 13), ("LF", b == 10), ("DQUOTE", b == 34),
    ] { assert_eq(p.recognize(name, input).status == @moonabnf.Matched, expected) }
  }
  assert_eq(p.recognize("CRLF", b"\r\n").status, @moonabnf.Matched)
  assert_eq(p.recognize("CRLF", b"\n").status, @moonabnf.NoMatch)
  assert_eq(p.recognize("LWSP", b" \t\r\n \t").status, @moonabnf.Matched)
  assert_eq(p.recognize("LWSP", b"\r\n").status, @moonabnf.NoMatch)
}
