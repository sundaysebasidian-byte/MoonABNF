> 下文描述已发布 0.3.0 的历史边界。2026-10-30 源码修订已新增左递归支持，后续实现又新增scalar与有限prose绑定；当前范围与新回执见 [增量说明](SCALAR_PROSE_EXTENSION_20261030.md) 和 [修复说明](LEFT_RECURSION_REVIEW_20261030.md)，这些改进不属于已发布 0.3.0。

# 支持范围、边界与失败契约（0.3.0）

适用于已发布的 [MoonABNF 0.3.0](https://mooncakes.io/docs/sundaysebasidian-byte/moonabnf@0.3.0/)。输入树与字段提取从 0.2.0 起已发布，0.3.0 增加有界输入诊断；安装与复现见[输入树上手](INPUT_TREE_QUICKSTART.zh-CN.md)和[技术证据索引](TECHNICAL_EVIDENCE.zh-CN.md)。

历史 0.1.0 仅有文法 AST 与识别；它不代表当前安装版。历史源码记录保留在[原提交](https://github.com/sundaysebasidian-byte/MoonABNF/blob/3af48664afae0bf4414e238f72d64597c7f291ef/docs/BOUNDARIES.zh-CN.md)。

## 文法与输入

| 边界 | 实际行为与调用方责任 | 对应验证 |
|---|---|---|
| 标准范围 | RFC5234语法及RFC7405大小写前缀；数值终端是0..255字节；不是任意字符编码的完整标准认证 | parser_test、256字节core谓词、数值序列和case测试 |
| 文法文本 | 规则名是ASCII字母开头，后接字母/数字/连字符；行尾与最后一行必须CRLF；折行由SP/HTAB开始；字符串/注释/prose文本只允许规范对应ASCII范围 | strict syntax、folding、invalid numeric/string/terminator回归 |
| 转义和Unicode | ABNF引号内反斜杠是普通字符，`"a\nb"`表示四个字节，不表示换行。DQUOTE用%x22；UTF-8可用数值字节序列描述，识别器不解码/归一化Unicode | boundaries_test的literal ASCII/raw bytes回归 |
| AST保留内容 | 文法AST保留规则、增量标志与文法字节位置；不保留注释、空白或独立括号，不提供round-trip。parse_input另返回含规则/表达式结构与输入字节跨度的派生树 | parser AST、input_tree_test与消费者断言 |
| 输入树歧义 | 各替代都探索、保留所有结束偏移；同端点保留首派生。重复按次数升序，精确次数内保留首路径；无歧义枚举或唯一性认证 | 不同端点延续、同端点分支、穷举小输入 |
| 树预算及空重复 | 最小次数实际物化；recognize成功不保证parse_input在树预算内成功。失败无部分树；平坦可达树避免宽重复列表的深栈 | epsilon minima、百万空重复、finish耗尽 |
| 空文法与空输入 | 空字节文法parse失败；仅注释/空行可parse成零规则AST，compile返回no-rules。被识别输入可为空，是否匹配由文法决定 | comment-only回归、nullable repeats、max_input_bytes=0回归 |
| 全文法校验 | 未选入口的规则也须合法、可生产、无左递归；0rule不会执行，但未定义引用和prose仍拒绝；core规则可显式覆盖/扩展 | unused/zero-times回归、compiler core与循环测试 |
| 替代与重复 | 无序选择，传播全部结束位置；没有PEG优先顺序或贪心短路。可空重复的集合稳定后停止，空元素可补足最小次数 | alternatives/nullable/exact counts、独立正则子集差分 |
| 左递归 | 编译拒绝直接、间接、可空前缀循环；不会自动改写。消耗字节的递归允许，仍可能耗尽预算 | compiler循环回归、consuming recursion与depth耗尽 |
| 协议/配置边界 | 只识别字节格式，不验证认证、网络握手、校验和、字段含义、键重复或数字业务范围。如三位DIGIT可接受999，调用者仍需验证TTL业务范围 | 三场景仅格式断言；无broker/办公软件集成声明 |

## 资源预算的实际范围

README列出的字节、声明数、AST节点、嵌套、分析工作、识别工作、累计端点、深度上限均由实现检查。
节点预算统计**解析产生的语义AST节点**，不把编译器添加的core默认项/增量合并外壳称为调用者解析节点。
编译max_work计引用/生产性/可空性/循环分析，规则解析与合并另受文法字节/声明/节点等上限约束。

识别max_work计表达式分派、字节比较、端点插入与去重比较；max_states计各临时数组累计成功插入数。
两者不是CPU指令数、墙钟超时、峰值内存字节或进程内存限制。入口名称归一化/查表、SDK分配与文件I/O不计入识别工作计数。
调用者应使用从自身配置或rule_names清单选择的入口名；不要把无限长不可信入口字符串当成已受input-bytes预算保护的数据。
如需墙钟/进程级限制，由调用者在外层设置；本库没有流式增量输入、取消操作或沙箱。

每次recognize独立记账，预算耗尽不污染后续调用；Program不暴露内部可变AST，rule_names返回独立数组。
parse_input也独立记账。max_nodes/max_edges累计计探索、临时路径、孩子数组及最终压缩。
返回树由调用方拥有，修改不影响Program；树不复制输入，调用者须保留原input并使用字节切片。
无共享缓存不等于已验证多线程并发安全；当前batch与验收均串行。

## 失败结果

| 结果 | 契约 | 回归 |
|---|---|---|
| Diagnostic | 编译/解析只返回一个诊断；offset从0计字节，line/column从1计字节位置；不提供恢复或完整期望集合；多规则同时非法时不保证跨后端选择同一首错规则 | syntax locations、compiler单故障与unused规则回归 |
| Matched | 整个输入匹配，offset为输入长度；不接受仅匹配前缀 | alternatives、trailing suffix、三场景 |
| NoMatch | 预算内未找到全匹配；offset是全部实际尝试的最远位置，可为EOF，不是唯一错误原因或解析树 | furthest real byte locations |
| BudgetExceeded | 未完成当前算法的判定；即使早期分支已找到全匹配，后续探索仍可返回预算耗尽；不能改称确定的NoMatch。调用者可按资源策略拒绝/限流，但应保留未判定原因 | discovered-match预算回归及四种耗尽路径 |
| InvalidLimits/UnknownRule | 参数检查顺序：非法预算→超长输入→入口查找；同时存在问题时按此顺序返回。非输入错误offset/work/states为0 | failure precedence回归 |

`diagnose_input` 是独立入口：失败时给出最远失败分支的局部期望和实际字节/EOF；期望数量与工作预算有上限。它不提供唯一修复、完整错误集合或错误恢复。`Matched` 与 `BudgetExceeded` 不附失败解释。

## CLI与后端

0.3.0 的独立 registry 消费者已验证 JS、Wasm、Wasm GC、native 的核心、输入树与诊断 API。CLI 和协议 JSON 适配示例只验证 JS + Node.js。发布提交及 CI 见[发布回执](release-0.3.0.zh-CN.md)。
Windows、LLVM、浏览器 JS、其他 Wasm 宿主及并发调用未验证。源码复现使用 `TOOLCHAIN.lock`，不同 SDK 的记录分别看待。

CLI固定64KiB文法/输入与最多256个batch文件，读至上限+1后拒绝，不会把截断前缀误当完整输入。
文法过长是grammar-error/parse-budget、退出2；输入过长是budget-exceeded:input-bytes、退出3。
输入文件I/O失败只写stderr，**不产生对应JSON行**；其他文件继续处理。调用者用JSON的file字段关联，不以行号强行对应输入列表，并须检查退出码和stderr。
混合batch取最高退出码（3>2>1>0），因此退出3也可能伴随I/O失败；混合I/O/匹配/预算回归验证这一点。
读取目录/设备/FIFO拒绝，FIFO非阻塞回归只在具备该设施的POSIX系统实测；不保证普通文件I/O墙钟时间或外部文件快照一致性。

## 明确未测与不支持

未测：Windows、完整第三方ABNF解析器差分、真实外部下游采用、多线程、真实broker、办公软件。
不支持：Unicode数值终端、prose识别、左递归自动改写、代码生成、全部歧义树枚举、错误恢复、流式识别、完整协议/配置业务语义。
正则子集5,440次差分只验证已列算法路径，不能改称完整ABNF标准认证。

历史0.3.0数值终端范围说明：该版本文法解析入口将数值终端限制为0–255，超出范围在parse阶段即拒绝，并非已能保留任意RFC数值终端、仅输入执行受字节域限制。扩展数值表示及外部编码契约仍是后续兼容工作，不能将本实现称作完整RFC语法解析器。
