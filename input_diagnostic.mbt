///|
/// ByteRange's third value denotes ASCII case-insensitive matching, not Unicode.
pub(all) enum InputExpectation {
  ByteRange(Int32, Int32, Bool)
  EndOfInput
} derive(Eq, Debug)

///|
/// grammar_offset is the terminal expression's original grammar byte offset.
/// None denotes implicit core terminals or an end-of-input requirement.
pub(all) struct ExpectedInput {
  expectation : InputExpectation
  grammar_offset : Int32?
} derive(Eq, Debug)

///|
pub(all) struct InputDiagnosticLimits {
  max_work : Int32
  max_expectations : Int32
} derive(Eq, Debug)

///|
pub fn default_input_diagnostic_limits() -> InputDiagnosticLimits {
  { max_work: 500000, max_expectations: 16, }
}

///|
pub(all) struct InputFailure {
  offset : Int32
  actual : Int32?
  expected : Array[ExpectedInput]
  truncated : Bool
} derive(Eq, Debug)

///|
/// match is the unchanged recognition result. explanation_status describes only
/// the separately budgeted explanatory replay (not another acceptance verdict).
pub(all) struct InputDiagnosticReport {
  report : MatchReport
  failure : InputFailure?
  explanation_status : String
  explanation_work : Int32
} derive(Eq, Debug)

///|
priv struct FailureCollector {
  max_expectations : Int32
  mut offset : Int32
  expected : Array[ExpectedInput]
  mut truncated : Bool
}

///|
fn Runner::expect(
  self : Runner,
  at : Int32,
  expectation : InputExpectation,
  source : Int32,
) -> Unit raise MatchStop {
  match self.failures {
    None => ()
    Some(f) => {
      self.tick(at)
      if at < f.offset {
        return
      }
      if at > f.offset {
        f.offset = at
        f.expected.clear()
        f.truncated = false
      }
      let item = {
        expectation,
        grammar_offset: if source > 0 {
          Some(source)
        } else {
          None
        },
      }
      for old in f.expected {
        self.tick(at)
        if old == item {
          return
        }
      }
      if f.expected.length() >= f.max_expectations {
        f.truncated = true
      } else {
        f.expected.push(item)
      }
    }
  }
}

///|
/// Explain a NoMatch using bounded local expectations at the farthest observed
/// failed terminal/complete-prefix endpoint. Not a unique repair or full trace.
/// Successful/unknown recognition is never overwritten by exploratory failure.
pub fn Program::diagnose_input(
  self : Program,
  start : String,
  input : Bytes,
  limits~ : MatchLimits = default_match_limits(),
  diagnostic_limits~ : InputDiagnosticLimits = default_input_diagnostic_limits(),
) -> InputDiagnosticReport {
  let report = self.recognize(start, input, limits~)
  if report.status != NoMatch {
    return {
      report,
      failure: None,
      explanation_status: "not-applicable",
      explanation_work: 0,
    }
  }
  if !self.productive.contains(lower_name(start)) {
    return {
      report,
      failure: None,
      explanation_status: "empty-language",
      explanation_work: 0,
    }
  }
  if self.left_recursive {
    return {
      report,
      failure: None,
      explanation_status: "generalized-explanation-unavailable",
      explanation_work: 0,
    }
  }
  if diagnostic_limits.max_work < 1 ||
    diagnostic_limits.max_work > 10000000 ||
    diagnostic_limits.max_expectations < 1 ||
    diagnostic_limits.max_expectations > 128 {
    return {
      report,
      failure: None,
      explanation_status: "invalid-diagnostic-limits",
      explanation_work: 0,
    }
  }
  let failures = {
    max_expectations: diagnostic_limits.max_expectations,
    offset: -1,
    expected: [],
    truncated: false,
  }
  let runner = {
    program: self,
    input: ByteSymbols(input),
    limits: { ..limits, max_work: diagnostic_limits.max_work, },
    work: 0,
    states: 0,
    furthest: 0,
    failures: Some(failures),
    chart: Map([]),
  }
  let status = try {
    let ends = runner.eval(self.rules[lower_name(start)], 0, 0)
    for at in ends {
      runner.tick(at)
      if at < input.length() {
        runner.expect(at, EndOfInput, 0)
      }
    }
    if failures.truncated {
      "truncated"
    } else {
      "complete"
    }
  } catch {
    MatchStop(reason) => {
      failures.truncated = true
      "budget-exceeded:" + reason
    }
  }
  let failure = if failures.offset < 0 {
    None
  } else {
    Some({
      offset: failures.offset,
      actual: if failures.offset < input.length() {
        Some(input[failures.offset].to_int())
      } else {
        None
      },
      expected: failures.expected,
      truncated: failures.truncated,
    })
  }
  {
    report,
    failure,
    explanation_status: status,
    explanation_work: runner.work,
  }
}

///|
pub extend InputExpectation with Eq::{equal, not_equal}

///|
pub extend InputExpectation with @debug.Debug::{to_repr}

///|
pub extend ExpectedInput with Eq::{equal, not_equal}

///|
pub extend ExpectedInput with @debug.Debug::{to_repr}

///|
pub extend InputDiagnosticLimits with Eq::{equal, not_equal}

///|
pub extend InputDiagnosticLimits with @debug.Debug::{to_repr}

///|
pub extend InputFailure with Eq::{equal, not_equal}

///|
pub extend InputFailure with @debug.Debug::{to_repr}

///|
pub extend InputDiagnosticReport with Eq::{equal, not_equal}

///|
pub extend InputDiagnosticReport with @debug.Debug::{to_repr}

///|
/// Optional adapter representation, separate from the existing match JSON schema.
pub fn InputDiagnosticReport::to_json(self : InputDiagnosticReport) -> Json {
  let failure : Json = match self.failure {
    None => {
      let empty : Int32? = None
      @json.to_json(empty)
    }
    Some(f) => {
      let expected = f.expected.map(e => {
        let (kind, lo, hi, insensitive) = match e.expectation {
          EndOfInput => ("eof", -1, -1, false)
          ByteRange(lo, hi, ci) => ("byte-range", lo, hi, ci)
        }
        @json.to_json(
          Map([
            ("kind", Json(kind)),
            ("lo", Json(lo)),
            ("hi", Json(hi)),
            ("ascii_case_insensitive", Json(insensitive)),
            ("grammar_offset", diagnostic_optional_int(e.grammar_offset)),
          ]),
        )
      })
      @json.to_json(
        Map([
          ("offset", Json(f.offset)),
          ("actual", diagnostic_optional_int(f.actual)),
          ("expected", Json(expected)),
          ("truncated", Json(f.truncated)),
        ]),
      )
    }
  }
  @json.to_json(
    Map([
      ("explanation_status", Json(self.explanation_status)),
      ("explanation_work", Json(self.explanation_work)),
      ("failure", failure),
    ]),
  )
}

///|
fn diagnostic_optional_int(value : Int32?) -> Json {
  match value {
    Some(n) => Json(n)
    None => {
      let empty : Int32? = None
      @json.to_json(empty)
    }
  }
}
