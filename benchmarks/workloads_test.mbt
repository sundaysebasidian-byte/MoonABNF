///|
test "protocol workloads separate compilation recognition and tree construction" (
  b : @bench.T,
) {
  let grammar = @protocols.cookie_grammar()
  let cookie = @abnf.compile(grammar).unwrap()
  let input = b"session=abc; theme=\"dark\"; empty="
  assert_eq(cookie.parse_input("cookie-string", input).status, @abnf.Matched)
  b.bench(
    name="compile_cookie",
    fn() { b.keep(@abnf.compile(grammar)) },
    count=5,
  )
  b.bench(
    name="recognize_cookie_\{input.length()}B",
    fn() { b.keep(cookie.recognize("cookie-string", input)) },
    count=5,
  )
  b.bench(
    name="tree_cookie_\{input.length()}B",
    fn() { b.keep(cookie.parse_input("cookie-string", input)) },
    count=5,
  )
  let uri = @abnf.compile(@protocols.uri_grammar()).unwrap()
  let input = b"https://[2001:db8::1]:8443/a%20b?q=1#top"
  assert_eq(uri.parse_input("URI", input).status, @abnf.Matched)
  b.bench(
    name="tree_uri_ipv6_\{input.length()}B",
    fn() { b.keep(uri.parse_input("URI", input)) },
    count=5,
  )
}

///|
test "fixed-width binary tree workloads and scoped capture queries" (
  b : @bench.T,
) {
  // A fixed repeat avoids collecting every prefix as an output endpoint.
  // It measures one specific linear workload, not arbitrary ABNF complexity.
  let p = @abnf.compile(b"blob = 4096OCTET\r\n").unwrap()
  let input = Bytes::make(4096, 0xFF)
  let r = p.parse_input("blob", input)
  assert_eq(r.status, @abnf.Matched)
  let tree = r.tree.unwrap()
  assert_eq(tree.rule_nodes_in("octet", 0).unwrap().length(), 4096)
  println(
    "binary workload: bytes=\{input.length()} work=\{r.work} states=\{r.states} nodes=\{r.nodes} edges=\{r.edges}",
  )
  b.bench(
    name="tree_binary_4096B",
    fn() { b.keep(p.parse_input("blob", input)) },
    count=5,
  )
  b.bench(
    name="captures_binary_4096_nodes",
    fn() { b.keep(tree.rule_nodes_in("OCTET", 0)) },
    count=5,
  )
}

///|
test "scoped queries across many Cookie pairs" (b : @bench.T) {
  let p = @abnf.compile(@protocols.cookie_grammar()).unwrap()
  let bytes : Array[Byte] = []
  for i = 0; i < 32; i = i + 1 {
    if i > 0 {
      bytes.push(b';')
      bytes.push(b' ')
    }
    for byte in b"a=b" {
      bytes.push(byte)
    }
  }
  let input = Bytes::from_array(bytes)
  let tree = p.parse_input("cookie-string", input).tree.unwrap()
  let pairs = tree.rule_nodes_in("cookie-pair", tree.root).unwrap()
  assert_eq(pairs.length(), 32)
  b.bench(
    name="scoped_name_value_32_pairs",
    fn() {
      for pair in pairs {
        b.keep(tree.rule_nodes_in("cookie-name", pair))
        b.keep(tree.rule_nodes_in("cookie-value", pair))
      }
    },
    count=5,
  )
}
