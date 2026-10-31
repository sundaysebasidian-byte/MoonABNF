///|
test "additional round 18: composition depth boundary and repeated DAG expansion bound" {
  let mut accepted = @moonabnf.Words([[97]])
  for i = 0; i < 63; i = i + 1 {
    accepted = @moonabnf.Concat([accepted])
  }
  let p = @moonabnf.compile_with_prose(b"s = <p>\r\n", [
    { name: "p", predicate: accepted, },
  ]).unwrap()
  assert_eq(p.recognize("s", b"a").status, @moonabnf.Matched)
  let too_deep = @moonabnf.Concat([accepted])
  assert_true(
    @moonabnf.compile_with_prose(b"s = <p>\r\n", [
      { name: "p", predicate: too_deep, },
    ])
    is Err(d) &&
    d.code == "compile-budget",
  )
  let mut dag = @moonabnf.Words([[97]])
  for i = 0; i < 14; i = i + 1 {
    dag = @moonabnf.Alternative([dag, dag])
  }
  assert_true(
    @moonabnf.compile_with_prose(b"s = <p>\r\n", [
      { name: "p", predicate: dag, },
    ])
    is Err(d) &&
    d.code == "compile-budget",
  )
}
