///|
/// Work counts expression dispatches, byte comparisons and endpoint operations.
pub(all) struct MatchLimits {
  max_input_bytes : Int32
  max_work : Int32
  max_states : Int32
  max_depth : Int32
} derive(Eq, Debug)

///|
pub fn default_match_limits() -> MatchLimits {
  {
    max_input_bytes: 65536,
    max_work: 500000,
    max_states: 100000,
    max_depth: 128,
  }
}

///|
pub(all) enum MatchStatus {
  Matched
  NoMatch
  BudgetExceeded(String)
  UnknownRule
  InvalidLimits
} derive(Eq, Debug)

///|
/// offset is a zero-based furthest attempted byte; full match offset is length.
/// Budget exhaustion is indeterminate, even if an explored branch matched.
pub(all) struct MatchReport {
  status : MatchStatus
  offset : Int32
  work : Int32
  states : Int32
} derive(Eq, Debug)

///|
priv suberror MatchStop {
  MatchStop(String)
}

///|
priv struct Runner {
  program : Program
  input : Symbols
  limits : MatchLimits
  mut work : Int32
  mut states : Int32
  mut furthest : Int32
  failures : FailureCollector?
  chart : Map[(String, Int32), Array[Int32]]
}

///|
fn Runner::tick(self : Runner, _pos : Int32) -> Unit raise MatchStop {
  if self.work >= self.limits.max_work {
    raise MatchStop("work")
  }
  self.work = self.work + 1
}

///|
/// Every endpoint comparison is charged, including duplicates.
fn Runner::contains(
  self : Runner,
  es : Array[Int32],
  pos : Int32,
) -> Bool raise MatchStop {
  for old in es {
    self.tick(pos)
    if old == pos {
      return true
    }
  }
  false
}

///|
fn Runner::insert(
  self : Runner,
  es : Array[Int32],
  pos : Int32,
) -> Unit raise MatchStop {
  if pos > self.furthest {
    self.furthest = pos
  }
  self.tick(pos)
  if !self.contains(es, pos) {
    if self.states >= self.limits.max_states {
      raise MatchStop("states")
    }
    self.states = self.states + 1
    es.push(pos)
  }
}

///|
/// All successful ending positions are propagated; choices are unordered ABNF
/// alternatives, with no greedy/ordered-choice loss of later solutions.
fn Runner::eval(
  self : Runner,
  e : Expr,
  pos : Int32,
  depth : Int32,
) -> Array[Int32] raise MatchStop {
  if pos > self.furthest {
    self.furthest = pos
  }
  self.tick(pos)
  if depth > self.limits.max_depth {
    raise MatchStop("depth")
  }
  match e {
    Ref(name, _) =>
      if !self.program.productive.contains(name) {
        []
      } else if self.program.left_recursive {
        let cached = self.chart.get((name, pos)).unwrap_or([])
        for end in cached {
          self.tick(end)
        }
        cached.copy()
      } else {
        self.eval(self.program.rules[name], pos, depth + 1)
      }
    Literal(s, sensitive, grammar_pos) => {
      for i = 0; i < s.length(); i = i + 1 {
        let at = pos + i
        if at > self.furthest {
          self.furthest = at
        }
        self.tick(at)
        if at >= self.input.length() {
          self.expect(
            at,
            ByteRange(s[i].to_int(), s[i].to_int(), !sensitive),
            grammar_pos,
          )
          return []
        }
        let actual = self.input.at(at)
        let wanted = s[i].to_int()
        if (if sensitive {
            actual != wanted
          } else {
            ascii_lower(actual) != ascii_lower(wanted)
          }) {
          self.expect(at, ByteRange(wanted, wanted, !sensitive), grammar_pos)
          return []
        }
      }
      let ends : Array[Int32] = []
      self.insert(ends, pos + s.length())
      ends
    }
    Range(lo, hi, grammar_pos) => {
      if pos >= self.input.length() {
        self.expect(pos, ByteRange(lo, hi, false), grammar_pos)
        return []
      }
      let value = self.input.at(pos)
      if value < lo || value > hi {
        self.expect(pos, ByteRange(lo, hi, false), grammar_pos)
        return []
      }
      let ends : Array[Int32] = []
      self.insert(ends, pos + 1)
      ends
    }
    Choice(es, _) => {
      let ends : Array[Int32] = []
      for child in es {
        for at in self.eval(child, pos, depth + 1) {
          self.insert(ends, at)
        }
      }
      ends
    }
    Sequence(es, _) => {
      let mut frontier : Array[Int32] = []
      self.insert(frontier, pos)
      for child in es {
        let next : Array[Int32] = []
        for at in frontier {
          for end in self.eval(child, at, depth + 1) {
            self.insert(next, end)
          }
        }
        frontier = next
        if frontier.is_empty() {
          break
        }
      }
      frontier
    }
    Repeat(lo, hi, child, _) => self.repeat(lo, hi, child, pos, depth)
    Prose(_, _) => raise MatchStop("invalid-program")
  }
}

