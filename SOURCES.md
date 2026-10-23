# 来源与许可清单

| 来源 | 链接/位置 | 用途与参考范围 | 许可/处理 |
|---|---|---|---|
| RFC 5234, D. Crocker / P. Overell, January 2008 | https://www.rfc-editor.org/info/rfc5234/ | 完整阅读；规则名、操作符、CRLF/c-wsp、数值终端、core 语义 | IETF Trust / BCP 78；自己的算法实现，不打包 RFC 原文或抽取的 ABNF 文本 |
| RFC 7405, P. Kyzivat, December 2014 | https://www.rfc-editor.org/info/rfc7405/ | 完整阅读；%s/%i 与默认字符串匹配语义 | IETF Trust；不把 RFC 原文作为 MIT 重新分发 |
| IETF Trust Legal Provisions | https://trustee.ietf.org/documents/trust-legal-provisions/tlp-5/ | 核对文本引用与 Code Components；旧 RFC 适用其发布日期条款 | 若未来抽取 RFC grammar/Code Components，须单独保留归属及适用 BSD 文本，不默认整体 MIT |
| MoonBit core bundled with locked SDK | https://github.com/moonbitlang/core | builtin、debug、env、json 等 API；读取 API/FFI 形状，不移植标准库源码 | Apache-2.0 及 NOTICE；原样保留在 licenses/ |
| MoonBit package documentation | https://docs.moonbitlang.com/en/latest/toolchain/moon/package.html | JS 专用 CLI、CommonJS link 配置 | API 文档参考，无复制正文 |
| Python standard library re | https://docs.python.org/3/library/re.html | 独立字节正则 oracle；无第三方 Python ABNF 包 | Python 自身许可，无 Python 源码打包 |
| Mooncakes module search | https://mooncakes.io/ | 2026-09-30 abnf、bnf 两次有界站内核查 | abnf 仅返回 marianoguerra/uri@0.1.2 字符编码表；bnf 无结果；不是全生态穷尽证明 |
| marianoguerra/uri | https://mooncakes.io/docs/marianoguerra/uri@0.1.2/enc | 只读摘要对比范围 | 未复制代码，未作为依赖或 fixture 来源 |
| 用户先前 LogLens CI | 本机只读既有配置 | 核实已经使用的官方固定版安装参数与 SDK 来源 | 未修改 LogLens，未复制其功能或 fixtures |
| 本项目 fixtures 与例子 | fixtures/、examples/、scripts/differential.py、integration/protocol_consumer/ | AI辅助自制输入，无真实业务或个人数据；规范文法及RFC原例子按对应行单独归属 | 自制周边代码MIT，不把规范抽取部分改称MIT原创 |
| RFC9110, Fielding / Nottingham / Reschke, June 2022 | https://www.rfc-editor.org/rfc/rfc9110.html#section-8.8.3 与 §5.5 | examples/http_etag/main.mbt 字段值文法Code Component，不是完整HTTP实现，输入自制 | Copyright 2022 IETF Trust，文法见licenses/rfc9110-BSD，不称MIT原创 |
| RFC9112, Fielding / Nottingham / Reschke, June 2022；RFC3986 pchar/unreserved/pct-encoded/sub-delims | https://www.rfc-editor.org/rfc/rfc9112.html#section-3 、https://www.rfc-editor.org/rfc/rfc3986.html | examples/request_line 的 request-line、method/tchar、http-version 与路径/查询规则（origin-form 简化），输入自制 | Copyright IETF Trust，Code Component 适用 IETF BSD（同 licenses/rfc9110-BSD 文本），不称 MIT 原创；周边示例实现为 MIT |
| Official compiler release | https://github.com/moonbitlang/moonbit-compiler/releases/tag/v0.10.14%2B7d59c7ec9 | 原生SDK下载403后的同版本Wasm编译器/formatter和捆绑core，官方源码工具构建路径 | 隔离工具链、不打包进项目；发布SHA256核对见本轮记录 |
| Official MoonBit skills | https://github.com/moonbitlang/skills | moonbit-agent-guide 工程指导 | 只参考规范，不复制实现 |
| RFC3986, Berners-Lee / Fielding / Masinter, January 2005 | https://www.rfc-editor.org/rfc/rfc3986.html#appendix-A | URI grammar in fixtures/protocols and examples/protocols; path-empty zero-count prose replaced by empty literal; §1.1.2 URI examples | Original copyright/BCP78 notice retained in licenses/rfc3986-notice; grammar/examples not relicensed as MIT |
| RFC6265, A. Barth, April 2011 | https://www.rfc-editor.org/rfc/rfc6265.html#section-4.2.1 | Cookie grammar with explicit RFC9110 token/tchar; independent consumer imports this same attributed grammar | licenses/rfc6265-BSD and licenses/rfc9110-BSD; surrounding adapter/tests are self-authored |

2026-10-23离线记录案例另使用RFC3986 §1.1.2的单个HTTP URI、RFC6265 §3.1的单个Cookie字段值；
保留上述对应归属与许可。两项组合为一条采集记录及失败/重复/预算输入均为自制，不是生产流量或外部认证语料。

标准语义的功能重实现与第三方原文抽取有区别。这里不附 RFC 原文、标准示例长段落或
第三方测试集；新增RFC9110文法Code Component按上表单独归属。不是其他ABNF库源码移植。发布二进制时继续携带标准库及依赖
许可证/NOTICE，并核对最终构建组件；当前交付为源码及自制材料。

Protocol corpus exception: fixtures/protocols/*.abnf and the corresponding embedded grammar are third-party grammar Code Components with the notices above; surrounding code and generated test inputs are MIT.
