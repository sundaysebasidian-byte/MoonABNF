///|
test "additional round 16: declaration permutation and idempotent alternative metamorphism" {
  let p0 = @moonabnf.compile(
    b"s = left / right\r\nleft = %s\"a\" [s]\r\nright = %s\"b\"\r\n",
  ).unwrap()
  let p1 = @moonabnf.compile(
    b"right = %s\"b\"\r\nleft = %s\"a\" [s]\r\ns = right / left\r\n",
  ).unwrap()
  let p2 = @moonabnf.compile(
    b"s = left / right / left\r\nright = %s\"b\"\r\nleft = %s\"a\" [s]\r\n",
  ).unwrap()
  for
    input in [
      b"", b"a", b"b", b"aa", b"ab", b"ba", b"bb", b"aaa", b"aab", b"aba", b"abb",
      b"baa", b"bab", b"bba", b"bbb", b"aaaa", b"aaab", b"aaba", b"aabb", b"abaa",
      b"abab", b"abba", b"abbb", b"baaa", b"baab", b"baba", b"babb", b"bbaa", b"bbab",
      b"bbba", b"bbbb",
    ] {
    let expected = p0.recognize("s", input).status
    assert_eq(p1.recognize("s", input).status, expected)
    assert_eq(p2.recognize("s", input).status, expected)
    assert_eq(p1.parse_input("s", input).status, expected)
    assert_eq(p2.parse_input("s", input).status, expected)
  }
}
