///|
fn byte_label(value : Int) -> String raise {
  if value == 32 {
    "32 SPACE"
  } else if value >= 33 && value <= 126 {
    let text = @utf8.decode(Bytes::from_array([value.to_byte()]))
    "\{value} '\{text}'"
  } else {
    value.to_string()
  }
}

///|
fn show_case(
  label : String,
  program : @abnf.Program,
  rule : String,
  input : Bytes,
  revised : Bytes,
  field : String,
) -> Unit raise {
  let result = program.diagnose_input(rule, input)
  assert_eq(result.report.status, @abnf.NoMatch)
  let failure = result.failure.unwrap()
  let left = if failure.offset > 6 { failure.offset - 6 } else { 0 }
  let right = if failure.offset + 6 < input.length() {
    failure.offset + 6
  } else {
    input.length()
  }
  println("\{label}: input=\{input}")
  println(
    "  byte \{failure.offset}; nearby [\{left},\{right})=\{input[left:right]}",
  )
  let actual = match failure.actual {
    Some(value) => byte_label(value)
    None => "EOF"
  }
  println("  actual=\{actual}; explanation=\{result.explanation_status}")
  if failure.truncated {
    println("  partial expectations only; missing entries are not ruled out")
  }
  for item in failure.expected {
    let expected = match item.expectation {
      @abnf.EndOfInput => "EOF"
      @abnf.ByteRange(lo, hi, insensitive) => {
        let bounds = if lo == hi {
          byte_label(lo)
        } else {
          "\{byte_label(lo)} .. \{byte_label(hi)}"
        }
        if insensitive {
          bounds + " (ASCII case-insensitive)"
        } else {
          bounds
        }
      }
    }
    let position = match item.grammar_offset {
      Some(offset) => "terminal expression at grammar byte \{offset}"
      None => "implicit core/EOF; no user grammar position"
    }
    println("  expected \{expected}; \{position}")
  }
  println("  manual revision=\{revised} (one choice, not automatic repair)")
  let parsed = program.parse_input(rule, revised)
  assert_eq(parsed.status, @abnf.Matched)
  let tree = parsed.tree.unwrap()
  let nodes = tree.rule_nodes_in(field, tree.root).unwrap()
  assert_true(!nodes.is_empty())
  for node in nodes {
    let (start, end) = tree.span(node).unwrap()
    println(
      "  verified \{field} [\{start},\{end})=\{tree.extract(revised, node).unwrap()}",
    )
  }
}

///|
fn main raise {
  println(
    "Local farthest-branch explanations; syntax only, no unique repair claim.",
  )
  let uri = @abnf.compile(@protocols.uri_grammar()).unwrap()
  let cookie = @abnf.compile(@protocols.cookie_grammar()).unwrap()
  show_case(
    "URI percent escape", uri, "URI", b"https://example.test/%GG", b"https://example.test/%20",
    "path-abempty",
  )
  show_case(
    "Cookie value", cookie, "cookie-string", b"session=bad value", b"session=bad-value",
    "cookie-value",
  )
  show_case(
    "Truncated URI", uri, "URI", b"https://[2001:db8::1", b"https://[2001:db8::1]",
    "host",
  )
  show_case(
    "Trailing URI space", uri, "URI", b"https://example.test/a ", b"https://example.test/a",
    "path-abempty",
  )
  let limited = uri.diagnose_input("URI", b"https://example.test/%GG", limits={
    ..@abnf.default_match_limits(),
    max_work: 1,
  })
  assert_true(limited.report.status is @abnf.BudgetExceeded(_))
  assert_true(limited.failure is None)
  println(
    "Limited recognition: indeterminate; no rejection or repair suggestion.",
  )
}
