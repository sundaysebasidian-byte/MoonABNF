///|
test "additional round 14: parser byte node declaration and stack-depth ceilings" {
  let g = b"s = %s\"a\" %s\"b\"\r\n"
  assert_true(
    @moonabnf.parse(g, limits={
      ..@moonabnf.default_parse_limits(),
      max_bytes: g.length() - 1,
    })
    is Err(d) &&
    d.code == "parse-budget",
  )
  assert_true(
    @moonabnf.parse(g, limits={
      ..@moonabnf.default_parse_limits(),
      max_bytes: g.length(),
      max_nodes: 3,
    })
    is Ok(_),
  )
  assert_true(
    @moonabnf.parse(g, limits={
      ..@moonabnf.default_parse_limits(),
      max_nodes: 2,
    })
    is Err(d) &&
    d.code == "parse-budget",
  )
  let increment = b"s = \"a\"\r\ns =/ \"b\"\r\n"
  assert_true(
    @moonabnf.parse(increment, limits={
      ..@moonabnf.default_parse_limits(),
      max_rules: 1,
    })
    is Err(d) &&
    d.code == "parse-budget",
  )
  assert_true(
    @moonabnf.parse(increment, limits={
      ..@moonabnf.default_parse_limits(),
      max_rules: 2,
    })
    is Ok(_),
  )
  assert_true(@moonabnf.parse(b"s = (\"a\")\r\n") is Ok(_))
  assert_true(@moonabnf.parse(b"s = ((\"a\"))\r\n") is Ok(_))
  assert_true(
    @moonabnf.parse(
      b"s = (((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((\"a\")))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))\r\n",
    )
    is Ok(_),
  )
  assert_true(
    @moonabnf.parse(
      b"s = ((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((\"a\"))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))\r\n",
    )
    is Ok(_),
  )
  assert_true(
    @moonabnf.parse(
      b"s = (((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((\"a\")))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))\r\n",
    )
    is Err(d) &&
    d.code == "parse-budget",
  )
  assert_true(
    @moonabnf.parse(g, limits={
      ..@moonabnf.default_parse_limits(),
      max_depth: -1,
    })
    is Err(d) &&
    d.code == "invalid-limits",
  )
  assert_true(
    @moonabnf.parse(g, limits={
      ..@moonabnf.default_parse_limits(),
      max_depth: 0,
    })
    is Err(d) &&
    d.code == "invalid-limits",
  )
  assert_true(
    @moonabnf.parse(g, limits={
      ..@moonabnf.default_parse_limits(),
      max_depth: 65,
    })
    is Err(d) &&
    d.code == "invalid-limits",
  )
  assert_true(
    @moonabnf.parse(g, limits={
      ..@moonabnf.default_parse_limits(),
      max_depth: 2147483647,
    })
    is Err(d) &&
    d.code == "invalid-limits",
  )
}
