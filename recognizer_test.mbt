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
