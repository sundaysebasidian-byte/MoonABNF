///|
test "numeric syntax is encoding independent but legacy parser stays byte oriented" {
  for
    grammar in [
      b"s = %x100\r\n", b"s = %x110000\r\n", b"s = %x7FFFFFFF\r\n", b"s = %d2147483647\r\n",
      b"s = %b1111111111111111111111111111111\r\n",
    ] {
    assert_true(@moonabnf.parse_numeric(grammar) is Ok(_))
    assert_true(@moonabnf.parse(grammar) is Err(_))
  }
  for
    grammar in [
      b"s = %x80000000\r\n", b"s = %d2147483648\r\n", b"s = %b10000000000000000000000000000000\r\n",
    ] {
    assert_true(
      @moonabnf.parse_numeric(grammar) is Err(d) && d.code == "number-limit",
    )
  }
  for
    grammar in [b"s = %x110000\r\n", b"s = %xD800\r\n", b"s = %xD800-DFFF\r\n"] {
    assert_true(
      @moonabnf.compile_scalar(grammar) is Err(d) && d.code == "symbol-domain",
    )
  }
  assert_true(@moonabnf.compile(b"s = %x100\r\n") is Err(_))
}

///|
test "scalar numbers ranges offsets and case folding are not UTF8 or UTF16" {
  let p = @moonabnf.compile_scalar(
    b"s = %x1F600.4E2D %x100-102 %x10FFFF\r\na = \"Az\"\r\n",
  ).unwrap()
  let input = [0x1F600, 0x4E2D, 0x101, 0x10FFFF]
  assert_eq(p.recognize("s", input).unwrap().status, @moonabnf.Matched)
  let report = p.parse_input("s", input).unwrap()
  assert_eq(report.status, @moonabnf.Matched)
  assert_eq(report.offset, 4)
  let tree = report.tree.unwrap()
  assert_eq(tree.span(tree.root), Some((0, 4)))
  assert_eq(tree.extract(input, tree.root), Some(input))
  assert_eq(tree.rule_nodes("S"), [0])
  assert_eq(tree.rule_nodes_in("S", tree.root), Some([0]))
  assert_eq(tree.extract([0x1F600], tree.root), None)
  assert_eq(
    p.recognize("s", [0xF0, 0x9F, 0x98, 0x80]).unwrap().status,
    @moonabnf.NoMatch,
  )
  assert_eq(
    p.recognize("s", [0xD83D, 0xDE00]),
    Err(@moonabnf.InvalidScalar(0, 0xD83D)),
  )
  assert_eq(p.recognize("a", [65, 90]).unwrap().status, @moonabnf.Matched)
  assert_eq(p.recognize("a", [97, 122]).unwrap().status, @moonabnf.Matched)
  assert_eq(
    p.recognize("a", [0xFF21, 0xFF3A]).unwrap().status,
    @moonabnf.NoMatch,
  )
}

///|
test "scalar spanning surrogate ranges and invalid input are explicit" {
  let p = @moonabnf.compile_scalar(b"s = %xD7FF-E000\r\nall = %x0-10FFFF\r\n").unwrap()
  for n in [0xD7FF, 0xE000] {
    assert_eq(p.recognize("s", [n]).unwrap().status, @moonabnf.Matched)
  }
  for n in [-1, 0xD800, 0xDBFF, 0xDFFF, 0x110000, 2147483647] {
    assert_eq(p.recognize("all", [n]), Err(@moonabnf.InvalidScalar(0, n)))
    assert_eq(p.parse_input("all", [n]), Err(@moonabnf.InvalidScalar(0, n)))
  }
  for n in [0, 0xD7FF, 0xE000, 0x10FFFF] {
    assert_eq(p.recognize("all", [n]).unwrap().status, @moonabnf.Matched)
  }
}

///|
test "finite prose binding owns nested input and uses exact names" {
  let word = [65, 66]
  let words = [word]
  let bindings : Array[@moonabnf.ProseBinding] = [
    { name: "exact name", predicate: @moonabnf.Words(words), },
  ]
  let p = @moonabnf.compile_with_prose(b"s = <exact name>\r\n", bindings).unwrap()
  word[0] = 90
  words.push([67])
  bindings[0] = { name: "exact name", predicate: @moonabnf.Words([]), }
  assert_eq(p.recognize("s", b"AB").status, @moonabnf.Matched)
  assert_eq(p.recognize("s", b"ZB").status, @moonabnf.NoMatch)
  assert_eq(p.recognize("s", b"C").status, @moonabnf.NoMatch)
  assert_eq(p.recognize("s", b"ab").status, @moonabnf.NoMatch)
  assert_eq(p.parse_input("s", b"AB").status, @moonabnf.Matched)
  assert_true(
    @moonabnf.compile_with_prose(b"s = <Exact name>\r\n", bindings) is Err(d) &&
    d.code == "prose-unbound",
  )
  assert_true(
    @moonabnf.compile(b"s = <exact name>\r\n") is Err(d) &&
    d.code == "prose-unsupported",
  )
}

