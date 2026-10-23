///|
/// Keeps the README snippets compiling and correct.
test "README: validate a field" {
  match @moonabnf.compile(b"field = %i\"Trace\" \":\" SP 1*8HEXDIG CRLF\r\n") {
    Err(d) => fail("\{d.code} at line \{d.line}, column \{d.column}")
    Ok(program) => {
      let r = program.recognize("field", b"TRACE: aF12\r\n")
      assert_true(r.status is @moonabnf.Matched)
    }
  }
}

///|
test "README: grammar errors carry a code and position" {
  match @moonabnf.compile(b"a = b\r\n") {
    Err(d) => {
      assert_eq(d.code, "undefined-rule")
      assert_true(d.line >= 1 && d.column >= 1)
    }
    Ok(_) => fail("undefined rule must be rejected")
  }
}

///|
test "README: extract field bytes" {
  let program = @moonabnf.compile(
    b"record = key \":\" value\r\nkey = 1*ALPHA\r\nvalue = 1*DIGIT\r\n",
  ).unwrap()
  let input = b"Age:42"
  let report = program.parse_input("record", input)
  match report.status {
    @moonabnf.Matched => {
      let tree = report.tree.unwrap()
      let ids = tree.rule_nodes_in("value", tree.root).unwrap()
      assert_eq(tree.extract(input, ids[0]), Some(b"42"))
    }
    _ => fail("expected a complete match")
  }
}
