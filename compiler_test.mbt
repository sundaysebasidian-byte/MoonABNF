test "link core, extension and case-insensitive names" {
  match @moonabnf.compile(b"Start = AlPhA\r\nSTART =/ DIGIT\r\n") {
    Ok(p) => assert_eq(p.rule_names().length(), 17)
    Err(d) => fail(d.message)
  }
  assert_true(@moonabnf.compile(b"DIGIT = %x61\r\nx = DIGIT\r\n") is Ok(_))
  assert_true(@moonabnf.compile(b"x = missing\r\n") is Err(d) && d.code == "undefined-rule")
  assert_true(@moonabnf.compile(b"x =/ \"a\"\r\n") is Err(d) && d.code == "increment-without-base")
  assert_true(@moonabnf.compile(b"x = \"a\"\r\nX = \"b\"\r\n") is Err(d) && d.code == "duplicate-rule")
  assert_true(@moonabnf.compile(b"x = <external>\r\n") is Err(d) && d.code == "prose-unsupported")
}

test "productive and nullable-prefix cycles are diagnosed" {
  assert_true(@moonabnf.compile(b"x = x\r\n") is Err(d) && d.code == "nonproductive-rule")
  assert_true(@moonabnf.compile(b"x = y\r\ny = x\r\n") is Err(d) && d.code == "nonproductive-rule")
  for g in [b"x = x / \"a\"\r\n", b"x = y / \"a\"\r\ny = x\r\n", b"x = [\"\"] x / \"a\"\r\n", b"x = *\"a\" x / \"a\"\r\n"] {
    assert_true(@moonabnf.compile(g) is Err(d) && d.code == "left-recursion")
  }
  assert_true(@moonabnf.compile(b"x = \"a\" [x]\r\n") is Ok(_))
  assert_true(@moonabnf.compile(b"x = \"(\" [x] \")\" / \"a\"\r\n") is Ok(_))
  assert_true(@moonabnf.compile(b"x = 0x\r\n") is Ok(_))
  assert_true(@moonabnf.compile(b"x = \"a\"\r\n", max_work=1) is Err(d) && d.code == "compile-budget")
}
