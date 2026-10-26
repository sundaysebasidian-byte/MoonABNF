# RFC3339：安装版字段提取

2026-10-26，用 registry **MoonABNF 0.3.0**、moonc **0.10.15**、JS + Node **24.18.0** 实测，无 workspace/path 覆盖。

输入来自 [RFC3339 §5.8](https://www.rfc-editor.org/rfc/rfc3339.html#section-5.8)，文法来自 §5.6。两条样例分别提取 `Z` 的 `[22,23)`、`-08:00` 的 `[19,25)`。自编负例 `-08:GG` 在字节 23 失败：实际为 `G`（71），局部期望为数字（48..57）。

## 复现

在仓库外的新目录下载 RFC 原文并保留其版权声明：Copyright © The Internet Society (2002), All Rights Reserved。上游文字不改标为项目 MIT。

```sh
mkdir rfc3339-consumer && cd rfc3339-consumer
curl -fL https://www.rfc-editor.org/rfc/rfc3339.txt -o rfc3339.txt
printf 'name = "local/rfc3339-demo"\nversion = "0.1.0"\n' > moon.mod
moon add sundaysebasidian-byte/moonabnf@0.3.0
python3 - <<'PYCODE'
from pathlib import Path
import hashlib
raw = Path('rfc3339.txt').read_bytes()
assert hashlib.sha256(raw).hexdigest() == '9ab2b8864a85dca73a88f49b0927bc7bc85f596926e4fd1890905777924e700a'
text = raw.decode()
start = text.index('   date-fullyear   =')
end = text.index('      NOTE:', start)
grammar = '\r\n'.join(line[3:] for line in text[start:end].splitlines()).strip() + '\r\n'
Path('rfc3339.abnf').write_bytes(grammar.encode())
PYCODE
export CASE_GRAMMAR="$PWD/rfc3339.abnf"
```

创建 `moon.pkg`：

```moonbit
import { "sundaysebasidian-byte/moonabnf" @abnf }
options(is_main: true)
```

创建 `main.mbt`：

```moonbit
extern "js" fn grammar_bytes() -> Bytes =
  #| () => new Uint8Array(require('node:fs').readFileSync(process.env.CASE_GRAMMAR))

fn check(program : @abnf.Program, input : Bytes, expected : Bytes) -> Unit raise {
  let report = program.parse_input("date-time", input)
  assert_eq(report.status, @abnf.Matched)
  let tree = report.tree.unwrap()
  let ids = tree.rule_nodes_in("time-offset", tree.root).unwrap()
  assert_eq(ids.length(), 1)
  let id = ids[0]
  assert_eq(tree.extract(input, id).unwrap(), expected)
  let (start, end) = tree.span(id).unwrap()
  println("PASS: input=\{input}; time-offset [\{start},\{end})=\{expected}")
}

fn main raise {
  let program = match @abnf.compile(grammar_bytes()) {
    Ok(program) => program
    Err(d) => fail("grammar \{d.code} at byte \{d.offset}")
  }
  check(program, b"1985-04-12T23:20:50.52Z", b"Z")
  check(program, b"1996-12-19T16:39:57-08:00", b"-08:00")
  let invalid = program.diagnose_input("date-time", b"1996-12-19T16:39:57-08:GG")
  assert_eq(invalid.report.status, @abnf.NoMatch)
  let failure = invalid.failure.unwrap()
  println(invalid.to_json().stringify())
  assert_eq(failure.offset, 23)
  assert_eq(failure.actual, Some(71))
  println("PASS: invalid offset byte=\{failure.offset}, actual=\{failure.actual.unwrap()}, local expectations=\{failure.expected.length()}")
  // Section 5.6 grammar alone does not enforce section 5.7 semantic ranges.
  assert_eq(program.recognize("date-time", b"1996-99-99T99:99:99Z").status, @abnf.Matched)
  println("BOUNDARY: grammar accepts 1996-99-99T99:99:99Z; calendar and leap-second validation is separate")
}
```

```sh
moon run . --target js -j 1
moon tree --json  # moonabnf 应为 0.3.0、source.kind=registry
```

该流程实际退出 0。§5.6 文法也接受 `1996-99-99T99:99:99Z`：月份天数、时间范围、闰秒及 §5.7 的语义限制需另行校验。这不是完整日期合法性验证或外部用户采用证明。
