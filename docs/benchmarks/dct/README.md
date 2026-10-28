# SkewDCT64 and MatrixDCT64 comparison

Latest supplied 50 MHz results replace the pending register-MatrixDCT hardware fields. **Whole MFCC: 30,110 LUT, 43,473 FF, 6.5 BRAM tiles, 19 DSP. Standalone MatrixDCT: 1,847 LUT, 2,717 FF, zero BRAM, one DSP.** Hardware values are user-reported OOC post-route summaries; original Vivado reports were not supplied. [Source and checks](../matrix_register_50MHz_20261027/README.md).

[Benchmark catalog](../README.md) · [Merged comparison CSV](DCT_Comparison.csv) · [Verified merged records](verified_summary.json)

One row is retained per backend. Dense/recursive implementation changes, interface narrowing and C64 pipelining do not form separate comparison rows. Configuration: N=1024, STRIDE=512, 64-point DCT, OUT_WIDTH=64, four frames / 256 coefficients.

## Resources at 50 MHz

| Backend | MFCC LUT | MFCC FF | MFCC BRAM | MFCC DSP | DCT LUT | DCT FF | DCT BRAM | DCT DSP |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| SkewDCT | 35,601 | 52,870 | 6.5 | 59 | 5,875 | 11,981 | 0 | 41 |
| MatrixDCT | 30,110 | 43,473 | 6.5 | 19 | 1,749 | 2,584 | 0 | 1 |

DCT hierarchy counts are included in MFCC totals. The current available 150 MHz SkewDCT-inclusive hierarchy uses 6,041 LUT, 12,125 FF, zero BRAM and 41 DSP; that frequency-specific result is in the [resource overview](../overview/Resources.csv), without replacing the latest measured 50 MHz resource row above.

## Complete-MFCC runtime and error

| Backend | Four-frame cycles | Batch us at 50MHz | MFCC MAE | MFCC RMSE | MFCC SNR dB |
| --- | --- | --- | --- | --- | --- |
| SkewDCT | 39,508 | 790.16 | 3.429 | 12.492 | 16.049 |
| MatrixDCT | 43,622 | 872.44 | 3.429 | 12.49 | 16.05 |

Cycles and floating-reference errors cover the complete MFCC, not standalone DCT latency or isolated DCT error. Runtime/precision sources are linked per row; resource fields use the latest applicable report and remain pending when an RTL replacement invalidates that report. Per-metric source columns retain the provenance. No recognition-accuracy claim follows from these numerical errors. Earlier DCT measurements explicitly removed from the benchmark set remain excluded.

## Standalone 64-point DCT at 50 MHz

| Backend | LUT | FF | BRAM tiles | DSP | WNS ns | WHS ns | First output cycles | Final output cycles | Final us |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| SkewDCT | 5,113 | 12,378 | 0 | 41 | 14.342 | 0.011 | 175 | 238 | 4.76 |
| MatrixDCT | 1,847 | 2,717 | 0 | 1 | 12.740 | 0.067 | 4,289 | 4,352 | 87.04 |

[Standalone CSV](DCT_Standalone.csv). Latency runs from an accepted 64-word input frame to accepted first/final output. Standalone top-level counts are distinct from the inclusive DCT hierarchy inside MFCC: the latter is 1,749 LUT / 2,584 FF / zero BRAM / one DSP for MatrixDCT. The existing 50 MHz SkewDCT MFCC hierarchy report remains the source for that hierarchy; the new standalone value does not replace it.

Both standalone DCTs now report zero BRAM. MatrixDCT uses 63.876% fewer LUT, 78.050% fewer FF and 97.561% fewer DSP than SkewDCT in these supplied runs; its final-output latency is 18.286 times larger. The complete MFCC MatrixDCT batch takes 10.413% more cycles. Different multiplier parallelism remains; these figures alone do not isolate an algorithmic advantage at equal resources.

The normalized MatrixDCT-versus-SkewDCT **complete-MFCC** outputs have MAE 0.004591108, RMSE 0.005612514 and maximum absolute difference 0.015573386. Both report 36.328125% within 1% and 65.234375% within 2% of the floating reference; the supplied summary does not define the relative-error denominator. These are numerical comparisons, not recognition accuracy.
