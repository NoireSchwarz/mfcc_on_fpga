# C64 pipeline: N1024 MFCC passes 150 MHz

Tested revision: `b0db7a079ba203eb0b2b88bb8a03c578899d5549` on xck26-sfvc784-2LV-c with Vivado 2026.1. Configuration: complete MFCC, N=1024, STRIDE=512, OUT_WIDTH=64, recursive SkewDCT. This is a supplied OOC post-route implementation and RTL simulation result. The run used default synthesis/place/route without Explore or an implementation retry; it is not a board measurement.

## Resource utilization

| Scope | LUT | FF | BRAM tiles | DSP |
| --- | --- | --- | --- | --- |
| Whole MFCC | 35,777 | 53,107 | 6.5 | 59 |
| DCT subsystem | 6,041 | 12,125 | 0 | 41 |
| C64 output processing | 1,107 | 1,706 | 0 | 1 |
| Shared SkewDCT8 core | 1,706 | 2,357 | 0 | 24 |

Hierarchy rows are inclusive and already contained in the whole-MFCC total. Whole-MFCC usage is 30.55% LUT, 22.67% FF, 4.51% BRAM and 4.73% DSP. BRAM comprises three RAMB36 and seven RAMB18 primitives.

Matched comparison against the pre-C64-pipeline recursive revision, both at **150 MHz**, using default OOC implementation:

| Scope | LUT before | LUT after | Delta LUT | FF before | FF after | Delta FF |
| --- | --- | --- | --- | --- | --- | --- |
| Whole MFCC | 35,657 | 35,777 | 120 | 52,906 | 53,107 | 201 |
| DCT subsystem | 5,871 | 6,041 | 170 | 11,981 | 12,125 | 144 |
| C64 output processing | 939 | 1,107 | 168 | 1,562 | 1,706 | 144 |
| Shared SkewDCT8 core | 1,706 | 1,706 | 0 | 2,357 | 2,357 | 0 |

Whole-MFCC DSP remains 59 and BRAM remains 6.5 tiles; DCT64 remains 41 DSP and zero BRAM. The archive narrative's +176 LUT / +237 FF comparison uses the earlier **50 MHz** resource numbers (35,601 / 52,870). Against the available **150 MHz** baseline (35,657 / 52,906), the matched changes are **+120 LUT / +201 FF**. Netlist mapping outside C64 can also change between implementations.

## Timing and cycle results

WNS **+0.258 ns**, TNS 0.000 ns, zero setup-failing endpoints; WHS **+0.010 ns**, THS 0.000 ns, zero hold-failing endpoints. Pulse-width slack is +2.571 ns with zero failing endpoints. The prior default 150 MHz recursive implementation had WNS -0.196 ns and 444 setup-failing endpoints; worst slack improves by 0.454 ns across the two implementations.

The four-frame / 256-coefficient RTL regression passes in **39,508 cycles**, versus 39,505 before C64 pipelining. At the passing 150 MHz constraint this converts to **263.387 us per four-frame batch**, or **65.847 us as the batch average per frame**. It is not independently measured single-frame latency, steady-state initiation interval or board end-to-end time. The packet's precision JSON labels its RTL simulation configuration as 50 MHz; the 150 MHz time here is a cycle conversion supported by the separate implementation result.

The local new and pre-C64 SkewDCT coefficient CSVs are identical and match the packet's SHA-256. Floating-reference metrics were independently recomputed: SkewDCT RMSE 12.49161094 / SNR 16.048625 dB; MatrixDCT RMSE 12.49010998 / SNR 16.049669 dB. These are complete-MFCC errors under the existing reference and scaling definition, not isolated DCT accuracy or recognition accuracy. The packet includes no new MatrixDCT implementation run.

## Remaining critical paths and 200 MHz assessment

The 20 reported worst setup paths now fall into two groups: **12** acknowledgement/frame-clear paths ending in filter-bank energy registers, and **8** input-selection/Hamming paths ending at FFT input RAM. None of these 20 paths traverses C64 arithmetic; this does not bound every other path in the design.

The worst path is `gen_skew.my_dct/FSM_onehot_state_reg[0] -> my_filt_bank/m_ready -> energy_reg[31][2]`. Its data delay is **6.150 ns**, split into **0.303 ns logic and 5.847 ns routing (95.07%)**. There is only one LUT level. The m_ready net has **4,167 loads**; its first data-net delay is 5.777 ns. In RTL, accepting the filter-bank output clears all 64 x 64-bit energy words, producing this broad control load. Prioritize physical replication/local distribution of this control driver. A separately registered local clear phase is another design option, but ready/valid acceptance and the start of the next frame must be preserved; blindly delaying m_ready can change protocol behavior. AMD discusses [register replication for high-fanout drivers](https://docs.amd.com/r/2024.1-English/ug949-vivado-design-methodology/Replicate-High-Fanout-Net-Drivers).

The next path is `prepare_input/output_index -> sample-selection MUX -> hamming/result multiply -> FFT input RAM`. It has slack **+0.314 ns**, data delay **5.528 ns** (2.631 ns logic / 2.897 ns routing) and 12 reported logic levels including internal combinational DSP arcs. A practical RTL option is to register selected sample/coefficient operands and the window product, with matching valid/enable/address timing. Check coefficient rotation and FFT write timing together. Fixing only the filter-bank fanout leaves this second class exposed at 200 MHz.

200 MHz requires a 5.000 ns period, 1.667 ns shorter than 150 MHz. **Holding the present route, skew and uncertainty fixed**, the worst setup slack would move from +0.258 ns to approximately **-1.409 ns**; the next path would be approximately -1.353 ns. The corresponding frozen-route period limit is about 6.409 ns / 156.04 MHz. These are estimates from the 150 MHz report, **not measured 200 MHz timing or a certified maximum frequency**. A 200 MHz implementation may produce a different placement and route.

Judgement: 200 MHz is a reasonable further optimization target, but this report does not support claiming that unchanged RTL will pass. Address both path classes, run implementation with a 5.000 ns clock and review a wider per-module timing set. C64 frame-buffer BRAM conversion can still reduce resource/routing pressure; it is not the first directly evidenced fix for these current worst paths.

## Provenance and evidence limits

All **16** archive checksums pass. Four delivered core RTL snapshots match tested revision `b0db7a079ba203eb0b2b88bb8a03c578899d5549` in the current project; the RTL source-list hash also matches. The package contains selected snapshots rather than the full measured checkout. Raw coefficient CSVs are absent from the packet, but both corresponding local CSV hashes match and the numerical metrics were recomputed.

The route-status report records 71,423/71,423 routable nets fully routed and zero routing errors, plus one explicit gap. DRC contains 96 warnings: 19 DPIP-2, 21 DPOP-3, 55 DPOP-4 and one RTSTAT-10 for `U_CORE/my_in/s_ready` having no routable loads. Its header says Partially Routed. Preserve these qualifications; do not describe this as a warning-free bitstream or board signoff. The OOC script supplies a clock constraint, without external input/output delays, and the timing report lists unconstrained I/O checks.

The original checksums, raw reports and supplied precision JSON are retained here. Source snapshots and helper scripts remain in the local extracted archive; no production RTL was changed and no Vivado or board run was performed during this import. `verified_results.json` and the verified CSV tables record the cross-checks and the explicitly estimated 200 MHz projection. Historical reports remain pinned to their earlier revisions.
