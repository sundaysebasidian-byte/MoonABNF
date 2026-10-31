///|
test "round11 public rule lookup uses ASCII folding only" {
  let p = @moonabnf.compile(b"k = %s\"ok\"\r\n").unwrap()
  assert_eq(p.recognize("K", b"ok").status, @moonabnf.Matched)
  assert_eq(p.recognize("K", b"ok").status, @moonabnf.UnknownRule)
  assert_eq(p.parse_input("K", b"ok").status, @moonabnf.UnknownRule)
  let t = p.parse_input("k", b"ok").tree.unwrap()
  assert_eq(t.rule_nodes("K"), [])
  assert_eq(t.rule_nodes_in("K", t.root), Some([]))
  let s = @moonabnf.compile_scalar(b"k = %x41\r\n").unwrap()
  assert_eq(s.recognize("K", [65]).unwrap().status, @moonabnf.UnknownRule)
}
