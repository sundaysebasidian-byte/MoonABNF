test "AST primitive slice" {
  let g = @moonabnf.parse(b"start = %s\"Hi\" / %x00-FF\r\n")
  assert_true(g is Ok(_))
  assert_true(@moonabnf.parse(b"start = \"x\"\n") is Err(_))
  assert_true(@moonabnf.parse(b"start = %d256\r\n") is Err(_))
}

test "references, increments, repetition and folding" {
  let source = b"; fixture\r\nstart = 1*2(\"a\" / %i\"B\") ; fold\r\n \"c\"\r\nstart =/ [other]\r\nother = %b01000001.01000010\r\n"
  match @moonabnf.parse(source) {
    Ok(g) => {
      assert_eq(g.rules.length(), 3)
      assert_true(g.rules[1].incremental)
      assert_true(g.rules[0].expression is @moonabnf.Sequence(_, _))
    }
    Err(d) => fail(d.message)
  }
}

test "strict syntax and locations" {
  for source in [b"x = \"a\"\"b\"\r\n", b" x = \"a\"\r\n", b"x = %x01-02.03\r\n", b"x = 3*2DIGIT\r\n", b"x = (\"a\"\r\n", b"x = %s\"\xFF\"\r\n", b"x = \"a\";unfinished"] {
    assert_true(@moonabnf.parse(source) is Err(_))
  }
  match @moonabnf.parse(b"x = \"a\"\r\ny = @\r\n") {
    Err(d) => { assert_eq(d.offset, 13); assert_eq(d.line, 2); assert_eq(d.column, 5) }
    Ok(_) => fail("invalid syntax accepted")
  }
  assert_true(@moonabnf.parse(b"\r\n; comment only\r\n") is Ok(_))
}

test "every AST node and parser resource ceiling is enforced" {
  let base = @moonabnf.default_parse_limits()
  assert_true(@moonabnf.parse(b"x = \"a\" / \"b\"\r\n", limits={ ..base, max_nodes: 2 }) is Err(d) && d.code == "parse-budget")
  assert_true(@moonabnf.parse(b"x = 2\"a\"\r\n", limits={ ..base, max_nodes: 1 }) is Err(d) && d.code == "parse-budget")
  assert_true(@moonabnf.parse(b"x = %x00.01\r\n", limits={ ..base, max_nodes: 2 }) is Err(d) && d.code == "parse-budget")
  assert_true(@moonabnf.parse(b"x = (((\"a\")))\r\n", limits={ ..base, max_depth: 2 }) is Err(d) && d.code == "parse-budget")
  assert_true(@moonabnf.parse(b"x = \"a\"\r\ny = \"b\"\r\n", limits={ ..base, max_rules: 1 }) is Err(d) && d.code == "parse-budget")
  assert_true(@moonabnf.parse(b"x = \"a\"\r\n", limits={ ..base, max_bytes: 4 }) is Err(d) && d.code == "parse-budget")
  assert_true(@moonabnf.parse(b"x = \"a\"\r\n", limits={ ..base, max_depth: 65 }) is Err(d) && d.code == "invalid-limits")
  assert_true(@moonabnf.parse(b"x = 1000001\"\"\r\n") is Err(d) && d.code == "number-limit")
  assert_true(@moonabnf.parse(b"x = %") is Err(d) && d.offset == 5)
}

test "folding inside groups, comments and semicolon literals" {
  assert_true(@moonabnf.parse(b"x = (\r\n \"a\" / ; alternatives\r\n \"b\")\r\n") is Ok(_))
  assert_true(@moonabnf.parse(b"x = \"a;b\";fold\r\n \"c\"\r\n") is Ok(_))
  assert_true(@moonabnf.parse(b"x = \"a\"\r\n;standalone\r\ny = \"b\"\r\n") is Ok(_))
  assert_true(@moonabnf.parse(b"x = []\r\n") is Err(_))
  assert_true(@moonabnf.parse(b"x = <description>\r\n") is Ok(_))
}
