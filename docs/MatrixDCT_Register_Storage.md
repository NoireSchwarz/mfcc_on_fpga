# MatrixDCT with register and LUT storage

The MatrixDCT reference now uses parallel input flip-flops, an asynchronous LUT coefficient ROM and independent output flip-flop words. This replaces the previous BRAM-backed storage while retaining the public `dct64_matrix` ports, parameters, coefficient file, signed arithmetic, rounding/scaling and overflow behavior. The single multiplier/accumulator organization remains. This removes the block-memory storage distinction from the comparison; it does not equalize DSP parallelism with SkewDCT.

## Datapath

```text
64-word frame input -> frame_hold FFs -> indexed sample selection --+
                                                                 +-> operand registers
coefficient file -> LUT ROM -> indexed coefficient selection ------+        |
                                                                          v
                                                                  product register
                                                                          |
                                                                          v
                                                                 accumulator register
                                                                          |
                                                                 round / scale / slice
                                                                          |
                                                          64 output FF words -> mux
                                                                          |
                                                          m_data / m_index / m_valid
```

`frame_hold` captures all 64 input words on the accepted frame edge. Each output word is a separately generated register with an address-decoded write enable; an asynchronous mux selects the serialized result. Payload words are not reset, because every word is written before output validity is asserted. The controller and input snapshot retain their reset behavior.

`dct64_coeff_rom.v` retains `COEFF_FILE` and initialization through `$readmemh`, but its output is combinational and carries `rom_style="distributed"`. AMD documents this attribute as requesting [LUT ROM mapping](https://docs.amd.com/r/en-US/ug901-vivado-synthesis/ROM_STYLE). The legacy CLK/ED pins remain on that internal helper for source compatibility; the datapath operand registers capture the selected value. Likewise, `dct64_ram64.v` retains its legacy filename/module name, but now describes separate FF words and an asynchronous output; its RE pin is retained without a read-register function.

Sample/coefficient selection, multiplication and accumulation have **separate register boundaries**. A large coefficient-selection mux is not placed in the same combinational stage as the multiplier. The original product width, accumulator width, negative-value rounding bias, final scaling and sticky overflow calculation are preserved.

## Controller and latency

The controller uses IDLE, PRIME, MUL, MAC, STORE and OUTPUT. PRIME captures the first operands and clears the accumulator; MUL captures the first product while reading the next operands. MAC then consumes 64 products, with operand/product stages overlapping. STORE writes one rounded result. Each of the 64 matrix rows takes 67 clocks; output serialization takes 64 more clocks.

The former 64-clock BRAM input-loading phase and one-clock output-read preparation are removed. With no backpressure, measured from accepted frame input:

| Metric | Previous BRAM implementation | Register/LUT implementation |
| --- | ---: | ---: |
| First accepted output | 4,354 cycles | 4,289 cycles |
| Final accepted output | 4,417 cycles | 4,352 cycles |
| N1024 MFCC four-frame batch | 43,687 cycles | 43,622 cycles |

The standalone result satisfies `64*67 + 64 = 4352`. Busy input-valid pulses remain ignored. Output index/data hold under backpressure. Reset aborts an active frame and flushes control validity. The existing MFCC integration needs no port or fixed-latency change.

## Validation

The frozen reference is the five MatrixDCT RTL files from commit `a9ceb12ba1f3ee0beb19d6e1dcab33133c6dc05d`. Validation uses Verilog-2001 compilation and an independent integer model of the matrix products, accumulator wrapping, rounding, scaling, output truncation and overflow flags.

- Six parameter cases, 192 checked frames / 12,288 coefficients: zero differences against both the previous implementation and the independent model. Cases cover 8/12/16/20-bit inputs, narrow/wide outputs, all 16 shift settings, a custom coefficient file and COEF_FRAC=0.
- Reset during calculation and while output is held; randomized backpressure, forced final-word stalls, input/shift changes while busy and ignored busy valid pulses.
- Twenty complete-MFCC configurations: all eight FFT lengths 16..2048, 1/64 output lanes, stalls and two unchanged SkewDCT controls. All 5,120 compared coefficients match the frozen reference.
- The N1024, 64-lane, unstalled output CSV matches the previous published MatrixDCT SHA-256. Floating-reference metrics are unchanged. Its four-frame count is 43,622 cycles; 872.44 us at 50 MHz is a nominal cycle conversion only.

The [verified summary](benchmarks/matrix_register_20261026/verified_results.json) records the source hashes and per-case results. Detailed simulation logs, baseline source copies and test helpers remain local, outside the published project.

## Hardware measurements pending

No local Vivado run was available for this replacement. The RTL explicitly requests FF/LUT storage; actual LUT/FF/BRAM/DSP mapping and post-route timing must be confirmed by a new implementation report. The former MatrixDCT figures (647 DCT LUT, 1,098 DCT FF, 2.5 BRAM tiles and one DSP) belong to the previous BRAM implementation and must not be used as measurements of this revision. The current catalog marks MatrixDCT hardware fields pending and retains those original reports as historical evidence.

SkewDCT, ordinary DCT8, the variable-size FFT, coefficient contents and MFCC external ports are unchanged by this replacement.
