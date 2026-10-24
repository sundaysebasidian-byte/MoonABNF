# 验证准备（Draft）（2026-10-24）

基线 `5a410cc9c1aabec49a72a93161118e6a4eebe076`。本补丁未公开，版本保持 0.2.0。既有主分支/registry 结果不为本补丁背书；CI 配置已准备未执行。

`MOONABNF_SDK=/existing/sdk python3 scripts/protocol_record_test.py --output /new/out` 复用 integration/protocol_consumer 与 contract_wbtest，测试源码绑定的实际 ZIP，使用显式本地 workspace。它**不是 registry 消费测试**，不改 scripts/registry_consumer.py，不替换发布轮证据。check/test/run 均 JS、frozen、单 worker；非空输出目录拒绝；全程 120 秒与进程树 RSS 512 MiB 上限，失败保留 partial 日志。CI 在 acceptance 后单列一步、always 仅保存白名单 JSON/命令日志，不上传 workspace/归档。

## 成对成本

使用现有官方 SDK，串行运行：

```sh
export MOON_HOME=/existing/sdk
export PATH="$MOON_HOME/bin:$PATH"
export RUST_LOG=error
python3 scripts/bounded_run.py --output /new/workloads -- moon bench benchmarks --target js --release --frozen --no-parallelize -j 1
```

URI IPv6 和 4096B binary 的 recognize/tree 共享相同输入、SDK、release 模式及 matching 预算；树还单列自身 nodes/edges 预算。compile 单独计时，不混入识别/构树时间；已有 Cookie 对称项保留。work/states/nodes/edges 是算法计数，**不是 RSS**；RSS 为外部监督器对本命令进程树的采样和，记录上限/partial，不宣称精确 OS 峰值。

core bench 的 `count=5` 是同一进程的五组自适应统计，不能描述成五轮独立实验，也不推导 p95、吞吐优势或生产内存。匹配、拒绝、预算未判定分别输出；合成 URI 非法 IPv6、短 binary 和极低 work 预算是自编控制。

## 复用来源

RFC3986 八 URI 与 IPv6 边界、RFC6265 单字节 raw/quoted 共 512 对照继续使用 `examples/protocols/protocols_test.mbt`；ETag 的 256 字节对照继续使用 `examples/http_etag`。不另造 oracle。规范/文法哈希及许可保持在 `fixtures/protocols/SOURCES.md`、sources.json、根 SOURCES.md 与 licenses/。其余手工负例、自编适配代码不冒充第三方一致性套件；完整协议语义、生产采用与性能领先均无此证据。

## 本轮本地结果

Mac arm64，moon 0.1.20260920 (914d7da)，moonc v0.10.14+7d59c7ec9；2026-10-24 一轮串行有界复验。源码绑定协议脚本通过，契约 4/4；JSON 接受/拒绝/预算/配置进程退出码分别 0/1/3/2，后三区分按预期判定。规范复用测试 8/8，fixture 来源哈希通过，非空输出目录拒绝退出2并保留 sentinel。info/fmt 通过，生成接口无差异。

单次 JS release bench（含构建）8.957秒，采样进程树 RSS 峰值255492096字节（约243.7MiB），未达上限。core bench 同进程五组自适应统计：URI40B recognize均值61.39µs、tree127.16µs；binary4096B recognize245.84µs、tree2.09ms。compile_cookie20.27µs、compile_uri107.06µs、compile_binary7.73µs单列。这些只是本机单次观测，不是跨实现优势、独立五轮、p95或生产性能承诺。

URI匹配 recognize/tree 的 work为5565/10512、states1276/1766，树nodes1231/edges1869；binary匹配work24581/67595、states8194/12290，树nodes16388/edges20482。自编拒绝与work=1预算未判定日志单列。节点/边是算法计数，不是RSS。

首轮误给 tree 传--frozen、info传-j，均诊断退出2；按本SDK help修正后，受影响步骤复验通过。旧失败日志保留，不改成成功。远端CI未运行，既有registry消费者没有重跑或改动。完整本地命令、原始输出和源码哈希在本任务私有证据目录，不随公共artifact上传。

## Draft PR 费用约束

公开仓库使用标准 GitHub-hosted runner。本分支禁用 artifact 上传且不增加缓存写入，结果保留于普通日志/job summary；它们不计入 artifact 存储额度。未扩大账户权限或新增费用承诺。配置中的禁用上传步骤不是已上传证据。
