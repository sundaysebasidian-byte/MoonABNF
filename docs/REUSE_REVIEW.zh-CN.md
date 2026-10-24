# 有界复用价值审查（AI 辅助技术事实）

> 2026-10-12完整SDK复验及当前候选范围见 [Mac补审记录](MAC_REVIEW.zh-CN.md)，本文其余部分保留历史事实。
> 历史0.1.0识别API记录；“没有解析树”等范围不适用于当前未发布补强分支，新事实见 [本轮记录](INPUT_TREE_REVIEW.zh-CN.md)。

日期：2026-10-01。依据用户核实的 LogLens 邮件：9/24 退回是赛期提交不足、需先完成 MVP；
本节保留发布前本地命名空间与核查状态的历史事实；正式版本使用
`sundaysebasidian-byte/moonabnf@0.1.0`，候选消费脚本读取当前 metadata，注册表验证使用独立脚本。
9/28 退回是特定 JSONL HTTP 场景、通用与生态复用价值有限；9/30 初审通过。
这里据此检查完整性与下游复用，不把退回解释为测试或许可证失败，也不自动把九月提交门槛套到十月。
本文不是人工最终申报书或赛事选题认可。

## 三个完整下游场景

所有文法文本均以 CRLF 终止；以下输入用 MoonBit bytes 字面量显示，保证 CRLF、NUL 与 FF 不被展示层转码。
完整可执行源码是 `integration/consumer/main.mbt.in`，脚本生成独立 `local/moonabnf-downstream` 模块运行。
该模块只 `import { "local/moonabnf" @abnf }`，不读取库私有结构、不复制实现。

| 调用者与完整输入 | 公共 API 与断言 | 实际 stdout | 下游用途与边界 |
|---|---|---|---|
| 协议字段接入：`fixtures/protocol.abnf`；`b"TRACE: aF12\r\n"`、`b"Trace:aF12\r\n"` | `compile(grammar)` 一次；`Program::recognize("field", input)`；分别断言 Matched/13、NoMatch/6；work/states > 0 | `protocol/accept: matched offset=13`；`protocol/reject: no-match offset=6` | 给协议适配器在业务处理前做字段格式校验；拒绝缺少显式 SP 的输入；不实现网络协议、认证或业务语义 |
| 配置编辑校验：`fixtures/config.abnf`；`b"ttl=120"`、`b"cache=ON"` | 独立配置文法 compile 一次；recognize("setting", input)；分别断言 Matched/7、NoMatch/6；work/states > 0 | `config/accept: matched offset=7`；`config/reject: no-match offset=6` | 编辑器能定位敏感大小写值的失败字节；语法和长度校验可复用；不声称实现 INI/TOML、键含义或配置加载 |
| 二进制 fixture 批量回归：`fixtures/binary.abnf`；`b"\x00\x00\xFF"`、`b"\x00\xFF\xFF"`、`b"\x00ABCD\xFF"`、`b"\x00ABCDE\xFF"` | 同一编译程序逐输入 recognize("frame", input)；前三个 Matched/3、3、6；第四个 NoMatch/5；work/states > 0 | `fixture/accept-0: matched offset=3`；`fixture/accept-1: matched offset=3`；`fixture/accept-2: matched offset=6`；`fixture/reject: no-match offset=5` | 原始字节回归维护，可检查 NUL/FF 与负例；这里只验证帧格式，不验证校验和或真实设备互操作；生产 CLI 另有有界 batch |

消费者还直接断言以下 API 契约：`max_work: 1` 返回 BudgetExceeded；不存在入口返回 UnknownRule；
预算耗尽后下一次调用仍能正常匹配，说明账本独立；未定义规则 compile 返回 `undefined-rule`；
parse 返回含两个声明、第二个 incremental=true 的公开 AST。全部四后端输出由脚本逐字比较，进程错误不会被当作通过。

## 真实候选包消费路径

运行 `python3 scripts/downstream.py`。它用已有锁定工具链运行 `moon package --frozen`，
将实际生成的 `local-moonabnf-0.1.0.zip` 解压到新的临时目录；并在相邻目录生成独立消费者模块及
`moon.work`。通过消费者自身模块依赖引用解压后的库，依赖树 JSON 断言解析到 candidate 路径，
不是主工程路径。四后端串行运行，编译警告作为错误，不调用原工程已有编译缓存。
运行后逐文件 SHA256 验证解压候选库没有被消费过程改变；候选 ZIP 与清单随证据保留。

这种本地模块依赖路径符合 [MoonBit 官方模块配置说明](https://docs.moonbitlang.com/en/latest/toolchain/moon/module.html)。
`.moonignore` 从候选包排除生成的 evidence，避免把测试记录反复嵌入包；源码交付 ZIP 仍保留证据。
这是**未发布候选包的独立本地消费者验证**，不是 Mooncakes 注册表安装或真实第三方用户采用证据。
没有执行 publish、push、注册或报名。

初版消费脚本失败记录保留：第一轮为 `moon tree` 不支持 `--frozen` 参数，未运行场景；
第二轮为消费者断言函数缺少 raise 声明、使用不存在的 enumerate，未运行断言。
修正消费者与脚本后全部预期不变，未修改核心实现或降低断言。最终完整验收输出见
`evidence/reuse-20261001/`，早期消费尝试日志保留，不混称最终成功。

## 范围审查结论

实际支持范围内公共 API 可直接被独立模块调用，三个调用者使用同一库与不同文法，无需为每场景修改解析器。
因此工程提供通用字节文法机制，已有证据超出单一 HTTP JSONL 场景；生态实际采用、性能优势、
全标准符合性、赛事原创性认可均未由这些测试证明。

保留限制：输入是字节；Unicode 数值终端与 prose-val 识别不支持；直接/间接/可空前缀左递归
编译拒绝；没有解析树、错误恢复、流式识别、代码生成或完整协议/配置语义。
有预算的高复杂度有效文法可能返回未判定；只返回首个编译诊断和最远尝试偏移。
当前消费者证明 AST/诊断/编译/识别及预算 API 实用，不意味着每个公开字段已有真实外部用户需求验证。

人工最终申报、十月资格、公开仓库、远端 CI、正式 Mooncakes 发布与发布后 consumer 仍待处理。
真实 broker、办公软件、Windows/Linux 实机及完整第三方 ABNF parser 差分未测；不将这些写成通过。
