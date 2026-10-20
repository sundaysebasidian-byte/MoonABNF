# MoonABNF

MoonBit 实现的 ABNF 文法解析、编译验证、有界字节识别和输入派生树库，依据
[RFC 5234](https://www.rfc-editor.org/info/rfc5234/) 与
[RFC 7405](https://www.rfc-editor.org/info/rfc7405/)。适合协议字段、配置输入和二进制 fixture 校验。
项目使用 MIT，仓库地址为 https://github.com/sundaysebasidian-byte/MoonABNF 。
正式模块名为 `sundaysebasidian-byte/moonabnf`，已发布版本 `0.1.0`。
[Mooncakes 文档](https://mooncakes.io/docs/sundaysebasidian-byte/moonabnf@0.1.0/) ·
[发布证据](docs/PUBLICATION.md)。

## 状态一览（2026-10-18 整改后；先读这里）

本仓库同时含有**已发布的 0.1.0**和**尚未发布的候选**（输入解析树等）。`moon.mod` 未改版本号，候选没有新版本。二者不要混读。

| 能力 | 0.1.0 正式包 | 本分支候选（未发布） |
|---|---|---|
| `parse` 文法 AST、`compile` 校验、`Program::recognize` 有界字节识别 | 已实现并发布 | 保留 |
| 输入解析树 `Program::parse_input` → `InputTreeReport`/`InputTree`/`InputNode`（规则/字面量/区间/序列/分支/重复节点，字节跨度） | **没有**（安装 0.1.0 后查看，无 `parse_input`） | 已实现 |
| 真实协议：RFC 9110 ETag 字段值 | 无 | `examples/http_etag`（已有） |
| 真实协议：RFC 9112 HTTP 请求行（origin-form）解析树 + 字段提取 | 无 | `examples/request_line`（本轮新增） |
| CLI（check / match / batch） | 有（只做识别，不出树） | 同，不出树 |
| 全部歧义枚举（解析森林）、代码生成、错误恢复、Unicode 数值终端、流式识别、左递归 | 不支持 | 不支持（左递归在编译期拒绝） |

**关于“通用 ABNF 解析器”（初审意见）**：候选可以编译任何符合 RFC 5234/7405 的文法（有预算与左递归限制），并对任意输入给出一棵派生树，歧义时保留首次遇到的路径，不是 PEG，也不枚举全部解析。它是字节级的；协议语义（例如 HTTP 方法是否被允许、URI 是否可解析）不在范围内。

### 验证结果分开列（候选）

| 层面 | 结果 |
|---|---|
| 本地，锁定工具链（`moon 0.1.20260920 (914d7da)`、`moonc v0.10.14+7d59c7ec9`、Node v24.18.0，macOS arm64） | `moon test` 在 js / wasm-gc / native / wasm 各 **41/41**（其中 5 项为本轮新增的请求行用例；起点基线为 36/36）。`python3 scripts/acceptance.py` 全部 18 个阶段通过（格式、消费者证据防伪测试 `consumer-guards`、四后端 check/build/test、`examples`、`example-request-line`、cli、differential、downstream）；CI 同样执行这 18 个阶段 |
| 远端 CI | 候选**未运行**（未推送）。0.1.0 的旧 Linux CI 记录见 `docs/PUBLICATION.md` |
| 注册表 | 候选未发布，不适用。0.1.0 已用 `moon add …@0.1.0` 安装查看，确认不含输入树 API |

本轮日志：`evidence/review-20261018/`。

### 请求行示例（真实协议、解析树、字段提取，本轮实跑）

```sh
moon run examples/request_line/cmd --target js
```

输入 `GET /search/a%20b?q=moon&n=2 HTTP/1.1\r\n`（文法取自 RFC 9112 §3 的 request-line，路径/查询取自 RFC 3986 的 pchar 等规则，**只覆盖 origin-form 目标**），输出的解析树（隐藏 `tchar`/`pchar`）与提取：

```text
request-line [0,39) "GET /search/a%20b?q=moon&n=2 HTTP/1.1\r\n"
  method [0,3) "GET"
  sp [3,4) " "
  request-target [4,28) "/search/a%20b?q=moon&n=2"
    absolute-path [4,17) "/search/a%20b"
    query [18,28) "q=moon&n=2"
  sp [28,29) " "
  http-version [29,37) "HTTP/1.1"
    digit [34,35) "1"
    digit [36,37) "1"
  crlf [37,39) "\r\n"
fields: method=b"GET" path=[4,17) HTTP/1.1
        query=[18,28)
```

`python3 scripts/example_request_line.py`（已并入 `scripts/acceptance.py` 和 CI）在 js / wasm-gc / native 上运行该示例，输出必须与 `examples/request_line/cmd/expected_output.txt` 逐字节一致，其中含 1 个合法请求行（树与字段提取）和 4 个非法输入的拒绝偏移；脚本带自检，输出被改动（含偏移改动、截断、多余字节）时判失败。

负例同样实跑：`GET index.html HTTP/1.1\r\n`（目标不是 `/` 开头，byte 4 不匹配）、缺 CRLF、路径含空格、小写 `http/1.1`（`%s` 区分大小写）均无树，并报告最远字节位置；预算过紧时返回“未判定”而不是“不匹配”（单测覆盖，示例输出未展示）。js / wasm-gc / native 三个后端输出完全相同（本轮实跑）。限制：只做语法与字节跨度提取，不含 absolute-form/authority-form/`*` 目标、整条 HTTP 报文、头字段、方法白名单或 URI 规范化。

## 安装与复现

需要 `moonc v0.10.14+7d59c7ec9`、`moon/moonrun 0.1.20260920`，记录见
[TOOLCHAIN.lock](TOOLCHAIN.lock)。CLI 需要 Node.js（本机实测 24.18.0），差分与验收脚本需要 Python 3，仅用标准库。
未增加第三方 Mooncakes 依赖。解压源码 ZIP 后进入 `moonabnf`：

```sh
# 指向现有可信 SDK；脚本不安装或修改全局配置。
export MOONABNF_SDK=/absolute/path/to/moonbit-sdk
scripts/moon-local.sh check -j 1 -d
scripts/moon-local.sh build -j 1 -d
scripts/moon-local.sh test -j 1 -d
scripts/moon-local.sh run examples -j 1
python3 scripts/acceptance.py
# 只跑请求行示例的跨后端黄金输出对比（已含在 acceptance 中）
python3 scripts/example_request_line.py
# 只验证独立下游消费本地候选包；不执行正式发布
python3 scripts/downstream.py
```

使用 Unix `unzip` 可保留脚本执行位；若解压工具移除了执行位，先运行 `chmod +x scripts/*.sh`。
脚本通过 `MOONABNF_SDK`（或 `MOON_HOME`）使用已有 SDK，不依赖作者本机绝对路径。
在独立下游模块内使用 `moon add sundaysebasidian-byte/moonabnf@0.1.0`。
本地候选包消费和正式注册表消费分别保留证据，不把前者当成后者。

## 库 API

包配置和可运行样例见 `examples/moon.pkg` 与 `examples/main.mbt`：

```moonbit
import { "sundaysebasidian-byte/moonabnf" @abnf }
```

```moonbit
match @abnf.compile(b"field = %i\"Trace\" \":\" SP 1*8HEXDIG CRLF\r\n") {
  Err(d) => println("\{d.code} at byte \{d.offset}, line \{d.line}, column \{d.column}")
  Ok(program) => {
    let result = program.recognize("field", b"TRACE: aF12\r\n")
    assert_true(result.status is @abnf.Matched)
  }
}
```

`parse(Bytes)` 返回公开 AST，保留规则顺序、增量标志和源字节位置。
`compile(Bytes)` 独立解析并拥有内部 AST，合并规则、解析 core 默认值并校验。
`Program::recognize(rule, Bytes)` 要求输入全部匹配，返回状态、偏移、工作量及累积端点存储数。
`Program::parse_input(rule, Bytes)` 要求输入全部匹配，返回 `InputTreeReport`；
仅 `Matched` 带 `Some(InputTree)`，失败或预算耗尽均无部分树。
`InputTree.nodes` 为只含选定派生的平坦节点数组，`root=0`；节点包含规则名/终端/序列/
分支索引/实际重复次数、`[start,end)` 输入字节跨度及孩子ID。
使用 `input[node.start:node.end]` 提取原始字节；`source_offset` 指文法表达式，隐式core为合成位置0。
文法 `Expr` AST 描述规则；输入树描述某次输入的派生，二者不可混称。
程序可复用，每次识别有独立预算；没有隐藏全局缓存。完整接口见 `pkg.generated.mbti`。

```moonbit
let p = @abnf.compile(b"record = key \":\" 1*DIGIT\r\nkey = 1*ALPHA\r\n").unwrap()
let r = p.parse_input("record", b"Age:42")
assert_true(r.status is @abnf.Matched)
assert_eq(r.tree.unwrap().nodes[0].end, 6)
```

歧义策略：遍历所有替代、保留所有不同结束偏移；同一端点保留首次遇到的派生路径，
重复次数按升序探索。这不是PEG优先匹配，不枚举全部歧义，也不认证唯一解析。
可空重复在树中实际生成最小次数；百万次空重复可被recognize快速识别，parse_input则可能耗尽树预算。
设计、预算及新验证见 [本轮补强记录](docs/INPUT_TREE_REVIEW.zh-CN.md)。

## 规范协议示例

`examples/http_etag` 使用 [RFC9110 §8.8.3](https://www.rfc-editor.org/rfc/rfc9110.html#section-8.8.3)
及 [§5.5](https://www.rfc-editor.org/rfc/rfc9110.html#section-5.5) 的 ETag 字段值文法。
`scripts/moon-local.sh run examples/http_etag/cmd -j 1` 解析 `W/"revision-7"`，
提取弱标签标志与 `[3,13)` 原始内容字节，拒绝错误的小写前缀。
测试覆盖全部256种内部字节、空值、反斜杠、高位字节及非法值。
范围仅为字段值语法与提取；不含 `ETag:` 行包装、外部空白、HTTP整报文、
验证器生成/比较或条件请求语义。规范文法另有 [IETF BSD许可](licenses/rfc9110-BSD)。

## 支持与限制

支持规则名及引用（大小写不敏感）、`=`/`=/`、无序替代、序列、分组、可选项、
`n`/`n*m`/`*m`/`n*`/`*` 重复；`%b/%d/%x` 单值、点连接序列、闭区间；
默认及 `%i` 的 ASCII 大小写不敏感字符串、`%s` 的敏感字符串；16 个 RFC core 规则。
大小写前缀自身也不敏感。输入是字节，NUL 与 255 不会经过 UTF-8 解码。

文法文本严格遵守 CRLF（包括最后一行）；折行须以 SP/HTAB 开始，支持注释。
文法里的空白不隐式插入到被识别输入。可空字符串和可空重复有明确语义。
解析可接受 prose-val AST，但编译拒绝自然语言终端。数值终端限制为 0..255；
重复次数单个整数限制为 1,000,000，超限报错。未实现 Unicode 数值终端、全部歧义树枚举、
代码生成、错误恢复、自动左递归改写、完整协议语义检查和流式识别。

显式 `=` 可覆盖 core 默认规则；`=/` 可扩展已存在的用户规则或 core 默认规则。
重复显式基定义、先扩展不存在的规则、扩展后又覆盖基定义都会报错。
所有规则（包括未选作入口的规则）都必须已定义、可生产且无左递归。

**左递归策略：编译拒绝。** 先做可空性与生产性不动点，再在可空前缀引用图上查循环，
覆盖直接、间接和隐藏于可空重复/可选项前缀的循环。消耗字节的递归允许，
受识别深度及工作量预算约束。`0rule` 不执行引用，但引用本身仍须存在。

详细范围、预算计数范围、失败优先级、batch错误行与后端边界见
[支持范围与失败契约](docs/BOUNDARIES.zh-CN.md)。该说明不把字节格式校验当作完整协议或配置业务校验。

## 预算与错误

| 阶段/项 | 默认 | 可设置的硬上限 |
|---|---:|---:|
| 文法字节数 | 65,536 | 1,048,576 |
| 用户规则声明数（含增量） | 256 | 512 |
| 实际 AST 节点数 | 4,096 | 8,192 |
| 文法分组嵌套深度 | 64 | 64 |
| 编译分析工作量 | 1,000,000 | 10,000,000 |
| 输入字节数 | 65,536 | 1,048,576 |
| 识别工作量 | 500,000 | 10,000,000 |
| 累积端点存储次数 | 100,000 | 1,000,000 |
| 识别递归调用深度 | 128 | 128 |
| 输入树累计节点分配 | 20,000 | 100,000 |
| 输入树累计子边/路径分配 | 40,000 | 200,000 |

用 `limits={ ..@abnf.default_match_limits(), max_work: 1000 }` 设置识别预算。
工作量计表达式分派、字节比较、端点插入及去重比较；端点存储是累积次数，非峰值内存字节。
这是确定性的操作预算，不是墙钟超时，不承诺任意文法在默认预算下结束识别。
输入树由 `InputTreeLimits.matching` 设置匹配预算，另有 `max_nodes/max_edges`。
计数涵盖丢弃分支、路径列表、孩子数组和最终压缩；不是输出节点数或内存字节数。
树工作量额外计分配与路径反转，其计数和预算通过与否不必与recognize相同。
不使用贪心或 PEG 优先选择：保留全部可达结束偏移。重复可达集合稳定后停止，允许空元素补足最小次数。

语法/编译错误给零起始字节偏移和一起始行、列；只返回首个诊断。
成功偏移为输入长度；失败偏移是最远实际尝试/达到的字节位置，可能为 EOF。
`BudgetExceeded` 是未判定，不能当作 `NoMatch`；未知入口及非法预算也有独立状态。

## CLI

```sh
scripts/cli.sh check fixtures/protocol.abnf
scripts/cli.sh match fixtures/protocol.abnf field fixtures/protocol-valid.bin
scripts/cli.sh match fixtures/config.abnf setting fixtures/config-invalid.bin
scripts/cli.sh batch fixtures/binary.abnf frame fixtures/binary-valid.bin fixtures/binary-invalid.bin
# 设置工作预算（只有 match 的可选最后一个参数）
scripts/cli.sh match fixtures/protocol.abnf field fixtures/protocol-valid.bin 8
```

CLI 的参数验证、文法编译和识别均由 MoonBit 实现。Node FFI 仅做有界普通文件读取与设置退出码。
`check` 输出文法有效性/规则清单；`match` 和 `batch` 每个成功读取的输入输出一行 JSON。
I/O 错误输出 stderr；其余状态带 JSON。CLI 使用默认 64 KiB 文法/输入预算，读取至上限加一字节即报超限；
一次 batch 最多 256 个文件，逐个处理并只编译一次，每个输入独立预算。拒绝目录/设备/FIFO，不改写原文件。
退出码：0 全匹配/检查有效；1 有不匹配；2 参数、I/O、文法或入口错误；3 有预算耗尽。
混合 batch 取最高退出码。

## 验证与证据

`scripts/acceptance.py` 串行执行格式检查、check/build/test、例子、CLI 和差分，`-j 1`。
历史323a3728…记录为四后端各22组、CLI24项及5,440正则子集差分通过，不能作为新树实现的验证。
云端运行与工具链替代路径见 [原始补强记录](docs/INPUT_TREE_REVIEW.zh-CN.md)；当前完整SDK复验见 [Mac补审记录](docs/MAC_REVIEW.zh-CN.md)。
云端旧记录为JS30组、CLI24项、5,440次差分通过，其替代工具链完整验收失败，原始日志保留。
随后在Mac已有完整锁定SDK上，原始d0982d80候选的71项源码哈希一致，四后端30组、CLI24项、5,440次差分、标准候选包及隔离消费者全部通过。
树测试另有1,820个穷举输入与独立AST见证重放。Mac另补预算逐阈值、后续分支失败与长递归/输入长度契约回归；
最终源码快照的完整验收与协议命令日志随审查包保存，详见 [Mac补审记录](docs/MAC_REVIEW.zh-CN.md)。
新增树API的远端CI、注册表新版本消费仍未验证；公开0.1.0不含它。本轮（2026-10-18）的本地结果见顶部状态表。
独立 oracle 使用 Python 字节正则全匹配：固定 seed，80 组随机正则子集文法，5,440 次比较。
它验证识别语义及相应解析路径，不是完整 ABNF 解析器对全部规范的认证。
递归场景由明确预期的本地测试覆盖；未做第三方完整 ABNF 解析器差分。
历史0.1.0发布提交有Linux CI记录，见发布事实；本轮未push或触发远端CI。

历史独立下游验证用 `moon package --frozen` 生成候选 ZIP，解压到隔离 workspace，
由 `local/moonabnf-downstream` 模块引用公开 API。三个场景有完整输入/输出/断言，
四后端运行并核对解压源码哈希。历史注册表证据使用当时的0.1.0消费者模板，从 Mooncakes 安装正式0.1.0，
依赖树确认registry来源，三个场景/API断言四后端通过。当前消费者模板包含新增输入树API，
不可再用它验证0.1.0。验证经批准且实际发布的新版本时，必须显式提供
`python3 scripts/registry_consumer.py --release-version "$APPROVED_RELEASE_VERSION" --output /absolute/evidence/path`；
脚本不会从本地moon.mod推断发布版本，也不会发布任何版本。未发布候选继续使用
`scripts/downstream.py`，其打包源码逐文件SHA-256须与当前源码一致，并确认本地解析路径。
离线验证这些门禁可运行 `python3 scripts/test_consumer_contract.py`，无需SDK或注册表访问。
公开0.1.0基线的证据与范围审查见 [复用价值审查](docs/REUSE_REVIEW.zh-CN.md) 与 `evidence/reuse-20261001/`。
历史收尾核对见 [FINAL_GATE.zh-CN.md](docs/FINAL_GATE.zh-CN.md)，不覆盖新增输入树API。
重新生成独立证据目录可运行 `python3 scripts/acceptance.py --output /absolute/evidence/path`；新运行记录自身源码哈希，不沿用旧快照哈希。

[技术事实与三场景](docs/TECHNICAL_FACTS.md) · [理解说明](docs/UNDERSTANDING.md) ·
[中文验收矩阵](docs/ACCEPTANCE.zh-CN.md) · [来源](SOURCES.md) · [AI 使用说明](AI_USAGE.md)

## 许可与赛事边界

原创实现与自制 fixtures 使用 MIT。标准库依赖许可及 NOTICE 在 `licenses/`。
RFC9110示例文法Code Component单独使用IETF BSD许可；未将RFC全文打包或把规范文法当作MIT原创，见 `SOURCES.md`。
代码和事实资料均有 AI 辅助；最终申报书必须由用户本人撰写，身份材料与诚信承诺由本人处理。
此前0.1.0公开GitHub和Mooncakes的发布证据另记；本轮只交本地分支/补丁，不push、不发布、不操作表单或发邮件。
用户反馈已初审未过，申报修改、身份材料、诚信承诺与奖励资格仍由本人和赛事审核处理。

### 审查补丁的兼容性复验

新增消费者门禁使用显式异常，Python `-O` / `PYTHONOPTIMIZE` 不会移除版本、来源、
工作区、输出或包内容校验；证据目录必须为空，避免沿用旧的成功摘要。
运行 `python3 scripts/test_consumer_optimized.py` 可做离线假SDK防误报回归。
消费者脚本默认保留锁定SDK入口；兼容性复验可显式传入 `--moon /trusted/sdk/bin/moon`，
并设置该SDK的 `MOON_HOME` 和PATH。新SDK结果必须单独标注版本，不能冒充锁定SDK复验。

## 输入树上手与评审核对

[输入树最短可复现路径](docs/INPUT_TREE_QUICKSTART.zh-CN.md) 提供完整成功、拒绝和预算未判定的公共API示例。
`moon run examples/input_tree --target js -j 1 -d` 可直接运行，按命名规则提取 `Age:42` 的值字节。
[评审补充说明草稿](docs/REVIEWER_RESPONSE_DRAFT.zh-CN.md) 将原始反馈逐项对应到实现与证据，供作者核对改写，尚未提交。


本轮边界回归进一步覆盖UTF-8外观字节中的失败位置、尾随NUL、歧义空输入，以及空派生预算失败后的复用。
源码归档的解压层级与SDK选择见[从交付归档开始](docs/INPUT_TREE_QUICKSTART.zh-CN.md#从交付归档开始)。

## Named captures and protocol corpora (local candidate)

`InputTree::rule_nodes(name)` finds named-rule node IDs case-insensitively in stable tree storage order. `span(id)` returns a checked half-open byte span; `extract(original_input, id)` copies the original bytes or returns `None` for invalid IDs/spans. Supply the exact input used to parse; the tree does not store or authenticate it. No UTF-8, URI escape or quoted-string decoding is implicit.

For nested captures or pairing fields, use `rule_nodes_in(name, root_id)`: it walks only that subtree in depth-first pre-order, includes the selected root, and returns `None` for malformed structure (including cycles/shared descendants). `Some([])` means no occurrence; a zero-width occurrence remains a node with `Some(b"")` on extraction. Existing `rule_nodes` retains breadth-first storage order, which can differ from input order for nested rules. See [capture contracts and design](docs/QUALITY_20261020.zh-CN.md).

`examples/protocols` supplies RFC3986 URI-reference grammar (including IPv6 and relative references) and RFC6265 Cookie-value grammar. Tests use the generic `Program::parse_input` and the public query API to extract URI components and repeated cookie pairs. These are syntactic examples: no scheme-specific URI validation, host disambiguation policy, network access, cookie state/security policy or full HTTP parser. Source fixtures, the equivalent URI `path-empty` adaptation, and third-party license notices are in `fixtures/protocols/SOURCES.md` and `licenses/`.

Run the byte-preserving URI/Cookie demonstration with `MOONABNF_SDK=/path/to/trusted-sdk scripts/moon-local.sh run examples/protocols/cmd --target js -j 1 -d`. The [walkthrough](docs/QUALITY_20261020.zh-CN.md) explains duplicate Cookie names, quoted/empty values, rejection and indeterminate budget results. Reproduce fixed-workload benchmarks with `scripts/moon-local.sh bench benchmarks --target js --release -j 1 -d` after setting the same SDK. Timings are measurements of those inputs, not a general ABNF complexity guarantee.

Run the complete acceptance with a new evidence directory; it includes the corpus-byte binding check and protocol tests on the existing supported targets.
