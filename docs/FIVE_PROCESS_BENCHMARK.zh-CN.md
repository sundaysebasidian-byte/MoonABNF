# 五次独立运行实测（本地候选，2026-10-25）

固定Mac16,12、arm64、16GiB内存、10逻辑核，SDK/moonc/Node完整版本、文法与工作负载SHA256、URI/Cookie原字节及binary长度/摘要均保存在原始summary。串行、JS release、frozen、单worker；先构建一次，再启动五个独立进程。每进程内部core bench仍包含五组自适应warm-up/测量；不能把内部组当独立进程。

构建缓存为暖；未清空OS文件缓存，未隔离其他系统后台任务。每轮是新运行时/JIT进程，但下面均值是各进程内adaptive测量的稳态均值，不是冷启动延迟。进程wall时间含启动/校准，分别保留，不从五个均值推p95。没有跨语言、不同优化配置速度胜负宣传。

下表单位全部为µs；binary tree由原始ms换算。不是合并所有内层样本所得统计：

| 独立轮次 | PID | URI recognize | URI tree | binary recognize | binary tree |
|---|---|---|---|---|---|
| 1 | 89886 | 60.29 | 125.29 | 283.76 | 2260.00 |
| 2 | 89939 | 59.40 | 125.48 | 228.42 | 2160.00 |
| 3 | 89997 | 60.39 | 125.50 | 220.83 | 2120.00 |
| 4 | 90069 | 60.53 | 126.74 | 221.89 | 2090.00 |
| 5 | 90127 | 64.87 | 128.27 | 229.93 | 2330.00 |

compile_cookie/compile_uri/compile_binary逐轮单列在原始stdout与means_us，不混入recognize/tree；work/states/nodes/edges与RSS分别记录。每进程120秒/RSS512MiB监督，五轮均退出0，无超限。完整输入、原始数据及命令见本任务evidence/quarter-followup/five-independent；这些本机完整日志未公开上传。

复现：`MOONABNF_SDK=/existing/sdk python3 scripts/independent_workloads.py --output /new/five-processes`。输出目录必须不存在。每轮stdout/stderr和summary均保留。
