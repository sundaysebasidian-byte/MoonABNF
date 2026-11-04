///|
test "unreachable left recursion preserves fast path reports trees and diagnostics" {
  let plain = @moonabnf.compile(b"s = %s\"ab\"\r\n").unwrap()
  let mixed = @moonabnf.compile(
    b"s = %s\"ab\"\r\nunused = unused %s\"x\" / %s\"x\"\r\n",
  ).unwrap()
  for input in [b"ab", b"aX", b"", b"abc"] {
    assert_eq(mixed.recognize("S", input), plain.recognize("s", input))
    assert_eq(mixed.parse_input("S", input), plain.parse_input("s", input))
    assert_eq(
      mixed.diagnose_input("S", input),
      plain.diagnose_input("s", input),
    )
  }
}

///|
test "reachable left recursion after consumed prefix still uses generalized path" {
  let p = @moonabnf.compile(
    b"s = %s\"!\" alias\r\nalias = loop\r\nloop = loop %s\"a\" / %s\"a\"\r\n",
  ).unwrap()
  for input in [b"!a", b"!aa", b"!aaaa"] {
    assert_eq(p.recognize("S", input).status, @moonabnf.Matched)
    assert_eq(p.parse_input("S", input).status, @moonabnf.Matched)
  }
  let d = p.diagnose_input("S", b"!b")
  assert_eq(d.report.status, @moonabnf.NoMatch)
  assert_eq(d.explanation_status, "generalized-explanation-unavailable")
}

///|
test "zero repeat cannot make unreachable left recursion affect the entry" {
  let plain = @moonabnf.compile(b"s = 0unused %s\"ok\"\r\nunused = %s\"x\"\r\n").unwrap()
  let mixed = @moonabnf.compile(
    b"s = 0unused %s\"ok\"\r\nunused = unused / %s\"x\"\r\n",
  ).unwrap()
  for input in [b"ok", b"no"] {
    assert_eq(mixed.recognize("s", input), plain.recognize("s", input))
    assert_eq(mixed.parse_input("s", input), plain.parse_input("s", input))
    assert_eq(
      mixed.diagnose_input("s", input),
      plain.diagnose_input("s", input),
    )
  }
}

///|
test "scalar entry and core rules ignore disconnected left recursive component" {
  let plain = @moonabnf.compile_scalar(b"s = %x100\r\n").unwrap()
  let mixed = @moonabnf.compile_scalar(
    b"s = %x100\r\nunused = unused %x101 / %x101\r\n",
  ).unwrap()
  for input in [[256], [257], []] {
    assert_eq(mixed.recognize("S", input), plain.recognize("s", input))
    assert_eq(mixed.parse_input("S", input), plain.parse_input("s", input))
  }
  let bytes = @moonabnf.compile(b"s = s %s\"a\" / %s\"a\"\r\n").unwrap()
  let digit = bytes.diagnose_input("digit", b"x")
  assert_eq(digit.explanation_status, "complete")
  assert_eq(digit.failure.unwrap().offset, 0)
}

///|
test "entry scope preserves small work budget and ordinary right recursion" {
  let plain = @moonabnf.compile(b"s = %s\"a\" [s] / %s\"b\"\r\n").unwrap()
  let mixed = @moonabnf.compile(
    b"s = %s\"a\" [s] / %s\"b\"\r\nunused = unused / %s\"x\"\r\n",
  ).unwrap()
  for input in [b"a", b"aa", b"aaab", b"aax"] {
    assert_eq(mixed.recognize("s", input), plain.recognize("s", input))
    assert_eq(mixed.parse_input("s", input), plain.parse_input("s", input))
    assert_eq(
      mixed.diagnose_input("s", input),
      plain.diagnose_input("s", input),
    )
  }
  let small = @moonabnf.compile(
    b"s = %s\"ab\"\r\nunused = unused / %s\"x\"\r\n",
  ).unwrap()
  assert_eq(
    small.recognize("s", b"ab", limits={
      ..@moonabnf.default_match_limits(),
      max_work: 10,
    }).status,
    @moonabnf.Matched,
  )
}

///|
test "nullable mutual cycles and right recursive callers retain generalized solving" {
  let p = @moonabnf.compile(
    b"s = %s\"!\" alias / %s\"?\" s\r\nalias = [loop]\r\nloop = alias %s\"a\"\r\n",
  ).unwrap()
  for input in [b"!", b"!a", b"!aaa", b"?!aa", b"??!"] {
    assert_eq(p.recognize("s", input).status, @moonabnf.Matched)
    let tree = p.parse_input("s", input)
    assert_eq(tree.status, @moonabnf.Matched)
    assert_eq(tree.tree.unwrap().extract(input, 0), Some(input))
  }
  assert_eq(p.recognize("s", b"!b").status, @moonabnf.NoMatch)
  assert_eq(
    p.diagnose_input("s", b"!b").explanation_status,
    "generalized-explanation-unavailable",
  )
}

///|
test "core overrides incremental branches and compile bounds remain effective" {
  let source = b"s = %s\"!\" DIGIT\r\ns =/ %s\"ok\"\r\ndigit = digit %s\"a\" / %s\"b\"\r\n"
  let p = @moonabnf.compile(source).unwrap()
  for input in [b"!b", b"!baaa", b"ok"] {
    assert_eq(p.recognize("s", input).status, @moonabnf.Matched)
    assert_eq(p.parse_input("s", input).status, @moonabnf.Matched)
  }
  assert_eq(p.recognize("s", b"!0").status, @moonabnf.NoMatch)
  match @moonabnf.compile(source, max_work=1) {
    Err(d) => assert_eq(d.code, "compile-budget")
    Ok(_) => fail("compile work limit was ignored")
  }
}
