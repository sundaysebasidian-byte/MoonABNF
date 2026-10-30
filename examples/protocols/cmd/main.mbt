///|
fn show_field(
  tree : @abnf.InputTree,
  input : Bytes,
  root : Int32,
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
fn show_grammar(grammar : Bytes) -> Unit raise {
  let ast = @abnf.parse(grammar).unwrap()
  let mut end = 0
  while end < grammar.length() && grammar[end] != b'\r' {
    end = end + 1
  }
  println("Grammar AST: \{ast.rules.length()} rules; first source rule:")
  println("  \{@utf8.decode(grammar[0:end])}")
}

///|
fn node_label(kind : @abnf.InputNodeKind) -> String {
  match kind {
    @abnf.RuleNode(name) => "Rule(\{name})"
    @abnf.LiteralNode => "Literal"
    @abnf.RangeNode => "Range"
    @abnf.SequenceNode => "Sequence"
    @abnf.ChoiceNode(branch) => "Choice(\{branch})"
    @abnf.RepeatNode(count) => "Repeat(\{count})"
  }
}

///|
fn show_node(tree : @abnf.InputTree, id : Int32, indent : String) -> Unit {
  let node = tree.nodes[id]
  println("\{indent}\{node_label(node.kind)} [\{node.start},\{node.end})")
}

///|
fn show_tree(tree : @abnf.InputTree) -> Unit {
  println("Input derivation tree (first 3 levels):")
  show_node(tree, tree.root, "  ")
  for child in tree.nodes[tree.root].children {
    show_node(tree, child, "    ")
    for grandchild in tree.nodes[child].children {
      show_node(tree, grandchild, "      ")
    }
  }
}

///|
fn main raise {
  let grammar = @protocols.uri_grammar()
  show_grammar(grammar)
  let uri = @abnf.compile(grammar).unwrap()
  let input = b"https://[2001:db8::1]:8443/a%20b?q=1#top"
  let tree = uri.parse_input("URI", input).tree.unwrap()
  show_tree(tree)
  println("URI components (syntax only, no percent decoding):")
  for name in ["scheme", "host", "port", "path-abempty", "query", "fragment"] {
    show_field(tree, input, tree.root, name)
  }
  let grammar = @protocols.cookie_grammar()
  show_grammar(grammar)
  let cookie = @abnf.compile(grammar).unwrap()
  let input = b"session=abc; theme=\"dark\"; empty=; session=second"
  let tree = cookie.parse_input("cookie-string", input).tree.unwrap()
  show_tree(tree)
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
