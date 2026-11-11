# MoonABNF

[![CI](https://github.com/sundaysebasidian-byte/MoonABNF/actions/workflows/ci.yml/badge.svg)](https://github.com/sundaysebasidian-byte/MoonABNF/actions/workflows/ci.yml)
[![Fresh clone](https://github.com/sundaysebasidian-byte/MoonABNF/actions/workflows/fresh-clone.yml/badge.svg)](https://github.com/sundaysebasidian-byte/MoonABNF/actions/workflows/fresh-clone.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

MoonABNF 用 MoonBit 实现 ABNF 解析，保留字节 API，当前源码另有独立 Unicode scalar 应用域。调用方提供文法，编译后可识别完整输入、生成输入派生树并提取字段。

文法文本 → 文法 AST → 编译校验 → 整段识别 / 输入派生树 → 按规则名取出原字节字段。
实现依据 [RFC 5234](https://www.rfc-editor.org/rfc/rfc5234)（ABNF）与 [RFC 7405](https://www.rfc-editor.org/rfc/rfc7405)（大小写敏感字符串）。

适合：协议字段离线诊断、配置格式校验、二进制 fixture 回归、把 RFC 文法变成可执行的测试。

## 先选择源码还是已发布包

| 交付物 | 能力与工具链 | 入口 |
| --- | --- | --- |
| 当前源码 | Bytes API、预算内左递归识别 / 输入树、独立 Unicode scalar API、显式组合 prose；工具链锁定 `moonc 0.10.20+65efd5b93`（`moon 0.1.20261104`），需要 MoonBit 0.10.20 及以上 | [技术证据与复现](docs/TECHNICAL_EVIDENCE.zh-CN.md)、[scalar / prose](docs/SCALAR_PROSE_EXTENSION_20261030.md)、[左递归边界](docs/LEFT_RECURSION_REVIEW_20261030.md) |
| Mooncakes 0.3.0 | 已发布的 Bytes API、输入派生树、字段提取与有界失败诊断；历史锁定工具链为 `0.10.14+7d59c7ec9` | [0.3.0 版本说明](docs/release-0.3.0.zh-CN.md) |

**源码新增能力不属于已发布的 0.3.0。** 当前源码的 `moon.mod` 仍保留 0.3.0；这个版本字段不是再次发布或覆盖旧包的凭据。源码分支、GitHub Release 和 Mooncakes 发布应分别核验。

## 当前源码快速开始

准备 [TOOLCHAIN.lock](TOOLCHAIN.lock) 中的已有 MoonBit SDK，以及 Node.js、Python 3 和 native 后端需要的 C 工具链。以下示例假定 POSIX shell；不是 Windows 原生执行验证。

```sh
git clone https://github.com/sundaysebasidian-byte/MoonABNF.git
cd MoonABNF
export MOONABNF_SDK=/absolute/path/to/existing/locked-sdk
scripts/moon-local.sh version --all
scripts/moon-local.sh test --target js
scripts/moon-local.sh run examples --target js
scripts/moon-local.sh run examples/protocols/cmd --target js
scripts/moon-local.sh run examples/scalar_prose --target native
```

`moon-local.sh` 会核对编译器版本（`v0.10.20+65efd5b93`）。**版本要求：MoonBit 0.10.20 及以上**——源码使用该版本的 `#derive` 语法，0.10.18 无法编译；旧的 `derive(...)` 写法在 0.10.20 上会产生 `deprecated_syntax` 告警并使 `moon check --deny-warn` 失败。已发布的 Mooncakes 0.3.0 仍对应其历史工具链。[fresh-clone.yml](.github/workflows/fresh-clone.yml) 同时在锁定 SDK 与最新官方 SDK 上运行，并每周定时执行。复现特定结果时还须检出对应提交，并保留本地补丁；验收脚本会记录 Git HEAD、工作树状态与源码 SHA-256，不把旧分支日志当作当前源码的测试结果。

## Mooncakes 0.3.0 快速开始

只需已发布功能时，在自己的项目里指定精确版本：

```sh
moon add sundaysebasidian-byte/moonabnf@0.3.0
```

```moonbit
// moon.pkg
import { "sundaysebasidian-byte/moonabnf" @abnf }
```

> [mooncakes 上的 0.3.0](https://mooncakes.io/docs/sundaysebasidian-byte/moonabnf@0.3.0/) 包含 `parse` / `compile` / `recognize`、输入派生树与字段提取（`parse_input`、`rule_nodes_in`、`extract`）和 `diagnose_input`，已从 registry 全新安装并在 Wasm、Wasm GC、JS、native 上验证。协议集成方式见下文。

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

文法写错时得到带错误码、字节偏移和行列号的 `Diagnostic`，例如 `undefined-rule`、`prose-unsupported`、`duplicate-rule`。

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

### 5. 解释为什么不匹配

`program.diagnose_input(rule, input)` 在不匹配时返回局部最远失败字节、实际输入字节或 EOF，以及有限期望集合。诊断使用独立预算，不改变原 `MatchReport`；`BudgetExceeded` 为未判定，而非 `NoMatch`。局部解释不代表唯一修复。

```sh
moon run examples/diagnostics --target js
moon run cmd/main --target js -- diagnose grammar.abnf rule input.bin
```

示例覆盖 URI `%GG`、非法 Cookie 空格、截断与尾随字节。完整契约见 [0.3.0 说明](docs/release-0.3.0.zh-CN.md)和[公开接口](pkg.generated.mbti)。

协议 JSON 适配器是 [integration/protocol_consumer](integration/protocol_consumer) 下可复制的 JS 示例，不是根库导出；诊断扩展模板和运行方式见[协议案例](docs/PROTOCOL_RECORD_CASE.zh-CN.md)。

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
| prose-val `<...>` | 原compile仍拒绝；compile_with_prose/compile_scalar接受显式词表、单符号范围及Concat/Alternative/Repetition组合；组合可表达无限语言，但执行仍有预算 |

编译阶段检查未定义规则和重复定义；无有限终结推导的闭合规则视为空语言；左递归 / 可空前缀循环改用有预算不动点识别与输入树路径，不再直接拒绝。

## 设计取舍

- **两棵树分开**：文法 AST 描述文法本身，输入派生树描述某段输入怎样被匹配。
- **ABNF 不是 PEG**：替代分支会保留全部可能的结束位置，不会因为先匹配到短的分支就错判。
- **按入口选择算法**：只有静态引用可达左递归环的入口使用不动点求解；不相关规则不改变普通入口的预算和局部诊断。已消耗前缀后的左递归仍正确支持，0 次重复不会引入调用。
- **资源有预算**：输入长度、工作量、状态数、深度、树节点都有上限。预算用完返回 `BudgetExceeded`（未判定），不会被当成“不匹配”。
- **偏移单位按入口分开**：Bytes树跨度是半开字节区间，ScalarInputTree跨度是scalar索引；文法位置始终是字节。extract使用对应输入类型，不做URI/UTF解码。
- 不做：任意外部编码/无限整数、自然语言prose解释或通用回调、错误恢复、代码生成、流式输入、歧义全枚举，以及URI/Cookie语义层规则。

详细契约见 [边界说明](docs/BOUNDARIES.zh-CN.md) 和 [输入树上手](docs/INPUT_TREE_QUICKSTART.zh-CN.md)，公开接口见 [pkg.generated.mbti](pkg.generated.mbti)。

## 测试

测试结果须绑定实际检出与补丁。历史 `c89f804` 的 90 / 93 组测试不是当前版本的验收结论；当前数量和退出码以本次运行输出为准。[技术证据索引](docs/TECHNICAL_EVIDENCE.zh-CN.md) 给出完整验收、独立源码消费者及证据读取方法。

- 单元与场景测试：解析器、编译器、识别器、输入树、边界、鲁棒性（1024 个变异文法、预算终止）。
- 差分测试：随机生成 80 个文法、5440 次比对，结果与独立的正则 oracle 一致（`scripts/differential.py`）。
- 真实协议语料：URI、Cookie、ETag、HTTP 请求行。
- CI：[ci.yml](.github/workflows/ci.yml) 在官方 SDK 上跑完整验收（JS / Wasm / native 的 check、build、test，Wasm GC 的 test，以及示例、CLI、差分、下游包消费）；[fresh-clone.yml](.github/workflows/fresh-clone.yml) 模拟新用户 `git clone` 后直接 `moon check`、`moon test` 和本页的快速开始。

设置上述 `MOONABNF_SDK` 后运行完整验收，输出路径必须尚不存在（包括空目录）：

```sh
python3 scripts/acceptance.py --output /tmp/moonabnf-acceptance-new-run
python3 scripts/protocol_record_test.py --diagnostics --output /tmp/moonabnf-protocol-new-run
```

第一项保存逐阶段原始 stdout / stderr、退出码、`summary.json` 与 `SHA256.json`；超时、监控、Git 元数据或源码读取失败，以及运行前后源码变动，均不能标为通过；须在无并发写入的隔离副本执行。第二项测试实际打包后的源码绑定消费者，**不是 registry 安装**。每次使用新的路径，保留失败回执后再修复重验；不要覆盖历史证据。

## 性能

以下是旧发布版历史性能数据，不是当前源码的重新测量。`moon bench --release` 实测，每项 5 组取平均；GitHub Actions ubuntu-24.04（AMD EPYC 9V45 96-Core Processor，4 个逻辑 CPU），moonc v0.10.14。

| 场景 | 输入 | JS | native |
| --- | --- | --- | --- |
| 编译 URI 文法 | — | 122 µs | 74.5 µs |
| 识别 URI（IPv6 主机） | 40 B | 56.1 µs | 40.6 µs |
| 构建 URI 派生树 | 40 B | 152 µs | 119 µs |
| 编译 Cookie 文法 | — | 21.1 µs | 15.7 µs |
| 识别 Cookie 头 | 33 B | 13.0 µs | 10.8 µs |
| 构建 Cookie 派生树 | 33 B | 38.0 µs | 32.4 µs |
| 识别定长二进制字段 | 4096 B | 255 µs | 192 µs |
| 构建定长二进制派生树 | 4096 B | 2.21 ms | 1.59 ms |
| 32 个 Cookie 对的子树查询 | 32 对 | 89.4 µs | 51.8 µs |

数字只说明数量级，换机器会变。复现：`moon bench benchmarks --target native --release`；CI 见 [bench.yml](.github/workflows/bench.yml)，本表来自[这次运行](https://github.com/sundaysebasidian-byte/MoonABNF/actions/runs/40287620677)。

## 目录

| 路径 | 内容 |
| --- | --- |
| `parser.mbt` `types.mbt` | ABNF 文本 → 文法 AST |
| `compiler.mbt` `analysis.mbt` `core.mbt` | 规则合并、核心规则、引用 / 生产性 / 左递归检查 |
| `recognizer.mbt` | 有预算的整段识别 |
| `input_tree.mbt` `input_query.mbt` | 输入派生树、子树查询、字段提取 |
| `cmd/main` | JSON 命令行 |
| `examples/` | 可运行示例与黄金输出 |
| `benchmarks/` | `moon bench` 基准 |
| `fixtures/` | 测试文法与 RFC 文法语料（来源见 [fixtures/protocols/SOURCES.md](fixtures/protocols/SOURCES.md)） |

## 许可与来源

代码 MIT（[LICENSE](LICENSE)）。从 RFC 摘录的 URI / Cookie / HTTP 文法保留原有归属，不改称 MIT 原创，出处与哈希见 [SOURCES.md](SOURCES.md)。
开发中 AI 的参与方式见 [AI_USAGE.md](AI_USAGE.md)，设计说明见 [docs/UNDERSTANDING.md](docs/UNDERSTANDING.md)。

重复次数的十进制语法计数目前限制为 1,000,000；超出会被实现拒绝。这是资源实现边界，不是 RFC 5234 对合法 ABNF 的限制。

### CLI I/O error records

For valid `check`, `match`, `diagnose`, and `batch` invocations, a failed grammar/input regular-file read emits a JSON object with `status: "io-error"`, `stage: "grammar"` or `"input"`, and `file`. The detailed operating-system cause remains on stderr. Batch input read failures keep their original position and do not suppress later results. Exit 2 signals usage/grammar/I/O errors; an encountered indeterminate budget result keeps exit 3 even when another input fails to read. A missing/unrecognized command prints human-readable usage rather than a JSON result; consumers must check exit status and stderr. Build output goes to stderr. This does not change FIFO/nonregular-file rejection or the bounded reader.

Read completion includes closing the opened descriptor: a close failure produces the same structured I/O refusal, never a successful match. If both reading and closing fail, both causes remain on stderr and later batch inputs still run. This is a CLI filesystem-adapter guarantee, not a change to grammar recognition.
