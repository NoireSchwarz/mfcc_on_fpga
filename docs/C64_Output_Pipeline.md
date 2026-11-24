# C64 output pipeline

The C64 output path previously combined indexed selection from a 64-word frame, sqrt(2) compensation, post-addition and output selection before MFCC captured the result. In the supplied 150 MHz implementation of `8f1fd37`, the reported worst setup path ran from C64's output index through that combinational arithmetic and MFCC writeback. This update inserts registered boundaries inside `c64_8_postadd_serial.v`.

Only [`c64_8_postadd_serial.v`](../src/work/DCT40_64/c64_8_postadd_serial.v) changes in production RTL relative to `24d0342`. Port names, widths, parameters, frame packing and numeric operations are preserved. The existing DCT64/MFCC wrappers already wait for valid outputs and final acceptance, so they require no fixed-latency adjustment.

## Three stages

| Stage | Payload | Matching control |
| --- | --- | --- |
| S0 | Select A and B from din_hold; register a_s0/b_s0 | index_s0, add_s0, scale_s0, valid_s0 |
| S1 | Register the signed compensation product; delay A and B as a_s1/b_s1 | index_s1, add_s1, scale_s1, valid_s1 |
| S2 | Choose scaled sum, ordinary sum or A bypass; register m_data | Register the corresponding m_index and m_valid |

The sqrt(2) constant remains signed Q14 `23170`. The full intermediate product retains the original `COMP_W=OUT_W+16` width. Compensation still uses an arithmetic right shift by 14 followed by post-addition; no rounding bias or saturation is added. Assigning to OUT_W retains the original signed wrap behavior. The two alternative RTL sum expressions are shown separately on the schematic; synthesis may share arithmetic resources.

For issue index i, q=i[5:3] and r=i[2:0]. A is D[q] when r=0, otherwise D[8*r+q]. A second operand is used when r!=0 and q<7, at D[8*(8-r)+q+1]. The implementation forms the addresses as six-bit concatenations. Only ORTHO_DCT8_INPUT!=0, q=0 and r!=0 applies compensation; other add lanes use A+B, and the remaining lanes bypass A.

## Issue, stall and completion

The entire input frame is captured on an enabled START edge. A separate issue counter emits indices 0...63 exactly once, then stops while the pipeline drains. Output metadata travels with the operands; m_index no longer directly exposes the issue counter.

`advance = ED && (!m_valid || m_ready)` controls all three stages. When an output is blocked, every payload and metadata stage holds. With no stalls, the pipeline produces one coefficient per clock after filling. The accepted transfer condition is ED && m_valid && m_ready, matching the original module's clock-enable contract. The active DCT64 wrapper ties ED high and uses the normal valid/ready handshake.

RDY is asserted only after the final registered output, index 63, is accepted. Merely issuing the last index does not complete the frame. Synchronous reset clears validity and controller state even when ED=0. An enabled START retains the original priority: it replaces the active frame and flushes pending validity. The input snapshot and output data reset as before; invalid internal A/B/product payload registers need no reset.

If START is accepted at edge F, selection runs at F+1, the product stage at F+2 and the first output register becomes valid after F+3. The first output can be accepted at F+4. The previous implementation accepted its first output at F+1; the no-stall first and last transfers therefore move by three clocks.

## Functional checks

All comparisons use a frozen copy of the pre-update RTL at `24d0342f60cca9a9cac156df243669d88e8d426a`.

| Check | Result |
| --- | --- |
| C64 unit regression | 10 parameter configurations; IN_W 12/16/24/32, wider and narrower OUT_W, both orthogonal-input settings; 66 checked frames per configuration / 42,240 coefficients in total; zero differences |
| C64 protocol | Random ED pauses and independent backpressure; forced stalls on index 63; reset during fill and held output; enabled START replacement; START ignored while ED=0; RDY checked against final accepted transfer |
| Complete DCT64 | 64 frames with stalls and 64 without; all 16 shift values, held-output and reset checks; zero coefficient or overflow-flag differences |
| Complete MFCC | 20 configurations covering FFT lengths 16...2048, 1- and 64-lane output, stalls and unchanged MatrixDCT controls; zero coefficient differences |
| Full audio | Two N=512 runs, each 459 frames / 29,376 coefficients, with 64-lane unstalled and 1-lane stalled output; zero coefficient differences |

No-stall cycle measurements:

| Scope | Before | After |
| --- | ---: | ---: |
| Standalone C64 first accepted output after START | 1 | 4 |
| Standalone C64 final accepted output after START | 64 | 67 |
| DCT64 first accepted output | 172 | 175 |
| DCT64 final accepted output | 235 | 238 |
| N=512 MFCC, four-frame batch, 64 lanes | 16,585 | 16,588 |
| N=1024 MFCC, four-frame batch, 64 lanes | 39,505 | 39,508 |

The supplied follow-up implementation of tested commit `b0db7a0` **passes 150 MHz default OOC post-route timing**, with WNS +0.258 ns, WHS +0.010 ns and zero setup/hold failures. Complete MFCC uses **35,777 LUT, 53,107 FF, 6.5 BRAM tiles and 59 DSP**. Against the pre-C64 recursive implementation at the same 150 MHz constraint, the change is +120 LUT / +201 FF, with unchanged DSP and BRAM. The four-frame 39,508-cycle regression converts to 263.387 us at 150 MHz, or a 65.847 us batch average per frame; these are cycle conversions, not board measurements or independently measured single-frame latency.

The 20 reported worst setup paths now comprise 12 filter-bank acknowledgement/frame-clear paths and eight input-selection/Hamming-to-FFT-RAM paths. The worst data delay is 6.150 ns, including 5.847 ns routing, on a 4,167-load m_ready control net. None of those 20 paths traverses C64 arithmetic; other unreported paths still require review before claiming a higher frequency. **200 MHz remains untested**: freezing the present route gives approximately -1.409 ns worst slack at a 5 ns period. See the [raw reports, verified resource comparison and 200 MHz assessment](benchmarks/c64_pipeline_N1024_150MHz_20261026/README.md).

The earlier [pre-C64 measurements](benchmarks/recursive_skewdct_N1024_20261026/README.md) remain pinned to `8f1fd37`. Their 50 MHz resource totals and -0.196 ns 150 MHz slack describe that historical revision.

## Updated figures

The existing [D08 C64 figure](../Architecture/SKEW_DCT64/D08.png) is replaced in place and also exported as [SVG](../Architecture/SKEW_DCT64/D08.svg) and [PDF](../Architecture/SKEW_DCT64/D08.pdf). The [DCT64 overview](../Architecture/SkewDCT8_Recursive/R04.png), its existing D01 PNG and the [combined architecture PDF](../Architecture/SkewDCT8_Recursive/SkewDCT8_Recursive_Architecture.pdf) are updated in place. The combined PDF now has six pages, including D08. All captions remain English with the established black/blue palette.

Additional simulation scripts, frozen references and detailed logs remain local, outside the uploaded project.
