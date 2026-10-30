///|
/// Source positions are zero-based byte offsets; line/column are one-based.
pub(all) struct Diagnostic {
  code : String
  message : String
  offset : Int32
  line : Int32
  column : Int32
} derive(Eq, Debug)

///|
/// Public AST. Repeat maximum None means unbounded; positions refer to source.
pub(all) enum Expr {
  Ref(String, Int32)
  Literal(Bytes, Bool, Int32)
  Range(Int32, Int32, Int32)
  Sequence(Array[Expr], Int32)
  Choice(Array[Expr], Int32)
  Repeat(Int32, Int32?, Expr, Int32)
  Prose(String, Int32)
} derive(Eq, Debug)

///|
pub(all) struct Rule {
  name : String
  expression : Expr
  incremental : Bool
  offset : Int32
} derive(Eq, Debug)

///|
pub(all) struct Grammar {
  rules : Array[Rule]
} derive(Eq, Debug)

///|
/// Hard implementation ceilings prevent caller budgets from risking the stack.
pub(all) struct ParseLimits {
  max_bytes : Int32
  max_rules : Int32
  max_nodes : Int32
  max_depth : Int32
} derive(Eq, Debug)

///|
pub fn default_parse_limits() -> ParseLimits {
  { max_bytes: 65536, max_rules: 256, max_nodes: 4096, max_depth: 64, }
}

///|
fn diagnostic(
  source : Bytes,
  offset : Int32,
  code : String,
  message : String,
) -> Diagnostic {
  let mut line = 1
  let mut column = 1
  for i = 0; i < offset && i < source.length(); i = i + 1 {
    if source[i] == b'\n' {
      line = line + 1
      column = 1
    } else {
      column = column + 1
    }
  }
  { code, message, offset, line, column, }
}

///|
fn Expr::offset(self : Expr) -> Int32 {
  match self {
    Ref(_, p)
    | Literal(_, _, p)
    | Range(_, _, p)
    | Sequence(_, p)
    | Choice(_, p)
    | Repeat(_, _, _, p)
    | Prose(_, p) => p
  }
}

///|
fn ascii_lower(c : Int32) -> Int32 {
  if c >= 65 && c <= 90 {
    c + 32
  } else {
    c
  }
}

///|
fn alpha(c : Int32) -> Bool {
  let v = ascii_lower(c)
  v >= 97 && v <= 122
}

///|
fn digit(c : Int32) -> Bool {
  c >= 48 && c <= 57
}

///|
fn lower_name(s : String) -> String {
  s.to_lower()
}

///|
pub extend Diagnostic with Eq::{equal, not_equal}

///|
pub extend Diagnostic with @debug.Debug::{to_repr}

///|
pub extend Expr with Eq::{equal, not_equal}

///|
pub extend Expr with @debug.Debug::{to_repr}

///|
pub extend Rule with Eq::{equal, not_equal}

///|
pub extend Rule with @debug.Debug::{to_repr}

///|
pub extend Grammar with Eq::{equal, not_equal}

///|
pub extend Grammar with @debug.Debug::{to_repr}

///|
pub extend ParseLimits with Eq::{equal, not_equal}

///|
pub extend ParseLimits with @debug.Debug::{to_repr}
