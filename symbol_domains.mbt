///|
priv enum Symbols {
  ByteSymbols(Bytes)
  ScalarSymbols(Array[Int32])
}

///|
fn Symbols::length(self : Symbols) -> Int32 {
  match self {
    ByteSymbols(b) => b.length()
    ScalarSymbols(s) => s.length()
  }
}

///|
fn Symbols::at(self : Symbols, i : Int32) -> Int32 {
  match self {
    ByteSymbols(b) => b[i].to_int()
    ScalarSymbols(s) => s[i]
  }
}

///|
fn is_scalar(n : Int32) -> Bool {
  n >= 0 && n <= 0x10FFFF && !(n >= 0xD800 && n <= 0xDFFF)
}

///|
/// Declarative predicates: words/ranges and bounded-depth composition.
/// Words([]) is the empty language; Words([[]]) matches epsilon. Range matches
/// exactly one symbol, never epsilon. Concat([]) is epsilon; Alternative([])
/// is empty. Repetition permits unbounded languages, not executable callbacks.
pub(all) enum ProsePredicate {
  Words(Array[Array[Int32]])
  SymbolRange(Int32, Int32)
  Concat(Array[ProsePredicate])
  Alternative(Array[ProsePredicate])
  Repetition(Int32, Int32?, ProsePredicate)
} derive(Eq, Debug)

///|
/// Names equal the exact ASCII text inside <...>, case and spaces preserved.
/// Empty names are allowed: <> is a legal prose token. Duplicate and invalid
/// bindings are errors even if unused. Compiled programs own a lowered copy.
pub(all) struct ProseBinding {
  name : String
  predicate : ProsePredicate
} derive(Eq, Debug)

///|
priv struct Lowering {
  a : Analysis
  mut nodes : Int32
  max_nodes : Int32
  scalar : Bool
}

///|
fn Lowering::charge(self : Lowering, pos : Int32) -> Unit raise ParseFailure {
  self.a.tick(pos)
  if self.nodes >= self.max_nodes {
    raise ParseFailure(
      diagnostic(
        self.a.source,
        pos,
        "compile-budget",
        "expanded grammar node budget exhausted",
      ),
    )
  }
  self.nodes = self.nodes + 1
}

///|
fn Lowering::range(
  self : Lowering,
  lo : Int32,
  hi : Int32,
  pos : Int32,
) -> Expr raise ParseFailure {
  self.charge(pos)
  let valid = if self.scalar {
    lo >= 0 && hi <= 0x10FFFF && lo <= hi && !(lo >= 0xD800 && hi <= 0xDFFF)
  } else {
    lo >= 0 && hi <= 255 && lo <= hi
  }
  if !valid {
    raise ParseFailure(
      diagnostic(
        self.a.source,
        pos,
        "symbol-domain",
        "terminal range outside selected symbol domain",
      ),
    )
  }
  // Scalar input validation excludes surrogates even when a range spans them.
  Range(lo, hi, pos)
}

///|
fn Lowering::predicate(
  self : Lowering,
  predicate : ProsePredicate,
  depth~ : Int32 = 0,
) -> Expr raise ParseFailure {
  self.a.tick(0)
  if depth >= 64 {
    raise ParseFailure(
      diagnostic(
        self.a.source,
        0,
        "compile-budget",
        "prose composition depth exceeded (possibly cyclic caller structure)",
      ),
    )
  }
  match predicate {
    Concat(parts) => {
      self.charge(0)
      let es : Array[Expr] = []
      for p in parts {
        es.push(self.predicate(p, depth=depth + 1))
      }
      Sequence(es, 0)
    }
    Alternative(parts) => {
      self.charge(0)
      let es : Array[Expr] = []
      for p in parts {
        es.push(self.predicate(p, depth=depth + 1))
      }
      Choice(es, 0)
    }
    Repetition(lo, hi, p) => {
      self.charge(0)
      if lo < 0 || lo > 1000000 || (hi is Some(n) && (n < lo || n > 1000000)) {
        raise ParseFailure(
          diagnostic(
            self.a.source,
            0,
            "prose-repeat",
            "repeat bounds must be ordered in 0..1000000",
          ),
        )
      }
      Repeat(lo, hi, self.predicate(p, depth=depth + 1), 0)
    }
    SymbolRange(lo, hi) => self.range(lo, hi, 0)
    Words(words) => {
      self.charge(0)
      let alternatives : Array[Expr] = []
      for word in words {
        self.charge(0)
        let sequence : Array[Expr] = []
        for symbol in word {
          sequence.push(self.range(symbol, symbol, 0))
        }
        alternatives.push(Sequence(sequence, 0))
      }
      Choice(alternatives, 0)
    }
  }
}

///|
// Clone a compiled binding at each use so source offsets refer to the actual
// prose occurrence, not the out-of-band binding, and no caller arrays survive.
fn Lowering::at_source(
  self : Lowering,
  e : Expr,
  pos : Int32,
) -> Expr raise ParseFailure {
  self.charge(pos)
  match e {
    Range(lo, hi, _) => Range(lo, hi, pos)
    Sequence(es, _) => {
      let out : Array[Expr] = []
      for child in es {
        out.push(self.at_source(child, pos))
      }
      Sequence(out, pos)
    }
    Choice(es, _) => {
      let out : Array[Expr] = []
      for child in es {
        out.push(self.at_source(child, pos))
      }
      Choice(out, pos)
    }
    Repeat(lo, hi, child, _) => Repeat(lo, hi, self.at_source(child, pos), pos)
    _ => e // Only validated lowered binding variants are constructed.
  }
}

///|
fn Lowering::expression(
  self : Lowering,
  e : Expr,
  bindings : Map[String, Expr],
  allow_prose : Bool,
) -> Expr raise ParseFailure {
  match e {
    Range(lo, hi, pos) => self.range(lo, hi, pos)
    Prose(name, pos) => {
      self.a.tick(pos)
      if !allow_prose {
        raise ParseFailure(
          diagnostic(
            self.a.source,
            pos,
            "prose-unsupported",
            "prose-val requires an explicit binding",
          ),
        )
      }
      match bindings.get(name) {
        Some(bound) => self.at_source(bound, pos)
        None =>
          raise ParseFailure(
            diagnostic(
              self.a.source,
              pos,
              "prose-unbound",
              "no exact binding for prose value",
            ),
          )
      }
    }
    Sequence(es, pos) => {
      self.charge(pos)
      let out : Array[Expr] = []
      for child in es {
        out.push(self.expression(child, bindings, allow_prose))
      }
      Sequence(out, pos)
    }
    Choice(es, pos) => {
      self.charge(pos)
      let out : Array[Expr] = []
      for child in es {
        out.push(self.expression(child, bindings, allow_prose))
      }
      Choice(out, pos)
    }
    Repeat(lo, hi, child, pos) => {
      self.charge(pos)
      Repeat(lo, hi, self.expression(child, bindings, allow_prose), pos)
    }
    _ => {
      self.charge(e.offset())
      e
    }
  }
}

///|
pub extend ProsePredicate with Eq::{equal, not_equal}

///|
pub extend ProsePredicate with @debug.Debug::{to_repr}

///|
pub extend ProseBinding with Eq::{equal, not_equal}

///|
pub extend ProseBinding with @debug.Debug::{to_repr}
