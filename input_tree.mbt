///|
/// A witness of an input derivation, distinct from the grammar Expr AST.
pub(all) enum InputNodeKind {
  RuleNode(String)
  LiteralNode
  RangeNode
  SequenceNode
  ChoiceNode(Int)
  RepeatNode(Int)
} derive(Eq, Debug)

///|
/// Half-open input byte span. source_offset refers to the grammar expression;
/// implicit core expressions have synthetic offset 0. Children are node IDs.
pub(all) struct InputNode {
  kind : InputNodeKind
  start : Int
  end : Int
  source_offset : Int
  children : Array[Int]
} derive(Eq, Debug)

///|
/// Flat, reachable-only tree; root is always 0. No input bytes are copied.
pub(all) struct InputTree {
  nodes : Array[InputNode]
  root : Int
} derive(Eq, Debug)

///|
/// Allocation budgets count all explored witnesses, paths and final compaction,
/// not only the returned tree. Match limits retain their existing meaning.
pub(all) struct InputTreeLimits {
  matching : MatchLimits
  max_nodes : Int
  max_edges : Int
} derive(Eq, Debug)

///|
pub fn default_input_tree_limits() -> InputTreeLimits {
  { matching: default_match_limits(), max_nodes: 20000, max_edges: 40000, }
}

///|
/// tree is Some exactly when status is Matched. Budget failure discards trees.
pub(all) struct InputTreeReport {
  status : MatchStatus
  tree : InputTree?
  offset : Int
  work : Int
  states : Int
  nodes : Int
  edges : Int
} derive(Eq, Debug)

///|
priv struct Witness {
  end : Int
  id : Int
}

///|
priv struct PathLink {
  previous : Int
  node : Int
}

///|
priv struct TreeRunner {
  runner : Runner
  limits : InputTreeLimits
  arena : Array[InputNode]
  paths : Array[PathLink]
  mut nodes : Int
  mut edges : Int
}

///|
fn TreeRunner::edge(self : TreeRunner) -> Unit raise MatchStop {
  self.runner.tick(0)
  if self.edges >= self.limits.max_edges {
    raise MatchStop("tree-edges")
  }
  self.edges = self.edges + 1
}

///|
fn TreeRunner::charge_node(self : TreeRunner) -> Unit raise MatchStop {
  self.runner.tick(0)
  if self.nodes >= self.limits.max_nodes {
    raise MatchStop("tree-nodes")
  }
  self.nodes = self.nodes + 1
}

///|
fn TreeRunner::node(
  self : TreeRunner,
  kind : InputNodeKind,
  start : Int,
  end : Int,
  source_offset : Int,
  children : Array[Int],
) -> Int raise MatchStop {
  self.charge_node()
  // children was constructed by a charged path traversal or a bounded literal.
  let id = self.arena.length()
  self.arena.push({ kind, start, end, source_offset, children, })
  id
}

///|
fn TreeRunner::single(
  self : TreeRunner,
  id : Int,
) -> Array[Int] raise MatchStop {
  self.edge()
  [id]
}

///|
fn TreeRunner::append(
  self : TreeRunner,
  previous : Int,
  node : Int,
) -> Int raise MatchStop {
  self.edge()
  let id = self.paths.length()
  self.paths.push({ previous, node, })
  id
}

///|
fn TreeRunner::children(
  self : TreeRunner,
  path : Int,
) -> Array[Int] raise MatchStop {
  let out : Array[Int] = []
  let mut at = path
  while at >= 0 {
    self.edge()
    let link = self.paths[at]
    out.push(link.node)
    at = link.previous
  }
  // Charge reversal operations too; paths avoid quadratic prefix copying.
  for i = 0; i < out.length() / 2; i = i + 1 {
    self.runner.tick(0)
    let j = out.length() - i - 1
    let old = out[i]
    out[i] = out[j]
    out[j] = old
  }
  out
}

///|
/// One witness per endpoint is sufficient for context-free continuation.
/// Traversal order chooses a witness only; it never prunes a distinct endpoint.
fn TreeRunner::contains(
  self : TreeRunner,
  out : Array[Witness],
  end : Int,
) -> Bool raise MatchStop {
  for old in out {
    self.runner.tick(end)
    if old.end == end {
      return true
    }
  }
  false
}

