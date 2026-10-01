# MoonABNF

MoonBit 实现的通用 ABNF 文本解析、编译验证和有界字节识别库，依据
[RFC 5234](https://www.rfc-editor.org/info/rfc5234/) 与
[RFC 7405](https://www.rfc-editor.org/info/rfc7405/)。适合协议字段、配置输入和二进制 fixture 校验。
项目使用 MIT，仓库地址为 https://github.com/sundaysebasidian-byte/MoonABNF 。
正式模块名为 `sundaysebasidian-byte/moonabnf`，版本 `0.1.0`。发布与远端验证状态见中文验收矩阵；未提交赛事表单。

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
# 只验证独立下游消费本地候选包；不执行正式发布
python3 scripts/downstream.py
```

使用 Unix `unzip` 可保留脚本执行位；若解压工具移除了执行位，先运行 `chmod +x scripts/*.sh`。
脚本通过 `MOONABNF_SDK`（或 `MOON_HOME`）使用已有 SDK，不依赖作者本机绝对路径。
在独立下游模块内，正式版本发布后可使用 `moon add sundaysebasidian-byte/moonabnf@0.1.0`。
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
程序可复用，每次识别有独立预算；没有隐藏全局缓存。完整接口见 `pkg.generated.mbti`。

## 支持与限制

支持规则名及引用（大小写不敏感）、`=`/`=/`、无序替代、序列、分组、可选项、
`n`/`n*m`/`*m`/`n*`/`*` 重复；`%b/%d/%x` 单值、点连接序列、闭区间；
默认及 `%i` 的 ASCII 大小写不敏感字符串、`%s` 的敏感字符串；16 个 RFC core 规则。
大小写前缀自身也不敏感。输入是字节，NUL 与 255 不会经过 UTF-8 解码。

文法文本严格遵守 CRLF（包括最后一行）；折行须以 SP/HTAB 开始，支持注释。
文法里的空白不隐式插入到被识别输入。可空字符串和可空重复有明确语义。
解析可接受 prose-val AST，但编译拒绝自然语言终端。数值终端限制为 0..255；
重复次数单个整数限制为 1,000,000，超限报错。未实现 Unicode 数值终端、解析树生成、
代码生成、错误恢复、自动左递归改写、完整协议语义检查和流式识别。

显式 `=` 可覆盖 core 默认规则；`=/` 可扩展已存在的用户规则或 core 默认规则。
重复显式基定义、先扩展不存在的规则、扩展后又覆盖基定义都会报错。
所有规则（包括未选作入口的规则）都必须已定义、可生产且无左递归。

**左递归策略：编译拒绝。** 先做可空性与生产性不动点，再在可空前缀引用图上查循环，
覆盖直接、间接和隐藏于可空重复/可选项前缀的循环。消耗字节的递归允许，
受识别深度及工作量预算约束。`0rule` 不执行引用，但引用本身仍须存在。

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

用 `limits={ ..@abnf.default_match_limits(), max_work: 1000 }` 设置识别预算。
工作量计表达式分派、字节比较、端点插入及去重比较；端点存储是累积次数，非峰值内存字节。
这是确定性的操作预算，不是墙钟超时，不承诺任意文法在默认预算下结束识别。
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
最新四种后端（Wasm、Wasm GC、JS、native）的测试及 CLI/差分原始输出见 `evidence/final-20261001/`；旧快照保留在 `evidence/acceptance/`。
独立 oracle 使用 Python 字节正则全匹配：固定 seed，80 组随机正则子集文法，5,440 次比较。
它验证识别语义及相应解析路径，不是完整 ABNF 解析器对全部规范的认证。
递归场景由明确预期的本地测试覆盖；未做第三方完整 ABNF 解析器差分。
CI 配置覆盖同一流程，锁定编译器；尚未在远端执行，不把本地通过称为 CI 已通过。

独立下游验证用 `moon package --frozen` 生成候选 ZIP，解压到隔离 workspace，
由 `local/moonabnf-downstream` 模块引用公开 API。三个场景有完整输入/输出/断言，
四后端运行并核对解压源码哈希。此路径是本地模块依赖，尚未验证 Mooncakes 注册表安装。
证据与范围审查见 [复用价值审查](docs/REUSE_REVIEW.zh-CN.md)；最新完整验收在 `evidence/reuse-20261001/`。

[技术事实与三场景](docs/TECHNICAL_FACTS.md) · [理解说明](docs/UNDERSTANDING.md) ·
[中文验收矩阵](docs/ACCEPTANCE.zh-CN.md) · [来源](SOURCES.md) · [AI 使用说明](AI_USAGE.md)

## 许可与赛事边界

原创实现与自制 fixtures 使用 MIT。标准库依赖许可及 NOTICE 在 `licenses/`。
RFC 文本未作为 MIT 源码或 fixture 打包；规范依据与参考范围见 `SOURCES.md`。
代码和事实资料均有 AI 辅助；最终申报书必须由用户本人撰写，身份材料与诚信承诺由本人处理。
用户已条件批准公开 GitHub 和按现有 MIT 发布 Mooncakes；实际发布状态与证据另记。
本人报名、人工最终申报书、身份材料、诚信承诺及奖励资格仍由本人和赛事审核处理。
