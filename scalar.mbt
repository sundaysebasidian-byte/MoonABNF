///|
/// An explicitly selected Unicode-scalar application domain, not an ABNF
/// mandated external encoding. Byte Program and ScalarProgram cannot be mixed.
pub struct ScalarProgram {
  priv program : Program
}

///|
pub fn compile_scalar(
  source : Bytes,
  bindings~ : Array[ProseBinding] = [],
  limits~ : ParseLimits = default_parse_limits(),
  max_work~ : Int32 = 1000000,
) -> Result[ScalarProgram, Diagnostic] {
  match compile_domain(source, limits, max_work, true, bindings, true) {
    Ok(program) => Ok({ program, })
    Err(d) => Err(d)
  }
}

///|
pub fn ScalarProgram::rule_names(self : ScalarProgram) -> Array[String] {
  self.program.rule_names()
}

///|
/// No UTF-8/UTF-16 decoding is performed: one Int is one scalar value.
pub(all) enum ScalarInputError {
  InvalidScalar(Int32, Int32) // zero-based input index, invalid value
} derive(Eq, Debug)

///|
pub(all) struct ScalarMatchLimits {
  max_input_scalars : Int32
  max_work : Int32
  max_states : Int32
  max_depth : Int32
} derive(Eq, Debug)

///|
pub fn default_scalar_match_limits() -> ScalarMatchLimits {
  {
    max_input_scalars: 65536,
    max_work: 500000,
    max_states: 100000,
    max_depth: 128,
  }
}

///|
fn ScalarMatchLimits::matching(self : ScalarMatchLimits) -> MatchLimits {
  {
    max_input_bytes: self.max_input_scalars,
    max_work: self.max_work,
    max_states: self.max_states,
    max_depth: self.max_depth,
  }
}

///|
/// All report offsets are scalar indices. Validation costs one work unit per
/// scalar, before matching. This synchronous method neither copies nor retains
/// the input array and never invokes user callbacks. Exhausted validation is
/// indeterminate, not a claim that the unchecked suffix is valid.
pub fn ScalarProgram::recognize(
  self : ScalarProgram,
  start : String,
  input : Array[Int32],
  limits~ : ScalarMatchLimits = default_scalar_match_limits(),
) -> Result[MatchReport, ScalarInputError] {
  let matching = limits.matching()
  let empty : MatchReport = {
    status: InvalidLimits,
    offset: 0,
    work: 0,
    states: 0,
  }
  if !valid_match_limits(matching) {
    return Ok(empty)
  }
  if input.length() > limits.max_input_scalars {
    return Ok({ ..empty, status: BudgetExceeded("input-scalars"), })
  }
  for i, value in input {
    if i >= limits.max_work {
      return Ok({ ..empty, status: BudgetExceeded("work"), work: i, })
    }
    if !is_scalar(value) {
      return Err(InvalidScalar(i, value))
    }
  }
  let report = self.program.recognize_symbols(
    start,
    ScalarSymbols(input),
    matching,
    input.length(),
  )
  // Empty/unknown start shortcuts still expose the validation work consumed.
  Ok({
    ..report,
    work: if report.work < input.length() {
      input.length()
    } else {
      report.work
    },
  })
}

///|
/// A distinct tree type prevents accidental use of byte extract() with scalar
/// indices. start/end are scalar positions; source_offset stays a grammar byte
/// position. Prose bindings are represented by lowered Choice/Sequence/Range.
pub(all) struct ScalarInputTree {
  nodes : Array[InputNode]
  root : Int32
} derive(Eq, Debug)

///|
fn ScalarInputTree::inner(self : ScalarInputTree) -> InputTree {
  { nodes: self.nodes, root: self.root, }
}

///|
pub fn ScalarInputTree::span(
  self : ScalarInputTree,
  node : Int32,
) -> (Int32, Int32)? {
  self.inner().span(node)
}

///|
pub fn ScalarInputTree::rule_nodes(
  self : ScalarInputTree,
  name : String,
) -> Array[Int32] {
  self.inner().rule_nodes(name)
}

///|
pub fn ScalarInputTree::rule_nodes_in(
  self : ScalarInputTree,
  name : String,
  root : Int32,
) -> Array[Int32]? {
  self.inner().rule_nodes_in(name, root)
}

///|
/// Copies the selected scalar span, returning None for invalid spans.
pub fn ScalarInputTree::extract(
  self : ScalarInputTree,
  input : Array[Int32],
  node : Int32,
) -> Array[Int32]? {
  match self.span(node) {
    Some((start, end)) if end <= input.length() => {
      let out : Array[Int32] = []
      for i = start; i < end; i = i + 1 {
        out.push(input[i])
      }
      Some(out)
    }
    _ => None
  }
}

///|
pub(all) struct ScalarInputTreeLimits {
  matching : ScalarMatchLimits
  max_nodes : Int32
  max_edges : Int32
} derive(Eq, Debug)

///|
pub fn default_scalar_input_tree_limits() -> ScalarInputTreeLimits {
  {
    matching: default_scalar_match_limits(),
    max_nodes: 20000,
    max_edges: 40000,
  }
}

///|
pub(all) struct ScalarInputTreeReport {
  status : MatchStatus
  tree : ScalarInputTree?
  offset : Int32
  work : Int32
  states : Int32
  nodes : Int32
  edges : Int32
} derive(Eq, Debug)

///|
pub fn ScalarProgram::parse_input(
  self : ScalarProgram,
  start : String,
  input : Array[Int32],
  limits~ : ScalarInputTreeLimits = default_scalar_input_tree_limits(),
) -> Result[ScalarInputTreeReport, ScalarInputError] {
  let matching = limits.matching.matching()
  let empty : ScalarInputTreeReport = {
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
    return Ok(empty)
  }
  if input.length() > limits.matching.max_input_scalars {
    return Ok({ ..empty, status: BudgetExceeded("input-scalars"), })
  }
  for i, value in input {
    if i >= matching.max_work {
      return Ok({ ..empty, status: BudgetExceeded("work"), work: i, })
    }
    if !is_scalar(value) {
      return Err(InvalidScalar(i, value))
    }
  }
  let report = self.program.parse_symbols(
    start,
    ScalarSymbols(input),
    { matching, max_nodes: limits.max_nodes, max_edges: limits.max_edges, },
    input.length(),
  )
  Ok({
    status: report.status,
    tree: match report.tree {
      None => None
      Some(tree) => Some({ nodes: tree.nodes, root: tree.root, })
    },
    offset: report.offset,
    work: if report.work < input.length() {
      input.length()
    } else {
      report.work
    },
    states: report.states,
    nodes: report.nodes,
    edges: report.edges,
  })
}

///|
pub extend ScalarInputError with Eq::{equal, not_equal}

///|
pub extend ScalarInputError with @debug.Debug::{to_repr}

///|
pub extend ScalarMatchLimits with Eq::{equal, not_equal}

///|
pub extend ScalarMatchLimits with @debug.Debug::{to_repr}

///|
pub extend ScalarInputTree with Eq::{equal, not_equal}

///|
pub extend ScalarInputTree with @debug.Debug::{to_repr}

///|
pub extend ScalarInputTreeLimits with Eq::{equal, not_equal}

///|
pub extend ScalarInputTreeLimits with @debug.Debug::{to_repr}

///|
pub extend ScalarInputTreeReport with Eq::{equal, not_equal}

///|
pub extend ScalarInputTreeReport with @debug.Debug::{to_repr}
