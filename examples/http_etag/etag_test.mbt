///|
test "RFC9110 ETag value extraction and invalid values" {
  let p = @abnf.compile(@http_etag.grammar()).unwrap()
  for
    (input, weak, value) in [
      (b"\"\"", false, b""),
      (b"\"version-12\"", false, b"version-12"),
      (b"W/\"rev-7\"", true, b"rev-7"),
      (b"W/\"\x80\xFF\"", true, b"\x80\xFF"),
      (b"\"a\\b\"", false, b"a\\b"),
    ] {
    let r = p.parse_input("ENTITY-TAG", input)
    assert_eq(r.status, @abnf.Matched)
    let tag = @http_etag.extract(r.tree.unwrap())
    assert_eq(tag.weak, weak)
    assert_eq(input[tag.value_start:tag.value_end].to_owned(), value)
    assert_eq(r.offset, input.length())
    assert_eq(p.recognize("entity-tag", input).status, r.status)
  }
  for
    input in [
      b"w/\"x\"", b"W /\"x\"", b"\"a b\"", b"\"a\tb\"", b"\"a\x00b\"", b"\"a\x7Fb\"",
      b"\"a\r\nb\"", b"\"a\"b\"", b"\"unfinished", b"\"x\"tail", b"\"x\",\"y\"",
      b"ETag: \"x\"\r\n", b" \"x\" ",
    ] {
    let r = p.parse_input("entity-tag", input)
    assert_eq(r.status, @abnf.NoMatch)
    assert_true(r.tree is None)
  }
}

///|
test "RFC9110 ETag every interior octet against independent numeric predicate" {
  let p = @abnf.compile(@http_etag.grammar()).unwrap()
  for byte = 0; byte < 256; byte = byte + 1 {
    let input = Bytes::from_array([b'"', byte.to_byte(), b'"'])
    let permitted = byte == 33 || (byte >= 35 && byte <= 126) || byte >= 128
    let r = p.parse_input("entity-tag", input)
    assert_eq(r.status == @abnf.Matched, permitted)
    assert_eq(p.recognize("entity-tag", input).status, r.status)
    if permitted {
      let span = @http_etag.extract(r.tree.unwrap())
      assert_eq(span.value_start, 1)
      assert_eq(span.value_end, 2)
      assert_eq(input[span.value_start], byte.to_byte())
    } else {
      assert_true(r.tree is None)
    }
  }
}

///|
test "RFC9110 empty weak tag and reuse after rejection or budget exhaustion" {
  let p = @abnf.compile(@http_etag.grammar()).unwrap()
  let input = b"W/\"\""
  let weak_empty = p.parse_input("entity-tag", input)
  assert_eq(weak_empty.status, @abnf.Matched)
  let span = @http_etag.extract(weak_empty.tree.unwrap())
  assert_true(span.weak)
  assert_eq(span.value_start, 3)
  assert_eq(span.value_end, 3)
  assert_eq(input[span.value_start:span.value_end].to_owned(), b"")
  for input in [b"W/", b"W/\"", b"W/\"\"x", b"w/\"\""] {
    let rejected = p.parse_input("entity-tag", input)
    assert_eq(rejected.status, @abnf.NoMatch)
    assert_true(rejected.tree is None)
  }
  let exhausted = p.parse_input("entity-tag", input, limits={
    ..@abnf.default_input_tree_limits(),
    max_nodes: 1,
  })
  assert_true(exhausted.status is @abnf.BudgetExceeded(_))
  assert_true(exhausted.tree is None)
  let strong_empty = p.parse_input("entity-tag", b"\"\"")
  assert_eq(strong_empty.status, @abnf.Matched)
  let span = @http_etag.extract(strong_empty.tree.unwrap())
  assert_false(span.weak)
  assert_eq(span.value_start, 1)
  assert_eq(span.value_end, 1)
  assert_eq(p.parse_input("entity-tag", input).tree, weak_empty.tree)
}
