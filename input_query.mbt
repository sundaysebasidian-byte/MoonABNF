///|
/// Matching rule nodes in the tree's stable storage order (breadth-first for
/// parse_input results). Rule names are ASCII case-insensitive as in ABNF.
/// Does not traverse caller-mutable children, so malformed cycles cannot loop.
pub fn InputTree::rule_nodes(self : InputTree, name : String) -> Array[Int32] {
  let wanted = lower_name(name)
  let result : Array[Int32] = []
  for id, node in self.nodes {
    if node.kind is RuleNode(rule) && lower_name(rule) == wanted {
      result.push(id)
    }
  }
  result
}

///|
/// Named nodes within a subtree, including `root`, in depth-first pre-order.
/// Unlike rule_nodes' storage order, this follows the derivation's child order:
/// outer captures precede inner captures, and siblings follow input order.
/// Returns None for an invalid ID, span, arity, cycle or shared descendant in
/// the selected subtree. Unreachable nodes outside it are not inspected.
/// Iterative; storage is proportional to visited descendants, not the entire
/// tree. Never schedules a child twice.
/// This checks structure, not grammar membership or original-input identity.
///
/// ```mbt check
/// test {
///   let p = @moonabnf.compile(b"s = item item\r\nitem = DIGIT\r\n").unwrap()
///   let tree = p.parse_input("s", b"42").tree.unwrap()
///   let ids = tree.rule_nodes_in("item", tree.root).unwrap()
///   assert_eq(ids.map(id => tree.extract(b"42", id)), [Some(b"4"), Some(b"2")])
/// }
/// ```
pub fn InputTree::rule_nodes_in(
  self : InputTree,
  name : String,
  root : Int32,
) -> Array[Int32]? {
  if root < 0 || root >= self.nodes.length() {
    return None
  }
  let wanted = lower_name(name)
  let seen : Map[Int32, Bool] = Map([(root, true)])
  let pending = [root]
  let result : Array[Int32] = []
  while !pending.is_empty() {
    let id = pending.pop().unwrap()
    let node = self.nodes[id]
    if node.start < 0 || node.end < node.start || node.source_offset < 0 {
      return None
    }
    match node.kind {
      LiteralNode => if !node.children.is_empty() { return None }
      RangeNode =>
        if !node.children.is_empty() || node.end - node.start != 1 {
          return None
        }
      RuleNode(_) => if node.children.length() != 1 { return None }
      ChoiceNode(index) =>
        if index < 0 || node.children.length() != 1 {
          return None
        }
      RepeatNode(count) =>
        if count < 0 || node.children.length() != count {
          return None
        }
      SequenceNode => ()
    }
    // Reject invalid topology while scheduling, so even a wide malformed
    // graph cannot grow pending beyond the number of stored nodes.
    let mut end = node.start
    for child in node.children {
      if child < 0 || child >= self.nodes.length() || seen.contains(child) {
        return None
      }
      let next = self.nodes[child]
      if next.start != end || next.end < next.start || next.end > node.end {
        return None
      }
      seen[child] = true
      end = next.end
    }
    if !node.children.is_empty() ||
      node.kind is SequenceNode ||
      node.kind is RepeatNode(_) {
      if end != node.end {
        return None
      }
    }
    if node.kind is RuleNode(rule) && lower_name(rule) == wanted {
      result.push(id)
    }
    for i = node.children.length(); i > 0; i = i - 1 {
      pending.push(node.children[i - 1])
    }
  }
  Some(result)
}

///|
/// Half-open byte span, or None for an invalid node ID or malformed span.
/// Zero-width spans are valid. This local check does not validate topology,
/// the root, grammar membership or the span against an input length.
pub fn InputTree::span(self : InputTree, node : Int32) -> (Int32, Int32)? {
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
/// A different input of sufficient length is accepted, even if its bytes or
/// total length differ. Use the exact original Bytes; this is not validation.
pub fn InputTree::extract(
  self : InputTree,
  input : Bytes,
  node : Int32,
) -> Bytes? {
  match self.span(node) {
    Some((start, end)) if end <= input.length() =>
      Some(input[start:end].to_owned())
    _ => None
  }
}
