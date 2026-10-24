// Grammar Code Component derived from IETF RFC 9110 §§8.8.3 and 5.5.
// Copyright (c) 2022 IETF Trust and the persons identified as authors of the code.
// All rights reserved. Grammar is subject to licenses/rfc9110-BSD;
// the surrounding example implementation is MoonABNF MIT.

///|
pub fn grammar() -> Bytes {
  b"entity-tag = [weak] opaque-tag\r\nweak = %s\"W/\"\r\nopaque-tag = DQUOTE *etagc DQUOTE\r\netagc = %x21 / %x23-7E / obs-text\r\nobs-text = %x80-FF\r\n"
}

///|
/// Application adapter metadata; value bytes remain opaque, without unescaping.
pub(all) struct TagSpan {
  weak : Bool
  value_start : Int
  value_end : Int
} derive(Eq)

///|
pub extend TagSpan with Eq::{equal, not_equal}

///|
/// Precondition: a successful entity-tag tree from this example's grammar().
/// This example extracts named rules,
/// without depending on incidental sequence/choice node IDs.
pub fn extract(tree : @abnf.InputTree) -> TagSpan {
  let mut weak = false
  let mut value_start = 0
  let mut value_end = 0
  for node in tree.nodes {
    match node.kind {
      @abnf.RuleNode("weak") => weak = true
      @abnf.RuleNode("opaque-tag") => {
        value_start = node.start + 1
        value_end = node.end - 1
      }
      _ => ()
    }
  }
  { weak, value_start, value_end, }
}