///|
fn TreeRunner::insert(
  self : TreeRunner,
  out : Array[Witness],
  end : Int,
  id : Int,
) -> Unit raise MatchStop {
  if end > self.runner.furthest {
    self.runner.furthest = end
  }
  self.runner.tick(end)
  if !self.contains(out, end) {
    if self.runner.states >= self.runner.limits.max_states {
      raise MatchStop("states")
    }
    self.runner.states = self.runner.states + 1
    out.push({ end, id, })
  }
}

///|
fn TreeRunner::eval(
  self : TreeRunner,
  e : Expr,
  pos : Int,
  depth : Int,
) -> Array[Witness] raise MatchStop {
  let runner = self.runner
  if pos > runner.furthest {
    runner.furthest = pos
  }
  runner.tick(pos)
  if depth > runner.limits.max_depth {
    raise MatchStop("depth")
  }
  let out : Array[Witness] = []
  match e {
    Ref(name, source) =>
      for w in self.eval(runner.program.rules[name], pos, depth + 1) {
        let id = self.node(
          RuleNode(name),
          pos,
          w.end,
          source,
          self.single(w.id),
        )
        self.insert(out, w.end, id)
      }
    Literal(s, sensitive, source) => {
      for i = 0; i < s.length(); i = i + 1 {
        let at = pos + i
        if at > runner.furthest {
          runner.furthest = at
        }
        runner.tick(at)
        if at >= runner.input.length() {
          return out
        }
        let actual = runner.input[at].to_int()
        let wanted = s[i].to_int()
        if (if sensitive {
            actual != wanted
          } else {
            ascii_lower(actual) != ascii_lower(wanted)
          }) {
          return out
        }
      }
      let end = pos + s.length()
      self.insert(out, end, self.node(LiteralNode, pos, end, source, []))
    }
    Range(lo, hi, source) =>
      if pos < runner.input.length() {
        let value = runner.input[pos].to_int()
        if value >= lo && value <= hi {
          self.insert(
            out,
            pos + 1,
            self.node(RangeNode, pos, pos + 1, source, []),
          )
        }
      }
    Choice(es, source) =>
      for index = 0; index < es.length(); index = index + 1 {
        for w in self.eval(es[index], pos, depth + 1) {
          let id = self.node(
            ChoiceNode(index),
            pos,
            w.end,
            source,
            self.single(w.id),
          )
          self.insert(out, w.end, id)
        }
      }
    Sequence(es, source) => {
      let mut frontier : Array[Witness] = []
      self.insert(frontier, pos, -1)
      for child in es {
        let next : Array[Witness] = []
        for w in frontier {
          for child_w in self.eval(child, w.end, depth + 1) {
            self.insert(next, child_w.end, self.append(w.id, child_w.id))
          }
        }
        frontier = next
        if frontier.is_empty() {
          break
        }
      }
      for w in frontier {
        let id = self.node(
          SequenceNode,
          pos,
          w.end,
          source,
          self.children(w.id),
        )
        self.insert(out, w.end, id)
      }
    }
    Repeat(lo, hi, child, source) => {
      let mut frontier : Array[Witness] = []
      self.insert(frontier, pos, -1)
      let mut count = 0
      while true {
        runner.tick(pos)
        if count >= lo {
          for w in frontier {
            if !self.contains(out, w.end) {
              let id = self.node(
                RepeatNode(count),
                pos,
                w.end,
                source,
                self.children(w.id),
              )
              self.insert(out, w.end, id)
            }
          }
        }
        if hi is Some(max) && count >= max {
          break
        }
        let next : Array[Witness] = []
        for w in frontier {
          for child_w in self.eval(child, w.end, depth + 1) {
            self.insert(next, child_w.end, self.append(w.id, child_w.id))
          }
        }
        if next.is_empty() {
          break
        }
        let mut stable = next.length() == frontier.length()
        if stable {
          for w in next {
            if !self.contains(frontier, w.end) {
              stable = false
              break
            }
          }
        }
        // A stable endpoint set can stop only after an actual minimum-count
        // witness exists. Epsilon occurrences cannot be invented in the tree.
        if stable && count >= lo {
          break
        }
        count = count + 1
        frontier = next
      }
    }
    Prose(_, _) => raise MatchStop("invalid-program")
  }
  out
}

