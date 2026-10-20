///|
fn show_field(
  tree : @abnf.InputTree,
  input : Bytes,
  root : Int,
  name : String,
) -> Unit {
  for id in tree.rule_nodes_in(name, root).unwrap() {
    let (start, end) = tree.span(id).unwrap()
    println(
      "  \{name}=[\{start},\{end}) raw=\{tree.extract(input, id).unwrap()}",
    )
  }
}

///|
fn outcome(status : @abnf.MatchStatus) -> String {
  match status {
    @abnf.Matched => "matched"
    @abnf.NoMatch => "no-match"
    @abnf.BudgetExceeded(reason) => "indeterminate (\{reason})"
    @abnf.UnknownRule => "unknown-rule"
    @abnf.InvalidLimits => "invalid-limits"
  }
}

///|
fn main {
  let uri = @abnf.compile(@protocols.uri_grammar()).unwrap()
  let input = b"https://[2001:db8::1]:8443/a%20b?q=1#top"
  let tree = uri.parse_input("URI", input).tree.unwrap()
  println("URI components (syntax only, no percent decoding):")
  for name in ["scheme", "host", "port", "path-abempty", "query", "fragment"] {
    show_field(tree, input, tree.root, name)
  }
  let cookie = @abnf.compile(@protocols.cookie_grammar()).unwrap()
  let input = b"session=abc; theme=\"dark\"; empty=; session=second"
  let tree = cookie.parse_input("cookie-string", input).tree.unwrap()
  println("Cookie pairs (duplicates and quotes preserved):")
  for pair in tree.rule_nodes_in("cookie-pair", tree.root).unwrap() {
    show_field(tree, input, pair, "cookie-name")
    show_field(tree, input, pair, "cookie-value")
  }
  let rejected = cookie.parse_input("cookie-string", b"session=bad value")
  println(
    "Invalid Cookie: \{outcome(rejected.status)} at byte \{rejected.offset}",
  )
  let limited = cookie.parse_input("cookie-string", input, limits={
    ..@abnf.default_input_tree_limits(),
    max_nodes: 1,
  })
  println(
    "Limited Cookie: \{outcome(limited.status)}, tree absent=\{limited.tree is None}",
  )
}
