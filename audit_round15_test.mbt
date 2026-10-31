///|
test "additional round 15: transitive built-in override and unproductive core dependency" {
  let p = @moonabnf.compile(
    b"s = CRLF WSP HEXDIG\r\nCR = %s\"C\"\r\nLF = %s\"L\"\r\nSP = %s\"S\"\r\nHTAB = %s\"T\"\r\nDIGIT = %s\"D\"\r\n",
  ).unwrap()
  for good in [b"CLSD", b"CLTD", b"CLSa", b"CLTF"] {
    assert_eq(p.recognize("s", good).status, @moonabnf.Matched)
  }
  for bad in [b"\r\n D", b"CL 1", b"CLT1", b"CLSg"] {
    assert_eq(p.recognize("s", bad).status, @moonabnf.NoMatch)
  }
  let q = @moonabnf.compile(b"s = HEXDIG\r\nDIGIT = DIGIT\r\n").unwrap()
  assert_eq(q.recognize("s", b"A").status, @moonabnf.Matched)
  assert_eq(q.recognize("s", b"9").status, @moonabnf.NoMatch)
  let r = @moonabnf.compile(b"s = LWSP\r\nWSP = WSP\r\n").unwrap()
  assert_eq(r.recognize("s", b"").status, @moonabnf.Matched)
  assert_eq(r.recognize("s", b" ").status, @moonabnf.NoMatch)
}
