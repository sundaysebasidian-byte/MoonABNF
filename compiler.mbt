///|
/// Compiled rules are private. Each compile parses its own AST, so caller-owned
/// mutable AST arrays cannot invalidate the compiled program.
pub struct Program {
  priv rules : Map[String, Expr]
  priv left_recursive : Bool
  priv productive : Map[String, Bool]
}

///|
priv struct Analysis {
  source : Bytes
  mut work : Int32
  max_work : Int32
}

///|
fn Analysis::tick(self : Analysis, offset : Int32) -> Unit raise ParseFailure {
  if self.work >= self.max_work {
    raise ParseFailure(
      diagnostic(
        self.source,
        offset,
        "compile-budget",
        "analysis work exhausted",
      ),
    )
  }
  self.work = self.work + 1
}

///|
fn validate_references(
  e : Expr,
  rules : Map[String, Expr],
  a : Analysis,
) -> Unit raise ParseFailure {
  a.tick(e.offset())
  match e {
    Ref(n, p) =>
      if !rules.contains(n) {
        raise ParseFailure(
          diagnostic(a.source, p, "undefined-rule", "undefined rule \{n}"),
        )
      }
    Prose(_, p) =>
      raise ParseFailure(
        diagnostic(
          a.source,
          p,
          "prose-unsupported",
          "prose-val cannot be recognized",
        ),
      )
    Sequence(es, _) | Choice(es, _) =>
      for e in es {
        validate_references(e, rules, a)
      }
    Repeat(_, _, e, _) => validate_references(e, rules, a)
    _ => ()
  }
}

///|
/// Core rules are implicit defaults. Explicit '=' overrides a core default;
/// '=/‘ may extend it. Duplicate explicit '=' and extension before base fail.
fn compile_domain(
  source : Bytes,
  limits : ParseLimits,
  max_work : Int32,
  scalar : Bool,
  bindings : Array[ProseBinding],
  allow_prose : Bool,
) -> Result[Program, Diagnostic] {
  if max_work < 1 || max_work > 10000000 {
    return Err(
      diagnostic(
        source, 0, "invalid-limits", "compile work must be 1..10000000",
      ),
    )
  }
  match parse_domain(source, limits, if scalar { 2147483647 } else { 255 }) {
    Err(d) => Err(d)
    Ok(g) =>
      try {
        if g.rules.is_empty() {
          raise ParseFailure(
            diagnostic(
              source, 0, "no-rules", "compilation requires a user rule",
            ),
          )
        }
        let a = { source, work: 0, max_work, }
        let lowering : Lowering = {
          a,
          nodes: 0,
          max_nodes: limits.max_nodes,
          scalar,
        }
        let predicates : Map[String, Expr] = Map([])
        for binding in bindings {
          a.tick(0)
          for c in binding.name.iter() {
            a.tick(0)
            let n = c.to_int()
            if n < 32 || n > 126 || n == 62 {
              raise ParseFailure(
                diagnostic(
                  source, 0, "invalid-prose-name", "binding name must be valid prose text",
                ),
              )
            }
          }
          if predicates.contains(binding.name) {
            raise ParseFailure(
              diagnostic(
                source, 0, "duplicate-prose-binding", "duplicate exact prose name",
              ),
            )
          }
          predicates[binding.name] = lowering.predicate(binding.predicate)
        }
        let rules = core_rules()
        let defined : Map[String, Bool] = Map([])
        for rule in g.rules {
          let expression = lowering.expression(
            rule.expression,
            predicates,
            allow_prose,
          )

          if rule.incremental {
            match rules.get(rule.name) {
              None =>
                raise ParseFailure(
                  diagnostic(
                    source,
                    rule.offset,
                    "increment-without-base",
                    "extension before base \{rule.name}",
                  ),
                )
              Some(old) => {
                // Flatten successive extensions to keep compiler recursion bounded.
                let es = match old {
                  Choice(es, _) => es.copy()
                  _ => [old]
                }
                es.push(expression)
                rules[rule.name] = Choice(es, rule.offset)
                defined[rule.name] = true
              }
            }
          } else {
            if defined.contains(rule.name) {
              raise ParseFailure(
                diagnostic(
                  source,
                  rule.offset,
                  "duplicate-rule",
                  "duplicate base \{rule.name}",
                ),
              )
            }
            rules[rule.name] = expression
            defined[rule.name] = true
          }
        }
        for _, e in rules {
          validate_references(e, rules, a)
        }
        let productive = fixed_point(rules, false, a)
        let left_recursive = validate_recursion(rules, a)
        Ok({ rules, left_recursive, productive, })
      } catch {
        ParseFailure(d) => Err(d)
      }
  }
}

///|
/// Deterministic inventory useful to grammar-checking tools.
pub fn Program::rule_names(self : Program) -> Array[String] {
  let names = self.rules.keys().collect()
  names.sort()
  names
}

///|
/// Legacy byte compiler. Prose remains rejected unless explicitly bound using
/// compile_with_prose. Byte behavior and the numeric ceiling are unchanged.
pub fn compile(
  source : Bytes,
  limits~ : ParseLimits = default_parse_limits(),
  max_work~ : Int32 = 1000000,
) -> Result[Program, Diagnostic] {
  compile_domain(source, limits, max_work, false, [], false)
}

///|
/// Bind exact prose names to finite languages or single-symbol ranges.
/// No natural-language interpretation or user callback is executed.
pub fn compile_with_prose(
  source : Bytes,
  bindings : Array[ProseBinding],
  limits~ : ParseLimits = default_parse_limits(),
  max_work~ : Int32 = 1000000,
) -> Result[Program, Diagnostic] {
  compile_domain(source, limits, max_work, false, bindings, true)
}
