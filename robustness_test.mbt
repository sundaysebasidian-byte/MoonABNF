///|
// Reproducible robustness corpus, not a grammar-validity oracle. UInt arithmetic
// is modulo 2^32; use upper bits for bounded draws, with no platform RNG.
struct RobustRng {
  mut state : UInt32
}

///|
fn RobustRng::draw(self : RobustRng, bound : Int32) -> Int32 {
  self.state = self.state * 1664525U + 1013904223U
  ((self.state >> 8) % bound.reinterpret_as_uint()).reinterpret_as_int()
}

///|
fn check_diagnostic(source : Bytes, d : @moonabnf.Diagnostic) -> Unit raise {
  assert_true(
    d.offset >= 0 && d.offset <= source.length(),
    msg="source=\{source}, offset=\{d.offset}",
  )
  let mut line = 1
  let mut column = 1
  for i = 0; i < d.offset; i = i + 1 {
    if source[i] == b'\n' {
      line = line + 1
      column = 1
    } else {
      column = column + 1
    }
  }
  assert_true(
    (d.line, d.column) == (line, column),
    msg="source=\{source}, offset=\{d.offset}",
  )
  assert_false(d.code.is_empty())
}

///|
fn mutated_source(rng : RobustRng, seed : Bytes, mode : Int32) -> Bytes {
  let at = rng.draw(seed.length() + 1)
  let bytes : Array[Byte] = []
  if mode == 0 {
    return seed[0:at].to_owned()
  }
  if mode == 7 {
    let size = rng.draw(193)
    for i = 0; i < size; i = i + 1 {
      bytes.push(rng.draw(256).to_byte())
    }
    return Bytes::from_array(bytes)
  }
  for i = 0; i < seed.length(); i = i + 1 {
    if i == at && mode == 1 {
      bytes.push(rng.draw(256).to_byte())
    }
    if i == at && mode == 2 {
      continue
    }
    bytes.push(
      if i == at && mode == 3 {
        rng.draw(256).to_byte()
      } else {
        seed[i]
      },
    )
  }
  if mode == 4 {
    for i = 0; i < 16; i = i + 1 {
      bytes.push(rng.draw(256).to_byte())
    }
  }
  if mode == 5 {
    bytes.push(b'\xFF')
  }
  // Mode 6 intentionally preserves the seed as a valid-input control.
  Bytes::from_array(bytes)
}

///|
test "robustness seed20261022 mutated byte grammars return bounded diagnostics" {
  let fingerprint : RobustRng = { state: 20261022U, }
  for expected in [1908340581U, 1116782976U, 811714271U, 308930226U] {
    ignore(fingerprint.draw(1))
    assert_eq(fingerprint.state, expected)
  }
  let rng : RobustRng = { state: 20261022U, }
  let seeds = [
    b"s = (%s\"a\" / %s\"ab\") *2[\"b\"]\r\n", b"s = %x00-FF / %d48.49\r\n", b"s = \"a\" [s] / \"\"\r\n",
    b"s = 1000000\"\"\r\n", b"s = (\r\n \"a\" / ; folded\r\n \"b\")\r\n", b"s = DIGIT\r\ns =/ %s\"Z\"\r\n",
    b"s = missing\r\n", b"s = s / \"a\"\r\n",
  ]
  let limits : @moonabnf.ParseLimits = {
    max_bytes: 256,
    max_rules: 8,
    max_nodes: 64,
    max_depth: 8,
  }
  let mut accepted = 0
  let mut rejected = 0
  let mut compiled = 0
  let mut largest = 0
  for case = 0; case < 1024; case = case + 1 {
    let source = mutated_source(rng, seeds[rng.draw(seeds.length())], case % 8)
    assert_true(source.length() <= limits.max_bytes)
    if source.length() > largest {
      largest = source.length()
    }
    match @moonabnf.parse(source, limits~) {
      Err(d) => {
        check_diagnostic(source, d)
        rejected = rejected + 1
      }
      Ok(_) => accepted = accepted + 1
    }
    match @moonabnf.compile(source, limits~, max_work=4096) {
      Err(d) => check_diagnostic(source, d)
      Ok(_) => compiled = compiled + 1
    }
    // The same arbitrary source must reject before parsing when its byte
    // allowance is one byte short; empty sources have no shorter allowance.
    if source.length() > 0 {
      assert_true(
        @moonabnf.parse(source, limits={
          ..limits,
          max_bytes: source.length() - 1,
        })
        is Err(d) &&
        d.code == "parse-budget" &&
        d.offset == 0,
      )
    }
  }
  println(
    "robustness seed=20261022 cases=1024 max-bytes=\{largest} parsed=\{accepted} rejected=\{rejected} compiled=\{compiled}",
  )
  assert_eq(accepted + rejected, 1024)
  assert_true(accepted > 0 && rejected > 0 && compiled > 0)
  assert_true(
    @moonabnf.compile(b"s = \"a\"\r\n", max_work=1) is Err(d) &&
    d.code == "compile-budget",
  )
}

