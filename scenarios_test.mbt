///|
test "protocol field with explicit whitespace and CRLF" {
  let p = checked(b"field = %i\"Trace\" \":\" SP 1*8HEXDIG CRLF\r\n")
  assert_eq(p.recognize("field", b"TRACE: aF12\r\n").status, @moonabnf.Matched)
  for
    input in [
      b"Trace:aF12\r\n", b"Trace: \r\n", b"Trace: 012345678\r\n", b"Trace: ab\n",
      b"Trace: g\r\n",
    ] {
    assert_eq(p.recognize("field", input).status, @moonabnf.NoMatch)
  }
}

///|
test "config input with length and case constraints" {
  let p = checked(
    b"setting = key \"=\" value\r\nkey = ALPHA *7(ALPHA / DIGIT / \"-\")\r\nvalue = %s\"on\" / %s\"off\" / 1*3DIGIT\r\n",
  )
  for input in [b"cache=on", b"ttl=120", b"a=0", b"abc-def=off"] {
    assert_eq(p.recognize("setting", input).status, @moonabnf.Matched)
  }
  for
    input in [
      b"cache=ON", b"ttl=1000", b"9a=on", b"abcdefghi=off", b"a=", b"a =on",
    ] {
    assert_eq(p.recognize("setting", input).status, @moonabnf.NoMatch)
  }
}

///|
test "binary fixture batches preserve NUL and high bytes" {
  let p = checked(b"frame = %x00 1*4OCTET %xFF\r\n")
  for input in [b"\x00A\xFF", b"\x00ABCD\xFF", b"\x00\x00\xFF", b"\x00\xFF\xFF"] {
    assert_eq(p.recognize("frame", input).status, @moonabnf.Matched)
  }
  for input in [b"\x00\xFF", b"\x00ABCDE\xFF", b"\x00A\xFE", b"A\xFF"] {
    assert_eq(p.recognize("frame", input).status, @moonabnf.NoMatch)
  }
}
