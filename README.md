# MoonABNF

[![CI](https://github.com/sundaysebasidian-byte/MoonABNF/actions/workflows/ci.yml/badge.svg)](https://github.com/sundaysebasidian-byte/MoonABNF/actions/workflows/ci.yml)
[![Fresh clone](https://github.com/sundaysebasidian-byte/MoonABNF/actions/workflows/fresh-clone.yml/badge.svg)](https://github.com/sundaysebasidian-byte/MoonABNF/actions/workflows/fresh-clone.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

用 MoonBit 写的字节级 ABNF 库：**直接拿 RFC 里的 ABNF 文法校验协议字段，不用手写解析器。**

文法文本 → 文法 AST → 编译校验 → 整段识别 / 输入派生树 → 按规则名取出原字节字段。
实现依据 [RFC 5234](https://www.rfc-editor.org/rfc/rfc5234)（ABNF）与 [RFC 7405](https://www.rfc-editor.org/rfc/rfc7405)（大小写敏感字符串）。

适合：协议字段离线诊断、配置格式校验、二进制 fixture 回归、把 RFC 文法变成可执行的测试。

**0.3.0 已正式发布**，包含输入派生树、字段提取与有界输入失败诊断。[发布版本及验证范围](docs/release-0.3.0.zh-CN.md)；[评审问题证据索引](docs/REVIEW_EVIDENCE_INDEX.zh-CN.md)；[技术补审草稿（供用户审阅）](docs/REVIEW_RESUBMISSION_DRAFT.zh-CN.md)。

## 快速开始

需要 MoonBit 工具链（CI 锁定 `moonc v0.10.14+7d59c7ec9`，见 [TOOLCHAIN.lock](TOOLCHAIN.lock)）和 Node.js。

```sh
git clone https://github.com/sundaysebasidian-byte/MoonABNF.git
cd MoonABNF
moon test                                     # 全部单元测试
moon run examples --target js                 # 协议 / 配置 / 二进制三个小场景
moon run examples/protocols/cmd --target js   # URI 与 Cookie：输入树和字段提取
```

在自己的项目里使用：

```sh
moon add sundaysebasidian-byte/moonabnf@0.3.0
```

0.3.0 保留原识别与输入树 API，新增 `Program::diagnose_input` 及显式诊断 JSON 序列化。已从 registry 精确安装验证核心、输入树与诊断的四后端消费；协议 JSON 适配器仍是需复制的 JS 集成示例。历史 [0.2.1 说明](docs/release-0.2.1.zh-CN.md)保留原证据日期，不替代本次发布回执。

```moonbit
// moon.pkg
import { "sundaysebasidian-byte/moonabnf" @abnf }
```

> [当前安装版本 0.3.0](https://mooncakes.io/docs/sundaysebasidian-byte/moonabnf@0.3.0/)：包含 `parse` / `compile` / `recognize` 以及输入派生树与字段提取（`parse_input`、`rule_nodes_in`、`extract`）。全新 registry 消费者已验证 Wasm、Wasm GC、JS 和 native；JS JSON 协议适配为需复制的 [集成示例](integration/protocol_consumer/main.mbt.in)，使用公开核心 API 和 `examples/protocols` 文法子包，并非根包 JSON 导出。

## 用法

### 1. 校验一个字段

```moonbit
match @abnf.compile(b"field = %i\"Trace\" \":\" SP 1*8HEXDIG CRLF\r\n") {
  Err(d) => println("\{d.code} at line \{d.line}, column \{d.column}")
  Ok(program) => {
    let r = program.recognize("field", b"TRACE: aF12\r\n")
    assert_true(r.status is @abnf.Matched)
  }
}
```

文法写错时得到带错误码、字节偏移和行列号的 `Diagnostic`，例如 `undefined-rule`、`left-recursion`、`duplicate-rule`。

### 2. 取出字段的原始字节

```moonbit
let program = @abnf.compile(
  b"record = key \":\" value\r\nkey = 1*ALPHA\r\nvalue = 1*DIGIT\r\n",
).unwrap()
let input = b"Age:42"
let report = program.parse_input("record", input)
match report.status {
  @abnf.Matched => {
    let tree = report.tree.unwrap()
    let ids = tree.rule_nodes_in("value", tree.root).unwrap()
    assert_eq(tree.extract(input, ids[0]), Some(b"42"))
  }
  @abnf.NoMatch => println("no-match at byte \{report.offset}")
  @abnf.BudgetExceeded(why) => println("indeterminate: \{why}")
  _ => ()
}
```

本页代码片段都在 [readme_test.mbt](readme_test.mbt) 中作为测试运行；完整示例见 [examples/input_tree/main.mbt](examples/input_tree/main.mbt)。

### 3. 用真实 RFC 文法

[examples/protocols](examples/protocols) 直接使用 RFC 3986（URI）和 RFC 6265（Cookie）的 ABNF，输出输入树前三层和各组件的字节跨度：

```text
URI components (syntax only, no percent decoding):
  scheme=[0,5) raw=b"https"
  host=[8,21) raw=b"[2001:db8::1]"
  port=[22,26) raw=b"8443"
  ...
Cookie pairs (duplicates and quotes preserved):
  cookie-name=[0,7) raw=b"session"
  cookie-value=[8,11) raw=b"abc"
  ...
Invalid Cookie: no-match at byte 11
Limited Cookie: indeterminate (tree-nodes), tree absent=true
```

另有 RFC 9110 ETag（[examples/http_etag](examples/http_etag)）与 RFC 9112 请求行（[examples/request_line](examples/request_line)）示例，输出都与仓库里的 `expected_output.txt` 逐字节比对。

实际应用：[离线采集记录导入门禁](docs/PROTOCOL_RECORD_CASE.zh-CN.md)复用独立URI/Cookie消费者，
把规范原例子转换为带字节span的JSON字段；用不同退出码区分语法拒绝、预算未判定和配置错误。
只有两字段均匹配才导出数据，并与仅识别的现有API作具体对照；不宣称完整HTTP支持或生产采用。

### 4. 命令行

```sh
scripts/cli.sh check fixtures/protocol.abnf
scripts/cli.sh match fixtures/protocol.abnf field fixtures/protocol-valid.bin
```

输出 JSON，退出码可直接用于脚本门禁。

## 规范覆盖

| RFC 5234 / 7405 | 支持 |
| --- | --- |
| 规则定义 `=`、增量替代 `=/`，规则名大小写不敏感 | ✅ |
| 替代 `/`、串联、分组 `( )`、可选 `[ ]` | ✅ |
| 重复 `n*m`、`*m`、`n*`、`*`、`n` | ✅ |
| 数值 `%b` `%d` `%x`：单值、点连接序列、区间 | ✅ |
| 字符串：默认大小写不敏感，`%i` / `%s`（RFC 7405） | ✅ |
| 注释、CRLF 行结构 | ✅ |
| 附录 B 核心规则 ALPHA … WSP（16 条） | ✅ 内置，可被同名规则覆盖 |
| prose-val `<...>` | 解析进 AST；编译时报 `prose-unsupported` |

编译阶段检查未定义规则、重复定义、不产生任何串的规则，以及左递归 / 可空前缀循环。

## 设计取舍

- **两棵树分开**：文法 AST 描述文法本身，输入派生树描述某段输入怎样被匹配。
- **ABNF 不是 PEG**：替代分支会保留全部可能的结束位置，不会因为先匹配到短的分支就错判。
- **资源有预算**：输入长度、工作量、状态数、深度、树节点都有上限。预算用完返回 `BudgetExceeded`（未判定），不会被当成“不匹配”。
- **偏移是字节**：跨度是半开字节区间，`extract` 从调用方保存的原始输入里复制，不做 URI 解码或去引号。
- 不做：Unicode 数值终端、错误恢复、代码生成、流式输入、歧义全枚举，以及 URI/Cookie 的语义层规则。

详细契约见 [边界说明](docs/BOUNDARIES.zh-CN.md) 和 [输入树上手](docs/INPUT_TREE_QUICKSTART.zh-CN.md)，公开接口见 [pkg.generated.mbti](pkg.generated.mbti)。

## 测试

- 单元与场景测试：解析器、编译器、识别器、输入树、边界、鲁棒性（1024 个变异文法、预算终止）。
- 差分测试：随机生成 80 个文法、5440 次比对，结果与独立的正则 oracle 一致（`scripts/differential.py`）。
- 真实协议语料：URI、Cookie、ETag、HTTP 请求行。
- CI：[ci.yml](.github/workflows/ci.yml) 在官方 SDK 上跑完整验收（JS / Wasm / Wasm GC / native 的 check、build、test，示例、CLI、差分、下游包消费）；[fresh-clone.yml](.github/workflows/fresh-clone.yml) 模拟新用户 `git clone` 后直接 `moon check`、`moon test` 和本页的快速开始。

本地完整验收：`python3 scripts/acceptance.py --output /tmp/moonabnf-evidence`。
各轮验证的命令、版本和结果记录在 [docs/VERIFICATION_20261022.zh-CN.md](docs/VERIFICATION_20261022.zh-CN.md) 和 `evidence/`。

## 目录

| 路径 | 内容 |
| --- | --- |
| `parser.mbt` `types.mbt` | ABNF 文本 → 文法 AST |
| `compiler.mbt` `analysis.mbt` `core.mbt` | 规则合并、核心规则、引用 / 生产性 / 左递归检查 |
| `recognizer.mbt` | 有预算的整段识别 |
| `input_tree.mbt` `input_query.mbt` | 输入派生树、子树查询、字段提取 |
| `cmd/main` | JSON 命令行 |
| `examples/` | 可运行示例与黄金输出 |
| `fixtures/` | 测试文法与 RFC 文法语料（来源见 [fixtures/protocols/SOURCES.md](fixtures/protocols/SOURCES.md)） |

## 许可与来源

代码 MIT（[LICENSE](LICENSE)）。从 RFC 摘录的 URI / Cookie / HTTP 文法保留原有归属，不改称 MIT 原创，出处与哈希见 [SOURCES.md](SOURCES.md)。
开发中 AI 的参与方式见 [AI_USAGE.md](AI_USAGE.md)，设计说明见 [docs/UNDERSTANDING.md](docs/UNDERSTANDING.md)。

### 0.3.0：有界输入失败解释

已发布入口 `program.diagnose_input(rule, input)` 保留原 `MatchReport`，仅对
`NoMatch` 作额外有界重放。`failure` 含局部最远失败字节、`actual` 字节整数或
EOF(None)、有限期望字节范围/ASCII 大小写语义或 EOF，以及可确定的原文法
terminal expression 起点 `grammar_offset`；内建 core terminal 和 EOF 的位置为 None。
它不是唯一修复建议，也不枚举全部失败路径。成功或 `BudgetExceeded` 不产生失败解释。

`diagnostic_limits={ max_work: 500000, max_expectations: 16 }` 独立限制额外重放；
工作包含重放、期望收集及去重，期望硬上限128。`explanation_status` 和
`failure.truncated` 区分解释预算不足/截断与原匹配判定；原接受集合、树与匹配预算不变。
`InputDiagnosticReport.to_json()` 只序列化解释，不另作接受判定。

仓库 CLI 可用 `moon run cmd/main --target js -- diagnose grammar.abnf rule input.bin [work-budget]`；
原 `match` 输出不变。JSON 案例须用独立 `main.diagnostics.mbt.in` 扩展模板，
`python3 scripts/protocol_record_test.py --diagnostics --output /new/external/evidence`
验证后，可在该消费者的 `--json URI COOKIE [node-budget]` 最后加 `--diagnostics`。
未加标志时黄金及退出0/1/3/2不变。原模板和 registry 消费者保持兼容已发布0.2.1；
**诊断核心 API 已包含于 0.3.0；扩展 JSON 模板是可复制的 JS 示例，不是根包直接导出的协议适配器。**

新手可先运行 `moon run examples/diagnostics --target js`：URI `%GG`、Cookie 空格、
截断与尾随空格四例会显示原字节上下文、实际字节/EOF和局部期望，再对人工选择的合法
修订重新解析并提取字段。它不自动更改输入，也不把预算不足当拒绝；示例使用合成协议字段。
