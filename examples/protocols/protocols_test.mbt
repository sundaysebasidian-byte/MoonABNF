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

///|
test "Cookie pair scoped captures preserve duplicates, quotes and empty values" {
  let p = @abnf.compile(@protocols.cookie_grammar()).unwrap()
  let input = b"a=first; a=\"second\"; a="
  let tree = p.parse_input("cookie-string", input).tree.unwrap()
  let pairs = tree.rule_nodes_in("cookie-pair", tree.root).unwrap()
  let values : Array[Bytes] = []
  for pair in pairs {
    let names = tree.rule_nodes_in("cookie-name", pair).unwrap()
    let captures = tree.rule_nodes_in("cookie-value", pair).unwrap()
    assert_eq(names.length(), 1)
    assert_eq(captures.length(), 1)
    assert_eq(tree.extract(input, names[0]), Some(b"a"))
    values.push(tree.extract(input, captures[0]).unwrap())
  }
  assert_eq(values, [b"first", b"\"second\"", b""])
}

///|
test "RFC6265 cookie-octet independently checks all 256 bytes in raw and quoted values" {
  let p = @abnf.compile(@protocols.cookie_grammar()).unwrap()
  // RFC6265 4.1.1 describes US-ASCII excluding CTLs, whitespace, DQUOTE,
  // comma, semicolon and backslash. Predicate is independent of ABNF ranges.
  for value = 0; value < 256; value = value + 1 {
    let allowed = value >= 33 &&
      value <= 126 &&
      value != 34 &&
      value != 44 &&
      value != 59 &&
      value != 92
    for quoted in [false, true] {
      let input = if quoted {
        Bytes::from_array([b'"', value.to_byte(), b'"'])
      } else {
        Bytes::from_array([value.to_byte()])
      }
      let r = p.parse_input("cookie-value", input)
      assert_eq(r.status, if allowed { @abnf.Matched } else { @abnf.NoMatch })
      if allowed {
        assert_eq(r.tree.unwrap().extract(input, 0), Some(input))
      } else {
        assert_eq(r.tree, None)
      }
    }
  }
}

///|
test "RFC3986 section 1.1.2 examples and IPv6 boundary vectors" {
  let p = @abnf.compile(@protocols.uri_grammar()).unwrap()
  // RFC3986 1.1.2 examples; syntax acceptance does not resolve these resources.
  for
    input in [
      b"ftp://ftp.is.co.za/rfc/rfc1808.txt", b"http://www.ietf.org/rfc/rfc2396.txt",
      b"ldap://[2001:db8::7]/c=GB?objectClass?one", b"mailto:John.Doe@example.com",
      b"news:comp.infosystems.www.servers.unix", b"tel:+1-816-555-1212", b"telnet://192.0.2.16:80/",
      b"urn:oasis:names:specification:docbook:dtd:xml:4.1.2",
    ] {
    let r = p.parse_input("URI", input)
    assert_eq(r.status, @abnf.Matched)
    assert_eq(r.tree.unwrap().extract(input, 0), Some(input))
  }
  // Hand-derived production boundaries, not copied conformance-suite vectors.
  for input in [b"::", b"::1", b"1::", b"1:2:3:4:5:6:7:8", b"::ffff:192.0.2.1"] {
    assert_eq(p.parse_input("IPv6address", input).status, @abnf.Matched)
  }
  for
    input in [
      b"", b":::1", b"1:2:3:4:5:6:7", b"1:2:3:4:5:6:7:8:9", b"::ffff:256.0.2.1",
    ] {
    let r = p.parse_input("IPv6address", input)
    assert_eq(r.status, @abnf.NoMatch)
    assert_eq(r.tree, None)
  }
}

///|
test "protocol failures have bounded local explanations without changing acceptance" {
  for
    (grammar, rule, input, expected_offset) in [
      (
        @protocols.uri_grammar(),
        "URI-reference",
        b"http://example.test/%GG",
        21,
      ),
      (@protocols.cookie_grammar(), "cookie-string", b"a=bad value", 5),
      (@protocols.uri_grammar(), "URI-reference", b"http://x/%", 10),
    ] {
    let p = @abnf.compile(grammar).unwrap()
    let d = p.diagnose_input(rule, input)
    assert_eq(d.report.status, @abnf.NoMatch)
    assert_eq(d.report, p.recognize(rule, input))
    assert_eq(d.failure.unwrap().offset, expected_offset)
    assert_true(d.failure.unwrap().expected.length() <= 16)
    assert_true(d.explanation_work <= 500000)
    assert_eq(p.parse_input(rule, input).status, @abnf.NoMatch)
  }
}
