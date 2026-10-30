///|
/// Monotone boolean analysis: nullable=true checks epsilon; false checks that
/// some finite terminal string can be generated (including epsilon).
fn property(
  e : Expr,
  state : Map[String, Bool],
  nullable : Bool,
  a : Analysis,
) -> Bool raise ParseFailure {
  a.tick(e.offset())
  match e {
    Ref(n, _) => state.get(n).unwrap_or(false)
    Literal(s, _, _) => !nullable || s.is_empty()
    Range(_, _, _) => !nullable
    Prose(_, _) => false
    Repeat(lo, hi, child, _) =>
      lo == 0 || hi == Some(0) || property(child, state, nullable, a)
    Sequence(es, _) => {
      for e in es {
        if !property(e, state, nullable, a) {
          return false
        }
      }
      true
    }
    Choice(es, _) => {
      for e in es {
        if property(e, state, nullable, a) {
          return true
        }
      }
      false
    }
  }
}

///|
fn fixed_point(
  rules : Map[String, Expr],
  nullable : Bool,
  a : Analysis,
) -> Map[String, Bool] raise ParseFailure {
  let state : Map[String, Bool] = Map([])
  let mut changed = true
  while changed {
    changed = false
    for name, e in rules {
      if !state.contains(name) && property(e, state, nullable, a) {
        state[name] = true
        changed = true
      }
    }
  }
  state
}

///|
/// Only references reachable before consuming a byte can cause left recursion.
fn leading(
  e : Expr,
  nullable : Map[String, Bool],
  out : Array[String],
  a : Analysis,
) -> Unit raise ParseFailure {
  a.tick(e.offset())
  match e {
    Ref(n, _) => out.push(n)
    Choice(es, _) =>
      for e in es {
        leading(e, nullable, out, a)
      }
    Sequence(es, _) =>
      for e in es {
        leading(e, nullable, out, a)
        if !property(e, nullable, true, a) {
          break
        }
      }
    Repeat(_, hi, child, _) =>
      if hi != Some(0) {
        leading(child, nullable, out, a)
      }
    _ => ()
  }
}

///|
/// Iterative reachability avoids recursion proportional to the number of rules.
fn validate_recursion(
  rules : Map[String, Expr],
  a : Analysis,
) -> Bool raise ParseFailure {
  let names = rules.keys().collect()
  names.sort()
  let nullable = fixed_point(rules, true, a)
  let graph : Map[String, Array[String]] = Map([])
  for name in names {
    let edges : Array[String] = []
    leading(rules[name], nullable, edges, a)
    graph[name] = edges
  }
  for root in names {
    let pending = [root]
    let seen : Map[String, Bool] = Map([])
    let mut i = 0
    while i < pending.length() {
      let node = pending[i]
      i = i + 1
      for next in graph[node] {
        a.tick(rules[root].offset())
        if next == root {
          return true
        }
        if !seen.contains(next) {
          seen[next] = true
          pending.push(next)
        }
      }
    }
  }
  false
}
