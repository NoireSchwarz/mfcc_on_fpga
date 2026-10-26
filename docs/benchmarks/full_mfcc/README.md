# Complete-MFCC benchmarks

[Benchmark catalog](../README.md) · [Frequency CSV](MFCC_Frequency.csv) · [FFT-size/output CSV](MFCC_PointSweep.csv) · [Latest setup paths](Timing_Paths.csv)

## Resources and timing

N=1024, STRIDE=512, OUT_WIDTH=64, four frames. Only the latest available metric is shown for each configuration; architecture/version labels are not separate rows.

| Project | MHz | LUT | FF | BRAM tiles | DSP |
| --- | --- | --- | --- | --- | --- |
| MFCC / SkewDCT | 50 | 35,601 | 52,870 | 6.5 | 59 |
| MFCC / SkewDCT | 100 | 35,606 | 52,870 | 6.5 | 59 |
| MFCC / SkewDCT | 150 | 35,777 | 53,107 | 6.5 | 59 |
| MFCC / MatrixDCT | 50 | 30,188 | 41,987 | 9 | 19 |

| Project | MHz | WNS ns | WHS ns | Setup failures | Status | Four-frame cycles | Batch us |
| --- | --- | --- | --- | --- | --- | --- | --- |
| MFCC / SkewDCT | 50 | 7.511 | 0.01 | 0 | PASS | 39,508 | 790.16 |
| MFCC / SkewDCT | 100 | 0.688 | 0.003 | 0 | PASS | 39,508 | 395.08 |
| MFCC / SkewDCT | 150 | 0.258 | 0.01 | 0 | PASS | 39,508 | 263.387 |
| MFCC / MatrixDCT | 50 | 8.254 | 0.01 | 0 | PASS | 43,687 | 873.74 |

The latest SkewDCT batch requires 39,508 cycles: 790.160 us at 50 MHz, 395.080 us at 100 MHz, and 263.387 us at 150 MHz. Resource/timing sources at 50/100 MHz are the latest corresponding frequency reports; the cycle count comes from the newer matching regression. The per-metric source columns preserve this distinction without splitting architecture versions into separate cases.

## FFT-size and output-interface cases

| FFT N | Output lanes | Stalls | Frames | Cycles | Batch us at 50 MHz |
| --- | --- | --- | --- | --- | --- |
| 16 | 1 | 1 | 4 | 1,226 | 24.52 |
| 32 | 1 | 1 | 4 | 1,407 | 28.14 |
| 64 | 1 | 1 | 4 | 2,537 | 50.74 |
| 128 | 1 | 1 | 4 | 4,304 | 86.08 |
| 256 | 1 | 1 | 4 | 6,838 | 136.76 |
| 512 | 1 | 1 | 4 | 13,950 | 279 |
| 1,024 | 1 | 1 | 4 | 37,307 | 746.14 |
| 2,048 | 1 | 1 | 4 | 65,677 | 1,313.54 |
| 128 | 64 | 1 | 4 | 4,233 | 84.66 |
| 512 | 64 | 1 | 16 | 51,711 | 1,034.22 |
| 512 | 64 | 0 | 16 | 51,258 | 1,025.16 |
| 1,024 | 64 | 0 | 4 | 39,508 | 790.16 |

Rows with different output lanes, frame counts or stalls are distinct test configurations. Stalled regression times are not isolated FFT/DCT performance. The 50 MHz eight-size one-lane sweep is included alongside the available 64-lane cases; a result is not invented for an untested combination.

## 200 MHz status

The newest 150 MHz run has WNS +0.258 ns and WHS +0.010 ns. Its reported worst setup paths comprise 12 filter-bank acknowledgement/frame-clear paths and eight input-selection/Hamming-to-FFT-RAM paths. The former has a 4,167-load control net and 95.07% route delay. These 20 paths are the listed worst paths, not an exhaustive classification of the design.

Reducing the period from 6.667 ns to 5.000 ns while freezing route/skew/uncertainty gives approximately -1.409 ns worst slack. No completed 200 MHz run exists for this RTL. The earlier ver.2 200 MHz attempt was interrupted during placement and is [recorded as USER_ABORTED_NOT_COUNTED](../evidence/ver2/04_frequency_runs/mfcc_N1024_200MHz/status.txt), not a timing failure or pass. [Detailed current analysis](../c64_pipeline_N1024_150MHz_20261026/README.md).

Post-route OOC timing does not establish board-level I/O or bitstream signoff. Original constraints, DRC and routing qualifications remain in the source evidence.
