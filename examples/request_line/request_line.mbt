// Grammar adapted from RFC 9112 §3 (request-line) with RFC 3986 path/query
// rules simplified to origin-form targets. Code Components in IETF RFCs are
// under the IETF Trust BSD license; see licenses/rfc9110-BSD and SOURCES.md.
// The surrounding example implementation is MoonABNF MIT.

///|
/// ABNF text for an HTTP/1.1 request line, as caller-supplied grammar bytes.
/// Scope: origin-form targets only (no absolute-form, authority-form or `*`).
pub fn grammar() -> Bytes {
  let lines = [
    "request-line = method SP request-target SP http-version CRLF", "method = 1*tchar",
    "tchar = \"!\" / \"#\" / \"$\" / \"%\" / \"&\" / \"'\" / \"*\" / \"+\" / \"-\" / \".\" / \"^\" / \"_\" / \"`\" / \"|\" / \"~\" / DIGIT / ALPHA",
    "request-target = absolute-path [ \"?\" query ]", "absolute-path = 1*( \"/\" *pchar )",
    "query = *( pchar / \"/\" / \"?\" )", "pchar = unreserved / pct-encoded / sub-delims / \":\" / \"@\"",
    "unreserved = ALPHA / DIGIT / \"-\" / \".\" / \"_\" / \"~\"", "pct-encoded = \"%\" HEXDIG HEXDIG",
    "sub-delims = \"!\" / \"$\" / \"&\" / \"'\" / \"(\" / \")\" / \"*\" / \"+\" / \",\" / \";\" / \"=\"",
    "http-version = %s\"HTTP/\" DIGIT \".\" DIGIT",
  ]
  @utf8.encode(lines.join("\r\n") + "\r\n")
}

///|
/// Fields lifted from a successful `request-line` derivation. Every field is a
/// `[start, end)` byte span of the original input; nothing is copied or decoded.
pub(all) struct RequestLine {
  verb : (Int, Int)
  path : (Int, Int)
  query : (Int, Int)?
  major : Int
  minor : Int
} derive(Eq)

///|
pub extend RequestLine with Eq::{equal, not_equal}

///|
/// Precondition: `tree` is a successful `request-line` tree for `grammar()`.
/// Looks nodes up by rule name instead of relying on incidental node ids.
pub fn extract(tree : @abnf.InputTree, input : Bytes) -> RequestLine {
  let mut meth = (0, 0)
  let mut path = (0, 0)
  let mut query = None
  let mut digits : Array[Int] = []
  for node in tree.nodes {
    match node.kind {
      @abnf.RuleNode("method") => meth = (node.start, node.end)
      @abnf.RuleNode("absolute-path") => path = (node.start, node.end)
      @abnf.RuleNode("query") => query = Some((node.start, node.end))
      @abnf.RuleNode("http-version") =>
        // "HTTP/" DIGIT "." DIGIT: the two digits are fixed offsets from start.
        digits = [
          input[node.start + 5].to_int() - 48,
          input[node.start + 7].to_int() - 48,
        ]
      _ => ()
    }
  }
  { verb: meth, path, query, major: digits[0], minor: digits[1], }
}

///|
/// Parse a complete request line (including its CRLF) into spans.
/// `Err` carries the farthest byte offset reached, or a budget notice.
pub fn parse(
  program : @abnf.Program,
  input : Bytes,
) -> Result[RequestLine, String] {
  let report = program.parse_input("request-line", input)
  match report.status {
    @abnf.Matched => Ok(extract(report.tree.unwrap(), input))
    @abnf.NoMatch => Err("no-match at byte \{report.offset}")
    @abnf.BudgetExceeded(reason) => Err("undecided: budget \{reason}")
    @abnf.UnknownRule => Err("unknown entry rule")
    @abnf.InvalidLimits => Err("invalid limits")
  }
}

///|
fn text(input : Bytes, start : Int, end : Int) -> String {
  let shown = input[start:end].to_owned()
  let s = @utf8.decode_lossy(shown)
  s.replace_all(old="\r", new="\\r").replace_all(old="\n", new="\\n")
}

///|
fn dump_node(
  tree : @abnf.InputTree,
  input : Bytes,
  id : Int,
  depth : Int,
  hidden : Array[String],
  leaf : Array[String],
  out : Array[String],
) -> Unit {
  let node = tree.nodes[id]
  let mut next_depth = depth
  let mut descend = true
  if node.kind is @abnf.RuleNode(name) {
    // Rule names are stored lower-case: ABNF rule names are case-insensitive.
    if hidden.contains(name) {
      return
    }
    let pad = "  ".repeat(depth)
    out.push(
      "\{pad}\{name} [\{node.start},\{node.end}) \"\{text(input, node.start, node.end)}\"",
    )
    next_depth = depth + 1
    descend = !leaf.contains(name)
  }
  if descend {
    for child in node.children {
      dump_node(tree, input, child, next_depth, hidden, leaf, out)
    }
  }
}

///|
/// Indented rule-level view of one derivation, e.g.
/// `request-line [0,24) "GET /a?x=1 HTTP/1.1\r\n"`. Nodes that are only
/// sequence/choice/repeat structure are skipped; per-byte character rules are hidden.
pub fn dump(tree : @abnf.InputTree, input : Bytes) -> String {
  let out : Array[String] = []
  // Per-byte character rules would add one line per byte: they stay visible
  // through their parent's text. sp/crlf/digit are shown but not expanded.
  let hidden = ["tchar", "pchar"]
  let leaf = ["sp", "crlf", "digit"]
  dump_node(tree, input, tree.root, 0, hidden, leaf, out)
  out.join("\n")
}
