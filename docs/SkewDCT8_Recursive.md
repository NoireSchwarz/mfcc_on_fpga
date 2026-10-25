# Recursive SkewDCT8 implementation

The active SkewDCT path now factors each eight-point transform into four two-point transforms, two four-point combinations and one eight-point combination. This replaces the dense 8-by-8 dot product inside the shared SkewDCT8 core. FFT processing, the downstream DCT8 core, normalization, C64 post-add processing and all external MFCC ports are unchanged.

Only two production RTL files change from commit `cb11535681cef1425747728b72b1ddc090927ca3`:

- [`skewdct_8.v`](../src/work/DCT40_64/skewdct_8.v): adds the recursive implementation behind an elaboration-time selection, retaining the original dense implementation.
- [`skewdct8_tdm.v`](../src/work/DCT40_64/skewdct8_tdm.v): selects the recursive implementation in the existing dynamic wrapper.

## Arithmetic structure

The factorization follows Equations (25)-(27) of Markus Püschel, [*Cooley-Tukey FFT Like Algorithms for the DCT*](https://www.ece.cmu.edu/~pueschel/papers/ctdct.pdf). The eight coefficient families already used by this project correspond to `r = (2*block+1)/16`, for `block=0,...,7`.

Define `q(t) = 1 / (2*cos(pi*t/2))`. A two-point leaf produces:

```text
sum        = a + b
difference = a - b
scaled     = q(t) * difference
outputs    = [sum, scaled]
```

The four leaf pairs and their parameters are:

| Inputs | Parameter t |
| --- | --- |
| x0, x7 | r/4 |
| x3, x4 | 1-r/4 |
| x1, x6 | 1/2-r/4 |
| x2, x5 | 1/2+r/4 |

The first two leaves combine into `S4(r/2)`; the other two combine into `S4(1-r/2)`. At each combination, corresponding child outputs form sums and differences. The differences pass through multiplication by that combination's `q(t)`. A sparse post-add then connects the required outputs:

```text
C4: z1 = z1 + z3
C8: z1 = z1 + z7; z2 = z2 + z6; z3 = z3 + z5
```

All other outputs pass through. The two four-point results finally combine into `S8(r)`. Input permutations are wires. The transform contains **12 real multiplication operations and 29 add/subtract operations**, excluding the extra adders used for fixed-point rounding. The previous dense transform expressed 64 products and 56 row-sum additions. This operation count is not a post-synthesis DSP or LUT count: a wide multiplication can occupy multiple FPGA DSP slices.

## Registered boundaries

The recursive path has 13 enabled register stages. There is no combinational path that multiplies a value and then accumulates that product before the next register. Product rounding and sparse post-adds also have separate boundaries.

| Stage | Registered result |
| --- | --- |
| S0 | Input capture, eight fractional guard bits, coefficient-family decode |
| S1 | Four leaf sums/differences and four selected factors |
| S2 | Four leaf products; matching sum delays |
| S3 | Rounded leaf products and aligned sums |
| S4 | Two four-point sum/difference groups and two selected factors |
| S5 | Four midpoint products; matching sum delays |
| S6 | Rounded midpoint products and aligned sums |
| S7 | Two sparse C4 additions; other outputs pass through |
| S8 | Four root sums/differences and the root factor |
| S9 | Four root products; matching sum delays |
| S10 | Rounded root products and aligned sums |
| S11 | Three parallel sparse C8 additions; other outputs pass through |
| S12 | Final rounding bias; output fractional-bit removal is fixed wiring |

Inputs accepted at enabled edge E0 produce `out_valid`, the corresponding `out_tag` and outputs after edge E12. The initiation interval is one enabled edge: a new eight-point vector can be accepted on every enabled clock edge. `ED=0` holds data, tags and validity together. Synchronous `RST` flushes the valid/tag state even if `ED=0`; invalid data registers need no reset.

The bank still issues eight groups consecutively, then collects completions by `out_valid/out_tag`. It writes output k of group b to `dout_hold[8*k+b]`, retaining the original transposition. Its controller already drains by returned validity rather than assuming a fixed latency, so no controller timing constants need changing.

## Interface compatibility and coefficient selection

The `skewdct8` port list, signal widths and original parameter declarations are unchanged. `USE_COEFF_PORT` has an additional supported value:

| Mode | Coefficients | Implementation / enabled stages |
| --- | --- | --- |
| 0 | Arbitrary compile-time C00...C77 parameters | Original dense pipeline / 6 |
| 1 | Arbitrary run-time matrix on c_in | Original dense pipeline / 6 |
| 2 | The project's eight original Q14 SkewDCT-II families | Recursive pipeline / 13 |

The existing `skewdct8_dctii_dyn` wrapper selects mode 2. It retains the original packed matrix interface and ROM file. The unique matrix element `C[4,0]` identifies the family; `in_tag` remains transaction metadata and does not select coefficients. The other matrix elements are not used by the recursive hardware. Consequently mode 2 must only receive the eight original matrices, with `COEF_FRAC=14` and `COEF_W>=18` (the production wrapper uses 20). Use mode 0 or 1 for arbitrary matrices. The simulation guard detects unsupported signatures and coefficient-width/fraction settings.

Mode 2 uses the mathematical structure of these matrices. It does not reproduce their original Q14 quantization at every product. Internal factors use signed 27-bit Q21 coefficients, eight fractional guard bits are retained between levels, and intermediate values use `IW=DATA_W+16` bits. Full products use `IW+27` bits. Rounding is to nearest, with ties away from zero. Output narrowing retains the existing signed wrap convention, rather than adding saturation.

The original modes remain bit exact. Mode 2 changes rounding order and factor precision, so its results can differ slightly from the dense Q14 path. Internal affine range bounds, including rounding error, were checked for all eight families over the complete signed input domain at DATA_W 12, 16 and 20; internal bounds stayed below 20% of the signed internal range. This does not prevent deliberate wrap if OUT_W is selected too narrow.

## Functional validation

Icarus Verilog simulation passed with the tested RTL source hashes pinned to the final revision. Additional simulation programs, generated vectors and detailed logs are retained locally, outside the uploaded project.

| Validation | Coverage / observed result |
| --- | --- |
| SkewDCT8 core | Seven parameter configurations; 3,600 presented vectors per configuration; random tags, input gaps, ED pauses, reset flushing and continuous II=1 traffic |
| Legacy modes 0/1 | Bit exact against the frozen original pipeline, including non-default widths and zero coefficient fractional bits |
| Recursive mode | Bit exact against a separate fixed-point recursive model; DATA_W 12/16/20 and an output-wrap configuration |
| Skew TDM bank | 32 frames in each of stalled/unstalled runs; every transposed coefficient matched the numerical model |
| DCT64 | 64 frames in each of stalled/unstalled runs; all 16 shift settings, reset interruption and held-output checks; maximum dense/recursive difference 22 raw units |
| Complete MFCC | 20 configurations, covering all FFT lengths 16...2048 with 1- and 64-lane output; stalled and selected unstalled cases; unchanged MatrixDCT control cases |
| Complete audio | 459 frames / 29,376 coefficients per run at N=512; both 64-lane unstalled and 1-lane stalled output passed and produced identical coefficient streams |

In the N=1024, 64-lane, unstalled four-frame MFCC test, elapsed cycles changed from **39,498 to 39,505**, an increase of seven cycles for the tested batch. Its maximum output difference was two raw integer units. In the complete audio regression, the maximum difference from the frozen dense baseline was four raw integer units; the RMS difference after the existing `256*sqrt(8)` output normalization was `0.00079148`. This is a difference between implementations, not an absolute error against an audio reference model.

An independent floating-point transform check on 28,800 core output coefficients per input width gave the following errors in unscaled output integer units:

| DATA_W | Dense Q14 RMS error | Recursive Q21 RMS error |
| --- | ---: | ---: |
| 12 | 0.260677 | 0.257120 |
| 16 | 0.789663 | 0.267511 |
| 20 | 12.170821 | 0.670141 |

These figures describe the tested vectors; they do not establish an application recognition-accuracy improvement.

## Architecture and hardware measurements

See the [five-page architecture PDF](../Architecture/SkewDCT8_Recursive/SkewDCT8_Recursive_Architecture.pdf) and its [page index](../Architecture/SkewDCT8_Recursive/README.md). Figures retain the existing black/blue style and show clock and enable connections on registers. The affected existing SkewDCT8, bank and DCT64 overview PNGs also point to the new implementation.

Vivado is not available in the local validation environment. **LUT/FF/DSP/BRAM utilization and post-route timing for this revision have not yet been measured.** The reduced arithmetic count cannot be reported as a measured resource reduction. Repeat synthesis and implementation on the same part, constraints and top level as the dense baseline before comparing hardware results. The existing C64 post-add arithmetic remains unchanged and can still limit the complete DCT path's clock frequency.