///|
test "prose contracts include empty name unused duplicates and domain errors" {
  let epsilon : @moonabnf.ProseBinding = {
    name: "",
    predicate: @moonabnf.Words([[]]),
  }
  let p = @moonabnf.compile_with_prose(b"s = <>\r\n", [epsilon]).unwrap()
  assert_eq(p.recognize("s", b"").status, @moonabnf.Matched)
  assert_true(
    @moonabnf.compile_with_prose(b"s = \"a\"\r\n", [epsilon, epsilon]) is Err(d) &&
    d.code == "duplicate-prose-binding",
  )
  assert_true(
    @moonabnf.compile_with_prose(b"s = <>\r\n", []) is Err(d) &&
    d.code == "prose-unbound",
  )
  for name in ["bad>", "bad\n", "中文"] {
    assert_true(
      @moonabnf.compile_with_prose(b"s = \"a\"\r\n", [
        { name, predicate: @moonabnf.Words([]), },
      ])
      is Err(d) &&
      d.code == "invalid-prose-name",
    )
  }
  // Valid unused bindings are accepted, invalid unused bindings are not hidden.
  assert_true(
    @moonabnf.compile_with_prose(b"s = \"a\"\r\n", [epsilon]) is Ok(_),
  )
  assert_true(
    @moonabnf.compile_with_prose(b"s = \"a\"\r\n", [
      { name: "unused", predicate: @moonabnf.Words([[256]]), },
    ])
    is Err(d) &&
    d.code == "symbol-domain",
  )
  assert_true(
    @moonabnf.compile_scalar(b"s = \"a\"\r\n", bindings=[
      { name: "unused", predicate: @moonabnf.SymbolRange(2, 1), },
    ])
    is Err(d) &&
    d.code == "symbol-domain",
  )
}

///|
test "nullable prose and empty language retain fixed point and tree semantics" {
  let bindings : Array[@moonabnf.ProseBinding] = [
    { name: "epsilon", predicate: @moonabnf.Words([[]]), },
    { name: "empty", predicate: @moonabnf.Words([]), },
    { name: "token", predicate: @moonabnf.Words([[0x4E2D], [0x1F600]]), },
  ]
  let p = @moonabnf.compile_scalar(
    b"s = s <token> / 2<epsilon>\r\ndead = 1*<empty>\r\n",
    bindings~,
  ).unwrap()
  for input in [[], [0x4E2D], [0x1F600, 0x4E2D], [0x4E2D, 0x4E2D, 0x1F600]] {
    assert_eq(p.recognize("s", input).unwrap().status, @moonabnf.Matched)
    let r = p.parse_input("s", input).unwrap()
    assert_eq(r.status, @moonabnf.Matched)
    let tree = r.tree.unwrap()
    assert_true(tree.rule_nodes_in("s", tree.root) is Some(_))
    assert_eq(tree.extract(input, tree.root), Some(input))
    assert_eq(p.recognize("dead", input).unwrap().status, @moonabnf.NoMatch)
    assert_eq(p.parse_input("dead", input).unwrap().tree, None)
  }
  assert_eq(p.recognize("s", [65]).unwrap().status, @moonabnf.NoMatch)
  // Positive repetitions of empty prose must not become epsilon.
  let bytep = @moonabnf.compile_with_prose(
    b"s = 1*<empty> / \"a\"\r\nt = *<empty>\r\n",
    [{ name: "empty", predicate: @moonabnf.Words([]), }],
  ).unwrap()
  assert_eq(bytep.recognize("s", b"").status, @moonabnf.NoMatch)
  assert_eq(bytep.recognize("s", b"a").status, @moonabnf.Matched)
  assert_eq(bytep.recognize("t", b"").status, @moonabnf.Matched)
}

///|
test "prose range is one symbol and grammar source offsets are preserved" {
  let p = @moonabnf.compile_scalar(b"s = <Han>\r\n", bindings=[
    { name: "Han", predicate: @moonabnf.SymbolRange(0x4E00, 0x9FFF), },
  ]).unwrap()
  assert_eq(p.recognize("s", []).unwrap().status, @moonabnf.NoMatch)
  assert_eq(
    p.recognize("s", [0x4E2D, 0x6587]).unwrap().status,
    @moonabnf.NoMatch,
  )
  let r = p.parse_input("s", [0x4E2D]).unwrap()
  assert_eq(r.status, @moonabnf.Matched)
  let tree = r.tree.unwrap()
  assert_true(
    tree.nodes.any(n => {
      n.kind == @moonabnf.RangeNode &&
      n.source_offset == 4 &&
      n.start == 0 &&
      n.end == 1
    }),
  )
}

