KV260 最新通用架构 FFT2048 / 150 MHz 测试结果
日期：2026-11-24

1. 被测版本
- GitHub 分支：optimization/skewdct8-recursive-pipeline
- Commit：9be89af18ca9cf42e6f47990d7d1b781afb47615
- 架构链：fft512 -> fft_tree_bram_engine -> fft2x
- 未使用此前的 fft2048_bram_stream 专用候选核。
- 算法 RTL 未为本次测试修改；仅增加板测包装、JTAG 测试设施和时钟配置。

2. 频率与时序
- 板端 PL1 实测配置：100,000,000 Hz。
- MMCM：反馈倍频 12，输出分频 8。
- 物理 fabric 时钟：150,000,000 Hz。
- Vivado 报告中的 149.998501 MHz 来自 KV260 PS 接口元数据将 100 MHz 写成 99.999001 MHz；生成的 MMCM 硬件参数仍是 12/8，板端寄存器读回确认输入为准确 100 MHz。
- Post-route WNS：+0.731 ns。
- Post-route WHS：+0.011 ns。
- Setup failing endpoints：0。
- Hold failing endpoints：0。
- 未布线或部分布线网络：0。

3. 资源占用
算法核心层级：
- LUT：9001
- FF：8505
- BRAM：8.5 tiles（5 RAMB36 + 7 RAMB18）
- DSP：8

包含 JTAG/AXI 板测设施的完整顶层：
- LUT：11009（9.40%）
- FF：11450（4.89%）
- BRAM：27 tiles（18.75%）
- DSP：8（0.64%）

4. 真实 KV260 板测
- 接口：USB/JTAG。
- 所有数据均在物理 150 MHz 下运行。
- 9 组测试全部通过，逐个 32 位输出字比较：0 mismatch、0 error。
- 单帧测试：每帧输入 2048 点、输出 2048 个复数数据字；总计 25390 cycles，首个输出位于 23343 cycles。
- 单帧总周期换算：169.267 us @ 150 MHz。
- 首输出延迟换算：155.620 us @ 150 MHz。
- 连续 4 帧测试：8192 输入、8192 输出，总计 101545 cycles，即 676.967 us。
- 测试集：original、zero、impulse、dc、alternating、random_low、random_full、original_4frames、mixed_4frames。

5. 数据口径
- 输入与期望输出语料沿用此前完整数值仿真生成的固定 9 组数据。
- 最新通用架构的真实板上输出对全部期望字均完全一致，因此同时证明其与该数值基线功能等价。
- host 端 upload/poll/download 毫秒数受 JTAG 传输与轮询影响，不代表 FFT 核计算时间；核心性能以板内 cycle counter 为准。

6. 文件结构
- 01_source：锁定 commit 的最新 FFT RTL、板测包装和复现脚本。
- 02_implementation：bitstream、路由 DCP、时序/资源/DRC/路由报告。
- 03_board_test：板端时钟读回、9 组原始输出及汇总 CSV。
- 04_logs：Vivado 构建和真实板测原始日志。

结论：项目最新通用 FFT 架构在 KV260 上以 2048 点模式、物理 150 MHz 真实运行通过；无需用专用 FFT2048 核替代。
