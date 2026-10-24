///|
/// Demonstrates a caller-supplied grammar and explicit result handling.
fn describe(report : @abnf.InputTreeReport, input : Bytes) -> Unit raise {
  match report.status {
    @abnf.Matched => {
      // The public contract guarantees a tree only for a complete match.
      let tree = report.tree.unwrap()
      let mut found = false
      for node in tree.nodes {
        if node.kind is @abnf.RuleNode("value") {
          let value = input[node.start:node.end].to_owned()
          assert_eq(value, b"42")
          println("matched: value bytes=[\{node.start},\{node.end})")
          found = true
        }
      }
      assert_true(found)
    }
    @abnf.NoMatch => {
      assert_true(report.tree is None)
      println("no-match: byte=\{report.offset}")
    }
    @abnf.BudgetExceeded(reason) => {
      assert_true(report.tree is None)
      println("indeterminate: \{reason}")
    }
    @abnf.UnknownRule => fail("caller selected an unknown entry rule")
    @abnf.InvalidLimits => fail("caller supplied invalid limits")
  }
}

///|
fn main raise {
  let grammar = b"record = key \":\" value\r\nkey = 1*ALPHA\r\nvalue = 1*DIGIT\r\n"
  let program = match @abnf.compile(grammar) {
    Ok(program) => program
    Err(d) => fail("grammar error \{d.code} at byte \{d.offset}")
  }
  describe(program.parse_input("record", b"Age:42"), b"Age:42")
  describe(program.parse_input("record", b"Age:"), b"Age:")
  describe(
    program.parse_input("record", b"Age:42", limits={
      ..@abnf.default_input_tree_limits(),
      max_nodes: 1,
    }),
    b"Age:42",
  )
}
