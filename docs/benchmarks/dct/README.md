# SkewDCT64 and MatrixDCT64 comparison

[Benchmark catalog](../README.md) · [Merged comparison CSV](DCT_Comparison.csv) · [Verified merged records](verified_summary.json)

One row is retained per backend. Dense/recursive implementation changes, interface narrowing and C64 pipelining do not form separate comparison rows. Configuration: N=1024, STRIDE=512, 64-point DCT, OUT_WIDTH=64, four frames / 256 coefficients.

## Resources at 50 MHz

| Backend | MFCC LUT | MFCC FF | MFCC BRAM | MFCC DSP | DCT LUT | DCT FF | DCT BRAM | DCT DSP |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| SkewDCT | 35,601 | 52,870 | 6.5 | 59 | 5,875 | 11,981 | 0 | 41 |
| MatrixDCT | 30,188 | 41,987 | 9 | 19 | 647 | 1,098 | 2.5 | 1 |

DCT hierarchy counts are included in MFCC totals. The current available 150 MHz SkewDCT-inclusive hierarchy uses 6,041 LUT, 12,125 FF, zero BRAM and 41 DSP; that frequency-specific result is in the [resource overview](../overview/Resources.csv), without replacing the latest measured 50 MHz resource row above.

## Complete-MFCC runtime and error

| Backend | Four-frame cycles | Batch us at 50MHz | MFCC MAE | MFCC RMSE | MFCC SNR dB |
| --- | --- | --- | --- | --- | --- |
| SkewDCT | 39,508 | 790.16 | 3.429 | 12.492 | 16.049 |
| MatrixDCT | 43,687 | 873.74 | 3.429 | 12.49 | 16.05 |

Cycles and floating-reference errors cover the complete MFCC, not standalone DCT latency or isolated DCT error. Latest runtime/precision values come from the C64 follow-up regression; latest resources come from the most recent report for that frequency. Per-metric source columns retain the provenance. No recognition-accuracy claim follows from these numerical errors. Earlier DCT measurements explicitly removed from the benchmark set remain excluded.
