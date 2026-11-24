# Recursive SkewDCT8 measurements and 150 MHz timing analysis

[Latest merged benchmark catalog](../README.md) · [Current DCT comparison](../dct/README.md). This directory preserves original measurement evidence; architecture generations are not separate rows in the primary catalog.

Historical measurement of pre-C64-pipeline revision `8f1fd37`. The subsequent C64-pipelined revision `b0db7a0` [passes 150 MHz in the follow-up implementation](../c64_pipeline_N1024_150MHz_20261026/README.md). The reports and failure analysis below remain attached to the earlier tested revision.

Measured revision: `8f1fd371d7a8cf441a2584526f4bac2570d97cfb`. Device: xck26-sfvc784-2LV-c; Vivado 2026.1. Configuration: complete MFCC, N=1024, STRIDE=512, OUT_WIDTH=64, four frames / 256 coefficients. Results are RTL simulation and out-of-context post-route implementation, not board-measured PS/DMA/audio latency. The supplied measurements use one implementation attempt with no retry or additional Explore physical optimization.

## Resource utilization first

Complete MFCC, 50 MHz:

| Design | LUT | FF | BRAM tiles | DSP |
| --- | --- | --- | --- | --- |
| Dense SkewDCT baseline | 31,943 | 50,689 | 6.5 | 123 |
| Recursive SkewDCT64 | 35,601 | 52,870 | 6.5 | 59 |
| MatrixDCT64 | 30,188 | 41,987 | 9 | 19 |

Inclusive DCT64 hierarchy, 50 MHz (already included in the MFCC totals):

| Design | LUT | FF | BRAM tiles | DSP |
| --- | --- | --- | --- | --- |
| Dense SkewDCT baseline | 4,589 | 9,817 | 0 | 105 |
| Recursive SkewDCT64 | 5,875 | 11,981 | 0 | 41 |
| MatrixDCT64 | 647 | 1,098 | 2.5 | 1 |

Relative to the dense baseline, complete-MFCC DSP use falls by 64 (52.03%), while LUTs rise by 3,658 (11.45%) and FFs by 2,181 (4.30%). DCT64 DSP use falls from 105 to 41 (60.95%). The shared recursive SkewDCT8 itself maps to **24 DSPs, 1,706 LUTs and 2,357 FFs**. Its 12 arithmetic products therefore do not mean 12 physical DSP slices. BRAM remains 6.5 tiles for the complete MFCC and zero in the DCT64 hierarchy.

The whole-MFCC LUT change is not entirely inside DCT: DCT adds 1,286 LUTs, whereas filter_bank changes from 10,290 to 12,665 LUTs across the two implementations. Do not attribute all netlist mapping differences to the recursive core, or add inclusive hierarchy subtotals to their parent.

## Frequency results

| MHz | LUT | FF | DSP | WNS ns | WHS ns | Setup failures | Result |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 50 | 35,601 | 52,870 | 59 | 7.511 | 0.01 | 0 | TIMING_PASS |
| 100 | 35,606 | 52,870 | 59 | 0.688 | 0.003 | 0 | TIMING_PASS |
| 150 | 35,657 | 52,906 | 59 | -0.196 | 0.01 | 444 | TIMING_FAIL |

The batch requires 39,505 RTL cycles, compared with 39,498 for the dense baseline and 43,687 for MatrixDCT. At 50 MHz this is 790.100 us per four-frame batch and a 197.525 us batch average per frame. At 100 MHz the batch is 395.050 us. These times are cycle conversions, not board measurements or independently measured steady-state initiation intervals.

**150 MHz fails setup timing.** Its 263.367 us batch conversion is nominal only and must not be described as timing-closed performance. The prior dense implementation's +0.001 ns 150 MHz result used an additional Explore step; it is a different implementation flow.

## Why 150 MHz fails

The timing report lists 444 setup-failing endpoints, TNS=-28.937 ns and WNS=-0.196 ns; hold passes with WHS=+0.010 ns. All 20 reported worst setup paths start at `U_CORE/gen_skew.my_dct/U_C64_8/out_idx_reg[0]` and end in `U_CORE/dct_output_reg[...]`. None of those 20 paths starts in the recursive SkewDCT8 arithmetic pipeline. This classification covers the reported paths, not every failing endpoint.

Worst endpoint: `dct_output_reg[1067]/D`. Data delay is **6.763 ns**: 3.522 ns logic (52.08%) and 3.241 ns routing (47.92%), with 17 logic levels, clock skew -0.109 ns and clock uncertainty 0.035 ns. The index net has fanout 121 and its first routed segment alone takes 0.666 ns.

```text
C64 out_idx register
  -> dynamic selection from din_hold (MUXF8 / LUT)
  -> unregistered sqrt(2) compensation multiplication (DSP)
  -> fixed shift and post-add (CARRY8 chain)
  -> output selection
  -> MFCC variable-index dct_output writeback
  -> output register
```

The RTL in `c64_8_postadd_serial.v`, for ORTHO_DCT8_INPUT and q=0, evaluates `(a * 23170 >>> 14) + b` combinationally. `m_data = calc_lane(out_idx)` is also combinational. The first capture of the complete result is downstream in `mfcc_core.v`; this path has no internal register boundary separating selection, multiplication and post-add. The shift is fixed wiring; the carry chain is the post-add, not rounding in this function.

The supplied narrative mentions wide-multiplier pipeline warnings. Such warnings deserve separate review, but they do not establish that the recursive core caused the reported 150 MHz failure. The original C64 output path remains the directly evidenced bottleneck. Changes in mapping and placement can change its routed delay; these reports alone do not prove congestion.

Recommended next work: register the selected operands, register the compensation product, then register post-add/output as needed. Delay b, index, valid and bypass controls alongside the data and preserve ED/backpressure/reset behavior. Also inspect the variable part-select writeback in mfcc_core and the fanout of out_idx. Physical optimization/Explore may recover margin, but it does not guarantee closure or replace checking the full path. These are recommendations; no RTL was changed in this results update. See [AMD pipelining guidance](https://docs.amd.com/r/en-US/ug949-vivado-design-methodology/Pipelining-Considerations).

## Numerical results and provenance

Four-frame whole-MFCC RMSE against the supplied floating-reference definition is 12.49161094 for recursive SkewDCT and 12.49010998 for MatrixDCT. The normalized difference between those implementations has RMSE 0.00561251. Recursive-versus-dense normalized RMSE is 0.00098416, with maximum raw coefficient difference two in the local matching batch. These are complete-pipeline measurements and do not isolate DCT error or establish recognition accuracy.

The archive omits the raw coefficient CSVs, but the corresponding local regression CSVs match both supplied SHA-256 values exactly; their floating-reference metrics were independently recomputed. All **35** packaged checksums pass, both included core RTL files match the tested branch sources, and resource/timing tables were cross-checked against raw reports. Archive SHA-256: `cf0ed70767ac8a9c877f5faa2552efd7052fdd336a2b95f22745d91dcf0ad2fe`.

Raw reports are in [raw_reports](raw_reports/), machine-readable records in [results](results/), and the classified paths and verification metadata are in [verified_results.json](verified_results.json). Historical dense resources come from the matched 2026-10-25 retest. External input/output delays are not constrained in this OOC setup; this is internal implementation evidence, not complete board-interface timing signoff.
