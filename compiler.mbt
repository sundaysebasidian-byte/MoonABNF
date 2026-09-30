///| Compiled rules are private. Each compile parses its own AST, so caller-owned
/// mutable AST arrays cannot invalidate the compiled program.
pub struct Program {
  priv rules : Map[String, Expr]
}

///|
priv struct Analysis {
  source : Bytes
  mut work : Int
  max_work : Int
}

///|
fn Analysis::tick(self : Analysis, offset : Int) -> Unit raise ParseFailure {
  if self.work >= self.max_work { raise ParseFailure(diagnostic(self.source, offset, "compile-budget", "analysis work exhausted")) }
  self.work = self.work + 1
}

///|
fn validate_references(e : Expr, rules : Map[String, Expr], a : Analysis) -> Unit raise ParseFailure {
  a.tick(e.offset())
  match e {
    Ref(n, p) => if !rules.contains(n) { raise ParseFailure(diagnostic(a.source, p, "undefined-rule", "undefined rule \{n}")) }
    Prose(_, p) => raise ParseFailure(diagnostic(a.source, p, "prose-unsupported", "prose-val cannot be recognized"))
    Sequence(es, _) | Choice(es, _) => for e in es { validate_references(e, rules, a) }
    Repeat(_, _, e, _) => validate_references(e, rules, a)
    _ => ()
  }
}

///| Core rules are implicit defaults. Explicit '=' overrides a core default;
/// '=/‘ may extend it. Duplicate explicit '=' and extension before base fail.
pub fn compile(source : Bytes, limits? : ParseLimits = default_parse_limits(), max_work? : Int = 1000000) -> Result[Program, Diagnostic] {
  if max_work < 1 || max_work > 10000000 { return Err(diagnostic(source, 0, "invalid-limits", "compile work must be 1..10000000")) }
  match parse(source, limits~) {
    Err(d) => Err(d)
    Ok(g) => try {
      if g.rules.is_empty() { raise ParseFailure(diagnostic(source, 0, "no-rules", "compilation requires a user rule")) }
      let rules = core_rules()
      let defined : Map[String, Bool] = {}
      for rule in g.rules {
        if rule.incremental {
          match rules.get(rule.name) {
            None => raise ParseFailure(diagnostic(source, rule.offset, "increment-without-base", "extension before base \{rule.name}"))
            Some(old) => {
              // Flatten successive extensions to keep compiler recursion bounded.
              let es = match old { Choice(es, _) => es.copy(); _ => [old] }
              es.push(rule.expression)
              rules[rule.name] = Choice(es, rule.offset)
            }
          }
        } else {
          if defined.contains(rule.name) { raise ParseFailure(diagnostic(source, rule.offset, "duplicate-rule", "duplicate base \{rule.name}")) }
          rules[rule.name] = rule.expression
          defined[rule.name] = true
        }
      }
      let a = { source, work: 0, max_work }
      for _, e in rules { validate_references(e, rules, a) }
      Ok({ rules, })
    } catch { ParseFailure(d) => Err(d) }
  }
}

///| Deterministic inventory useful to grammar-checking tools.
pub fn Program::rule_names(self : Program) -> Array[String] {
  let names = self.rules.keys().collect()
  names.sort()
  names
}
