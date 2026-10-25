# 离线采集记录的 URI/Cookie 导入门禁

用途：上游采集器已经分离出一条记录的页面 URI-reference 和请求 Cookie 字段值，
导入前需要校验格式，并把原字节字段交给后续分析。此处把已有独立消费者接成一个
**JSON 输出 + 进程退出码**的适配器。没有网络连接、数据库或第三方服务；不是整条 HTTP 报文解析器。
没有真实用户或生产流量采用证据。

## 输入与来源

输入是两个 argv 文本参数。适配器显式编码为 UTF-8，再使用通用 `compile`、`parse_input`、
`rule_nodes_in`、`span`、`extract`；URI/Cookie 没有硬编码进解析库。
URI 使用 RFC3986 Appendix A 的 `URI-reference`；Cookie 使用 RFC6265 §4.2.1 / §4.1.1 的
`cookie-string` / `cookie-pair`，token/tchar 的已有来源与改写见
[文法归属](../fixtures/protocols/SOURCES.md)。

主案例的 URI `http://www.ietf.org/rfc/rfc2396.txt` 来自
[RFC3986 §1.1.2](https://www.rfc-editor.org/rfc/rfc3986.html#section-1.1.2)，
Cookie `SID=31d4d96e407aad42; lang=en-US` 来自
[RFC6265 §3.1](https://www.rfc-editor.org/rfc/rfc6265.html#section-3.1)。
把两项合成一条采集记录是本例自制的组合，不称它们是同一次真实请求；其中 SID 是规范公开示例值。
其他畸形、重复名、等号、引号、零宽值和预算输入是有意构造的边界，不冒充 RFC 原向量或外部测试集。

## 在三分钟内复现

使用已有可信 MoonBit SDK 和 Node.js，不安装依赖、不调用注册表。
在一个新的空目录解压交付中的 `source.zip`，目录布局如下。使用仓库源码时也可把同一快照目录命名为 `candidate`。

```sh
unzip source.zip -d candidate
cp candidate/integration/protocol_consumer/moon.work.in moon.work
mkdir consumer
cp candidate/integration/protocol_consumer/moon.mod.in consumer/moon.mod
cp candidate/integration/protocol_consumer/moon.pkg.in consumer/moon.pkg
cp candidate/integration/protocol_consumer/main.mbt.in consumer/main.mbt
cp candidate/integration/protocol_consumer/contract_wbtest.mbt.in consumer/contract_wbtest.mbt
export MOONABNF_SDK=/absolute/path/to/existing-trusted-sdk
cd consumer
../candidate/scripts/moon-local.sh tree --json
../candidate/scripts/moon-local.sh test contract_wbtest.mbt --target js --frozen -j 1 -d
../candidate/scripts/moon-local.sh run . --target js --frozen -j 1 -d -- --json 'http://www.ietf.org/rfc/rfc2396.txt' 'SID=31d4d96e407aad42; lang=en-US' > record-report.json
```

依赖树必须指向解压的 `candidate`，且 `source.kind` 是 `local`，不能消费历史 0.1.0 注册表包。
正例进程退出 **0**，JSON 的 `schema` 是 `moonabnf.protocol-record.v1`，`decision` 为 `accept-syntax`。
`components` 保存 scheme、host、path 等规则名与 capture；`cookies` 是有序数组，按 pair 分组，
每项有 `name`、`value`，其中 capture 均为 `{start,end,raw}`。区间单位为原输入的半开字节偏移。
原文法 AST 描述这些规则；输入树描述本次匹配，JSON 是从输入树提取的应用数据，不是文法 AST。

例如 RFC Cookie 的 SID 名为 `[0,3)`、值为 `[4,20)`；lang 名为 `[22,26)`、值为 `[27,32)`。
完整黄金输出见 [expected-record.json](../integration/protocol_consumer/expected-record.json)。

接着分别观察拒绝和资源边界（**预期非零退出**）：

```sh
../candidate/scripts/moon-local.sh run . --target js --frozen -j 1 -d -- --json 'http://example.test/%GG' 'a=bad value'
../candidate/scripts/moon-local.sh run . --target js --frozen -j 1 -d -- --json '/ok' 'a=b' 1
../candidate/scripts/moon-local.sh run . --target js --frozen -j 1 -d -- --json '/ok' 'a=b' 0
```

| 退出码 | decision | 导入方的处理 |
| --- | --- | --- |
| 0 | accept-syntax | 可把提取结果交给业务规则；不代表授权或完整协议语义成立 |
| 1 | reject | 明确语法不匹配，隔离记录；保留字段诊断偏移 |
| 3 | defer | 预算未判定，进入独立复核队列；不能当作非法输入 |
| 2 | usage/configuration error | 修正调用/预算配置；不导入 |

最后一个可选参数是每个字段的树节点预算，十进制 1..100000，默认 20000；0/负数/非数字/超上限在识别前退出2。
其余仍使用库默认硬边界：每字段输入65536字节、工作量500000、累积端点100000、深度128、树边40000。
这不是墙钟时限。两个字段分别消费预算；即使某字段已经匹配，只要整条记录被拒绝或暂缓，
`components` 和 `cookies` 都为空，防止下游误用部分成功数据。配置错误优先于预算，预算优先于拒绝。
每个字段摘要仍说明 `status`、`reason`、`offset`、`input_bytes`、`tree_absent`；某字段自身匹配时 tree_absent 可以为false。

原两参数人类可读模式仍保留，黄金输出不变；它的退出0仅表示诊断报告完成。
**导入门禁必须使用 `--json` 模式**。SDK 参数 `-j 1` 和应用参数前的 `--` 不要省略。

## 与现有办法的有据对比

| 本例需求 | 现有 recognize | 本例 parse_input + scoped capture |
| --- | --- | --- |
| 按同一 RFC 文法判断整字段 | 提供状态与偏移；只需是/否时可继续使用 | 同样做语法识别，增加有预算的树构建 |
| 原字节字段与所在位置 | MatchReport没有字段/span，需要另写拆分 | 输出原字节半开span，保留百分号编码、引号和空值 |
| Cookie同名多项 | 单个状态不描述各项 | pair子树分别提取，数组保留每次出现，不用Map覆盖 |
| 预算失败 | 识别预算可能未判定 | 树节点/边也有预算，未判定不会被当作接受 |

`contract_wbtest.mbt.in` 对同一组 RFC 输入同时调用 recognize 和适配器，断言两者接受，
再断言具体捕获；另检查 `a=x=y; a="z"; a=` 的三个原值、零宽span、UTF-8非法字节偏移、
拒绝/预算无导出字段，以及预算失败后同一个Program仍可复用。
仅把 Cookie 按分号和第一个等号拆开再存进Map，会把同名项覆盖，且拆分本身并不校验cookie-octet；
这里比较的是这种具体简化写法，不是所有手写解析器，更不是与成熟HTTP库的性能比赛。
[RFC6265 §4.2.2](https://www.rfc-editor.org/rfc/rfc6265.html#section-4.2.2)
说明同名Cookie可能存在且服务器不应依赖其序列次序；本例保留次序供诊断，但不定义哪项应当生效。

代价：生成树比只取识别状态需要更多预算；这个短命令每次编译两个Program，只处理一条记录。
没有吞吐、内存优于竞品或生产部署宣称。通用库可让长期消费者编译一次复用，当前进程没有批量/流式承诺。

## 覆盖边界与事实身份

- 这里校验URI generic syntax，接受相对引用和fragment；不是HTTP request-target或scheme-specific语义校验，
  不做URI归一化、percent解码、DNS、资源获取或相对引用解析。
- Cookie采用§4的严格语法profile，不是浏览器§5的容错接收器，也不解析Set-Cookie。
  必须传入已经存在的Cookie字段值；无Cookie请求的可选字段处理由上游负责。
- 原始日志的引号/转义必须由上游先还原；argv不是二进制传输接口，不能携带NUL。
  通用库仍接收Bytes。成功字段为ASCII，JSON raw不去引号；未知UTF-8字节不被偷偷修复成合法协议输入。
- `accept-syntax`不验证Cookie Domain/Path/Secure/过期/认证/隐私策略。不要从本例推断完整HTTP支持。
- 适配器只测JS；核心四后端及PR fresh-clone的既有CI保持其原提交身份。
  发布后的registry消费者已有独立回执；本轮新复现脚本仅本地验证，未取得其新远端CI。

当前正式发布版本为0.2.1，开发候选manifest为未发布的0.3.0，发布与消费回执见[0.2.1说明](release-0.2.1.zh-CN.md)。上面的空目录源码方案消费解压快照，不是registry安装；两者要分开记录。JSON适配器仍是需复制的集成示例，不是根包API。RFC来源/许可在[SOURCES.md](../SOURCES.md)，
AI辅助事实在[AI_USAGE.md](../AI_USAGE.md)。没有替用户撰写诚信声明、提交比赛或承诺获奖。

## 一键核验实际发布包（2026-10-25 本地补强）

```sh
MOONABNF_SDK=/existing/trusted/sdk python3 scripts/registry_protocol_record_test.py --release-version 0.2.1 --output /new/empty/registry-case
```

该命令在全新目录从registry安装精确0.2.1，检查依赖树source.kind=registry、非workspace member；随后以frozen单worker运行既有4项契约和JSON黄金/拒绝/预算/配置检查，拒绝/预算不导出部分字段，Program复用由既有白盒契约确认。脚本和模板的SHA256记录于本地回执。使用已发布公共核心与文法子包，不复制库算法，也不替代source-bound协议测试。需要已有SDK及Mooncakes网络可达；没有联网业务服务或生产数据。

脚本保留默认0.2.0供历史回归，复现当前发布包须显式传上面的`--release-version 0.2.1`。未发布的`diagnose_input`与JSON诊断扩展只在开发源码中使用，见[README源码入口](../README.md#未发布源码有界输入失败解释)；本节registry命令使用原模板，不会调用新API。
