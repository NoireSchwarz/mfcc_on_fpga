# MatrixDCT register/LUT replacement validation

[Benchmark catalog](../README.md) · [Implementation notes](../../MatrixDCT_Register_Storage.md) · [Verified JSON](verified_results.json)

Current MatrixDCT storage uses FF input/output words and a LUT coefficient ROM, replacing the former BRAM implementation. Public ports and numeric parameters are retained. Operand selection, multiplication and accumulation remain registered separately; the arithmetic still uses one multiplier expression.

Six unit parameter cases compare 12,288 coefficients against the old RTL and an independent integer model, with zero differences. Twenty complete-MFCC configurations compare 5,120 coefficients, also with zero differences. Reset, output backpressure, custom coefficients, all shift settings and unchanged SkewDCT controls are covered.

No-stall standalone first/final output: **4,289 / 4,352 cycles**, versus 4,354 / 4,417 previously. N1024, 64-lane, four-frame MFCC: **43,622 cycles**, versus 43,687. Output coefficient CSV hashes match the previous MatrixDCT regression.

**New hardware resource and timing measurements are pending.** Simulation does not certify physical RAM mapping or frequency closure. Older MatrixDCT BRAM resource reports remain historical evidence; they are not assigned to the current register/LUT implementation in the primary catalog. DSP parallelism remains different from SkewDCT, so this replacement alone does not establish an equal-resource algorithm comparison.

This is a local RTL regression supplement to the six supplied benchmark archives. Detailed generated logs and helper scripts are not uploaded.
