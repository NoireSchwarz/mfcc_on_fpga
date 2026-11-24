# Matched memory-optimization benchmark

[Benchmark catalog](../README.md) · [Resource savings](Memory_Savings.csv) · [Paired functional regressions](Memory_Regression.csv)

## Matched resource comparison

Complete MFCC, N=512, STRIDE=256, OUT_WIDTH=1, 50 MHz OOC synthesis. This test explicitly compares before and after, so both comparison sides are retained; superseded architecture-generation rows are not added to the general latest-result tables.

| Resource | Before | After | Delta | Change % |
| --- | --- | --- | --- | --- |
| LUT | 65,158 | 26,543 | -38,615 | -59.264 |
| FF | 90,827 | 37,822 | -53,005 | -58.358 |
| BRAM Tile (36 Kb) | 1.5 | 5.5 | 4 | 266.667 |
| DSP | 98 | 98 | 0 | 0 |
| RAMB18 primitives | 3 | 11 | 8 | 266.667 |

LUT use falls by 59.264% and FF use by 58.358%, with unchanged 98 DSP and BRAM increasing from 1.5 to 5.5 tiles. These are synthesis estimates for this matched N512 case; they are not interchangeable with N1024 post-route whole-MFCC numbers.

## Functional regressions

The paired CSV retains all 11 supplied configurations, including FFT lengths 16..2048, one- and 64-lane output, recorded frame counts and stall conditions. Each side reports zero mismatches to its own reference. Cycle changes in stalled cases reflect the recorded test schedules; they are not isolated module throughput measurements. The [complete-MFCC category](../full_mfcc/README.md) uses the latest available result for each corresponding runtime configuration.
