///|
fn main raise {
  let grammar = b"message = message <emoji> / <greeting>\r\n"
  let bindings : Array[@abnf.ProseBinding] = [
    { name: "greeting", predicate: @abnf.Words([[0x4F60, 0x597D]]), },
    { name: "emoji", predicate: @abnf.SymbolRange(0x1F600, 0x1F64F), },
  ]
  let program = @abnf.compile_scalar(grammar, bindings~).unwrap()
  let input = [0x4F60, 0x597D, 0x1F600]
  let result = program.parse_input("message", input).unwrap()
  assert_eq(result.status, @abnf.Matched)
  let tree = result.tree.unwrap()
  assert_eq(tree.extract(input, tree.root), Some(input))
  println("Matched 3 Unicode scalars; grammar source offsets remain bytes.")
  println(
    "This local candidate uses explicit prose bindings, not natural-language inference.",
  )
}
