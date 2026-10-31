///|
test "new independent round 6: composed prose independent product-language oracle 1008 inputs" {
  let p0 = @moonabnf.compile_with_prose(b"s = <p>\r\n", [
    { name: "p", predicate: @moonabnf.Words([[97], [], [98, 97]]), },
  ]).unwrap()
  for input in [b"", b"a", b"ba"] {
    assert_eq(p0.recognize("s", input).status, @moonabnf.Matched)
    assert_eq(p0.parse_input("s", input).status, @moonabnf.Matched)
  }
  for
    input in [
      b"b", b"aa", b"ab", b"bb", b"aaa", b"aab", b"aba", b"abb", b"baa", b"bab",
      b"bba", b"bbb", b"aaaa", b"aaab", b"aaba", b"aabb", b"abaa", b"abab", b"abba",
      b"abbb", b"baaa", b"baab", b"baba", b"babb", b"bbaa", b"bbab", b"bbba", b"bbbb",
      b"aaaaa", b"aaaab", b"aaaba", b"aaabb", b"aabaa", b"aabab", b"aabba", b"aabbb",
      b"abaaa", b"abaab", b"ababa", b"ababb", b"abbaa", b"abbab", b"abbba", b"abbbb",
      b"baaaa", b"baaab", b"baaba", b"baabb", b"babaa", b"babab", b"babba", b"babbb",
      b"bbaaa", b"bbaab", b"bbaba", b"bbabb", b"bbbaa", b"bbbab", b"bbbba", b"bbbbb",
    ] {
    assert_eq(p0.recognize("s", input).status, @moonabnf.NoMatch)
    assert_eq(p0.parse_input("s", input).status, @moonabnf.NoMatch)
  }
  let p1 = @moonabnf.compile_with_prose(b"s = <p>\r\n", [
    {
      name: "p",
      predicate: @moonabnf.Concat([
        @moonabnf.Concat([
          @moonabnf.Alternative([]),
          @moonabnf.Concat([]),
          @moonabnf.Words([[98]]),
        ]),
        @moonabnf.Words([[98, 97], []]),
      ]),
    },
  ]).unwrap()
  for
    input in [
      b"", b"a", b"b", b"aa", b"ab", b"ba", b"bb", b"aaa", b"aab", b"aba", b"abb",
      b"baa", b"bab", b"bba", b"bbb", b"aaaa", b"aaab", b"aaba", b"aabb", b"abaa",
      b"abab", b"abba", b"abbb", b"baaa", b"baab", b"baba", b"babb", b"bbaa", b"bbab",
      b"bbba", b"bbbb", b"aaaaa", b"aaaab", b"aaaba", b"aaabb", b"aabaa", b"aabab",
      b"aabba", b"aabbb", b"abaaa", b"abaab", b"ababa", b"ababb", b"abbaa", b"abbab",
      b"abbba", b"abbbb", b"baaaa", b"baaab", b"baaba", b"baabb", b"babaa", b"babab",
      b"babba", b"babbb", b"bbaaa", b"bbaab", b"bbaba", b"bbabb", b"bbbaa", b"bbbab",
      b"bbbba", b"bbbbb",
    ] {
    assert_eq(p1.recognize("s", input).status, @moonabnf.NoMatch)
    assert_eq(p1.parse_input("s", input).status, @moonabnf.NoMatch)
  }
  let p2 = @moonabnf.compile_with_prose(b"s = <p>\r\n", [
    { name: "p", predicate: @moonabnf.Words([[98]]), },
  ]).unwrap()
  for input in [b"b"] {
    assert_eq(p2.recognize("s", input).status, @moonabnf.Matched)
    assert_eq(p2.parse_input("s", input).status, @moonabnf.Matched)
  }
  for
    input in [
      b"", b"a", b"aa", b"ab", b"ba", b"bb", b"aaa", b"aab", b"aba", b"abb", b"baa",
      b"bab", b"bba", b"bbb", b"aaaa", b"aaab", b"aaba", b"aabb", b"abaa", b"abab",
      b"abba", b"abbb", b"baaa", b"baab", b"baba", b"babb", b"bbaa", b"bbab", b"bbba",
      b"bbbb", b"aaaaa", b"aaaab", b"aaaba", b"aaabb", b"aabaa", b"aabab", b"aabba",
      b"aabbb", b"abaaa", b"abaab", b"ababa", b"ababb", b"abbaa", b"abbab", b"abbba",
      b"abbbb", b"baaaa", b"baaab", b"baaba", b"baabb", b"babaa", b"babab", b"babba",
      b"babbb", b"bbaaa", b"bbaab", b"bbaba", b"bbabb", b"bbbaa", b"bbbab", b"bbbba",
      b"bbbbb",
    ] {
    assert_eq(p2.recognize("s", input).status, @moonabnf.NoMatch)
    assert_eq(p2.parse_input("s", input).status, @moonabnf.NoMatch)
  }
  let p3 = @moonabnf.compile_with_prose(b"s = <p>\r\n", [
    {
      name: "p",
      predicate: @moonabnf.Repetition(
        1,
        Some(1),
        @moonabnf.Concat([
          @moonabnf.Concat([@moonabnf.Words([[]])]),
          @moonabnf.Alternative([]),
          @moonabnf.Words([]),
        ]),
      ),
    },
  ]).unwrap()
  for
    input in [
      b"", b"a", b"b", b"aa", b"ab", b"ba", b"bb", b"aaa", b"aab", b"aba", b"abb",
      b"baa", b"bab", b"bba", b"bbb", b"aaaa", b"aaab", b"aaba", b"aabb", b"abaa",
      b"abab", b"abba", b"abbb", b"baaa", b"baab", b"baba", b"babb", b"bbaa", b"bbab",
      b"bbba", b"bbbb", b"aaaaa", b"aaaab", b"aaaba", b"aaabb", b"aabaa", b"aabab",
      b"aabba", b"aabbb", b"abaaa", b"abaab", b"ababa", b"ababb", b"abbaa", b"abbab",
      b"abbba", b"abbbb", b"baaaa", b"baaab", b"baaba", b"baabb", b"babaa", b"babab",
      b"babba", b"babbb", b"bbaaa", b"bbaab", b"bbaba", b"bbabb", b"bbbaa", b"bbbab",
      b"bbbba", b"bbbbb",
    ] {
    assert_eq(p3.recognize("s", input).status, @moonabnf.NoMatch)
    assert_eq(p3.parse_input("s", input).status, @moonabnf.NoMatch)
  }
  let p4 = @moonabnf.compile_with_prose(b"s = <p>\r\n", [
    {
      name: "p",
      predicate: @moonabnf.Alternative([
        @moonabnf.Alternative([]),
        @moonabnf.Concat([]),
        @moonabnf.Words([[98]]),
      ]),
    },
  ]).unwrap()
  for input in [b"", b"b"] {
    assert_eq(p4.recognize("s", input).status, @moonabnf.Matched)
    assert_eq(p4.parse_input("s", input).status, @moonabnf.Matched)
  }
  for
    input in [
      b"a", b"aa", b"ab", b"ba", b"bb", b"aaa", b"aab", b"aba", b"abb", b"baa", b"bab",
      b"bba", b"bbb", b"aaaa", b"aaab", b"aaba", b"aabb", b"abaa", b"abab", b"abba",
      b"abbb", b"baaa", b"baab", b"baba", b"babb", b"bbaa", b"bbab", b"bbba", b"bbbb",
      b"aaaaa", b"aaaab", b"aaaba", b"aaabb", b"aabaa", b"aabab", b"aabba", b"aabbb",
      b"abaaa", b"abaab", b"ababa", b"ababb", b"abbaa", b"abbab", b"abbba", b"abbbb",
      b"baaaa", b"baaab", b"baaba", b"baabb", b"babaa", b"babab", b"babba", b"babbb",
      b"bbaaa", b"bbaab", b"bbaba", b"bbabb", b"bbbaa", b"bbbab", b"bbbba", b"bbbbb",
    ] {
    assert_eq(p4.recognize("s", input).status, @moonabnf.NoMatch)
    assert_eq(p4.parse_input("s", input).status, @moonabnf.NoMatch)
  }
  let p5 = @moonabnf.compile_with_prose(b"s = <p>\r\n", [
    {
      name: "p",
      predicate: @moonabnf.Alternative([
        @moonabnf.Alternative([
          @moonabnf.Repetition(2, Some(2), @moonabnf.Words([[97, 98], [98]])),
          @moonabnf.Concat([]),
          @moonabnf.Words([[98, 97]]),
        ]),
      ]),
    },
  ]).unwrap()
  for input in [b"", b"ba", b"bb", b"abb", b"bab", b"abab"] {
    assert_eq(p5.recognize("s", input).status, @moonabnf.Matched)
    assert_eq(p5.parse_input("s", input).status, @moonabnf.Matched)
  }
  for
    input in [
      b"a", b"b", b"aa", b"ab", b"aaa", b"aab", b"aba", b"baa", b"bba", b"bbb", b"aaaa",
      b"aaab", b"aaba", b"aabb", b"abaa", b"abba", b"abbb", b"baaa", b"baab", b"baba",
      b"babb", b"bbaa", b"bbab", b"bbba", b"bbbb", b"aaaaa", b"aaaab", b"aaaba",
      b"aaabb", b"aabaa", b"aabab", b"aabba", b"aabbb", b"abaaa", b"abaab", b"ababa",
      b"ababb", b"abbaa", b"abbab", b"abbba", b"abbbb", b"baaaa", b"baaab", b"baaba",
      b"baabb", b"babaa", b"babab", b"babba", b"babbb", b"bbaaa", b"bbaab", b"bbaba",
      b"bbabb", b"bbbaa", b"bbbab", b"bbbba", b"bbbbb",
    ] {
    assert_eq(p5.recognize("s", input).status, @moonabnf.NoMatch)
    assert_eq(p5.parse_input("s", input).status, @moonabnf.NoMatch)
  }
  let p6 = @moonabnf.compile_with_prose(b"s = <p>\r\n", [
    { name: "p", predicate: @moonabnf.Words([[98]]), },
  ]).unwrap()
  for input in [b"b"] {
    assert_eq(p6.recognize("s", input).status, @moonabnf.Matched)
    assert_eq(p6.parse_input("s", input).status, @moonabnf.Matched)
  }
  for
    input in [
      b"", b"a", b"aa", b"ab", b"ba", b"bb", b"aaa", b"aab", b"aba", b"abb", b"baa",
      b"bab", b"bba", b"bbb", b"aaaa", b"aaab", b"aaba", b"aabb", b"abaa", b"abab",
      b"abba", b"abbb", b"baaa", b"baab", b"baba", b"babb", b"bbaa", b"bbab", b"bbba",
      b"bbbb", b"aaaaa", b"aaaab", b"aaaba", b"aaabb", b"aabaa", b"aabab", b"aabba",
      b"aabbb", b"abaaa", b"abaab", b"ababa", b"ababb", b"abbaa", b"abbab", b"abbba",
      b"abbbb", b"baaaa", b"baaab", b"baaba", b"baabb", b"babaa", b"babab", b"babba",
      b"babbb", b"bbaaa", b"bbaab", b"bbaba", b"bbabb", b"bbbaa", b"bbbab", b"bbbba",
      b"bbbbb",
    ] {
    assert_eq(p6.recognize("s", input).status, @moonabnf.NoMatch)
    assert_eq(p6.parse_input("s", input).status, @moonabnf.NoMatch)
  }
  let p7 = @moonabnf.compile_with_prose(b"s = <p>\r\n", [
    {
      name: "p",
      predicate: @moonabnf.Repetition(
        1,
        Some(1),
        @moonabnf.Repetition(
          1,
          Some(2),
          @moonabnf.Concat([@moonabnf.Words([])]),
        ),
      ),
    },
  ]).unwrap()
  for
    input in [
      b"", b"a", b"b", b"aa", b"ab", b"ba", b"bb", b"aaa", b"aab", b"aba", b"abb",
      b"baa", b"bab", b"bba", b"bbb", b"aaaa", b"aaab", b"aaba", b"aabb", b"abaa",
      b"abab", b"abba", b"abbb", b"baaa", b"baab", b"baba", b"babb", b"bbaa", b"bbab",
      b"bbba", b"bbbb", b"aaaaa", b"aaaab", b"aaaba", b"aaabb", b"aabaa", b"aabab",
      b"aabba", b"aabbb", b"abaaa", b"abaab", b"ababa", b"ababb", b"abbaa", b"abbab",
      b"abbba", b"abbbb", b"baaaa", b"baaab", b"baaba", b"baabb", b"babaa", b"babab",
      b"babba", b"babbb", b"bbaaa", b"bbaab", b"bbaba", b"bbabb", b"bbbaa", b"bbbab",
      b"bbbba", b"bbbbb",
    ] {
    assert_eq(p7.recognize("s", input).status, @moonabnf.NoMatch)
    assert_eq(p7.parse_input("s", input).status, @moonabnf.NoMatch)
  }
  let p8 = @moonabnf.compile_with_prose(b"s = <p>\r\n", [
    { name: "p", predicate: @moonabnf.Words([]), },
  ]).unwrap()
  for
    input in [
      b"", b"a", b"b", b"aa", b"ab", b"ba", b"bb", b"aaa", b"aab", b"aba", b"abb",
      b"baa", b"bab", b"bba", b"bbb", b"aaaa", b"aaab", b"aaba", b"aabb", b"abaa",
      b"abab", b"abba", b"abbb", b"baaa", b"baab", b"baba", b"babb", b"bbaa", b"bbab",
      b"bbba", b"bbbb", b"aaaaa", b"aaaab", b"aaaba", b"aaabb", b"aabaa", b"aabab",
      b"aabba", b"aabbb", b"abaaa", b"abaab", b"ababa", b"ababb", b"abbaa", b"abbab",
      b"abbba", b"abbbb", b"baaaa", b"baaab", b"baaba", b"baabb", b"babaa", b"babab",
      b"babba", b"babbb", b"bbaaa", b"bbaab", b"bbaba", b"bbabb", b"bbbaa", b"bbbab",
      b"bbbba", b"bbbbb",
    ] {
    assert_eq(p8.recognize("s", input).status, @moonabnf.NoMatch)
    assert_eq(p8.parse_input("s", input).status, @moonabnf.NoMatch)
  }
  let p9 = @moonabnf.compile_with_prose(b"s = <p>\r\n", [
    {
      name: "p",
      predicate: @moonabnf.Repetition(
        1,
        Some(3),
        @moonabnf.Alternative([@moonabnf.Words([[], [97, 98], [98, 97]])]),
      ),
    },
  ]).unwrap()
  for input in [b"", b"ab", b"ba", b"abab", b"abba", b"baab", b"baba"] {
    assert_eq(p9.recognize("s", input).status, @moonabnf.Matched)
    assert_eq(p9.parse_input("s", input).status, @moonabnf.Matched)
  }
  for
    input in [
      b"a", b"b", b"aa", b"bb", b"aaa", b"aab", b"aba", b"abb", b"baa", b"bab", b"bba",
      b"bbb", b"aaaa", b"aaab", b"aaba", b"aabb", b"abaa", b"abbb", b"baaa", b"babb",
      b"bbaa", b"bbab", b"bbba", b"bbbb", b"aaaaa", b"aaaab", b"aaaba", b"aaabb",
      b"aabaa", b"aabab", b"aabba", b"aabbb", b"abaaa", b"abaab", b"ababa", b"ababb",
      b"abbaa", b"abbab", b"abbba", b"abbbb", b"baaaa", b"baaab", b"baaba", b"baabb",
      b"babaa", b"babab", b"babba", b"babbb", b"bbaaa", b"bbaab", b"bbaba", b"bbabb",
      b"bbbaa", b"bbbab", b"bbbba", b"bbbbb",
    ] {
    assert_eq(p9.recognize("s", input).status, @moonabnf.NoMatch)
    assert_eq(p9.parse_input("s", input).status, @moonabnf.NoMatch)
  }
  let p10 = @moonabnf.compile_with_prose(b"s = <p>\r\n", [
    {
      name: "p",
      predicate: @moonabnf.Repetition(
        0,
        Some(0),
        @moonabnf.Repetition(
          1,
          Some(1),
          @moonabnf.Alternative([
            @moonabnf.Words([[97, 98], [98, 97], [98]]),
            @moonabnf.Words([]),
            @moonabnf.Words([]),
          ]),
        ),
      ),
    },
  ]).unwrap()
  for input in [b""] {
    assert_eq(p10.recognize("s", input).status, @moonabnf.Matched)
    assert_eq(p10.parse_input("s", input).status, @moonabnf.Matched)
  }
  for
    input in [
      b"a", b"b", b"aa", b"ab", b"ba", b"bb", b"aaa", b"aab", b"aba", b"abb", b"baa",
      b"bab", b"bba", b"bbb", b"aaaa", b"aaab", b"aaba", b"aabb", b"abaa", b"abab",
      b"abba", b"abbb", b"baaa", b"baab", b"baba", b"babb", b"bbaa", b"bbab", b"bbba",
      b"bbbb", b"aaaaa", b"aaaab", b"aaaba", b"aaabb", b"aabaa", b"aabab", b"aabba",
      b"aabbb", b"abaaa", b"abaab", b"ababa", b"ababb", b"abbaa", b"abbab", b"abbba",
      b"abbbb", b"baaaa", b"baaab", b"baaba", b"baabb", b"babaa", b"babab", b"babba",
      b"babbb", b"bbaaa", b"bbaab", b"bbaba", b"bbabb", b"bbbaa", b"bbbab", b"bbbba",
      b"bbbbb",
    ] {
    assert_eq(p10.recognize("s", input).status, @moonabnf.NoMatch)
    assert_eq(p10.parse_input("s", input).status, @moonabnf.NoMatch)
  }
  let p11 = @moonabnf.compile_with_prose(b"s = <p>\r\n", [
    { name: "p", predicate: @moonabnf.Words([[], [98], [97, 98]]), },
  ]).unwrap()
  for input in [b"", b"b", b"ab"] {
    assert_eq(p11.recognize("s", input).status, @moonabnf.Matched)
    assert_eq(p11.parse_input("s", input).status, @moonabnf.Matched)
  }
  for
    input in [
      b"a", b"aa", b"ba", b"bb", b"aaa", b"aab", b"aba", b"abb", b"baa", b"bab",
      b"bba", b"bbb", b"aaaa", b"aaab", b"aaba", b"aabb", b"abaa", b"abab", b"abba",
      b"abbb", b"baaa", b"baab", b"baba", b"babb", b"bbaa", b"bbab", b"bbba", b"bbbb",
      b"aaaaa", b"aaaab", b"aaaba", b"aaabb", b"aabaa", b"aabab", b"aabba", b"aabbb",
      b"abaaa", b"abaab", b"ababa", b"ababb", b"abbaa", b"abbab", b"abbba", b"abbbb",
      b"baaaa", b"baaab", b"baaba", b"baabb", b"babaa", b"babab", b"babba", b"babbb",
      b"bbaaa", b"bbaab", b"bbaba", b"bbabb", b"bbbaa", b"bbbab", b"bbbba", b"bbbbb",
    ] {
    assert_eq(p11.recognize("s", input).status, @moonabnf.NoMatch)
    assert_eq(p11.parse_input("s", input).status, @moonabnf.NoMatch)
  }
  let p12 = @moonabnf.compile_with_prose(b"s = <p>\r\n", [
    {
      name: "p",
      predicate: @moonabnf.Concat([
        @moonabnf.Repetition(
          2,
          Some(3),
          @moonabnf.Concat([
            @moonabnf.Words([[98, 97]]),
            @moonabnf.Words([[97, 98], [97]]),
          ]),
        ),
        @moonabnf.Words([[98, 97], [97, 98]]),
      ]),
    },
  ]).unwrap()
  for
    input in [
      b"", b"a", b"b", b"aa", b"ab", b"ba", b"bb", b"aaa", b"aab", b"aba", b"abb",
      b"baa", b"bab", b"bba", b"bbb", b"aaaa", b"aaab", b"aaba", b"aabb", b"abaa",
      b"abab", b"abba", b"abbb", b"baaa", b"baab", b"baba", b"babb", b"bbaa", b"bbab",
      b"bbba", b"bbbb", b"aaaaa", b"aaaab", b"aaaba", b"aaabb", b"aabaa", b"aabab",
      b"aabba", b"aabbb", b"abaaa", b"abaab", b"ababa", b"ababb", b"abbaa", b"abbab",
      b"abbba", b"abbbb", b"baaaa", b"baaab", b"baaba", b"baabb", b"babaa", b"babab",
      b"babba", b"babbb", b"bbaaa", b"bbaab", b"bbaba", b"bbabb", b"bbbaa", b"bbbab",
      b"bbbba", b"bbbbb",
    ] {
    assert_eq(p12.recognize("s", input).status, @moonabnf.NoMatch)
    assert_eq(p12.parse_input("s", input).status, @moonabnf.NoMatch)
  }
  let p13 = @moonabnf.compile_with_prose(b"s = <p>\r\n", [
    {
      name: "p",
      predicate: @moonabnf.Repetition(
        1,
        Some(2),
        @moonabnf.Repetition(0, Some(2), @moonabnf.Words([[98], [97, 98], []])),
      ),
    },
  ]).unwrap()
  for
    input in [
      b"", b"b", b"ab", b"bb", b"abb", b"bab", b"bbb", b"abab", b"abbb", b"babb",
      b"bbab", b"bbbb", b"ababb", b"abbab", b"abbbb", b"babab", b"babbb", b"bbabb",
      b"bbbab",
    ] {
    assert_eq(p13.recognize("s", input).status, @moonabnf.Matched)
    assert_eq(p13.parse_input("s", input).status, @moonabnf.Matched)
  }
  for
    input in [
      b"a", b"aa", b"ba", b"aaa", b"aab", b"aba", b"baa", b"bba", b"aaaa", b"aaab",
      b"aaba", b"aabb", b"abaa", b"abba", b"baaa", b"baab", b"baba", b"bbaa", b"bbba",
      b"aaaaa", b"aaaab", b"aaaba", b"aaabb", b"aabaa", b"aabab", b"aabba", b"aabbb",
      b"abaaa", b"abaab", b"ababa", b"abbaa", b"abbba", b"baaaa", b"baaab", b"baaba",
      b"baabb", b"babaa", b"babba", b"bbaaa", b"bbaab", b"bbaba", b"bbbaa", b"bbbba",
      b"bbbbb",
    ] {
    assert_eq(p13.recognize("s", input).status, @moonabnf.NoMatch)
    assert_eq(p13.parse_input("s", input).status, @moonabnf.NoMatch)
  }
  let p14 = @moonabnf.compile_with_prose(b"s = <p>\r\n", [
    {
      name: "p",
      predicate: @moonabnf.Alternative([@moonabnf.Words([[97, 98], [97]])]),
    },
  ]).unwrap()
  for input in [b"a", b"ab"] {
    assert_eq(p14.recognize("s", input).status, @moonabnf.Matched)
    assert_eq(p14.parse_input("s", input).status, @moonabnf.Matched)
  }
  for
    input in [
      b"", b"b", b"aa", b"ba", b"bb", b"aaa", b"aab", b"aba", b"abb", b"baa", b"bab",
      b"bba", b"bbb", b"aaaa", b"aaab", b"aaba", b"aabb", b"abaa", b"abab", b"abba",
      b"abbb", b"baaa", b"baab", b"baba", b"babb", b"bbaa", b"bbab", b"bbba", b"bbbb",
      b"aaaaa", b"aaaab", b"aaaba", b"aaabb", b"aabaa", b"aabab", b"aabba", b"aabbb",
      b"abaaa", b"abaab", b"ababa", b"ababb", b"abbaa", b"abbab", b"abbba", b"abbbb",
      b"baaaa", b"baaab", b"baaba", b"baabb", b"babaa", b"babab", b"babba", b"babbb",
      b"bbaaa", b"bbaab", b"bbaba", b"bbabb", b"bbbaa", b"bbbab", b"bbbba", b"bbbbb",
    ] {
    assert_eq(p14.recognize("s", input).status, @moonabnf.NoMatch)
    assert_eq(p14.parse_input("s", input).status, @moonabnf.NoMatch)
  }
  let p15 = @moonabnf.compile_with_prose(b"s = <p>\r\n", [
    {
      name: "p",
      predicate: @moonabnf.Repetition(
        1,
        Some(2),
        @moonabnf.Words([[], [97, 98]]),
      ),
    },
  ]).unwrap()
  for input in [b"", b"ab", b"abab"] {
    assert_eq(p15.recognize("s", input).status, @moonabnf.Matched)
    assert_eq(p15.parse_input("s", input).status, @moonabnf.Matched)
  }
  for
    input in [
      b"a", b"b", b"aa", b"ba", b"bb", b"aaa", b"aab", b"aba", b"abb", b"baa", b"bab",
      b"bba", b"bbb", b"aaaa", b"aaab", b"aaba", b"aabb", b"abaa", b"abba", b"abbb",
      b"baaa", b"baab", b"baba", b"babb", b"bbaa", b"bbab", b"bbba", b"bbbb", b"aaaaa",
      b"aaaab", b"aaaba", b"aaabb", b"aabaa", b"aabab", b"aabba", b"aabbb", b"abaaa",
      b"abaab", b"ababa", b"ababb", b"abbaa", b"abbab", b"abbba", b"abbbb", b"baaaa",
      b"baaab", b"baaba", b"baabb", b"babaa", b"babab", b"babba", b"babbb", b"bbaaa",
      b"bbaab", b"bbaba", b"bbabb", b"bbbaa", b"bbbab", b"bbbba", b"bbbbb",
    ] {
    assert_eq(p15.recognize("s", input).status, @moonabnf.NoMatch)
    assert_eq(p15.parse_input("s", input).status, @moonabnf.NoMatch)
  }
}
