///|
test "new independent round 8: diagnostic report identity and recursive disclosure" {
  for
    g in [
      b"s = (%s\"ab\" / %s\"ac\") [DIGIT] %s\"!\"\r\n", b"s = s %s\"a\" / %s\"b\"\r\n",
      b"s = dead\r\ndead = dead\r\n",
    ] {
    let p = @moonabnf.compile(g).unwrap()
    for input in [b"", b"a", b"ab", b"ac9!", b"acx!", b"b", b"baa", b"baa!"] {
      let recognition = p.recognize("s", input)
      for cap in [1, 2, 8] {
        let d = p.diagnose_input("s", input, diagnostic_limits={
          max_work: 20000,
          max_expectations: cap,
        })
        assert_eq(d.report, recognition)
        assert_true(d.explanation_work <= 20000)
        if d.failure is Some(f) {
          assert_true(f.offset >= 0 && f.offset <= input.length())
          assert_true(f.expected.length() <= cap)
          assert_eq(
            f.actual,
            if f.offset == input.length() {
              None
            } else {
              Some(input[f.offset].to_int())
            },
          )
        }
        if recognition.status != @moonabnf.NoMatch {
          assert_true(d.failure is None)
        }
      }
    }
  }
  let recursive = @moonabnf.compile(b"s = s %s\"a\" / %s\"b\"\r\n").unwrap()
  let d = recursive.diagnose_input("s", b"c")
  assert_eq(d.explanation_status, "generalized-explanation-unavailable")
  assert_true(d.failure is None)
  assert_eq(d.report.status, @moonabnf.NoMatch)
}
