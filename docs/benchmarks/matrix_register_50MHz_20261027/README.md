# Register MatrixDCT and recursive SkewDCT results - 2026-10-27

[Benchmark catalog](../README.md) | [DCT comparison](../dct/README.md) | [Original JSON](results.json) | [Original CSV](results.csv) | [Import checks](verification.json) | [File hashes](manifest.json)

## Resource utilization

| Scope | Backend | LUT | FF | BRAM tiles | DSP |
| --- | --- | ---: | ---: | ---: | ---: |
| Whole MFCC, N1024 | Register MatrixDCT | 30,110 | 43,473 | 6.5 | 19 |
| DCT hierarchy inside MFCC | Register MatrixDCT | 1,749 | 2,584 | 0 | 1 |
| Standalone 64-point DCT | Register MatrixDCT | 1,847 | 2,717 | 0 | 1 |
| Standalone 64-point DCT | Recursive SkewDCT | 5,113 | 12,378 | 0 | 41 |

The MFCC hierarchy is included in the whole-MFCC counts. Standalone top-level resources are a separate measurement scope. No new whole-MFCC or MFCC-child hierarchy resource result was supplied for SkewDCT; their existing frequency-matched reports remain selected in the catalog.

## Runtime and timing

| Scope | Backend | Final cycles | Nominal us at 50 MHz | WNS ns | WHS ns |
| --- | --- | ---: | ---: | ---: | ---: |
| Four-frame complete MFCC | Register MatrixDCT | 43,622 | 872.44 | +8.235 | +0.010 |
| Four-frame complete MFCC | Recursive SkewDCT | 39,508 | 790.16 | Not supplied | Not supplied |
| Standalone DCT | Register MatrixDCT | 4,352 | 87.04 | +12.740 | +0.067 |
| Standalone DCT | Recursive SkewDCT | 238 | 4.76 | +14.342 | +0.011 |

First accepted DCT outputs occur at 4,289 and 175 cycles respectively. MatrixDCT takes 18.286 times as many cycles standalone, and 10.413% more cycles in the full MFCC test. Its single DSP versus 41 for SkewDCT reflects different parallelism. Both standalone implementations report zero BRAM.

## Numerical results

| Backend | MFCC MAE | MFCC RMSE | MFCC maximum absolute error | MFCC SNR dB |
| --- | ---: | ---: | ---: | ---: |
| Register MatrixDCT | 3.428547093 | 12.490109975 | 101.608879154 | 16.049668875 |
| Recursive SkewDCT | 3.428606572 | 12.491610941 | 101.624452540 | 16.048625134 |

Normalized complete-MFCC output differences between the two backends: MAE 0.004591108, RMSE 0.005612514, maximum 0.015573386. These are not isolated DCT error measurements or recognition results. Both summaries report 36.328125% within 1% and 65.234375% within 2%; the denominator convention is not supplied.

## Evidence and validation

The two supplied summaries identify unchanged RTL from commit `0dce6b054028ff37c3158adc0184acc030211d0e`, branch `optimization/skewdct8-recursive-pipeline`, device `xck26-sfvc784-2LV-c`, Vivado 2026.1. The CSV and JSON metrics, time conversions and comparison ratios were crosschecked. MatrixDCT cycle counts and precision agree with the previous independently verified local regression. Supplied files are retained byte-for-byte with SHA-256 hashes.

One derived percentage in the JSON differs slightly from its underlying counts: FF reduction is 78.049765713% from 2,717 versus 12,378 FF, rather than the supplied 78.050573598%. Analysis uses the recomputed value; the original file remains unchanged and the discrepancy is recorded in the import checks.

Hardware numbers and PASS status are user-reported out-of-context post-route results. Original Vivado utilization/timing reports and raw coefficient outputs were not included, so physical metrics were not independently recomputed here. Positive WNS/WHS are recorded as `PASS_REPORTED_WNS_WHS`; unreported TNS and setup/hold failure counts remain blank. Times are cycles divided by 50 MHz, not board, PS, DMA or audio wall-clock measurements. These 50 MHz runs do not establish 150/200 MHz timing closure for the replacement MatrixDCT.
