# MoonABNF：复审材料草稿（2026-10-25）

> 历史快照提示（2026-10-25更新）：下方正文保留原阶段事实、日期和失败记录，不是当前发布状态。两库正式版本现为0.2.1，ABNF #6与STOMP #8均已合并；本库发布提交、checksum、消费验证和边界见[0.2.1说明](release-0.2.1.zh-CN.md)。`diagnose_input`及诊断扩展仍仅在未公开开发源码，见[README](../README.md)，不属于0.2.1。“本轮”“未推送”“Draft”等下文表述只描述当时阶段；本轮未向评审发送或提交比赛。

供用户审阅改写，未发送、未提交，不冒充用户独立撰写。针对原评语“文法校验库而非通用解析器”，本工程已有调用者自定义文法→compile→可复用Program→输入派生树→原字节字段提取的闭环，0.2.0已发布。parse是文法AST，parse_input是一次输入的派生见证；二者不混淆。

## 可展示的代表任务

先运行registry_protocol_record_test.py：同一实际0.2.0发布包完成URI/Cookie规范字段的JSON导入门禁，黄金记录包含半开字节span、重复Cookie分组、原始编码保留。输入树由通用公共API产生，JSON是应用层适配，不是库硬编码协议。四项契约包含预算后同Program复用；退出0/1/3/2分别为接受/拒绝/预算未判定/配置错误。拒绝不泄露另一成功字段。规范来源、八URI、Cookie512、ETag256及许可保持原出处。

这是端到端可运行的规范案例，使用规范公开例子和自编负例，不是真实生产流量、完整HTTP栈或外部采用。核心四后端发布消费证据与JS适配器范围分列。全新registry消费避免“工作区实现冒充可安装包”；新脚本不替代独立源码测试。

## 竞争力与代价

展示价值在于可复用解析能力、可解释的原字节见证与受限失败语义，不在测试数量。输入按字节、拒绝左递归、歧义返回一个确定见证，受work/states/depth/nodes/edges约束。BudgetExceeded不能当NoMatch。

原有JS release单进程adaptive结果保留；后续已完成五次独立进程测量。compile单列、相同输入和matching预算、算法计数与采样RSS分开。没有p95；没有与成熟第三方parser公平性能对照，因此不宣称更快、更省内存或完整规范认证。

## 当前证据身份

实际发布版本0.2.0；公开Draft #6基线33b8b3159dee0a40ff7a59c42e76eb9ba52f9453的既有CI已绿。2026-10-25新增registry复现入口的测试是本地新证据，未推送，不借旧CI背书。逐条矩阵见REVIEW_CONCERNS_MATRIX.zh-CN.md。独立第三方代码审查与评委重新认可是未完成项；既有两个Draft均无新review。没有采用者、诚信声明或获奖概率承诺。

### 本轮本地实际回执

registry_protocol_record_test.py已通过：精确0.2.0、source.kind=registry、workspace_member=false，既有4/4契约及JSON黄金/拒绝/预算/配置检查通过；拒绝/预算字段隔离与Program复用有断言。先显式安装，再使用frozen检查；首轮安装顺序失败的日志保留，不能抹去。未改旧registry消费者脚本。

## 后续独立AI复审与五进程实测

独立AI发现的隔离/快照/统计问题已修复并复测；五个独立PID的代表性协议基准已实跑，详见FIVE_PROCESS_BENCHMARK.zh-CN.md。原单次adaptive结果保留原身份。暖构建、未清OS缓存、无p95；没有跨实现性能优越性结论。AI审查不是外部人类认可。
