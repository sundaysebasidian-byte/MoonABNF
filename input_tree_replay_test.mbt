///|
/// Independent validation: replay the chosen derivation against the public AST,
/// with no endpoint search or calls to either recognizer. Fixtures define every
/// referenced rule, avoiding reliance on the evaluator's implicit core table.
fn replay(
  tree : @moonabnf.InputTree,
  id : Int32,
  expr : @moonabnf.Expr,
  rules : Map[String, @moonabnf.Expr],
  input : Bytes,
) -> Unit raise {
  let node = tree.nodes[id]
  match expr {
    @moonabnf.Ref(name, source) => {
      assert_eq(node.kind, @moonabnf.RuleNode(name))
      assert_eq(node.source_offset, source)
      replay(tree, node.children[0], rules[name], rules, input)
    }
    @moonabnf.Literal(bytes, sensitive, source) => {
      assert_eq(node.kind, @moonabnf.LiteralNode)
      assert_eq(node.source_offset, source)
      assert_eq(node.end - node.start, bytes.length())
      for i = 0; i < bytes.length(); i = i + 1 {
        let actual = input[node.start + i].to_int()
        let expected = bytes[i].to_int()
        if sensitive {
          assert_eq(actual, expected)
        } else {
          let a = if actual >= 65 && actual <= 90 {
            actual + 32
          } else {
            actual
          }
          let e = if expected >= 65 && expected <= 90 {
            expected + 32
          } else {
            expected
          }
          assert_eq(a, e)
        }
      }
    }
    @moonabnf.Range(lo, hi, source) => {
      assert_eq(node.kind, @moonabnf.RangeNode)
      assert_eq(node.source_offset, source)
      assert_eq(node.end - node.start, 1)
      let actual = input[node.start].to_int()
      assert_true(actual >= lo && actual <= hi)
    }
    @moonabnf.Sequence(es, source) => {
      assert_eq(node.kind, @moonabnf.SequenceNode)
      assert_eq(node.source_offset, source)
      assert_eq(node.children.length(), es.length())
      for i = 0; i < es.length(); i = i + 1 {
        replay(tree, node.children[i], es[i], rules, input)
      }
    }
    @moonabnf.Choice(es, source) => {
      assert_eq(node.source_offset, source)
      match node.kind {
        @moonabnf.ChoiceNode(index) => {
          assert_true(index >= 0 && index < es.length())
          replay(tree, node.children[0], es[index], rules, input)
        }
        _ => fail("expected choice witness")
      }
    }
    @moonabnf.Repeat(lo, hi, child, source) => {
      assert_eq(node.source_offset, source)
      match node.kind {
        @moonabnf.RepeatNode(count) => {
          assert_true(count >= lo)
          if hi is Some(max) {
            assert_true(count <= max)
          }
          assert_eq(node.children.length(), count)
          for id in node.children {
            replay(tree, id, child, rules, input)
          }
        }
        _ => fail("expected repeat witness")
      }
    }
    @moonabnf.Prose(_, _) => fail("unexpected prose")
  }
}
