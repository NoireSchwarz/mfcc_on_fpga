# FFT and XFFT benchmarks

[Benchmark catalog](../README.md) · [Resources](FFT_Resources.csv) · [Latency](FFT_Latency.csv) · [Numerical error](FFT_Accuracy.csv) · [Verified source summary](verified_summary.json)

## Resources

| Backend | Points | LUT | FF | BRAM tiles | DSP | Stage | Resource clock ns |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Custom FFT | 16..2048 runtime | 10,539 | 12,004 | 8.5 | 8 | OOC post-route | 20 |
| XFFT | 1,024 | 1,643 | 2,950 | 3.5 | 9 | OOC synthesis estimate | 10 |
| XFFT | 128 | 1,551 | 2,825 | 3.5 | 9 | OOC synthesis estimate | 10 |
| XFFT | 16 | 699 | 1,276 | 1.5 | 3 | OOC synthesis estimate | 10 |
| XFFT | 2,048 | 1,786 | 3,087 | 3.5 | 9 | OOC synthesis estimate | 10 |
| XFFT | 256 | 1,563 | 2,855 | 3.5 | 9 | OOC synthesis estimate | 10 |
| XFFT | 32 | 718 | 1,307 | 1.5 | 3 | OOC synthesis estimate | 10 |
| XFFT | 512 | 1,615 | 2,923 | 3.5 | 9 | OOC synthesis estimate | 10 |
| XFFT | 64 | 1,502 | 2,747 | 3.5 | 9 | OOC synthesis estimate | 10 |

Each backend/configuration has one current row. Benchmark timing is expressed at 50 MHz. The resource report's actual synthesis/implementation clock is retained separately: 20 ns for the custom post-route core, 10 ns for fixed-size XFFT synthesis. The custom instance supports all eight runtime lengths; XFFT resource rows describe individual fixed-size instances. The 64..2048 XFFT latency results use runtime_2048. These are measurement attributes; architecture generations are not repeated as separate result rows.

## First output and complete frame

| N | First-output cycles | Custom full-frame cycles | XFFT full-frame cycles | Custom us | XFFT us |
| --- | --- | --- | --- | --- | --- |
| 16 | 68 | 82 | 154 | 1.64 | 3.08 |
| 32 | 164 | 243 | 253 | 4.86 | 5.06 |
| 64 | 443 | 554 | 257 | 11.08 | 5.14 |
| 128 | 827 | 1,194 | 487 | 23.88 | 9.74 |
| 256 | 1,357 | 1,612 | 871 | 32.24 | 17.42 |
| 512 | 2,893 | 4,172 | 1,789 | 83.44 | 35.78 |
| 1,024 | 8,239 | 10,030 | 3,453 | 200.6 | 69.06 |
| 2,048 | 14,383 | 20,270 | 7,315 | 405.4 | 146.3 |

First-output values use the latest package reporting that metric (2026-10-22). Complete-frame custom/XFFT comparison values use the newer 2026-10-25 package. For N=16 the latest reported custom full-frame count is **82**, while its accompanying regression records **83**; this counting/start-boundary discrepancy is retained in the CSV evidence column rather than replaced with an invented agreement. The original XFFT timing transcript is absent, so its cycle counts remain package-reported values. All times are cycles/50 MHz; configuration preambles and backpressure are excluded from this comparison.

## Numerical results

| N | Custom RMSE | XFFT RMSE | Custom SNR dB | XFFT SNR dB |
| --- | --- | --- | --- | --- |
| 16 | 0.723 | 0.6 | 57.736 | 59.355 |
| 32 | 0.624 | 0.531 | 56.047 | 57.444 |
| 64 | 0.527 | 0.445 | 54.475 | 55.946 |
| 128 | 0.321 | 0.537 | 55.808 | 51.324 |
| 256 | 1.611 | 0.472 | 38.755 | 49.424 |
| 512 | 1.361 | 0.538 | 37.212 | 45.281 |
| 1,024 | 1.058 | 0.477 | 36.393 | 43.323 |
| 2,048 | 0.595 | 0.527 | 38.389 | 39.438 |

The reference is FFT/N for one real-only input vector per size. The packaged generation recipe reproduces the error metrics, but original benchmark_input/reference files are absent. XFFT RTL numeric outputs for 64..2048 match its official C model; 16/32 RTL numeric outputs are absent. These vectors do not establish arbitrary complex-input coverage or broad audio accuracy.
