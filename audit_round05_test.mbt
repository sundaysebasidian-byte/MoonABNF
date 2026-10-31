///|
test "new independent round 5: byte scalar parity and surrogate suffix validation" {
  let bp = @moonabnf.compile(b"s = %x00-1F / %x41-5A / %x80-FF\r\n").unwrap()
  let sp = @moonabnf.compile_scalar(b"s = %x00-1F / %x41-5A / %x80-FF\r\n").unwrap()
  for i = 0; i < 256; i = i + 1 {
    let input = Bytes::from_array([i.to_byte()])
    assert_eq(
      sp.recognize("s", [i]).unwrap().status,
      bp.recognize("s", input).status,
    )
    assert_eq(
      sp.parse_input("s", [i]).unwrap().status,
      bp.parse_input("s", input).status,
    )
  }
  let wide = @moonabnf.compile_scalar(b"s = *%x0-10FFFF\r\n").unwrap()
  for (index, value) in [(0, -1), (1, 0xD800), (2, 0xDFFF), (3, 0x110000)] {
    let xs = [65, 66, 67, 68]
    xs[index] = value
    assert_eq(
      wide.recognize("s", xs),
      Err(@moonabnf.InvalidScalar(index, value)),
    )
    assert_eq(
      wide.parse_input("s", xs),
      Err(@moonabnf.InvalidScalar(index, value)),
    )
  }
  let limited = { ..@moonabnf.default_scalar_match_limits(), max_work: 2, }
  let r = wide.recognize("s", [65, 66, 0xD800], limits=limited).unwrap()
  assert_eq(r.status, @moonabnf.BudgetExceeded("work"))
  assert_eq(r.work, 2)
  for g in [b"s = %xD7FF-D800\r\n", b"s = %xDFFF-E000\r\n"] {
    let p = @moonabnf.compile_scalar(g).unwrap()
    assert_eq(
      p.recognize("s", [0xD800]),
      Err(@moonabnf.InvalidScalar(0, 0xD800)),
    )
  }
}
