///|
test "composed prose Unicode identifier and scalar span" {
  let name = @moonabnf.Concat([
    @moonabnf.SymbolRange(0x4E00, 0x4E02),
    @moonabnf.Repetition(
      0,
      None,
      @moonabnf.Alternative([
        @moonabnf.SymbolRange(48, 57),
        @moonabnf.SymbolRange(0x4E00, 0x4E02),
      ]),
    ),
  ])
  let p = @moonabnf.compile_scalar(b"s = <name>\r\n", bindings=[
    { name: "name", predicate: name, },
  ]).unwrap()
  for xs in [[0x4E00], [0x4E01, 48, 49, 0x4E02]] {
    assert_eq(p.recognize("s", xs).unwrap().status, @moonabnf.Matched)
    let t = p.parse_input("s", xs).unwrap().tree.unwrap()
    assert_eq(t.extract(xs, t.root), Some(xs))
  }
  for xs in [[], [48], [0x4E03], [0x4E00, 65]] {
    assert_eq(p.recognize("s", xs).unwrap().status, @moonabnf.NoMatch)
  }
}

///|
test "composed prose epsilon empty language and left recursion" {
  let bindings : Array[@moonabnf.ProseBinding] = [
    { name: "nil", predicate: @moonabnf.Concat([]), },
    { name: "dead", predicate: @moonabnf.Alternative([]), },
    {
      name: "a",
      predicate: @moonabnf.Repetition(1, None, @moonabnf.Words([[97]])),
    },
  ]
  let p = @moonabnf.compile_with_prose(
    b"s = s <a> / <nil>\r\nd = <dead>\r\nz = 0<dead>\r\n", bindings,
  ).unwrap()
  for input in [b"", b"a", b"aaa"] {
    assert_eq(p.recognize("s", input).status, @moonabnf.Matched)
    assert_eq(p.parse_input("s", input).status, @moonabnf.Matched)
  }
  assert_eq(p.recognize("s", b"b").status, @moonabnf.NoMatch)
  assert_eq(p.recognize("d", b"").status, @moonabnf.NoMatch)
  assert_eq(p.recognize("z", b"").status, @moonabnf.Matched)
  let q = @moonabnf.compile_with_prose(b"s = <e>\r\n", [
    {
      name: "e",
      predicate: @moonabnf.Repetition(0, None, @moonabnf.Concat([])),
    },
  ]).unwrap()
  assert_eq(q.recognize("s", b"").status, @moonabnf.Matched)
  assert_eq(q.parse_input("s", b"").status, @moonabnf.Matched)
}

///|
test "composed prose rejects cycles bounds and domain errors" {
  let children : Array[@moonabnf.ProsePredicate] = []
  let cycle = @moonabnf.Concat(children)
  children.push(cycle)
  assert_true(
    @moonabnf.compile_with_prose(b"s = <p>\r\n", [
      { name: "p", predicate: cycle, },
    ])
    is Err(d) &&
    d.code == "compile-budget",
  )
  for
    (lo, hi) in [
      (-1, None),
      (2, Some(1)),
      (0, Some(-1)),
      (1000001, None),
      (0, Some(2147483647)),
    ] {
    assert_true(
      @moonabnf.compile_with_prose(b"s = <p>\r\n", [
        {
          name: "p",
          predicate: @moonabnf.Repetition(lo, hi, @moonabnf.Words([[97]])),
        },
      ])
      is Err(d) &&
      d.code == "prose-repeat",
    )
  }
  for
    pred in [
      @moonabnf.Concat([@moonabnf.SymbolRange(-1, 1)]),
      @moonabnf.Alternative([@moonabnf.SymbolRange(0x110000, 0x110000)]),
    ] {
    assert_true(
      @moonabnf.compile_scalar(b"s = <p>\r\n", bindings=[
        { name: "p", predicate: pred, },
      ])
      is Err(d) &&
      d.code == "symbol-domain",
    )
  }
}

///|
test "composed prose owns snapshot and compile work bounded" {
  let parts = [@moonabnf.Words([[97]])]
  let binding : @moonabnf.ProseBinding = {
    name: "p",
    predicate: @moonabnf.Concat(parts),
  }
  let p = @moonabnf.compile_with_prose(b"s = <p>\r\n", [binding]).unwrap()
  parts.clear()
  assert_eq(p.recognize("s", b"a").status, @moonabnf.Matched)
  assert_eq(p.recognize("s", b"").status, @moonabnf.NoMatch)
  assert_true(
    @moonabnf.compile_with_prose(b"s = <p>\r\n", [binding], max_work=1)
    is Err(d) &&
    d.code == "compile-budget",
  )
}
