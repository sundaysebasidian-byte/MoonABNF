///| Core terminals are constructed as AST semantics, not copied RFC text.
fn core_rules() -> Map[String, Expr] {
  let r = (lo, hi) => Range(lo, hi, 0)
  let ref = name => Ref(name, 0)
  let alt = es => Choice(es, 0)
  let seq = es => Sequence(es, 0)
  {
    "alpha": alt([r(65, 90), r(97, 122)]),
    "bit": r(48, 49),
    "char": r(1, 127),
    "cr": r(13, 13),
    "crlf": seq([ref("cr"), ref("lf")]),
    "ctl": alt([r(0, 31), r(127, 127)]),
    "digit": r(48, 57),
    "dquote": r(34, 34),
    "hexdig": alt([ref("digit"), r(65, 70), r(97, 102)]),
    "htab": r(9, 9),
    "lf": r(10, 10),
    "lwsp": Repeat(0, None, alt([ref("wsp"), seq([ref("crlf"), ref("wsp")])]), 0),
    "octet": r(0, 255),
    "sp": r(32, 32),
    "vchar": r(33, 126),
    "wsp": alt([ref("sp"), ref("htab")]),
  }
}
