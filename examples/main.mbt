///|
/// Compile once, use the same program across protocol/config/fixture checks.
fn demo(
  name : String,
  grammar : Bytes,
  start : String,
  samples : Array[Bytes],
) -> Unit {
  match @abnf.compile(grammar) {
    Err(d) => println("\{name}: grammar error \{d.code} at \{d.offset}")
    Ok(program) =>
      for input in samples {
        let r = program.recognize(start, input)
        let status = match r.status {
          @abnf.Matched => "matched"
          @abnf.NoMatch => "no-match"
          @abnf.BudgetExceeded(why) => "budget-exceeded:\{why}"
          _ => "error"
        }
        println("\{name}: \{status} offset=\{r.offset} work=\{r.work}")
      }
  }
}

///|
fn main {
  demo(
    "protocol",
    b"field = %i\"Trace\" \":\" SP 1*8HEXDIG CRLF\r\n",
    "field",
    [b"TRACE: aF12\r\n", b"Trace:aF12\r\n"],
  )
  demo(
    "config",
    b"setting = key \"=\" value\r\nkey = ALPHA *7(ALPHA / DIGIT / \"-\")\r\nvalue = %s\"on\" / %s\"off\" / 1*3DIGIT\r\n",
    "setting",
    [b"cache=on", b"cache=ON", b"ttl=120"],
  )
  demo("fixture", b"frame = %x00 1*4OCTET %xFF\r\n", "frame", [
    b"\x00A\xFF", b"\x00ABCD\xFF", b"\x00ABCDE\xFF",
  ])
}
