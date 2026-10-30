///|
test "independent mixed epsilon range left recursion scalar oracle" {
  let p = @moonabnf.compile_scalar(b"s = s <u> / <nil>\r\n", bindings=[
    { name: "u", predicate: @moonabnf.SymbolRange(0x100, 0x102), },
    { name: "nil", predicate: @moonabnf.Words([[]]), },
  ]).unwrap()
  for n = 0; n < 7; n = n + 1 {
    let xs : Array[Int32] = []
    for _i = 0; _i < n; _i = _i + 1 {
      xs.push(0x101)
    }
    assert_eq(p.recognize("s", xs).unwrap().status, @moonabnf.Matched)
    let tr = p.parse_input("s", xs).unwrap()
    assert_eq(tr.status, @moonabnf.Matched)
    assert_eq(tr.tree.unwrap().extract(xs, tr.tree.unwrap().root), Some(xs))
    xs.push(0x103)
    assert_eq(p.recognize("s", xs).unwrap().status, @moonabnf.NoMatch)
  }
}

///|
test "independent zero work after scalar validation stays indeterminate" {
  let p = @moonabnf.compile_scalar(b"s = %x100\r\n").unwrap()
  let lim = { ..@moonabnf.default_scalar_match_limits(), max_work: 1, }
  assert_true(
    p.recognize("s", [256], limits=lim).unwrap().status
    is @moonabnf.BudgetExceeded(_),
  )
  assert_true(
    p
    .parse_input("s", [256], limits={
      ..@moonabnf.default_scalar_input_tree_limits(),
      matching: lim,
    })
    .unwrap().status
    is @moonabnf.BudgetExceeded(_),
  )
}

///|
test "independent quoted ascii not Unicode folding and max terminal syntax" {
  assert_true(@moonabnf.parse_numeric(b"s = %d2147483647.256\r\n") is Ok(_))
  assert_true(@moonabnf.compile_scalar(b"s = %d2147483647.256\r\n") is Err(_))
  let p = @moonabnf.compile_scalar(b"s = %i\"k\"\r\n").unwrap()
  assert_eq(p.recognize("s", [0x212A]).unwrap().status, @moonabnf.NoMatch)
  assert_eq(p.recognize("s", [75]).unwrap().status, @moonabnf.Matched)
}
