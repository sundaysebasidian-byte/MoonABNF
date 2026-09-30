test "AST primitive slice" {
  let g = parse(b"start = %s\"Hi\" / %x00-FF\r\n")
  assert_true(g is Ok(_))
  assert_true(parse(b"start = \"x\"\n") is Err(_))
  assert_true(parse(b"start = %d256\r\n") is Err(_))
}

test "references, increments, repetition and folding" {
  let source = b"; fixture\r\nstart = 1*2(\"a\" / %i\"B\") ; fold\r\n \"c\"\r\nstart =/ [other]\r\nother = %b01000001.01000010\r\n"
  match parse(source) {
    Ok(g) => {
      assert_eq(g.rules.length(), 3)
      assert_true(g.rules[1].incremental)
      assert_true(g.rules[0].expression is Sequence(_, _))
    }
    Err(d) => fail(d.message)
  }
}

test "strict syntax and locations" {
  for source in [b"x = \"a\"\"b\"\r\n", b" x = \"a\"\r\n", b"x = %x01-02.03\r\n", b"x = 3*2DIGIT\r\n", b"x = (\"a\"\r\n", b"x = %s\"\xFF\"\r\n", b"x = \"a\";unfinished"] {
    assert_true(parse(source) is Err(_))
  }
  match parse(b"x = \"a\"\r\ny = @\r\n") {
    Err(d) => { assert_eq(d.offset, 13); assert_eq(d.line, 2); assert_eq(d.column, 5) }
    Ok(_) => fail("invalid syntax accepted")
  }
  assert_true(parse(b"\r\n; comment only\r\n") is Ok(_))
}
