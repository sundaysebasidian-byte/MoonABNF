# MoonABNF 验证与证据记录（2026-10-22）

> 这是 2026-10-22 版 README 的完整证据说明，项目入口见 [README](../README.md)。

MoonBit 字节级 ABNF 库：**文法文本 → 文法 AST → 编译校验 → 输入派生树 → 原字节字段**。
依据 [RFC 5234](https://www.rfc-editor.org/info/rfc5234/) 与
[RFC 7405](https://www.rfc-editor.org/info/rfc7405/)，适合协议字段的离线诊断、配置校验和二进制 fixture 回归。
这不是完整 HTTP/URI/Cookie 语义实现；预算耗尽保留为“未判定”。

本交付是未发布的开发候选，模块名 `sundaysebasidian-byte/moonabnf`。**历史正式包0.1.0不含输入树/捕获API**；
候选的 `moon.mod` 仍写0.1.0，不代表新增功能已经发布。请使用交付中的 `source.zip`，不要用注册表旧包验证本页。

## 从源码归档快速上手

先把交付包解压到一个新的空目录，再解开其中的源码。需要已有可信 MoonBit SDK、Node.js；
Python验收脚本仅用标准库。SDK选择见 [TOOLCHAIN.lock](../TOOLCHAIN.lock)，本包不安装工具或更改全局配置。

```sh
unzip source.zip -d candidate
cd candidate
export MOONABNF_SDK=/absolute/path/to/existing-trusted-sdk
scripts/moon-local.sh version --all
scripts/moon-local.sh run examples/protocols/cmd --target js -j 1 -d > /tmp/moonabnf-demo.txt
diff -u examples/protocols/cmd/expected_output.txt /tmp/moonabnf-demo.txt
```

演示先显示源文法规则与文法AST规则数，再显示输入树前三层、URI组件和重复Cookie字段。
`empty=`有零宽值节点；引号与`%20`保留原样。最后分别显示非法Cookie的`no-match`和
紧节点预算的`indeterminate`，两者均不返回部分树。建议三分钟讲解节奏见
[现有讲解与取舍](QUALITY_20261020.zh-CN.md#三分钟演示)。

本云环境已复验的运行路径是 **JS**；GitHub Linux runner 的官方完整SDK已通过四后端验收，见下表。
本地SDK缺件和默认Wasm初始化失败的原回执仍保留；本轮未升级或覆盖已有SDK。

## 一个可用场景：离线协议字段诊断器

场景是检查一条采集记录中的URI-reference与Cookie字段值，再把带原字节跨度的组件交给后续日志处理。
它不建立连接、不发送请求，也不推断认证、Cookie安全策略或网络资源是否存在。
以下是独立模块导入候选公共API的真实源码消费，参数可替换为自己的文本字段，不是假称第三方采用。

在上一步的`candidate`目录中继续执行（外层目录必须是刚创建的空工作区）：

```sh
cd ..
cp candidate/integration/protocol_consumer/moon.work.in moon.work
mkdir consumer
cp candidate/integration/protocol_consumer/moon.mod.in consumer/moon.mod
cp candidate/integration/protocol_consumer/moon.pkg.in consumer/moon.pkg
cp candidate/integration/protocol_consumer/main.mbt.in consumer/main.mbt
cd consumer
../candidate/scripts/moon-local.sh tree --json
../candidate/scripts/moon-local.sh run . --target js --frozen -j 1 -d -- 'https://example.test/a%20b?q=1' 'session=abc; theme="dark"; empty=; session=second'
../candidate/scripts/moon-local.sh run . --target js --frozen -j 1 -d -- 'http://example.test/%GG' 'session=bad value'
```

依赖树中该模块应为`source.kind: local`且路径指向解压的`candidate`。`--frozen`运行不安装注册表依赖。
第一条诊断输出`URI-reference: matched`、`cookie-string: matched`和各字段跨度；两个`session`均保留。
第二条分别输出`no-match`的字节位置和`tree-absent=true`。
**示例进程退出0表示报告生成完成，不表示字段均匹配**；脚本门禁应读取报告状态，或使用已有CLI的退出码契约。
示例明确把argv文本编码为UTF-8，输入树本身不隐式解码、URI解码或Cookie去引号。

`Program`可以编译一次复用；这个短命令只处理一条记录。所有数据由调用者传入，示例没有真实业务/个人数据或用户采用证据。
正式 `moon package` 包消费者是独立门禁，仍使用 `python3 scripts/downstream.py`；
**源码归档消费通过不能替代官方打包/注册表安装通过**。

## 当前支持与证据矩阵（2026-10-22）

| 范围 | 当前云环境证据 | 边界 |
| --- | --- | --- |
| JS库运行 | 4306ca1：debug/release各58/58 | 包含确定种子鲁棒性；不是无bug证明 |
| JS CLI与差分 | 7826b166：CLI24；seed20260930、80文法/5440比较零差异 | 正则子集oracle，不覆盖全部递归文法 |
| URI/Cookie、请求行 | JS协议用例、演示黄金输出及隔离消费者 | 本轮新字段诊断消费者另有原始命令回执 |
| Wasm / Wasm GC | 静态check通过；各1个最小运行控制在框架StringBuilder初始化失败 | 完整运行矩阵受阻，未反复执行不变失败 |
| native | 静态check通过；SDK缺运行时C源码 | 本轮build/test/消费者受阻，不称运行支持 |
| 官方候选包消费 | SDK与PATH均缺mooncake | 未得到本轮打包/注册表消费回执 |
| 开发分支/远端CI | 已获准公开开发分支；实际SHA/CI见当前提交回执与[Actions](https://github.com/sundaysebasidian-byte/MoonABNF/actions) | 分支公开不等于新包发布；历史0.1.0证据不替代候选 |

另有独立 **GitHub Linux CI**：提交`3e0333a52e058b9213b84028c2aae2e1be35e966`的
[run 39827943551](https://github.com/sundaysebasidian-byte/MoonABNF/actions/runs/39827943551)
已于2026-10-22 UTC终态成功。Ubuntu 26.04.1 runner从官方来源安装完整锁定SDK：
moonc v0.10.14+7d59c7ec9，moon/moonrun 0.1.20260920（914d7da）。
`scripts/acceptance.py`的19个阶段均通过，包括JS/Wasm/native的check、build、test，
Wasm GC test、示例、请求行、CLI、差分、消费者保护，以及`moon package --frozen`归档的四后端独立消费者。
[原始验收附件](https://github.com/sundaysebasidian-byte/MoonABNF/actions/runs/39827943551/artifacts/12446339942)
绑定该SHA；这不是注册表安装、跨平台认证或绝对无bug证明。新字段诊断消费者另在本云环境按上述命令验证。

本云环境：Linux x86_64、Node v24.19.0、官方Wasm版moonc v0.10.14+7d59c7ec9；
moon/moonrun从锁定914d7da0源码本地构建，显示日期20261012，不能冒充锁文件中的官方完整发行二进制。
本轮从官方文档列出的安装来源只读获取发行路径时收到HTTP403，未执行安装脚本、重试或绕过。
本云环境完整SDK补齐仍受阻；远端CI的成功不覆盖这些历史失败，也不把源码ZIP称为注册表安装。

外层交付 `manifest.json` 为结果入口，`evidence/`逐项绑定命令、UTC、退出码、输入、种子、源码SHA和失败记录。
58组与5440比较的历史提交身份分别保留；本轮只复验文档/消费者变化，不重复计作新用例数量。
旧Mac/0.1.0/云端失败回执保留于原证据及[Mac记录](MAC_REVIEW.zh-CN.md)、
[发布历史](PUBLICATION.md)，不是当前分支跨后端通过证明。

可按需复验，避免覆盖已有证据目录：

```sh
scripts/moon-local.sh test --target js -j 1 -d
python3 scripts/verify_protocol_fixtures.py
python3 scripts/cli_test.py
python3 scripts/differential.py
```

CLI/差分依赖先构建 `scripts/moon-local.sh build --target js -j 1 -d`。
完整SDK环境的总门禁是 `python3 scripts/acceptance.py --output /absolute/new-evidence`；
当前已知受阻环境不要无变化反复运行失败矩阵。

## API与设计取舍

- `parse(Bytes)`返回**文法AST**；`compile(Bytes)`验证引用、生产性及可空前缀循环后得到可复用Program。
- `Program::recognize`只识别整段输入；`parse_input`在完整匹配且预算充足时返回一棵**输入派生树**。
  失败/未判定没有部分树，偏移是半开字节跨度，不能当Unicode字符索引。
- ABNF替代传播全部不同端点；同端点保留首次见证，重复次数由小到大。不把ABNF当PEG，不枚举解析森林。
- `rule_nodes_in(name, root)`在所选子树前序捕获，拒绝环、共享后代等畸形结构。
  旧`rule_nodes`保留BFS存储顺序，嵌套时不保证输入出现顺序。
- `span`是局部跨度检查；`extract(original_bytes,id)`复制原字节，空字段返回空Bytes。
  树不认证传入Bytes身份；必须由调用方保存原输入，提取成功不等于重新验证。
- 输入长度、工作/状态/深度、构树节点/边均有预算。`BudgetExceeded`表示未判定，不能改写为`NoMatch`。

支持引用、增量替代、分组/可选/重复、字节数值序列/区间、core规则和默认/%i/%s字符串。
prose-val可进入文法AST但不能编译为识别器；左递归/可空前缀循环编译拒绝，消耗输入的递归仍受预算限制。
不支持Unicode数值终端、错误恢复、代码生成、流式输入或全部歧义枚举。
URI不实现scheme语义、host first-match策略、DNS/端口策略/规范化；Cookie不实现浏览器存储、安全或完整HTTP语义。
详细契约见[边界说明](BOUNDARIES.zh-CN.md)、[输入树上手](INPUT_TREE_QUICKSTART.zh-CN.md)和`pkg.generated.mbti`。

## 当期可追踪贡献

| 提交 | 实质内容 |
| --- | --- |
| 接续基线97f5bb14及更早阶段 | 输入树、ETag/请求行/URI/Cookie文法等已有实现；不冒充本轮准备的新功能 |
| 9e03879e | 安全子树捕获、契约/资源回归、可复现基准与协议演示 |
| 7826b166 | 让演示显示文法AST、输入树和字段，增加预期输出与讲解节奏 |
| 4306ca1 | 1024个有限变异文法、64个嵌套、256组预算的鲁棒性检查；与差分分开记账 |
| 本次准备 | 文档入口、支持矩阵和参数化独立字段消费者；不增加核心解析功能 |

这些是工程事实，月度贡献有效性与资格由赛事审核判断；不制造提交数量或改写日期。

## 依赖、许可与AI辅助

原创库与示例周边代码为[MIT](../LICENSE)；SDK core依赖为Apache-2.0，NOTICE与许可在`licenses/`。
没有新增第三方Mooncakes依赖；JS运行依赖Node，验证脚本依赖Python标准库。
抽取的URI/Cookie/HTTP文法及RFC例子保留独立归属/适用通知，**不随周边代码改称MIT原创**。
准确出处、改写范围与原字节哈希见[SOURCES.md](../SOURCES.md)、[协议来源](../fixtures/protocols/SOURCES.md)及`licenses/`。

[AI_USAGE.md](../AI_USAGE.md)说明Codex参与的设计、实现、测试与文档；独立代理审阅不是人工审核，正则oracle也不是完整认证。
建议本人能解释：为何区分两棵树、为何保留端点、为何未判定不能当拒绝、为何span依赖原Bytes，以及真实协议覆盖边界。
不虚构采用、性能优势或全后端支持。
