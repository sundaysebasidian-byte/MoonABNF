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