///|
test "robustness seed20261023 nesting and random match budgets terminate safely" {
  let rng : RobustRng = { state: 20261023U, }
  let parse_limits = @moonabnf.default_parse_limits()
  for case = 0; case < 64; case = case + 1 {
    let depth = 16 + rng.draw(80)
    let bytes = b"s = ".to_array()
    for i = 0; i < depth; i = i + 1 {
      bytes.push(b'(')
    }
    for byte in b"\"a\"" {
      bytes.push(byte)
    }
    for i = 0; i < depth; i = i + 1 {
      bytes.push(b')')
    }
    bytes.push(b'\r')
    bytes.push(b'\n')
    assert_true(
      @moonabnf.parse(Bytes::from_array(bytes), limits={
        ..parse_limits,
        max_depth: 1 + rng.draw(8),
      })
      is Err(d) &&
      d.code == "parse-budget",
    )
  }
  let mut exhausted = 0
  let mut decided = 0
  let mut matched = 0
  for
    source in [
      b"s = 1000000\"\"\r\n", b"s = \"a\" [s] / \"\"\r\n", b"s = *(\"a\" / \"ab\") \"c\"\r\n",
      b"s = 4*8[\"a\"] *2\"b\"\r\n",
    ] {
    let p = @moonabnf.compile(source).unwrap()
    let stable = p.recognize("s", b"a")
    assert_false(stable.status is @moonabnf.BudgetExceeded(_))
    for case = 0; case < 64; case = case + 1 {
      let input = Bytes::make(rng.draw(49), b'a')
      let limits : @moonabnf.InputTreeLimits = {
        matching: {
          max_input_bytes: rng.draw(33),
          max_work: 8 + rng.draw(121),
          max_states: 1 + rng.draw(32),
          max_depth: 1 + rng.draw(8),
        },
        max_nodes: 1 + rng.draw(32),
        max_edges: 1 + rng.draw(64),
      }
      let r = p.parse_input("s", input, limits~)
      assert_true(r.work <= limits.matching.max_work)
      assert_true(r.states <= limits.matching.max_states)
      assert_true(r.nodes <= limits.max_nodes && r.edges <= limits.max_edges)
      assert_true(r.offset >= 0 && r.offset <= input.length())
      match r.status {
        @moonabnf.BudgetExceeded(_) => {
          exhausted = exhausted + 1
          assert_eq(r.tree, None)
        }
        @moonabnf.Matched => {
          matched = matched + 1
          decided = decided + 1
          let tree = r.tree.unwrap()
          assert_eq(tree.extract(input, tree.root), Some(input))
          assert_true(tree.rule_nodes_in("s", tree.root) is Some(_))
        }
        @moonabnf.NoMatch => {
          decided = decided + 1
          assert_eq(r.tree, None)
        }
        _ => fail("valid fixture and limits produced a configuration error")
      }
      if input.length() > limits.matching.max_input_bytes {
        assert_eq(r.status, @moonabnf.BudgetExceeded("input-bytes"))
        assert_eq((r.work, r.states, r.nodes, r.edges), (0, 0, 0, 0))
      }
    }
    // A failed call must not poison a reused Program.
    assert_eq(p.recognize("s", b"a"), stable)
  }
  assert_eq(exhausted + decided, 256)
  assert_true(exhausted > 0 && decided > 0)
  println(
    "robustness seed=20261023 nesting=64 budgets=256 exhausted=\{exhausted} decided=\{decided} matched=\{matched}",
  )
}
