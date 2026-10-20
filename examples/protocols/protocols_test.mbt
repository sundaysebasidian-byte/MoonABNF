///|
fn capture(tree : @abnf.InputTree, input : Bytes, name : String) -> Bytes {
  tree.extract(input, tree.rule_nodes(name)[0]).unwrap()
}

///|
test "RFC3986 URI tree extracts components including IPv6 and relative forms" {
  let p = @abnf.compile(@protocols.uri_grammar()).unwrap()
  let input = b"https://example.test:8443/a%20b?q=1#top"
  let report = p.parse_input("URI", input)
  assert_eq(report.status, @abnf.Matched)
  let tree = report.tree.unwrap()
  for
    (rule, expected) in [
      ("scheme", b"https"),
      ("host", b"example.test"),
      ("port", b"8443"),
      ("query", b"q=1"),
      ("fragment", b"top"),
      ("path-abempty", b"/a%20b"),
    ] {
    assert_eq(capture(tree, input, rule), expected)
  }
  for
    input in [
      b"http://[2001:db8::1]/", b"urn:example:animal:ferret:nose", b"../a?x#y", b"//example.test/a",
      b"", b"#fragment", b"https://127.0.0.1/",
    ] {
    let report = p.parse_input("URI-reference", input)
    assert_eq(report.status, @abnf.Matched)
    assert_eq(report.tree.unwrap().extract(input, 0), Some(input))
  }
  for
    input in [
      b"http://[::zz]/", b"http://example.test/%GG", b"http://exa mple/a", b"http://a/#b#c",
      b"https://a/\n",
    ] {
    let report = p.parse_input("URI-reference", input)
    assert_eq(report.status, @abnf.NoMatch)
    assert_eq(report.tree, None)
  }
}

///|
test "RFC6265 Cookie tree extracts repeated pairs without unquoting values" {
  let p = @abnf.compile(@protocols.cookie_grammar()).unwrap()
  let input = b"session=abc; theme=\"dark\"; empty="
  let report = p.parse_input("cookie-string", input)
  assert_eq(report.status, @abnf.Matched)
  let tree = report.tree.unwrap()
  assert_eq(tree.rule_nodes("cookie-pair").length(), 3)
  let names = tree
    .rule_nodes("cookie-name")
    .map(id => tree.extract(input, id).unwrap())
  let values = tree
    .rule_nodes("cookie-value")
    .map(id => tree.extract(input, id).unwrap())
  assert_eq(names, [b"session", b"theme", b"empty"])
  assert_eq(values, [b"abc", b"\"dark\"", b""])
  for
    input in [
      b"", b"=x", b"a=b;c=d", b"a=bad value", b"a=\"unfinished", b"a=b\r\n", b"a=\xFF",
    ] {
    let report = p.parse_input("cookie-string", input)
    assert_eq(report.status, @abnf.NoMatch)
    assert_eq(report.tree, None)
  }
}
