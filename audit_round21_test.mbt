///|
test "additional round 21: LWSP CRLF-followed-by-WSP sequence language 341 inputs" {
  let p = @moonabnf.compile(b"s = LWSP\r\n").unwrap()
  for
    input in [
      b"", b" ", b"\t", b"  ", b" \t", b"\t ", b"\t\t", b"   ", b"  \t", b" \t ",
      b" \t\t", b"\t  ", b"\t \t", b"\t\t ", b"\t\t\t", b"\r\n ", b"\r\n\t", b"    ",
      b"   \t", b"  \t ", b"  \t\t", b" \t  ", b" \t \t", b" \t\t ", b" \t\t\t",
      b" \r\n ", b" \r\n\t", b"\t   ", b"\t  \t", b"\t \t ", b"\t \t\t", b"\t\t  ",
      b"\t\t \t", b"\t\t\t ", b"\t\t\t\t", b"\t\r\n ", b"\t\r\n\t", b"\r\n  ", b"\r\n \t",
      b"\r\n\t ", b"\r\n\t\t",
    ] {
    assert_eq(p.recognize("s", input).status, @moonabnf.Matched)
  }
  for
    input in [
      b"\r", b"\n", b" \r", b" \n", b"\t\r", b"\t\n", b"\r ", b"\r\t", b"\r\r", b"\r\n",
      b"\n ", b"\n\t", b"\n\r", b"\n\n", b"  \r", b"  \n", b" \t\r", b" \t\n", b" \r ",
      b" \r\t", b" \r\r", b" \r\n", b" \n ", b" \n\t", b" \n\r", b" \n\n", b"\t \r",
      b"\t \n", b"\t\t\r", b"\t\t\n", b"\t\r ", b"\t\r\t", b"\t\r\r", b"\t\r\n",
      b"\t\n ", b"\t\n\t", b"\t\n\r", b"\t\n\n", b"\r  ", b"\r \t", b"\r \r", b"\r \n",
      b"\r\t ", b"\r\t\t", b"\r\t\r", b"\r\t\n", b"\r\r ", b"\r\r\t", b"\r\r\r",
      b"\r\r\n", b"\r\n\r", b"\r\n\n", b"\n  ", b"\n \t", b"\n \r", b"\n \n", b"\n\t ",
      b"\n\t\t", b"\n\t\r", b"\n\t\n", b"\n\r ", b"\n\r\t", b"\n\r\r", b"\n\r\n",
      b"\n\n ", b"\n\n\t", b"\n\n\r", b"\n\n\n", b"   \r", b"   \n", b"  \t\r", b"  \t\n",
      b"  \r ", b"  \r\t", b"  \r\r", b"  \r\n", b"  \n ", b"  \n\t", b"  \n\r",
      b"  \n\n", b" \t \r", b" \t \n", b" \t\t\r", b" \t\t\n", b" \t\r ", b" \t\r\t",
      b" \t\r\r", b" \t\r\n", b" \t\n ", b" \t\n\t", b" \t\n\r", b" \t\n\n", b" \r  ",
      b" \r \t", b" \r \r", b" \r \n", b" \r\t ", b" \r\t\t", b" \r\t\r", b" \r\t\n",
      b" \r\r ", b" \r\r\t", b" \r\r\r", b" \r\r\n", b" \r\n\r", b" \r\n\n", b" \n  ",
      b" \n \t", b" \n \r", b" \n \n", b" \n\t ", b" \n\t\t", b" \n\t\r", b" \n\t\n",
      b" \n\r ", b" \n\r\t", b" \n\r\r", b" \n\r\n", b" \n\n ", b" \n\n\t", b" \n\n\r",
      b" \n\n\n", b"\t  \r", b"\t  \n", b"\t \t\r", b"\t \t\n", b"\t \r ", b"\t \r\t",
      b"\t \r\r", b"\t \r\n", b"\t \n ", b"\t \n\t", b"\t \n\r", b"\t \n\n", b"\t\t \r",
      b"\t\t \n", b"\t\t\t\r", b"\t\t\t\n", b"\t\t\r ", b"\t\t\r\t", b"\t\t\r\r",
      b"\t\t\r\n", b"\t\t\n ", b"\t\t\n\t", b"\t\t\n\r", b"\t\t\n\n", b"\t\r  ",
      b"\t\r \t", b"\t\r \r", b"\t\r \n", b"\t\r\t ", b"\t\r\t\t", b"\t\r\t\r", b"\t\r\t\n",
      b"\t\r\r ", b"\t\r\r\t", b"\t\r\r\r", b"\t\r\r\n", b"\t\r\n\r", b"\t\r\n\n",
      b"\t\n  ", b"\t\n \t", b"\t\n \r", b"\t\n \n", b"\t\n\t ", b"\t\n\t\t", b"\t\n\t\r",
      b"\t\n\t\n", b"\t\n\r ", b"\t\n\r\t", b"\t\n\r\r", b"\t\n\r\n", b"\t\n\n ",
      b"\t\n\n\t", b"\t\n\n\r", b"\t\n\n\n", b"\r   ", b"\r  \t", b"\r  \r", b"\r  \n",
      b"\r \t ", b"\r \t\t", b"\r \t\r", b"\r \t\n", b"\r \r ", b"\r \r\t", b"\r \r\r",
      b"\r \r\n", b"\r \n ", b"\r \n\t", b"\r \n\r", b"\r \n\n", b"\r\t  ", b"\r\t \t",
      b"\r\t \r", b"\r\t \n", b"\r\t\t ", b"\r\t\t\t", b"\r\t\t\r", b"\r\t\t\n",
      b"\r\t\r ", b"\r\t\r\t", b"\r\t\r\r", b"\r\t\r\n", b"\r\t\n ", b"\r\t\n\t",
      b"\r\t\n\r", b"\r\t\n\n", b"\r\r  ", b"\r\r \t", b"\r\r \r", b"\r\r \n", b"\r\r\t ",
      b"\r\r\t\t", b"\r\r\t\r", b"\r\r\t\n", b"\r\r\r ", b"\r\r\r\t", b"\r\r\r\r",
      b"\r\r\r\n", b"\r\r\n ", b"\r\r\n\t", b"\r\r\n\r", b"\r\r\n\n", b"\r\n \r",
      b"\r\n \n", b"\r\n\t\r", b"\r\n\t\n", b"\r\n\r ", b"\r\n\r\t", b"\r\n\r\r",
      b"\r\n\r\n", b"\r\n\n ", b"\r\n\n\t", b"\r\n\n\r", b"\r\n\n\n", b"\n   ", b"\n  \t",
      b"\n  \r", b"\n  \n", b"\n \t ", b"\n \t\t", b"\n \t\r", b"\n \t\n", b"\n \r ",
      b"\n \r\t", b"\n \r\r", b"\n \r\n", b"\n \n ", b"\n \n\t", b"\n \n\r", b"\n \n\n",
      b"\n\t  ", b"\n\t \t", b"\n\t \r", b"\n\t \n", b"\n\t\t ", b"\n\t\t\t", b"\n\t\t\r",
      b"\n\t\t\n", b"\n\t\r ", b"\n\t\r\t", b"\n\t\r\r", b"\n\t\r\n", b"\n\t\n ",
      b"\n\t\n\t", b"\n\t\n\r", b"\n\t\n\n", b"\n\r  ", b"\n\r \t", b"\n\r \r", b"\n\r \n",
      b"\n\r\t ", b"\n\r\t\t", b"\n\r\t\r", b"\n\r\t\n", b"\n\r\r ", b"\n\r\r\t",
      b"\n\r\r\r", b"\n\r\r\n", b"\n\r\n ", b"\n\r\n\t", b"\n\r\n\r", b"\n\r\n\n",
      b"\n\n  ", b"\n\n \t", b"\n\n \r", b"\n\n \n", b"\n\n\t ", b"\n\n\t\t", b"\n\n\t\r",
      b"\n\n\t\n", b"\n\n\r ", b"\n\n\r\t", b"\n\n\r\r", b"\n\n\r\n", b"\n\n\n ",
      b"\n\n\n\t", b"\n\n\n\r", b"\n\n\n\n",
    ] {
    assert_eq(p.recognize("s", input).status, @moonabnf.NoMatch)
  }
}
