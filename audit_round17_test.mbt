///|
test "additional round 17: multiple lowered prose occurrences retain distinct source offsets" {
  let p = @moonabnf.compile_scalar(b"s = <p> \"-\" <p>\r\n", bindings=[
    { name: "p", predicate: @moonabnf.Words([[0x1F600], [0x4E2D]]), },
  ]).unwrap()
  let t = p.parse_input("s", [0x1F600, 45, 0x4E2D]).unwrap().tree.unwrap()
  let ranges = t.nodes.filter(n => n.kind is @moonabnf.RangeNode)
  assert_eq(ranges.length(), 2)
  assert_eq(
    (ranges[0].start, ranges[0].end, ranges[0].source_offset),
    (0, 1, 4),
  )
  assert_eq(
    (ranges[1].start, ranges[1].end, ranges[1].source_offset),
    (2, 3, 12),
  )
}
