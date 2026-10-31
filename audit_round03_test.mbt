///|
test "new independent round 3: bounded CFG oracle 18 grammars x 63 binary strings" {
  let p0 = @moonabnf.compile(
    b"s = %s\"b\" %s\"a\" / t / %s\"a\"\r\nt = %s\"\" / u t %s\"b\" / %s\"b\"\r\nu = %s\"a\" / %s\"\" / %s\"\"\r\n",
  ).unwrap()
  for
    input in [
      b"", b"a", b"b", b"ab", b"ba", b"bb", b"abb", b"bbb", b"aabb", b"abbb", b"bbbb",
      b"aabbb", b"abbbb", b"bbbbb",
    ] {
    let expected = @moonabnf.Matched
    assert_eq(p0.recognize("s", input).status, expected)
    let tree = p0.parse_input("s", input)
    assert_eq(tree.status, expected)
    let t = tree.tree.unwrap()
    assert_eq(t.extract(input, t.root), Some(input))
    assert_true(t.rule_nodes_in("s", t.root) is Some(_))
  }
  for
    input in [
      b"aa", b"aaa", b"aab", b"aba", b"baa", b"bab", b"bba", b"aaaa", b"aaab", b"aaba",
      b"abaa", b"abab", b"abba", b"baaa", b"baab", b"baba", b"babb", b"bbaa", b"bbab",
      b"bbba", b"aaaaa", b"aaaab", b"aaaba", b"aaabb", b"aabaa", b"aabab", b"aabba",
      b"abaaa", b"abaab", b"ababa", b"ababb", b"abbaa", b"abbab", b"abbba", b"baaaa",
      b"baaab", b"baaba", b"baabb", b"babaa", b"babab", b"babba", b"babbb", b"bbaaa",
      b"bbaab", b"bbaba", b"bbabb", b"bbbaa", b"bbbab", b"bbbba",
    ] {
    let expected = @moonabnf.NoMatch
    assert_eq(p0.recognize("s", input).status, expected)
    let tree = p0.parse_input("s", input)
    assert_eq(tree.status, expected)
    assert_true(tree.tree is None)
  }
  let p1 = @moonabnf.compile(
    b"s = u s / %s\"a\" s u / %s\"a\"\r\nt = %s\"a\" / %s\"a\" %s\"a\" / s / %s\"b\"\r\nu = %s\"b\" %s\"b\" / u u s / %s\"b\" s %s\"b\" / %s\"b\"\r\n",
  ).unwrap()
  for
    input in [
      b"a", b"ba", b"aab", b"bba", b"aabb", b"abab", b"baab", b"baba", b"bbaa", b"bbba",
      b"aaabb", b"aabab", b"aabba", b"ababb", b"abbab", b"baabb", b"babab", b"babba",
      b"bbaab", b"bbaba", b"bbbaa", b"bbbba",
    ] {
    let expected = @moonabnf.Matched
    assert_eq(p1.recognize("s", input).status, expected)
    let tree = p1.parse_input("s", input)
    assert_eq(tree.status, expected)
    let t = tree.tree.unwrap()
    assert_eq(t.extract(input, t.root), Some(input))
    assert_true(t.rule_nodes_in("s", t.root) is Some(_))
  }
  for
    input in [
      b"", b"b", b"aa", b"ab", b"bb", b"aaa", b"aba", b"abb", b"baa", b"bab", b"bbb",
      b"aaaa", b"aaab", b"aaba", b"abaa", b"abba", b"abbb", b"baaa", b"babb", b"bbab",
      b"bbbb", b"aaaaa", b"aaaab", b"aaaba", b"aabaa", b"aabbb", b"abaaa", b"abaab",
      b"ababa", b"abbaa", b"abbba", b"abbbb", b"baaaa", b"baaab", b"baaba", b"babaa",
      b"babbb", b"bbaaa", b"bbabb", b"bbbab", b"bbbbb",
    ] {
    let expected = @moonabnf.NoMatch
    assert_eq(p1.recognize("s", input).status, expected)
    let tree = p1.parse_input("s", input)
    assert_eq(tree.status, expected)
    assert_true(tree.tree is None)
  }
  let p2 = @moonabnf.compile(
    b"s = %s\"b\" %s\"a\" / u / %s\"a\"\r\nt = %s\"\" / %s\"a\" / u / %s\"b\"\r\nu = %s\"\" / s\r\n",
  ).unwrap()
  for input in [b"", b"a", b"ba"] {
    let expected = @moonabnf.Matched
    assert_eq(p2.recognize("s", input).status, expected)
    let tree = p2.parse_input("s", input)
    assert_eq(tree.status, expected)
    let t = tree.tree.unwrap()
    assert_eq(t.extract(input, t.root), Some(input))
    assert_true(t.rule_nodes_in("s", t.root) is Some(_))
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
    let expected = @moonabnf.NoMatch
    assert_eq(p2.recognize("s", input).status, expected)
    let tree = p2.parse_input("s", input)
    assert_eq(tree.status, expected)
    assert_true(tree.tree is None)
  }
  let p3 = @moonabnf.compile(
    b"s = %s\"\" / %s\"\" / s / %s\"a\" %s\"b\" / %s\"a\"\r\nt = s t %s\"a\" / %s\"a\" s / %s\"b\" %s\"a\" %s\"a\" / %s\"b\"\r\nu = %s\"\" / u / u s / %s\"b\" u t\r\n",
  ).unwrap()
  for input in [b"", b"a", b"ab"] {
    let expected = @moonabnf.Matched
    assert_eq(p3.recognize("s", input).status, expected)
    let tree = p3.parse_input("s", input)
    assert_eq(tree.status, expected)
    let t = tree.tree.unwrap()
    assert_eq(t.extract(input, t.root), Some(input))
    assert_true(t.rule_nodes_in("s", t.root) is Some(_))
  }
  for
    input in [
      b"b", b"aa", b"ba", b"bb", b"aaa", b"aab", b"aba", b"abb", b"baa", b"bab",
      b"bba", b"bbb", b"aaaa", b"aaab", b"aaba", b"aabb", b"abaa", b"abab", b"abba",
      b"abbb", b"baaa", b"baab", b"baba", b"babb", b"bbaa", b"bbab", b"bbba", b"bbbb",
      b"aaaaa", b"aaaab", b"aaaba", b"aaabb", b"aabaa", b"aabab", b"aabba", b"aabbb",
      b"abaaa", b"abaab", b"ababa", b"ababb", b"abbaa", b"abbab", b"abbba", b"abbbb",
      b"baaaa", b"baaab", b"baaba", b"baabb", b"babaa", b"babab", b"babba", b"babbb",
      b"bbaaa", b"bbaab", b"bbaba", b"bbabb", b"bbbaa", b"bbbab", b"bbbba", b"bbbbb",
    ] {
    let expected = @moonabnf.NoMatch
    assert_eq(p3.recognize("s", input).status, expected)
    let tree = p3.parse_input("s", input)
    assert_eq(tree.status, expected)
    assert_true(tree.tree is None)
  }
  let p4 = @moonabnf.compile(
    b"s = %s\"\" / s / %s\"a\"\r\nt = %s\"\" / u s / %s\"b\"\r\nu = %s\"b\" / %s\"\" / %s\"\"\r\n",
  ).unwrap()
  for input in [b"", b"a"] {
    let expected = @moonabnf.Matched
    assert_eq(p4.recognize("s", input).status, expected)
    let tree = p4.parse_input("s", input)
    assert_eq(tree.status, expected)
    let t = tree.tree.unwrap()
    assert_eq(t.extract(input, t.root), Some(input))
    assert_true(t.rule_nodes_in("s", t.root) is Some(_))
  }
  for
    input in [
      b"b", b"aa", b"ab", b"ba", b"bb", b"aaa", b"aab", b"aba", b"abb", b"baa", b"bab",
      b"bba", b"bbb", b"aaaa", b"aaab", b"aaba", b"aabb", b"abaa", b"abab", b"abba",
      b"abbb", b"baaa", b"baab", b"baba", b"babb", b"bbaa", b"bbab", b"bbba", b"bbbb",
      b"aaaaa", b"aaaab", b"aaaba", b"aaabb", b"aabaa", b"aabab", b"aabba", b"aabbb",
      b"abaaa", b"abaab", b"ababa", b"ababb", b"abbaa", b"abbab", b"abbba", b"abbbb",
      b"baaaa", b"baaab", b"baaba", b"baabb", b"babaa", b"babab", b"babba", b"babbb",
      b"bbaaa", b"bbaab", b"bbaba", b"bbabb", b"bbbaa", b"bbbab", b"bbbba", b"bbbbb",
    ] {
    let expected = @moonabnf.NoMatch
    assert_eq(p4.recognize("s", input).status, expected)
    let tree = p4.parse_input("s", input)
    assert_eq(tree.status, expected)
    assert_true(tree.tree is None)
  }
  let p5 = @moonabnf.compile(
    b"s = %s\"a\" / %s\"\" / %s\"\" / %s\"a\"\r\nt = %s\"\" / %s\"b\" %s\"b\" / %s\"b\"\r\nu = %s\"\" / %s\"b\" %s\"a\" u / %s\"b\" / %s\"a\"\r\n",
  ).unwrap()
  for input in [b"", b"a"] {
    let expected = @moonabnf.Matched
    assert_eq(p5.recognize("s", input).status, expected)
    let tree = p5.parse_input("s", input)
    assert_eq(tree.status, expected)
    let t = tree.tree.unwrap()
    assert_eq(t.extract(input, t.root), Some(input))
    assert_true(t.rule_nodes_in("s", t.root) is Some(_))
  }
  for
    input in [
      b"b", b"aa", b"ab", b"ba", b"bb", b"aaa", b"aab", b"aba", b"abb", b"baa", b"bab",
      b"bba", b"bbb", b"aaaa", b"aaab", b"aaba", b"aabb", b"abaa", b"abab", b"abba",
      b"abbb", b"baaa", b"baab", b"baba", b"babb", b"bbaa", b"bbab", b"bbba", b"bbbb",
      b"aaaaa", b"aaaab", b"aaaba", b"aaabb", b"aabaa", b"aabab", b"aabba", b"aabbb",
      b"abaaa", b"abaab", b"ababa", b"ababb", b"abbaa", b"abbab", b"abbba", b"abbbb",
      b"baaaa", b"baaab", b"baaba", b"baabb", b"babaa", b"babab", b"babba", b"babbb",
      b"bbaaa", b"bbaab", b"bbaba", b"bbabb", b"bbbaa", b"bbbab", b"bbbba", b"bbbbb",
    ] {
    let expected = @moonabnf.NoMatch
    assert_eq(p5.recognize("s", input).status, expected)
    let tree = p5.parse_input("s", input)
    assert_eq(tree.status, expected)
    assert_true(tree.tree is None)
  }
  let p6 = @moonabnf.compile(
    b"s = %s\"\" / u t / %s\"\" / %s\"a\"\r\nt = t s / s / u u / %s\"b\"\r\nu = %s\"b\" / %s\"b\" s / t s / u\r\n",
  ).unwrap()
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
    let expected = @moonabnf.Matched
    assert_eq(p6.recognize("s", input).status, expected)
    let tree = p6.parse_input("s", input)
    assert_eq(tree.status, expected)
    let t = tree.tree.unwrap()
    assert_eq(t.extract(input, t.root), Some(input))
    assert_true(t.rule_nodes_in("s", t.root) is Some(_))
  }
  let p7 = @moonabnf.compile(
    b"s = t %s\"a\" %s\"a\" / %s\"\" / %s\"a\"\r\nt = t / %s\"b\" / %s\"b\"\r\nu = u %s\"b\" / %s\"\" / t t\r\n",
  ).unwrap()
  for input in [b"", b"a", b"baa"] {
    let expected = @moonabnf.Matched
    assert_eq(p7.recognize("s", input).status, expected)
    let tree = p7.parse_input("s", input)
    assert_eq(tree.status, expected)
    let t = tree.tree.unwrap()
    assert_eq(t.extract(input, t.root), Some(input))
    assert_true(t.rule_nodes_in("s", t.root) is Some(_))
  }
  for
    input in [
      b"b", b"aa", b"ab", b"ba", b"bb", b"aaa", b"aab", b"aba", b"abb", b"bab", b"bba",
      b"bbb", b"aaaa", b"aaab", b"aaba", b"aabb", b"abaa", b"abab", b"abba", b"abbb",
      b"baaa", b"baab", b"baba", b"babb", b"bbaa", b"bbab", b"bbba", b"bbbb", b"aaaaa",
      b"aaaab", b"aaaba", b"aaabb", b"aabaa", b"aabab", b"aabba", b"aabbb", b"abaaa",
      b"abaab", b"ababa", b"ababb", b"abbaa", b"abbab", b"abbba", b"abbbb", b"baaaa",
      b"baaab", b"baaba", b"baabb", b"babaa", b"babab", b"babba", b"babbb", b"bbaaa",
      b"bbaab", b"bbaba", b"bbabb", b"bbbaa", b"bbbab", b"bbbba", b"bbbbb",
    ] {
    let expected = @moonabnf.NoMatch
    assert_eq(p7.recognize("s", input).status, expected)
    let tree = p7.parse_input("s", input)
    assert_eq(tree.status, expected)
    assert_true(tree.tree is None)
  }
  let p8 = @moonabnf.compile(
    b"s = %s\"\" / %s\"\" / %s\"a\"\r\nt = %s\"a\" s u / t s / u / t t / %s\"b\"\r\nu = %s\"b\" %s\"a\" s / %s\"a\" t u / %s\"b\" %s\"b\" u\r\n",
  ).unwrap()
  for input in [b"", b"a"] {
    let expected = @moonabnf.Matched
    assert_eq(p8.recognize("s", input).status, expected)
    let tree = p8.parse_input("s", input)
    assert_eq(tree.status, expected)
    let t = tree.tree.unwrap()
    assert_eq(t.extract(input, t.root), Some(input))
    assert_true(t.rule_nodes_in("s", t.root) is Some(_))
  }
  for
    input in [
      b"b", b"aa", b"ab", b"ba", b"bb", b"aaa", b"aab", b"aba", b"abb", b"baa", b"bab",
      b"bba", b"bbb", b"aaaa", b"aaab", b"aaba", b"aabb", b"abaa", b"abab", b"abba",
      b"abbb", b"baaa", b"baab", b"baba", b"babb", b"bbaa", b"bbab", b"bbba", b"bbbb",
      b"aaaaa", b"aaaab", b"aaaba", b"aaabb", b"aabaa", b"aabab", b"aabba", b"aabbb",
      b"abaaa", b"abaab", b"ababa", b"ababb", b"abbaa", b"abbab", b"abbba", b"abbbb",
      b"baaaa", b"baaab", b"baaba", b"baabb", b"babaa", b"babab", b"babba", b"babbb",
      b"bbaaa", b"bbaab", b"bbaba", b"bbabb", b"bbbaa", b"bbbab", b"bbbba", b"bbbbb",
    ] {
    let expected = @moonabnf.NoMatch
    assert_eq(p8.recognize("s", input).status, expected)
    let tree = p8.parse_input("s", input)
    assert_eq(tree.status, expected)
    assert_true(tree.tree is None)
  }
  let p9 = @moonabnf.compile(
    b"s = %s\"\" / u / %s\"a\" %s\"a\" / u / %s\"a\"\r\nt = s s %s\"a\" / %s\"a\" / %s\"b\"\r\nu = s %s\"b\" / u\r\n",
  ).unwrap()
  for
    input in [
      b"", b"a", b"b", b"aa", b"ab", b"bb", b"aab", b"abb", b"bbb", b"aabb", b"abbb",
      b"bbbb", b"aabbb", b"abbbb", b"bbbbb",
    ] {
    let expected = @moonabnf.Matched
    assert_eq(p9.recognize("s", input).status, expected)
    let tree = p9.parse_input("s", input)
    assert_eq(tree.status, expected)
    let t = tree.tree.unwrap()
    assert_eq(t.extract(input, t.root), Some(input))
    assert_true(t.rule_nodes_in("s", t.root) is Some(_))
  }
  for
    input in [
      b"ba", b"aaa", b"aba", b"baa", b"bab", b"bba", b"aaaa", b"aaab", b"aaba", b"abaa",
      b"abab", b"abba", b"baaa", b"baab", b"baba", b"babb", b"bbaa", b"bbab", b"bbba",
      b"aaaaa", b"aaaab", b"aaaba", b"aaabb", b"aabaa", b"aabab", b"aabba", b"abaaa",
      b"abaab", b"ababa", b"ababb", b"abbaa", b"abbab", b"abbba", b"baaaa", b"baaab",
      b"baaba", b"baabb", b"babaa", b"babab", b"babba", b"babbb", b"bbaaa", b"bbaab",
      b"bbaba", b"bbabb", b"bbbaa", b"bbbab", b"bbbba",
    ] {
    let expected = @moonabnf.NoMatch
    assert_eq(p9.recognize("s", input).status, expected)
    let tree = p9.parse_input("s", input)
    assert_eq(tree.status, expected)
    assert_true(tree.tree is None)
  }
  let p10 = @moonabnf.compile(
    b"s = %s\"\" / t / %s\"a\"\r\nt = %s\"b\" u %s\"a\" / s u / s / %s\"b\" %s\"a\" t / %s\"b\"\r\nu = %s\"\" / %s\"\" / u %s\"a\" s\r\n",
  ).unwrap()
  for
    input in [
      b"", b"a", b"b", b"aa", b"ab", b"ba", b"aaa", b"aab", b"aba", b"baa", b"bab",
      b"aaaa", b"aaab", b"aaba", b"abaa", b"abab", b"baaa", b"baab", b"baba", b"aaaaa",
      b"aaaab", b"aaaba", b"aabaa", b"aabab", b"abaaa", b"abaab", b"ababa", b"baaaa",
      b"baaab", b"baaba", b"babaa", b"babab",
    ] {
    let expected = @moonabnf.Matched
    assert_eq(p10.recognize("s", input).status, expected)
    let tree = p10.parse_input("s", input)
    assert_eq(tree.status, expected)
    let t = tree.tree.unwrap()
    assert_eq(t.extract(input, t.root), Some(input))
    assert_true(t.rule_nodes_in("s", t.root) is Some(_))
  }
  for
    input in [
      b"bb", b"abb", b"bba", b"bbb", b"aabb", b"abba", b"abbb", b"babb", b"bbaa",
      b"bbab", b"bbba", b"bbbb", b"aaabb", b"aabba", b"aabbb", b"ababb", b"abbaa",
      b"abbab", b"abbba", b"abbbb", b"baabb", b"babba", b"babbb", b"bbaaa", b"bbaab",
      b"bbaba", b"bbabb", b"bbbaa", b"bbbab", b"bbbba", b"bbbbb",
    ] {
    let expected = @moonabnf.NoMatch
    assert_eq(p10.recognize("s", input).status, expected)
    let tree = p10.parse_input("s", input)
    assert_eq(tree.status, expected)
    assert_true(tree.tree is None)
  }
  let p11 = @moonabnf.compile(
    b"s = %s\"b\" / t t / %s\"a\" s %s\"b\" / %s\"\" / %s\"a\"\r\nt = %s\"b\" u / %s\"b\" / %s\"\" / %s\"b\"\r\nu = %s\"\" / u t s / t t / %s\"\"\r\n",
  ).unwrap()
  for
    input in [
      b"", b"a", b"b", b"ab", b"ba", b"bb", b"aab", b"abb", b"baa", b"bab", b"bba",
      b"bbb", b"aabb", b"abab", b"abbb", b"baaa", b"baab", b"baba", b"babb", b"bbaa",
      b"bbab", b"bbba", b"bbbb", b"aaabb", b"aabbb", b"abaab", b"ababb", b"abbab",
      b"abbbb", b"baaaa", b"baaab", b"baaba", b"baabb", b"babaa", b"babab", b"babba",
      b"babbb", b"bbaaa", b"bbaab", b"bbaba", b"bbabb", b"bbbaa", b"bbbab", b"bbbba",
      b"bbbbb",
    ] {
    let expected = @moonabnf.Matched
    assert_eq(p11.recognize("s", input).status, expected)
    let tree = p11.parse_input("s", input)
    assert_eq(tree.status, expected)
    let t = tree.tree.unwrap()
    assert_eq(t.extract(input, t.root), Some(input))
    assert_true(t.rule_nodes_in("s", t.root) is Some(_))
  }
  for
    input in [
      b"aa", b"aaa", b"aba", b"aaaa", b"aaab", b"aaba", b"abaa", b"abba", b"aaaaa",
      b"aaaab", b"aaaba", b"aabaa", b"aabab", b"aabba", b"abaaa", b"ababa", b"abbaa",
      b"abbba",
    ] {
    let expected = @moonabnf.NoMatch
    assert_eq(p11.recognize("s", input).status, expected)
    let tree = p11.parse_input("s", input)
    assert_eq(tree.status, expected)
    assert_true(tree.tree is None)
  }
  let p12 = @moonabnf.compile(
    b"s = %s\"b\" / s t u / %s\"a\"\r\nt = s / %s\"\" / %s\"a\" %s\"b\" %s\"b\" / %s\"b\"\r\nu = %s\"a\" / %s\"b\" %s\"a\" t / u s\r\n",
  ).unwrap()
  for
    input in [
      b"a", b"b", b"aa", b"ba", b"aaa", b"aab", b"aba", b"baa", b"bab", b"bba", b"aaaa",
      b"aaab", b"aaba", b"aabb", b"abaa", b"abab", b"abba", b"baaa", b"baab", b"baba",
      b"babb", b"bbaa", b"bbab", b"bbba", b"aaaaa", b"aaaab", b"aaaba", b"aaabb",
      b"aabaa", b"aabab", b"aabba", b"aabbb", b"abaaa", b"abaab", b"ababa", b"ababb",
      b"abbaa", b"abbab", b"baaaa", b"baaab", b"baaba", b"baabb", b"babaa", b"babab",
      b"babba", b"babbb", b"bbaaa", b"bbaab", b"bbaba", b"bbabb", b"bbbaa", b"bbbab",
    ] {
    let expected = @moonabnf.Matched
    assert_eq(p12.recognize("s", input).status, expected)
    let tree = p12.parse_input("s", input)
    assert_eq(tree.status, expected)
    let t = tree.tree.unwrap()
    assert_eq(t.extract(input, t.root), Some(input))
    assert_true(t.rule_nodes_in("s", t.root) is Some(_))
  }
  for
    input in [
      b"", b"ab", b"bb", b"abb", b"bbb", b"abbb", b"bbbb", b"abbba", b"abbbb", b"bbbba",
      b"bbbbb",
    ] {
    let expected = @moonabnf.NoMatch
    assert_eq(p12.recognize("s", input).status, expected)
    let tree = p12.parse_input("s", input)
    assert_eq(tree.status, expected)
    assert_true(tree.tree is None)
  }
  let p13 = @moonabnf.compile(
    b"s = %s\"\" / s %s\"a\" / %s\"\" / %s\"a\"\r\nt = %s\"b\" / u s s / %s\"b\"\r\nu = %s\"\" / %s\"a\" s / u\r\n",
  ).unwrap()
  for input in [b"", b"a", b"aa", b"aaa", b"aaaa", b"aaaaa"] {
    let expected = @moonabnf.Matched
    assert_eq(p13.recognize("s", input).status, expected)
    let tree = p13.parse_input("s", input)
    assert_eq(tree.status, expected)
    let t = tree.tree.unwrap()
    assert_eq(t.extract(input, t.root), Some(input))
    assert_true(t.rule_nodes_in("s", t.root) is Some(_))
  }
  for
    input in [
      b"b", b"ab", b"ba", b"bb", b"aab", b"aba", b"abb", b"baa", b"bab", b"bba",
      b"bbb", b"aaab", b"aaba", b"aabb", b"abaa", b"abab", b"abba", b"abbb", b"baaa",
      b"baab", b"baba", b"babb", b"bbaa", b"bbab", b"bbba", b"bbbb", b"aaaab", b"aaaba",
      b"aaabb", b"aabaa", b"aabab", b"aabba", b"aabbb", b"abaaa", b"abaab", b"ababa",
      b"ababb", b"abbaa", b"abbab", b"abbba", b"abbbb", b"baaaa", b"baaab", b"baaba",
      b"baabb", b"babaa", b"babab", b"babba", b"babbb", b"bbaaa", b"bbaab", b"bbaba",
      b"bbabb", b"bbbaa", b"bbbab", b"bbbba", b"bbbbb",
    ] {
    let expected = @moonabnf.NoMatch
    assert_eq(p13.recognize("s", input).status, expected)
    let tree = p13.parse_input("s", input)
    assert_eq(tree.status, expected)
    assert_true(tree.tree is None)
  }
  let p14 = @moonabnf.compile(
    b"s = %s\"a\" %s\"a\" s / s u / t u / t %s\"b\" t / %s\"a\"\r\nt = t / s s / %s\"b\" u s / %s\"b\"\r\nu = %s\"a\" %s\"a\" / %s\"\" / %s\"a\" s s\r\n",
  ).unwrap()
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
    let expected = @moonabnf.Matched
    assert_eq(p14.recognize("s", input).status, expected)
    let tree = p14.parse_input("s", input)
    assert_eq(tree.status, expected)
    let t = tree.tree.unwrap()
    assert_eq(t.extract(input, t.root), Some(input))
    assert_true(t.rule_nodes_in("s", t.root) is Some(_))
  }
  for input in [b""] {
    let expected = @moonabnf.NoMatch
    assert_eq(p14.recognize("s", input).status, expected)
    let tree = p14.parse_input("s", input)
    assert_eq(tree.status, expected)
    assert_true(tree.tree is None)
  }
  let p15 = @moonabnf.compile(
    b"s = %s\"a\" / %s\"\" / %s\"a\" %s\"a\" / %s\"a\"\r\nt = %s\"\" / %s\"b\" %s\"a\" / %s\"a\" %s\"b\" s / %s\"b\"\r\nu = %s\"b\" u u / s u\r\n",
  ).unwrap()
  for input in [b"", b"a", b"aa"] {
    let expected = @moonabnf.Matched
    assert_eq(p15.recognize("s", input).status, expected)
    let tree = p15.parse_input("s", input)
    assert_eq(tree.status, expected)
    let t = tree.tree.unwrap()
    assert_eq(t.extract(input, t.root), Some(input))
    assert_true(t.rule_nodes_in("s", t.root) is Some(_))
  }
  for
    input in [
      b"b", b"ab", b"ba", b"bb", b"aaa", b"aab", b"aba", b"abb", b"baa", b"bab",
      b"bba", b"bbb", b"aaaa", b"aaab", b"aaba", b"aabb", b"abaa", b"abab", b"abba",
      b"abbb", b"baaa", b"baab", b"baba", b"babb", b"bbaa", b"bbab", b"bbba", b"bbbb",
      b"aaaaa", b"aaaab", b"aaaba", b"aaabb", b"aabaa", b"aabab", b"aabba", b"aabbb",
      b"abaaa", b"abaab", b"ababa", b"ababb", b"abbaa", b"abbab", b"abbba", b"abbbb",
      b"baaaa", b"baaab", b"baaba", b"baabb", b"babaa", b"babab", b"babba", b"babbb",
      b"bbaaa", b"bbaab", b"bbaba", b"bbabb", b"bbbaa", b"bbbab", b"bbbba", b"bbbbb",
    ] {
    let expected = @moonabnf.NoMatch
    assert_eq(p15.recognize("s", input).status, expected)
    let tree = p15.parse_input("s", input)
    assert_eq(tree.status, expected)
    assert_true(tree.tree is None)
  }
  let p16 = @moonabnf.compile(
    b"s = %s\"b\" / %s\"\" / %s\"\" / %s\"\" / %s\"a\"\r\nt = s / t %s\"a\" s / %s\"\" / %s\"a\" %s\"b\" / %s\"b\"\r\nu = u / %s\"b\" / u u %s\"b\" / s t %s\"a\"\r\n",
  ).unwrap()
  for input in [b"", b"a", b"b"] {
    let expected = @moonabnf.Matched
    assert_eq(p16.recognize("s", input).status, expected)
    let tree = p16.parse_input("s", input)
    assert_eq(tree.status, expected)
    let t = tree.tree.unwrap()
    assert_eq(t.extract(input, t.root), Some(input))
    assert_true(t.rule_nodes_in("s", t.root) is Some(_))
  }
  for
    input in [
      b"aa", b"ab", b"ba", b"bb", b"aaa", b"aab", b"aba", b"abb", b"baa", b"bab",
      b"bba", b"bbb", b"aaaa", b"aaab", b"aaba", b"aabb", b"abaa", b"abab", b"abba",
      b"abbb", b"baaa", b"baab", b"baba", b"babb", b"bbaa", b"bbab", b"bbba", b"bbbb",
      b"aaaaa", b"aaaab", b"aaaba", b"aaabb", b"aabaa", b"aabab", b"aabba", b"aabbb",
      b"abaaa", b"abaab", b"ababa", b"ababb", b"abbaa", b"abbab", b"abbba", b"abbbb",
      b"baaaa", b"baaab", b"baaba", b"baabb", b"babaa", b"babab", b"babba", b"babbb",
      b"bbaaa", b"bbaab", b"bbaba", b"bbabb", b"bbbaa", b"bbbab", b"bbbba", b"bbbbb",
    ] {
    let expected = @moonabnf.NoMatch
    assert_eq(p16.recognize("s", input).status, expected)
    let tree = p16.parse_input("s", input)
    assert_eq(tree.status, expected)
    assert_true(tree.tree is None)
  }
  let p17 = @moonabnf.compile(
    b"s = %s\"b\" t / t %s\"b\" / %s\"a\"\r\nt = t / t / %s\"b\"\r\nu = %s\"\" / %s\"a\" t / %s\"\" / u t\r\n",
  ).unwrap()
  for input in [b"a", b"bb"] {
    let expected = @moonabnf.Matched
    assert_eq(p17.recognize("s", input).status, expected)
    let tree = p17.parse_input("s", input)
    assert_eq(tree.status, expected)
    let t = tree.tree.unwrap()
    assert_eq(t.extract(input, t.root), Some(input))
    assert_true(t.rule_nodes_in("s", t.root) is Some(_))
  }
  for
    input in [
      b"", b"b", b"aa", b"ab", b"ba", b"aaa", b"aab", b"aba", b"abb", b"baa", b"bab",
      b"bba", b"bbb", b"aaaa", b"aaab", b"aaba", b"aabb", b"abaa", b"abab", b"abba",
      b"abbb", b"baaa", b"baab", b"baba", b"babb", b"bbaa", b"bbab", b"bbba", b"bbbb",
      b"aaaaa", b"aaaab", b"aaaba", b"aaabb", b"aabaa", b"aabab", b"aabba", b"aabbb",
      b"abaaa", b"abaab", b"ababa", b"ababb", b"abbaa", b"abbab", b"abbba", b"abbbb",
      b"baaaa", b"baaab", b"baaba", b"baabb", b"babaa", b"babab", b"babba", b"babbb",
      b"bbaaa", b"bbaab", b"bbaba", b"bbabb", b"bbbaa", b"bbbab", b"bbbba", b"bbbbb",
    ] {
    let expected = @moonabnf.NoMatch
    assert_eq(p17.recognize("s", input).status, expected)
    let tree = p17.parse_input("s", input)
    assert_eq(tree.status, expected)
    assert_true(tree.tree is None)
  }
}
