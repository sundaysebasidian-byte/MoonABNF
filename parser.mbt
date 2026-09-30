///|
suberror ParseFailure { ParseFailure(Diagnostic) }

///|
struct Parser {
  source : Bytes
  mut pos : Int
  mut nodes : Int
  limits : ParseLimits
}

///|
fn[T] Parser::fail(self : Parser, code : String, message : String) -> T raise ParseFailure {
  raise ParseFailure(diagnostic(self.source, self.pos, code, message))
}

///|
fn Parser::peek(self : Parser) -> Int {
  if self.pos < self.source.length() { self.source[self.pos].to_int() } else { -1 }
}

///|
fn Parser::take(self : Parser, c : Int) -> Bool {
  if self.peek() == c { self.pos = self.pos + 1; true } else { false }
}

///|
fn Parser::need(self : Parser, c : Int) -> Unit raise ParseFailure {
  if !self.take(c) { self.fail("syntax", "expected byte \{c}") }
}

///| Exact RFC c-nl: CRLF, optionally preceded by a printable ASCII comment.
fn Parser::newline(self : Parser) -> Bool raise ParseFailure {
  if self.take(59) {
    while self.peek() != 13 {
      let c = self.peek()
      if c != 9 && (c < 32 || c > 126) { self.fail("syntax", "comment requires ASCII and CRLF") }
      self.pos = self.pos + 1
    }
  } else if self.peek() != 13 { return false }
  self.need(13)
  self.need(10)
  true
}

///| c-wsp folds a c-nl only when followed by SP/HTAB.
fn Parser::space(self : Parser) -> Bool raise ParseFailure {
  let start = self.pos
  while true {
    if self.take(32) || self.take(9) { continue }
    let saved = self.pos
    if self.newline() && (self.take(32) || self.take(9)) { continue }
    self.pos = saved
    break
  }
  self.pos > start
}

///|
fn Parser::name(self : Parser) -> String raise ParseFailure {
  let out = StringBuilder()
  if !alpha(self.peek()) { self.fail("syntax", "expected rule name") }
  while alpha(self.peek()) || digit(self.peek()) || self.peek() == 45 {
    out.write_char(Char::from_int(ascii_lower(self.peek())))
    self.pos = self.pos + 1
  }
  out.to_string()
}

///|
fn Parser::number(self : Parser, base : Int, ceiling : Int) -> Int raise ParseFailure {
  let start = self.pos
  let mut value = 0
  while true {
    let c = ascii_lower(self.peek())
    let n = if digit(c) { c - 48 } else if c >= 97 && c <= 102 { c - 87 } else { -1 }
    if n < 0 || n >= base { break }
    if value > (ceiling - n) / base { self.fail("number-limit", "numeric value exceeds \{ceiling}") }
    value = value * base + n
    self.pos = self.pos + 1
  }
  if self.pos == start { self.fail("syntax", "expected base-\{base} digits") }
  value
}

///|
fn Parser::literal(self : Parser, sensitive : Bool, start : Int) -> Expr raise ParseFailure {
  self.need(34)
  let bytes : Array[Byte] = []
  while !self.take(34) {
    let c = self.peek()
    if c < 32 || c > 126 { self.fail("syntax", "quoted strings require printable ASCII") }
    bytes.push(c.to_byte())
    self.pos = self.pos + 1
  }
  Literal(Bytes::from_array(bytes), sensitive, start)
}

