///|
fn main raise {
  let program = @abnf.compile(@etag.grammar()).unwrap()
  let input = b"W/\"revision-7\""
  let report = program.parse_input("entity-tag", input)
  assert_eq(report.status, @abnf.Matched)
  let span = @etag.extract(report.tree.unwrap())
  assert_true(span.weak)
  assert_eq(input[span.value_start:span.value_end].to_owned(), b"revision-7")
  assert_eq(
    program.parse_input("entity-tag", b"w/\"revision-7\"").status,
    @abnf.NoMatch,
  )
  println(
    "HTTP ETag: weak=\{span.weak} value-bytes=[\{span.value_start},\{span.value_end})",
  )
}
