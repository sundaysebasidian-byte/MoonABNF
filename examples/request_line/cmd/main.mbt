///|
fn show(program : @abnf.Program, input : Bytes) -> Unit {
  let report = program.parse_input("request-line", input)
  match @request_line.parse(program, input) {
    Ok(line) => {
      println(@request_line.dump(report.tree.unwrap(), input))
      let (ms, me) = line.verb
      let (ps, pe) = line.path
      println(
        "fields: method=\{input[ms:me].to_owned()} path=[\{ps},\{pe}) HTTP/\{line.major}.\{line.minor}",
      )
      if line.query is Some((qs, qe)) {
        println("        query=[\{qs},\{qe})")
      }
    }
    Err(why) => println("rejected \{input.length()} bytes: \{why}")
  }
}

///|
fn main {
  let program = @abnf.compile(@request_line.grammar()).unwrap()
  show(program, b"GET /search/a%20b?q=moon&n=2 HTTP/1.1\r\n")
  println("---")
  show(program, b"GET index.html HTTP/1.1\r\n")
  show(program, b"GET /x HTTP/1.1")
  show(program, b"GET /a b HTTP/1.1\r\n")
  show(program, b"GET /x http/1.1\r\n")
}
