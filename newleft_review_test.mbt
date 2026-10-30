///|
// Independent review: finite-language differential oracle plus AST-only replay.
// The reference grammars do not contain left recursion.
test "review left recursive language agrees with equivalent nonrecursive languages" {
  for
    (recursive, reference) in [
      (b"s = s %s\"a\" / %s\"b\"\r\n", b"s = %s\"b\" *%s\"a\"\r\n"),
      (
        b"s = t %s\"a\" / %s\"b\"\r\nt = s %s\"c\" / %s\"d\"\r\n", b"s = (%s\"b\" / %s\"da\") *%s\"ca\"\r\n",
      ),
      (b"s = [s] %s\"a\" / %s\"\"\r\n", b"s = *%s\"a\"\r\n"),
      (b"s = 2*3s / %s\"a\"\r\n", b"s = 1*%s\"a\"\r\n"),
    ] {
    let p = @moonabnf.compile(recursive).unwrap()
    let refp = @moonabnf.compile(reference).unwrap()
    let ast = @moonabnf.parse(recursive).unwrap()
    let rules : Map[String, @moonabnf.Expr] = Map([])
    for rule in ast.rules {
      rules[rule.name] = rule.expression
    }
    let mut width = 1
    for size = 0; size <= 4; size = size + 1 {
      for value = 0; value < width; value = value + 1 {
        let mut n = value
        let bytes : Array[Byte] = []
        for i = 0; i < size; i = i + 1 {
          bytes.push([b'a', b'b', b'c', b'd'][n % 4])
          n = n / 4
        }
        let input = Bytes::from_array(bytes)
        let expected = refp.recognize("s", input).status
        assert_eq(p.recognize("s", input).status, expected)
        let result = p.parse_input("s", input)
        assert_eq(result.status, expected)
        if expected == @moonabnf.Matched {
          let tree = tree_of(p, "s", input)
          replay(tree, tree.nodes[0].children[0], rules["s"], rules, input)
        } else {
          assert_true(result.tree is None)
        }
      }
      width = width * 4
    }
  }
}

///|
test "review nullable left recursion parses balanced parentheses with replay" {
  let grammar = b"s = s s / %s\"(\" s %s\")\" / %s\"\"\r\n"
  let p = match @moonabnf.compile(grammar) {
    Ok(p) => p
    Err(d) => fail("compile: \{d.code} \{d.message}")
  }
  let rules : Map[String, @moonabnf.Expr] = Map([])
  for rule in @moonabnf.parse(grammar).unwrap().rules {
    rules[rule.name] = rule.expression
  }
  let mut width = 1
  for size = 0; size <= 6; size = size + 1 {
    for value = 0; value < width; value = value + 1 {
      let bytes : Array[Byte] = []
      let mut n = value
      let mut balance = 0
      let mut valid = true
      for i = 0; i < size; i = i + 1 {
        let open = n % 2 == 0
        n = n / 2
        bytes.push(if open { b'(' } else { b')' })
        balance = balance + (if open { 1 } else { -1 })
        if balance < 0 {
          valid = false
        }
      }
      valid = valid && balance == 0
      let input = Bytes::from_array(bytes)
      let expected = if valid { @moonabnf.Matched } else { @moonabnf.NoMatch }
      assert_eq(p.recognize("s", input).status, expected)
      let r = p.parse_input("s", input)
      assert_eq(r.status, expected)
      if valid {
        let tree = tree_of(p, "s", input)
        replay(tree, tree.nodes[0].children[0], rules["s"], rules, input)
      }
    }
    width = width * 2
  }
}

///|
test "review empty language is not epsilon under positive repetition or concatenation" {
  // Exercise both the generalized and recursive-descent dispatch paths.
  for
    grammar in [
      b"s = 1*2dead / %s\"ok\"\r\nleft = dead %s\"ok\"\r\nright = %s\"ok\" dead\r\nzero = 0dead %s\"ok\"\r\nstar = *dead %s\"ok\"\r\noptional = [dead] %s\"ok\"\r\ndead = dead\r\n",
      b"s = 1*2dead / %s\"ok\"\r\nleft = dead %s\"ok\"\r\nright = %s\"ok\" dead\r\nzero = 0dead %s\"ok\"\r\nstar = *dead %s\"ok\"\r\noptional = [dead] %s\"ok\"\r\ndead = %s\"x\" dead\r\n",
    ] {
    let p = match @moonabnf.compile(grammar) {
      Ok(p) => p
      Err(d) => fail("compile: \{d.code} \{d.message}")
    }
    let rules : Map[String, @moonabnf.Expr] = Map([])
    for rule in @moonabnf.parse(grammar).unwrap().rules {
      rules[rule.name] = rule.expression
    }
    for name in ["s", "left", "right", "zero", "star", "optional"] {
      for input in [b"", b"ok", b"x", b"xok", b"okx", b"okok"] {
        let expected = if input == b"ok" && name != "left" && name != "right" {
          @moonabnf.Matched
        } else {
          @moonabnf.NoMatch
        }
        assert_eq(p.recognize(name, input).status, expected)
        let result = p.parse_input(name, input)
        assert_eq(result.status, expected)
        if expected == @moonabnf.Matched {
          let tree = tree_of(p, name, input)
          replay(tree, tree.nodes[0].children[0], rules[name], rules, input)
        } else {
          assert_true(result.tree is None)
        }
      }
    }
  }
}

///|
test "review mutually recursive empty branch cannot poison productive nullable sibling" {
  let grammar = b"s = 2*3(dead / empty) %s\"a\"\r\nempty = %s\"\"\r\ndead = other %s\"b\"\r\nother = dead / 1*2other\r\nblocked = 1*dead\r\n"
  let p = match @moonabnf.compile(grammar) {
    Ok(p) => p
    Err(d) => fail("compile: \{d.code} \{d.message}")
  }
  let rules : Map[String, @moonabnf.Expr] = Map([])
  for rule in @moonabnf.parse(grammar).unwrap().rules {
    rules[rule.name] = rule.expression
  }
  for input in [b"", b"a", b"b", b"aa", b"ba", b"aba"] {
    let expected = if input == b"a" {
      @moonabnf.Matched
    } else {
      @moonabnf.NoMatch
    }
    assert_eq(p.recognize("s", input).status, expected)
    assert_eq(p.parse_input("s", input).status, expected)
    assert_eq(p.recognize("blocked", input).status, @moonabnf.NoMatch)
    assert_eq(p.parse_input("blocked", input).status, @moonabnf.NoMatch)
  }
  let tree = tree_of(p, "s", b"a")
  replay(tree, tree.nodes[0].children[0], rules["s"], rules, b"a")
}

///|
test "review duplicated nullable witnesses exhaust node budget without partial tree" {
  let p = @moonabnf.compile(
    b"s = 2*3(empty / dead) %s\"a\"\r\nempty = %s\"\"\r\ndead = dead\r\n",
  ).unwrap()
  let full = p.parse_input("s", b"a")
  assert_eq(full.status, @moonabnf.Matched)
  assert_true(full.nodes > 1)
  let limits = {
    ..@moonabnf.default_input_tree_limits(),
    max_nodes: full.nodes - 1,
  }
  let limited = p.parse_input("s", b"a", limits~)
  assert_true(limited.status is @moonabnf.BudgetExceeded(_))
  assert_true(limited.tree is None)
  assert_true(limited.nodes <= limits.max_nodes)
  let enough = { ..limits, max_nodes: full.nodes, }
  assert_eq(p.parse_input("s", b"a", limits=enough).status, @moonabnf.Matched)
}
