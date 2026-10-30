///|
/// Node adapter: bounded regular-file reads only. No parsing or matching in JS.
extern "js" fn read_file(path : String, max : Int32) -> Bytes? =
  #| (path, max) => {
  #|   const fs = require('node:fs');
  #|   let fd;
  #|   try {
  #|     fd = fs.openSync(path, fs.constants.O_RDONLY | fs.constants.O_NONBLOCK);
  #|     const stat = fs.fstatSync(fd);
  #|     if (!stat.isFile()) throw new Error('not a regular file');
  #|     const buffer = Buffer.alloc(max + 1);
  #|     let n = 0, got;
  #|     while (n < buffer.length && (got = fs.readSync(fd, buffer, n, buffer.length - n, null)) > 0) n += got;
  #|     return new Uint8Array(buffer.subarray(0, n));
  #|   } catch (e) {
  #|     console.error(`I/O: ${path}: ${e.message}`);
  #|     return undefined;
  #|   } finally { if (fd !== undefined) fs.closeSync(fd); }
  #| }

///|
extern "js" fn exit_code(code : Int32) -> Unit =
  #| code => { process.exitCode = code; }

///|
fn output(fields : Array[(String, Json)]) -> Unit {
  println(@json.to_json(Map(fields)).stringify())
}

///|
fn main {
  let args = @env.args()
  if args.length() < 4 ||
    (
      args[2] != "check" &&
      args[2] != "match" &&
      args[2] != "diagnose" &&
      args[2] != "batch"
    ) {
    println(
      "usage: node main.js check grammar.abnf | match grammar.abnf rule input.bin [work-budget] | diagnose grammar.abnf rule input.bin [work-budget] | batch grammar.abnf rule input.bin...",
    )
    exit_code(2)
    return
  }
  let diagnostics = args[2] == "diagnose"
  let mode = if diagnostics { "match" } else { args[2] }
  if (mode == "check" && args.length() != 4) ||
    (mode == "match" && args.length() != 6 && args.length() != 7) ||
    (mode == "batch" && (args.length() < 6 || args.length() > 261)) {
    exit_code(2)
    output([("status", Json("usage-error"))])
    return
  }
  let source = match read_file(args[3], 65536) {
    None => {
      exit_code(2)
      return
    }
    Some(s) => s
  }
  let program = match @abnf.compile(source) {
    Err(d) => {
      output([
        ("status", Json("grammar-error")),
        ("code", Json(d.code)),
        ("message", Json(d.message)),
        ("offset", Json(d.offset)),
        ("line", Json(d.line)),
        ("column", Json(d.column)),
      ])
      exit_code(2)
      return
    }
    Ok(p) => p
  }
  if mode == "check" {
    output([("status", Json("valid")), ("rules", Json(program.rule_names()))])
    return
  }
  let mut limits = @abnf.default_match_limits()
  if mode == "match" && args.length() == 7 {
    let mut n = 0
    for c in args[6].to_array() {
      let d = c.to_int() - 48
      if d < 0 || d > 9 || n > (10000000 - d) / 10 {
        output([("status", Json("invalid-work-budget"))])
        exit_code(2)
        return
      }
      n = n * 10 + d
    }
    if n == 0 {
      output([("status", Json("invalid-work-budget"))])
      exit_code(2)
      return
    }
    limits = { ..limits, max_work: n, }
  }
  let count = if mode == "match" { 6 } else { args.length() }
  let mut code = 0
  for i = 5; i < count; i = i + 1 {
    let input = match read_file(args[i], limits.max_input_bytes) {
      None => {
        if code < 2 {
          code = 2
        }
        continue
      }
      Some(s) => s
    }
    let explained = if diagnostics {
      Some(program.diagnose_input(args[4], input, limits~))
    } else {
      None
    }
    let report = match explained {
      Some(d) => d.report
      None => program.recognize(args[4], input, limits~)
    }
    let label = match report.status {
      @abnf.Matched => "matched"
      @abnf.NoMatch => {
        if code == 0 {
          code = 1
        }
        "no-match"
      }
      @abnf.BudgetExceeded(reason) => {
        code = 3
        "budget-exceeded:\{reason}"
      }
      @abnf.UnknownRule => {
        if code < 2 {
          code = 2
        }
        "unknown-rule"
      }
      @abnf.InvalidLimits => {
        if code < 2 {
          code = 2
        }
        "invalid-limits"
      }
    }
    let fields = [
      ("file", Json(args[i])),
      ("status", Json(label)),
      ("offset", Json(report.offset)),
      ("work", Json(report.work)),
      ("states", Json(report.states)),
    ]
    if diagnostics {
      fields.push(("diagnostic", explained.unwrap().to_json()))
    }
    output(fields)
  }
  exit_code(code)
}
