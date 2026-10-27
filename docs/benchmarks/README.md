# Benchmark catalog — latest results

Latest supplied 50 MHz results replace the pending register-MatrixDCT hardware fields. **Whole MFCC: 30,110 LUT, 43,473 FF, 6.5 BRAM tiles, 19 DSP. Standalone MatrixDCT: 1,847 LUT, 2,717 FF, zero BRAM, one DSP.** Hardware values are user-reported OOC post-route summaries; original Vivado reports were not supplied. [Source and checks](matrix_register_50MHz_20261027/README.md).

All six supplied benchmark packages and the two 2026-10-27 result summaries are consolidated here. The primary tables retain the **latest valid result for each test project and configuration**. Architecture, pipeline and version changes do not create separate result rows. Different FFT lengths, clock frequencies, backends being compared, output-lane counts, frame counts and stall conditions remain separate configurations.

Metrics are refreshed independently. A package that only updates 150 MHz implementation does not replace the last measured 50/100 MHz resources. Runtime cycles use the latest matching regression; source columns identify the evidence used for each metric. Earlier reports remain available for traceability without duplicating their values in the primary tables.

## Resource utilization first

Complete MFCC, N=1024, STRIDE=512, OUT_WIDTH=64:

| Project | MHz | LUT | FF | BRAM tiles | DSP |
| --- | --- | --- | --- | --- | --- |
| MFCC / SkewDCT | 50 | 35,601 | 52,870 | 6.5 | 59 |
| MFCC / SkewDCT | 100 | 35,606 | 52,870 | 6.5 | 59 |
| MFCC / SkewDCT | 150 | 35,777 | 53,107 | 6.5 | 59 |
| MFCC / MatrixDCT | 50 | 30,110 | 43,473 | 6.5 | 19 |

Latest 150 MHz MFCC: **35,777 LUT, 53,107 FF, 6.5 BRAM tiles and 59 DSP**, with **WNS +0.258 ns** and zero setup/hold failures. Inclusive child hierarchy counts are already part of whole-MFCC totals. [All resource scopes and standalone FFT/IP figures](overview/Resources.csv).

## Categories

| Category | Included benchmarks | Entry |
| --- | --- | --- |
| Complete MFCC | 50/100/150 MHz; eight FFT sizes; output lanes and stalls; latest timing paths | [Results](full_mfcc/README.md) |
| FFT / XFFT | Eight-size resources, first output, complete-frame latency and numerical error | [Results](fft/README.md) |
| DCT | Latest SkewDCT64 versus MatrixDCT64 resources, standalone latency, complete-MFCC runtime and precision | [Results](dct/README.md) |
| Memory optimization | Matched BRAM before/after resources and paired functional regressions | [Results](memory/README.md) |

## Complete downloads

- [Excel workbook — 14 classified sheets](MFCC_Benchmark_Summary.xlsx), with resources first.
- [Consolidated JSON](combined_data.json), [coverage](overview/Coverage.csv) and [source archives with SHA-256](source_archives.json).
- [Resource CSV](overview/Resources.csv), [source catalog CSV](overview/Sources.csv) and [selection/evidence notes](overview/Readme.csv).
- [Original evidence manifest](evidence/manifest.json). Source files retained in this collection are byte-identical to their supplied reports. Scripts, duplicate production RTL, checkpoints and executables are not copied into the benchmark catalog.
- [Additional supplied summaries and SHA-256](source_supplements.json), including the [50 MHz MatrixDCT/SkewDCT follow-up](matrix_register_50MHz_20261027/README.md).

## Timing and evidence scope

| Project | MHz | WNS ns | WHS ns | Setup failures | Status | Four-frame cycles | Batch us |
| --- | --- | --- | --- | --- | --- | --- | --- |
| MFCC / SkewDCT | 50 | 7.511 | 0.01 | 0 | PASS | 39,508 | 790.16 |
| MFCC / SkewDCT | 100 | 0.688 | 0.003 | 0 | PASS | 39,508 | 395.08 |
| MFCC / SkewDCT | 150 | 0.258 | 0.01 | 0 | PASS | 39,508 | 263.387 |
| MFCC / MatrixDCT | 50 | 8.235 | 0.01 | Not supplied | PASS_REPORTED_WNS_WHS | 43,622 | 872.44 |

Times are RTL cycle counts divided by MHz, not board/PS/DMA measurements. Four-frame batch averages are not independently measured single-frame latency or steady-state initiation intervals. Floating-reference errors cover the tested complete pipeline or FFT vectors, not recognition accuracy.

`PASS_REPORTED_WNS_WHS` records positive margins in supplied summaries. TNS and setup/hold failure counts were not supplied and remain blank; no zero-failure count is inferred.

**200 MHz has no completed implementation result for the latest RTL.** The frozen-route estimate is approximately -1.409 ns; it remains an estimate. The earlier frequency-sweep archive also contains an interrupted 200 MHz attempt (`USER_ABORTED_NOT_COUNTED`), which is excluded from pass/fail results. [Current path analysis](c64_pipeline_N1024_150MHz_20261026/README.md).

## Original evidence collections

Historical implementation-specific reports remain at their original paths to preserve existing links. They are source evidence rather than additional primary result rows: [recursive-SkewDCT reports](recursive_skewdct_N1024_20261026/README.md), [C64 follow-up reports](c64_pipeline_N1024_150MHz_20261026/README.md), and the four earlier packages under [evidence/](evidence/README.md). The previously excluded early DCT measurements remain excluded.
