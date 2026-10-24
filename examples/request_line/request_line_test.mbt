///|
fn program() -> @abnf.Program {
  @abnf.compile(@request_line.grammar()).unwrap()
}

///|
test "request line: fields are byte spans of the original input" {
  let input = b"GET /search/a%20b?q=moon&n=2 HTTP/1.1\r\n"
  let line = @request_line.parse(program(), input).unwrap()
  assert_eq(input[line.verb.0:line.verb.1].to_owned(), b"GET")
  assert_eq(input[line.path.0:line.path.1].to_owned(), b"/search/a%20b")
  let (qs, qe) = line.query.unwrap()
  assert_eq(input[qs:qe].to_owned(), b"q=moon&n=2")
  assert_eq((line.major, line.minor), (1, 1))
}

///|
test "request line: no query, HTTP/1.0, empty path segment" {
  let input = b"POST // HTTP/1.0\r\n"
  let line = @request_line.parse(program(), input).unwrap()
  assert_eq(input[line.path.0:line.path.1].to_owned(), b"//")
  assert_true(line.query is None)
  assert_eq((line.major, line.minor), (1, 0))
}

///|
test "request line: tree dump shows rule structure with spans" {
  let input = b"GET /a?x=1 HTTP/1.1\r\n"
  let report = program().parse_input("request-line", input)
  assert_eq(
    @request_line.dump(report.tree.unwrap(), input),
    (
      #|request-line [0,21) "GET /a?x=1 HTTP/1.1\r\n"
      #|  method [0,3) "GET"
      #|  sp [3,4) " "
      #|  request-target [4,10) "/a?x=1"
      #|    absolute-path [4,6) "/a"
      #|    query [7,10) "x=1"
      #|  sp [10,11) " "
      #|  http-version [11,19) "HTTP/1.1"
      #|    digit [16,17) "1"
      #|    digit [18,19) "1"
      #|  crlf [19,21) "\r\n"
    ),
  )
}

///|
test "request line: rejected inputs report the farthest byte, never a partial tree" {
  for
    (input, offset) in [
      (b"GET index.html HTTP/1.1\r\n", 4),
      (b"GET /x HTTP/1.1", 15),
      (b"GET /a b HTTP/1.1\r\n", 7),
      (b"GET /x http/1.1\r\n", 7),
      (b"GET /x HTTP/1.1\r\nHost: a\r\n", 17),
      (b"", 0),
    ] {
    let r = program().parse_input("request-line", input)
    assert_eq(r.status, @abnf.NoMatch)
    assert_true(r.tree is None)
    assert_eq(r.offset, offset)
  }
}

///|
test "request line: tight tree budget is undecided, not a mismatch" {
  let r = program().parse_input("request-line", b"GET /a HTTP/1.1\r\n", limits={
    ..@abnf.default_input_tree_limits(),
    max_nodes: 3,
  })
  assert_true(r.status is @abnf.BudgetExceeded(_))
  assert_true(r.tree is None)
}