///|
fn Runner::repeat(
  self : Runner,
  lo : Int32,
  hi : Int32?,
  child : Expr,
  pos : Int32,
  depth : Int32,
) -> Array[Int32] raise MatchStop {
  let ends : Array[Int32] = []
  let mut frontier : Array[Int32] = []
  self.insert(frontier, pos)
  let mut count = 0
  while true {
    self.tick(pos)
    if count >= lo {
      for at in frontier {
        self.insert(ends, at)
      }
    }
    if hi is Some(max) && count >= max {
      break
    }
    let next : Array[Int32] = []
    for at in frontier {
      for end in self.eval(child, at, depth + 1) {
        self.insert(next, end)
      }
    }
    count = count + 1
    if next.is_empty() {
      break
    }
    let mut stable = next.length() == frontier.length()
    if stable {
      for at in next {
        if !self.contains(frontier, at) {
          stable = false
          break
        }
      }
    }
    if stable {
      // Exact-count endpoint sets reached a fixed point. The same set is valid
      // at every later count, including a minimum larger than current count.
      for at in next {
        self.insert(ends, at)
      }
      break
    }
    frontier = next
  }
  ends
}

///|
/// Recognize the entire byte sequence, not just a prefix.
fn valid_match_limits(limits : MatchLimits) -> Bool {
  limits.max_input_bytes >= 0 &&
  limits.max_input_bytes <= 1048576 &&
  limits.max_work >= 1 &&
  limits.max_work <= 10000000 &&
  limits.max_states >= 1 &&
  limits.max_states <= 1000000 &&
  limits.max_depth >= 1 &&
  limits.max_depth <= 128
}

///|
/// Recognize the entire byte sequence, not just a prefix.
fn Program::recognize_symbols(
  self : Program,
  start : String,
  input : Symbols,
  limits : MatchLimits,
  initial_work : Int32,
) -> MatchReport {
  if !valid_match_limits(limits) {
    return { status: InvalidLimits, offset: 0, work: 0, states: 0, }
  }
  if input.length() > limits.max_input_bytes {
    return {
      status: BudgetExceeded("input-bytes"),
      offset: 0,
      work: 0,
      states: 0,
    }
  }
  let name = lower_name(start)
  let e = match self.rules.get(name) {
    None => return { status: UnknownRule, offset: 0, work: 0, states: 0, }
    Some(e) => e
  }
  if !self.productive.contains(name) {
    return { status: NoMatch, offset: 0, work: 0, states: 0, }
  }
  let runner = {
    program: self,
    input,
    limits,
    work: initial_work,
    states: 0,
    furthest: 0,
    failures: None,
    chart: Map([]),
  }
  let status = try {
    let ends = if self.left_recursive {
      runner.solve(name)
    } else {
      runner.eval(e, 0, 0)
    }
    if runner.contains(ends, input.length()) {
      Matched
    } else {
      NoMatch
    }
  } catch {
    MatchStop(reason) => BudgetExceeded(reason)
  }
  {
    status,
    offset: if status == Matched {
      input.length()
    } else {
      runner.furthest
    },
    work: runner.work,
    states: runner.states,
  }
}

///|
pub extend MatchLimits with Eq::{equal, not_equal}

///|
pub extend MatchLimits with @debug.Debug::{to_repr}

///|
pub extend MatchStatus with Eq::{equal, not_equal}

///|
pub extend MatchStatus with @debug.Debug::{to_repr}

///|
pub extend MatchReport with Eq::{equal, not_equal}

///|
pub extend MatchReport with @debug.Debug::{to_repr}

///|
// Monotone least fixed point over finite (rule,start,end) facts. No recursive
// rule expansion occurs in this path. Work/states charge every evaluation and
// insertion; exhaustion remains indeterminate, never a grammar rejection.
fn Runner::solve(self : Runner, start : String) -> Array[Int32] raise MatchStop {
  let names = self.reachable_rules(start)
  let mut changed = true
  while changed {
    changed = false
    for name in names {
      for pos = self.input.length(); pos >= 0; pos = pos - 1 {
        self.tick(pos)
        if !self.chart.contains((name, pos)) {
          if self.states >= self.limits.max_states {
            raise MatchStop("states")
          }
          self.states = self.states + 1
        }
        let old = self.chart.get((name, pos)).unwrap_or([])
        let results = self.eval(self.program.rules[name], pos, 0)
        for end in results {
          if !self.contains(old, end) {
            self.insert(old, end)
            changed = true
          }
        }
        self.chart[(name, pos)] = old
      }
    }
  }
  self.chart.get((start, 0)).unwrap_or([])
}

///|
fn Runner::collect_refs(
  self : Runner,
  e : Expr,
  names : Array[String],
  seen : Map[String, Bool],
) -> Unit raise MatchStop {
  self.tick(0)
  match e {
    Ref(name, _) =>
      if !seen.contains(name) {
        seen[name] = true
        names.push(name)
      }
    Sequence(es, _) | Choice(es, _) =>
      for child in es {
        self.collect_refs(child, names, seen)
      }
    Repeat(_, hi, child, _) =>
      if hi != Some(0) {
        self.collect_refs(child, names, seen)
      }
    _ => ()
  }
}

///|
fn Runner::reachable_rules(
  self : Runner,
  start : String,
) -> Array[String] raise MatchStop {
  let names = [start]
  let seen : Map[String, Bool] = Map([(start, true)])
  let mut at = 0
  while at < names.length() {
    self.collect_refs(self.program.rules[names[at]], names, seen)
    at = at + 1
  }
  names.sort()
  names
}

///|
pub fn Program::recognize(
  self : Program,
  start : String,
  input : Bytes,
  limits~ : MatchLimits = default_match_limits(),
) -> MatchReport {
  self.recognize_symbols(start, ByteSymbols(input), limits, 0)
}
