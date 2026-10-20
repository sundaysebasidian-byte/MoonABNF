///|
/// Matching rule nodes in the tree's stable storage order (breadth-first for
/// parse_input results). Rule names are ASCII case-insensitive as in ABNF.
/// Does not traverse caller-mutable children, so malformed cycles cannot loop.
pub fn InputTree::rule_nodes(self : InputTree, name : String) -> Array[Int] {
  let wanted = lower_name(name)
  let result : Array[Int] = []
  for id, node in self.nodes {
    if node.kind is RuleNode(rule) && lower_name(rule) == wanted {
      result.push(id)
    }
  }
  result
}

///|
/// Half-open byte span, or None for an invalid node ID or malformed span.
pub fn InputTree::span(self : InputTree, node : Int) -> (Int, Int)? {
  if node < 0 || node >= self.nodes.length() {
    return None
  }
  let n = self.nodes[node]
  if n.start < 0 || n.end < n.start {
    return None
  }
  Some((n.start, n.end))
}

///|
/// Copies raw bytes from the caller's original input; does not decode UTF-8,
/// URI escapes or quoted strings. Input identity remains caller responsibility.
/// Invalid IDs/spans or an input shorter than the span return None.
pub fn InputTree::extract(
  self : InputTree,
  input : Bytes,
  node : Int,
) -> Bytes? {
  match self.span(node) {
    Some((start, end)) if end <= input.length() =>
      Some(input[start:end].to_owned())
    _ => None
  }
}
