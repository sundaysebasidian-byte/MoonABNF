# 技术事实清单（AI 辅助参考，非最终申报书）

独立项目 MoonABNF：ABNF 文本 → AST → 编译验证 → 有界字节识别。
规范为 RFC 5234 / RFC 7405，原创 MoonBit 实现，不移植其他 ABNF 库源码。
最终申报书须用户本人理解后写；本资料不冒充人工 Proposal。

## 生态价值与有界核查

协议库作者经常需要把规范中的 ABNF 规则变为可复用校验器，并知道输入为何失败、
资源预算是否耗尽。2026-09-30 Mooncakes 站内只查 abnf / bnf 两个词：abnf 返回
marianoguerra/uri@0.1.2 的 URI/IRI 字符编码表，bnf 无结果。
该 URI 字符表不接受通用 ABNF 文本，也不提供本库的规则诊断与预算识别流程。
此核查未见高度同类，但不证明全生态没有潜在同类；正式申报前需再核一次当前结果。

## 三个完整场景（均有自制 fixtures 与可运行例子）

| 场景/调用者 | 文法与输入 | 实际预期结果 | 如何使用结果 |
|---|---|---|---|
| 协议字段：协议库在处理字段前做语法校验 | fixtures/protocol.abnf；`field`，`TRACE: aF12` 后带 CRLF | valid fixture Matched；缺冒号后SP、非HEX、过长、只有LF均 NoMatch | 先编译一次，逐字段识别；格式不合格拒绝处理；预算耗尽单独记录；协议认证与业务语义另做 |
| 配置输入：小型配置工具约束键和值 | fixtures/config.abnf；`setting`，`cache=on` / `ttl=120` | 两者 Matched；`cache=ON`、数字首键、四位数字、空值或多余空格 NoMatch | 将最远字节偏移返回给配置编辑者；严格匹配大小写与长度；不是完整INI/TOML实现 |
| 批量二进制回归：协议维护者批量检查 fixtures | fixtures/binary.abnf；`frame`，NUL + 1..4 任意字节 + FF | binary-valid.bin Matched；五字节payload NoMatch；NUL/高字节无转码 | CLI batch 编译一次，逐文件JSON输出；退出码使脚本发现失败；每文件独立预算，最多256文件 |

可复现命令：`scripts/moon-local.sh run examples -j 1`；或 README 的 check/match/batch 命令。
fixtures均为自制，二进制内容不是个人或业务数据。

独立消费者实证：`python3 scripts/downstream.py` 消费 `moon package` 生成并隔离解压的本地候选 ZIP，
三个场景通过同一个公共库 API、有明确状态/偏移断言，四后端输出逐字核对。
完整输入/API/实际输出、拒绝原因及证据边界见 [REUSE_REVIEW.zh-CN.md](REUSE_REVIEW.zh-CN.md)。
它证明本地包可被独立模块复用，不是 Mooncakes 安装、真实第三方采用或完整业务集成的证明。

## 交付范围与技术理解

支持引用、增量替代、重复、分组/可选、数值序列/range、16 core规则、默认与%i/%s字符串、
CRLF折行与注释。编译拒绝未定义引用、非生产规则、左递归、重复基定义及prose-val。
prose-val能进入AST，但不把自然语言静默解释成识别器。数值终端只支持0..255。

递归下降解析；生产性与可空性不动点；可空前缀引用图检查左递归。
识别传播所有结束偏移，避免ABNF替代误当PEG优先选择；可空重复达到固定集合后停止。
输入长度、工作量、累积端点、递归深度均有预算；耗尽是未判定，不是不匹配。
内部编译AST不可被外部可变AST破坏，程序可复用而每次识别资源账本独立。

不生成编译器代码，不覆盖Unicode数值终端，不自动重写左递归，不承诺任意文法都在默认预算内成功。
正式命名空间已核为 sundaysebasidian-byte/moonabnf@0.1.0；用户已条件批准公开仓库与Mooncakes发布。
准确发布、远端CI及注册表消费结果另据真实操作更新；本人报名未执行，资格/奖励仍由赛事审核。
