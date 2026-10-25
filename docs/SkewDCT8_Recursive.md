# Recursive SkewDCT8 implementation

The active SkewDCT path now factors each eight-point transform into four two-point transforms, two four-point combinations and one eight-point combination. The recursive core receives its family selection directly on a three-bit input, replacing the former full matrix coefficient bus, matrix ROM and coefficient-signature decoder. FFT processing, the downstream DCT8 core, normalization, C64 post-add processing and all external MFCC ports are unchanged.

Only two production RTL files change from commit `cb11535681cef1425747728b72b1ddc090927ca3`:

- [`skewdct_8.v`](../src/work/DCT40_64/skewdct_8.v): adds the recursive implementation behind an elaboration-time selection, retaining the original dense implementation.
- [`skewdct8_tdm.v`](../src/work/DCT40_64/skewdct8_tdm.v): selects the recursive implementation and connects BLOCK directly, without a matrix ROM or matrix coefficient bus.

## Three-bit family interface update

Compared with the first recursive commit `3a28790`, recursive-mode `c_in` now carries `BLOCK[2:0]` directly. With the production COEF_W=20 setting, the interface shrinks from 1,280 bits to three bits (1,277 fewer declared signal bits). The internal recursive module likewise replaces its matrix port with a three-bit BLOCK port. S0 captures that ID at the same edge as the input vector; the arithmetic and register stages are unchanged.

The TDM wrapper no longer instantiates `skewdct8_dctii_coeff_rom`, and that obsolete module is removed from the production RTL. No production SkewDCT module loads `skewdct8_coeff_rom.mem`. The data file is retained as reference data for the original matrix implementation and independent numerical comparisons; the new MFCC path does not require it at run time.

The narrowed interface was tested against a frozen copy of `3a28790`. Core, bank, DCT64, complete-MFCC and full-audio outputs must match exactly, rather than merely remain within an error tolerance. MFCC cycle counts must also match. The complete-MFCC and audio simulations run without the old Skew matrix ROM file. Declared interface-bit reduction does not establish an equal physical routing-resource reduction: synthesis could already prune unused matrix words in the earlier version.

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
| S0 | Input capture, eight fractional guard bits, direct BLOCK capture |
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

The `skewdct8` port names and original parameter declarations are retained. The width and meaning of `c_in` depend on `USE_COEFF_PORT`:

| Mode | c_in width / meaning | Implementation / enabled stages |
| --- | --- | --- |
| 0 | 64*COEF_W bits; unused because C00...C77 parameters supply coefficients | Original dense pipeline / 6 |
| 1 | 64*COEF_W bits; arbitrary run-time coefficient matrix | Original dense pipeline / 6 |
| 2 | 3 bits; unsigned family ID BLOCK=0...7 | Recursive pipeline / 13 |

The existing `skewdct8_dctii_dyn` wrapper selects mode 2 and connects `.c_in(BLOCK)`. `in_tag` remains independent transaction metadata and does not select factors. All eight BLOCK values are valid. Their factor families correspond to `r=(2*BLOCK+1)/16`. No coefficient-signature decoder remains. A simulation guard detects unknown family IDs on accepted inputs.

Mode 2 callers outside the supplied wrapper must also replace their matrix connection with a three-bit family ID. The name `c_in` is retained, but a full matrix is no longer a valid input in that mode. COEF_W, COEF_FRAC, ACC_W and C00...C77 continue to configure the original dense modes; they do not configure the recursive factor table. The recursive arithmetic derives its widths from DATA_W and OUT_W and always uses its internal Q21 factors. Use mode 0 or 1 for arbitrary matrices.

Mode 2 uses the mathematical structure of the original families. It does not reproduce their original Q14 quantization at every product. Internal factors use signed 27-bit Q21 coefficients, eight fractional guard bits are retained between levels, and intermediate values use `IW=DATA_W+16` bits. Full products use `IW+27` bits. Rounding is to nearest, with ties away from zero. Output narrowing retains the existing signed wrap convention, rather than adding saturation.

The original modes remain bit exact. Mode 2 changes rounding order and factor precision, so its results can differ slightly from the dense Q14 path. Internal affine range bounds, including rounding error, were checked for all eight families over the complete signed input domain at DATA_W 12, 16 and 20; internal bounds stayed below 20% of the signed internal range. This does not prevent deliberate wrap if OUT_W is selected too narrow.

## Functional validation

Icarus Verilog simulation passed with the tested RTL source hashes pinned to the final revision. Additional simulation programs, generated vectors and detailed logs are retained locally, outside the uploaded project.

| Validation | Coverage / observed result |
| --- | --- |
| SkewDCT8 core | Eight parameter configurations; 3,600 presented vectors per configuration; exact comparison with the preceding wide-interface core; random tags, input gaps, ED pauses, reset flushing and continuous II=1 traffic |
| Legacy modes 0/1 | Bit exact against the frozen original pipeline, including non-default widths and zero coefficient fractional bits |
| Recursive mode | Bit exact against a separate fixed-point recursive model; DATA_W 12/16/20 and an output-wrap configuration |
| Skew TDM bank | 32 frames in each of stalled/unstalled runs; every transposed coefficient matched the numerical model |
| DCT64 | 64 frames in each of stalled/unstalled runs; all 16 shift settings, reset interruption and held-output checks; zero coefficient differences from the preceding wide-interface version |
| Complete MFCC | 20 configurations, covering all FFT lengths 16...2048 with 1- and 64-lane output; stalled and selected unstalled cases; unchanged MatrixDCT controls; exact coefficient and batch-cycle comparison against the preceding version |
| Complete audio | 459 frames / 29,376 coefficients per run at N=512; both 64-lane unstalled and 1-lane stalled output; exact coefficient comparison against the preceding version, without the old matrix ROM file |

The interface-only update retains **39,505 cycles** for the N=1024, 64-lane, unstalled four-frame MFCC test. The original dense core required 39,498 cycles. The previously measured recursive-versus-dense maximum difference in this test was two raw integer units. In the complete audio regression, the maximum recursive-versus-dense difference was four raw integer units; the RMS difference after the existing `256*sqrt(8)` output normalization was `0.00079148`. Narrowing the interface introduces no additional coefficient differences. These are differences between implementations, not absolute errors against an audio reference model.

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