///|
fn Parser::element(self : Parser, depth : Int) -> Expr raise ParseFailure {
  if depth > self.limits.max_depth { self.fail("parse-budget", "grammar nesting depth exhausted") }
  self.nodes = self.nodes + 1
  if self.nodes > self.limits.max_nodes { self.fail("parse-budget", "AST node budget exhausted") }
  let start = self.pos
  if alpha(self.peek()) { return Ref(self.name(), start) }
  if self.peek() == 34 { return self.literal(false, start) }
  if self.take(40) {
    ignore(self.space())
    let e = self.alternation(depth + 1)
    ignore(self.space())
    self.need(41)
    return e
  }
  if self.take(91) {
    ignore(self.space())
    let e = self.alternation(depth + 1)
    ignore(self.space())
    self.need(93)
    return Repeat(0, Some(1), e, start)
  }
  if self.take(60) {
    let text = StringBuilder()
    while !self.take(62) {
      let c = self.peek()
      if c < 32 || c > 126 { self.fail("syntax", "invalid prose value") }
      text.write_char(Char::from_int(c))
      self.pos = self.pos + 1
    }
    return Prose(text.to_string(), start)
  }
  if self.take(37) {
    let prefix = ascii_lower(self.peek())
    self.pos = self.pos + 1
    if prefix == 105 || prefix == 115 { return self.literal(prefix == 115, start) }
    let base = match prefix { 98 => 2; 100 => 10; 120 => 16; _ => self.fail("syntax", "unknown percent prefix") }
    let lo = self.number(base, 255)
    if self.take(45) {
      let hi = self.number(base, 255)
      if lo > hi { self.fail("range", "descending numeric range") }
      return Range(lo, hi, start)
    }
    let es = [Range(lo, lo, start)]
    while self.take(46) { let n = self.number(base, 255); es.push(Range(n, n, start)) }
    return if es.length() == 1 { es[0] } else { Sequence(es, start) }
  }
  self.fail("syntax", "expected ABNF element")
}

///|
fn Parser::repetition(self : Parser, depth : Int) -> Expr raise ParseFailure {
  let start = self.pos
  let exact = if digit(self.peek()) { Some(self.number(10, 1000000)) } else { None }
  if self.take(42) {
    let hi = if digit(self.peek()) { Some(self.number(10, 1000000)) } else { None }
    let lo = exact.unwrap_or(0)
    if hi is Some(n) && n < lo { self.fail("repeat", "minimum exceeds maximum") }
    let e = self.element(depth)
    return Repeat(lo, hi, e, start)
  }
  let e = self.element(depth)
  match exact { Some(n) => Repeat(n, Some(n), e, start); None => e }
}

///|
fn Parser::concatenation(self : Parser, depth : Int) -> Expr raise ParseFailure {
  let start = self.pos
  let es = [self.repetition(depth)]
  while true {
    let saved = self.pos
    if !self.space() { break }
    let c = self.peek()
    if c == 47 || c == 41 || c == 93 || c == 13 || c == 59 || c == -1 {
      self.pos = saved
      break
    }
    es.push(self.repetition(depth))
  }
  if es.length() == 1 { es[0] } else { Sequence(es, start) }
}

///|
fn Parser::alternation(self : Parser, depth : Int) -> Expr raise ParseFailure {
  let start = self.pos
  let es = [self.concatenation(depth)]
  while true {
    let saved = self.pos
    ignore(self.space())
    if !self.take(47) { self.pos = saved; break }
    ignore(self.space())
    es.push(self.concatenation(depth))
  }
  if es.length() == 1 { es[0] } else { Choice(es, start) }
}

///| Strict grammar input: CRLF required, including the final rule terminator.
pub fn parse(source : Bytes, limits? : ParseLimits = default_parse_limits()) -> Result[Grammar, Diagnostic] {
  if limits.max_bytes < 0 || limits.max_bytes > 1048576 || limits.max_rules < 1 || limits.max_rules > 512 || limits.max_nodes < 1 || limits.max_nodes > 8192 || limits.max_depth < 1 || limits.max_depth > 64 {
    return Err(diagnostic(source, 0, "invalid-limits", "parse limits exceed implementation ceilings"))
  }
  if source.length() > limits.max_bytes { return Err(diagnostic(source, 0, "parse-budget", "grammar byte budget exhausted")) }
  let p = { source, pos: 0, nodes: 0, limits }
  try {
    let rules : Array[Rule] = []
    while p.pos < source.length() {
      let saved = p.pos
      ignore(p.space())
      if p.newline() { continue }
      p.pos = saved
      let offset = p.pos
      let name = p.name()
      ignore(p.space())
      p.need(61)
      let incremental = p.take(47)
      ignore(p.space())
      let expression = p.alternation(0)
      ignore(p.space())
      if !p.newline() { p.fail("syntax", "rule requires CRLF terminator") }
      rules.push({ name, expression, incremental, offset })
      if rules.length() > limits.max_rules { p.fail("parse-budget", "rule budget exhausted") }
    }
    if source.is_empty() { p.fail("syntax", "empty rulelist") }
    Ok({ rules })
  } catch { ParseFailure(d) => Err(d) }
}
