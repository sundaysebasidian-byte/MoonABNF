# 技术事实清单（AI 辅助参考，非最终申报书）

2026-10-22准备入口：当前能力/阻塞、当期真实提交与独立字段消费者集中在[README](../README.md)，
原始审计/失败日志以交付manifest标注的提交身份为准。以下保留早期技术事实，不把历史四后端回执算到新候选。
用户计划北京时间10月24日窗口准备，未擅定时刻或代交。用户随后批准公开开发分支；
未批准主分支合并、发包、release、部署或代交比赛，旧段落的“本轮不push”指其当时阶段。

独立项目 MoonABNF：ABNF 文本 → 文法AST → 编译验证 → 有界字节识别/输入派生树。
规范为 RFC 5234 / RFC 7405，原创 MoonBit 实现，不移植其他 ABNF 库源码。
最终申报书须用户本人理解后写；本资料不冒充人工 Proposal。
本轮未发布分支为回应初审意见；新增树API、规范ETag场景、实际验证及限制见
[INPUT_TREE_REVIEW.zh-CN.md](INPUT_TREE_REVIEW.zh-CN.md)。

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
原protocol是自造字段，不能算真实规范验证。新增examples/http_etag依据RFC9110
§§8.8.3/5.5，校验ETag字段值并通过规则树提取弱标志与原始内容字节。
规范文法BSD许可独立保留；不覆盖HTTP整报文或缓存/条件请求语义。

历史独立消费者实证（0.1.0识别API，不覆盖本轮新树API）：`python3 scripts/downstream.py` 消费 `moon package` 生成并隔离解压的本地候选 ZIP，
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
parse_input保留每端点一棵见证，输出全输入派生。树/路径分配亦受预算，
可空重复实际生成最小次数的子树，不凭固定点虚构节点。
内部编译AST不可被外部可变AST破坏，程序可复用而每次识别资源账本独立。

不生成编译器代码，不覆盖Unicode数值终端，不自动重写左递归，不承诺任意文法都在默认预算内成功。
正式命名空间已核为 sundaysebasidian-byte/moonabnf@0.1.0；用户已条件批准公开仓库与Mooncakes发布。
0.1.0不含新树API。本轮禁止push/新发包/修改表单或发邮件，用户反馈已初审未过。
剩余提交次数与本人材料由用户核对，资格/奖励由赛事审核。
