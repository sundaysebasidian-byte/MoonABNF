///|
/// Work counts expression dispatches, byte comparisons and endpoint operations.
pub(all) struct MatchLimits {
  max_input_bytes : Int
  max_work : Int
  max_states : Int
  max_depth : Int
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
  offset : Int
  work : Int
  states : Int
} derive(Eq, Debug)

///|
priv suberror MatchStop {
  MatchStop(String)
}

///|
priv struct Runner {
  program : Program
  input : Bytes
  limits : MatchLimits
  mut work : Int
  mut states : Int
  mut furthest : Int
}

///|
fn Runner::tick(self : Runner, _pos : Int) -> Unit raise MatchStop {
  if self.work >= self.limits.max_work {
    raise MatchStop("work")
  }
  self.work = self.work + 1
}

///|
/// Every endpoint comparison is charged, including duplicates.
fn Runner::contains(
  self : Runner,
  es : Array[Int],
  pos : Int,
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
  es : Array[Int],
  pos : Int,
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
  pos : Int,
  depth : Int,
) -> Array[Int] raise MatchStop {
  if pos > self.furthest {
    self.furthest = pos
  }
  self.tick(pos)
  if depth > self.limits.max_depth {
    raise MatchStop("depth")
  }
  match e {
    Ref(name, _) => self.eval(self.program.rules[name], pos, depth + 1)
    Literal(s, sensitive, _) => {
      for i = 0; i < s.length(); i = i + 1 {
        let at = pos + i
        if at > self.furthest {
          self.furthest = at
        }
        self.tick(at)
        if at >= self.input.length() {
          return []
        }
        let actual = self.input[at].to_int()
        let wanted = s[i].to_int()
        if (if sensitive {
            actual != wanted
          } else {
            ascii_lower(actual) != ascii_lower(wanted)
          }) {
          return []
        }
      }
      let ends : Array[Int] = []
      self.insert(ends, pos + s.length())
      ends
    }
    Range(lo, hi, _) => {
      if pos >= self.input.length() {
        return []
      }
      let value = self.input[pos].to_int()
      if value < lo || value > hi {
        return []
      }
      let ends : Array[Int] = []
      self.insert(ends, pos + 1)
      ends
    }
    Choice(es, _) => {
      let ends : Array[Int] = []
      for child in es {
        for at in self.eval(child, pos, depth + 1) {
          self.insert(ends, at)
        }
      }
      ends
    }
    Sequence(es, _) => {
      let mut frontier : Array[Int] = []
      self.insert(frontier, pos)
      for child in es {
        let next : Array[Int] = []
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
  lo : Int,
  hi : Int?,
  child : Expr,
  pos : Int,
  depth : Int,
) -> Array[Int] raise MatchStop {
  let ends : Array[Int] = []
  let mut frontier : Array[Int] = []
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
    let next : Array[Int] = []
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
pub fn Program::recognize(
  self : Program,
  start : String,
  input : Bytes,
  limits? : MatchLimits = default_match_limits(),
) -> MatchReport {
  if limits.max_input_bytes < 0 ||
    limits.max_input_bytes > 1048576 ||
    limits.max_work < 1 ||
    limits.max_work > 10000000 ||
    limits.max_states < 1 ||
    limits.max_states > 1000000 ||
    limits.max_depth < 1 ||
    limits.max_depth > 128 {
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
  let runner = {
    program: self,
    input,
    limits,
    work: 0,
    states: 0,
    furthest: 0,
  }
  let status = try {
    let ends = runner.eval(e, 0, 0)
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