///|
/// Compact iteratively so abandoned branches are not exposed. Flat nodes also
/// keep wide repetitions from making a recursive list on the runtime stack.
fn TreeRunner::finish(
  self : TreeRunner,
  root : Int,
) -> InputTree raise MatchStop {
  let pending = [root]
  let ids : Map[Int, Int] = Map([(root, 0)])
  let nodes : Array[InputNode] = []
  let mut i = 0
  while i < pending.length() {
    self.charge_node()
    let old = self.arena[pending[i]]
    let children : Array[Int] = []
    for child in old.children {
      self.edge()
      let id = match ids.get(child) {
        Some(id) => id
        None => {
          let id = pending.length()
          ids[child] = id
          pending.push(child)
          id
        }
      }
      children.push(id)
    }
    nodes.push({ ..old, children, })
    i = i + 1
  }
  { nodes, root: 0, }
}

///|
/// Parse the whole input into one deterministic derivation witness. All ABNF
/// alternatives/endpoints are explored; source order breaks equal-endpoint ties.
/// Repeats try counts ascending, retaining the first path at each exact count.
/// This does not enumerate ambiguity or change recognize's budgets/behavior.
///
/// ```mbt check
/// test {
///   let p = @moonabnf.compile(b"s = 1*DIGIT\r\n").unwrap()
///   let report = p.parse_input("s", b"42")
///   assert_true(report.status is @moonabnf.Matched)
///   assert_eq(report.tree.unwrap().nodes[0].end, 2)
/// }
/// ```
pub fn Program::parse_input(
  self : Program,
  start : String,
  input : Bytes,
  limits? : InputTreeLimits = default_input_tree_limits(),
) -> InputTreeReport {
  let matching = limits.matching
  let empty : InputTreeReport = {
    status: InvalidLimits,
    tree: None,
    offset: 0,
    work: 0,
    states: 0,
    nodes: 0,
    edges: 0,
  }
  if !valid_match_limits(matching) ||
    limits.max_nodes < 1 ||
    limits.max_nodes > 100000 ||
    limits.max_edges < 1 ||
    limits.max_edges > 200000 {
    return empty
  }
  if input.length() > matching.max_input_bytes {
    return { ..empty, status: BudgetExceeded("input-bytes"), }
  }
  let name = lower_name(start)
  let e = match self.rules.get(name) {
    None => return { ..empty, status: UnknownRule, }
    Some(e) => e
  }
  let runner : Runner = {
    failures: None,
    program: self,
    input,
    limits: matching,
    work: 0,
    states: 0,
    furthest: 0,
  }
  let tree_runner : TreeRunner = {
    runner,
    limits,
    arena: [],
    paths: [],
    nodes: 0,
    edges: 0,
  }
  let mut tree : InputTree? = None
  let status = try {
    let ends = tree_runner.eval(e, 0, 0)
    let mut selected : Int? = None
    for w in ends {
      runner.tick(w.end)
      if w.end == input.length() {
        selected = Some(w.id)
        break
      }
    }
    match selected {
      None => NoMatch
      Some(id) => {
        let root = tree_runner.node(
          RuleNode(name),
          0,
          input.length(),
          e.offset(),
          tree_runner.single(id),
        )
        tree = Some(tree_runner.finish(root))
        Matched
      }
    }
  } catch {
    MatchStop(reason) => BudgetExceeded(reason)
  }
  {
    status,
    tree,
    offset: if status == Matched {
      input.length()
    } else {
      runner.furthest
    },
    work: runner.work,
    states: runner.states,
    nodes: tree_runner.nodes,
    edges: tree_runner.edges,
  }
}

///|
pub extend InputNodeKind with Eq::{equal, not_equal}

///|
pub extend InputNodeKind with @debug.Debug::{to_repr}

///|
pub extend InputNode with Eq::{equal, not_equal}

///|
pub extend InputNode with @debug.Debug::{to_repr}

///|
pub extend InputTree with Eq::{equal, not_equal}

///|
pub extend InputTree with @debug.Debug::{to_repr}

///|
pub extend InputTreeLimits with Eq::{equal, not_equal}

///|
pub extend InputTreeLimits with @debug.Debug::{to_repr}

///|
pub extend InputTreeReport with Eq::{equal, not_equal}

///|
pub extend InputTreeReport with @debug.Debug::{to_repr}