///|
test "new scalar and prose budgets cannot become false matches" {
  let p = @moonabnf.compile_scalar(b"s = *%x0-10FFFF\r\n").unwrap()
  let input = [65, 66, 67]
  let matching = { ..@moonabnf.default_scalar_match_limits(), max_work: 2, }
  let r = p.recognize("s", input, limits=matching).unwrap()
  assert_eq(r.status, @moonabnf.BudgetExceeded("work"))
  assert_eq(r.work, 2)
  let tree_limits = {
    ..@moonabnf.default_scalar_input_tree_limits(),
    matching,
  }
  let t = p.parse_input("s", input, limits=tree_limits).unwrap()
  assert_eq(t.status, @moonabnf.BudgetExceeded("work"))
  assert_eq(t.tree, None)
  assert_eq(
    p
    .recognize("s", input, limits={ ..matching, max_input_scalars: 2, })
    .unwrap().status,
    @moonabnf.BudgetExceeded("input-scalars"),
  )
  assert_eq(
    p.recognize("s", input, limits={ ..matching, max_work: 0, }).unwrap().status,
    @moonabnf.InvalidLimits,
  )
  assert_eq(
    p.parse_input("s", input, limits={ ..tree_limits, max_nodes: 0, }).unwrap().status,
    @moonabnf.InvalidLimits,
  )
  assert_eq(
    p
    .parse_input("s", input, limits={
      ..@moonabnf.default_scalar_input_tree_limits(),
      max_nodes: 1,
    })
    .unwrap().tree,
    None,
  )
  assert_eq(
    p.recognize("missing", input).unwrap().status,
    @moonabnf.UnknownRule,
  )
  let binding : @moonabnf.ProseBinding = {
    name: "words",
    predicate: @moonabnf.Words([[65, 66, 67], [68, 69, 70]]),
  }
  assert_true(
    @moonabnf.compile_with_prose(b"s = <words>\r\n", [binding], max_work=3)
    is Err(d) &&
    d.code == "compile-budget",
  )
  assert_true(
    @moonabnf.compile_with_prose(b"s = <words>\r\n", [binding], limits={
      ..@moonabnf.default_parse_limits(),
      max_nodes: 5,
    })
    is Err(d) &&
    d.code == "compile-budget",
  )
}

///|
test "scalar bound recursive language matches an independent finite oracle" {
  let piece = [0x4E2D]
  let bindings : Array[@moonabnf.ProseBinding] = [
    { name: "piece", predicate: @moonabnf.Words([piece, [0x1F600, 0x4E2D]]), },
    { name: "start", predicate: @moonabnf.Words([[]]), },
  ]
  let p = @moonabnf.compile_scalar(b"s = s <piece> / <start>\r\n", bindings~).unwrap()
  piece[0] = 65
  let mut width = 1
  for size = 0; size <= 4; size = size + 1 {
    for v = 0; v < width; v = v + 1 {
      let mut n = v
      let input : Array[Int32] = []
      for i = 0; i < size; i = i + 1 {
        input.push([0x4E2D, 0x1F600, 65][n % 3])
        n = n / 3
      }
      // Independent scanner for (U+4E2D | U+1F600 U+4E2D)*.
      let mut at = 0
      let mut valid = true
      while at < input.length() {
        if input[at] == 0x4E2D {
          at = at + 1
        } else if input[at] == 0x1F600 &&
          at + 1 < input.length() &&
          input[at + 1] == 0x4E2D {
          at = at + 2
        } else {
          valid = false
          break
        }
      }
      let expected = if valid { @moonabnf.Matched } else { @moonabnf.NoMatch }
      assert_eq(p.recognize("s", input).unwrap().status, expected)
      let r = p.parse_input("s", input).unwrap()
      assert_eq(r.status, expected)
      if valid {
        let tree = r.tree.unwrap()
        assert_true(tree.rule_nodes_in("s", tree.root) is Some(_))
        assert_eq(tree.extract(input, tree.root), Some(input))
      } else {
        assert_eq(r.tree, None)
      }
    }
    width = width * 3
  }
}

///|
test "binding alternatives preserve endpoints and budget failures are reusable" {
  let p = @moonabnf.compile_scalar(b"s = <prefix> %x1F600\r\n", bindings=[
    {
      name: "prefix",
      predicate: @moonabnf.Words([[0x4E2D], [0x4E2D, 0x1F600]]),
    },
  ]).unwrap()
  let input = [0x4E2D, 0x1F600, 0x1F600]
  let full = p.parse_input("s", input).unwrap()
  assert_eq(full.status, @moonabnf.Matched)
  let limits = {
    ..@moonabnf.default_scalar_input_tree_limits(),
    max_nodes: full.nodes - 1,
  }
  let limited = p.parse_input("s", input, limits~).unwrap()
  assert_true(limited.status is @moonabnf.BudgetExceeded(_))
  assert_eq(limited.tree, None)
  assert_eq(p.parse_input("s", input).unwrap(), full)
  let valid_work = p.recognize("s", input).unwrap().work
  assert_eq(
    p
    .recognize("s", input, limits={
      ..@moonabnf.default_scalar_match_limits(),
      max_work: valid_work,
    })
    .unwrap().status,
    @moonabnf.Matched,
  )
  assert_true(
    p
    .recognize("s", input, limits={
      ..@moonabnf.default_scalar_match_limits(),
      max_work: valid_work - 1,
    })
    .unwrap().status
    is @moonabnf.BudgetExceeded(_),
  )
}
