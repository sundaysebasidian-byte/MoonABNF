///|
test "additional round 13: complete AST offsets incremental flags and numeric-sequence provenance" {
  let g = @moonabnf.parse(
    b";head\r\nFoO = 2*(%s\"A\" / %d66.67) [<note>] ;tail\r\nFoO =/ %i\"x\"\r\n",
  ).unwrap()
  assert_eq(g.rules.length(), 2)
  assert_eq(
    (g.rules[0].name, g.rules[0].incremental, g.rules[0].offset),
    ("foo", false, 7),
  )
  assert_eq(
    g.rules[0].expression,
    @moonabnf.Sequence(
      [
        @moonabnf.Repeat(
          2,
          None,
          @moonabnf.Choice(
            [
              @moonabnf.Literal(b"A", true, 16),
              @moonabnf.Sequence(
                [@moonabnf.Range(66, 66, 24), @moonabnf.Range(67, 67, 24)],
                24,
              ),
            ],
            16,
          ),
          13,
        ),
        @moonabnf.Repeat(0, Some(1), @moonabnf.Prose("note", 34), 33),
      ],
      13,
    ),
  )
  assert_eq(
    (g.rules[1].name, g.rules[1].incremental, g.rules[1].offset),
    ("foo", true, 49),
  )
  assert_eq(g.rules[1].expression, @moonabnf.Literal(b"x", false, 56))
}
