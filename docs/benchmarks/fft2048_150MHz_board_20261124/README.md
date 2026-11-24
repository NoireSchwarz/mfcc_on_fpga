# Latest shared FFT: 2048 points at 150 MHz on KV260

**Algorithm: 9,001 LUT, 8,505 FF, 8.5 BRAM tiles, 8 DSP.** The supplied routed implementation and board records pass for the fixed 2048-point configuration of commit `9be89af18ca9cf42e6f47990d7d1b781afb47615` on `optimization/skewdct8-recursive-pipeline`. Test date: 2026-11-24; device: xck26-sfvc784-2LV-c; Vivado 2026.1.

## Resources

| Scope | LUT | FF | RAMB36 | RAMB18 | BRAM tiles | DSP |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| FFT algorithm, inclusive | **9,001** | **8,505** | 5 | 7 | **8.5** | **8** |
| FFT2x, included above | 345 | 88 | 4 | 0 | 4 | 0 |
| Complete JTAG/AXI board-test design | 11,009 | 11,450 | 23 | 8 | 27 | 8 |

FFT2x storage maps to four RAMB36 primitives. The test-harness memory is included only in the complete-design row. These fixed-N board counts must not replace the separate 50 MHz OOC resource row for an instance retaining all eight runtime sizes. [Raw hierarchy](supplied/02_implementation/utilization_hierarchical_post_route.rpt) · [CSV](Resources.csv).

## Source and architecture verification

The wrapper instantiates `fft512 #(.N(2048), .HALF_SPECTRUM(0))`, followed by `fft_tree_bram_engine`, its direct FFT256 root, shared merge kernel and `fft2x` backend (RTL module name `fft2`). All 25 supplied FFT RTL files match the tested Git commit after CRLF/LF normalization. The implemented hierarchy contains this path and does not contain `fft2048_bram_stream`. Algorithm RTL was not changed for the test or this import. [File hashes](Source_Verification.csv) · [Build script](supplied/01_source/build_latest_exact150.tcl) · [Wrapper](supplied/01_source/bench_transform_latest.v).

## Routed timing and clock

Setup WNS **+0.731 ns**, TNS 0; hold WHS **+0.011 ns**, THS 0; zero setup, hold or pulse-width failing endpoints. All 12 `check_timing` categories report zero issues. All **19,275/19,275** routable nets are fully routed, with zero routing errors. DRC reports **19 warnings and no errors**, including DSP pipeline and RAM collision advisories; this is not a warning-free implementation.

The expanded timing paths trace PS PL1 through BUFG_PS, MMCM and BUFGCE to the algorithm clock. The routed DCP hardware definition confirms MMCM multiplier 12, input divider 1 and output divider 8. Board readback records the PS configuration used for a nominal 100 MHz PL1 source, giving nominal 150 MHz fabric operation. The 99.999001/149.998501 MHz IP metadata values reflect the packaged clock metadata; timing tables round the generated clock to 150.000 MHz. No independent frequency-counter or oscilloscope measurement was supplied.

The worst setup path starts at the engine state register and ends at a merge-kernel DSP operand register. Data delay is **5.327 ns**, comprising **1.575 ns logic and 3.752 ns routing**. It traverses shared control/coefficient-selection logic. A path crossing synthesized FFT2x names does not imply a failing FFT2x arithmetic chain: the reported worst slack is positive. [Timing summary](supplied/02_implementation/timing_post_route.rpt) · [Worst paths](supplied/02_implementation/setup_paths_post_route.rpt) · [Clock readback](supplied/03_board_test/fft_2048/clock_after_program.txt).

## Board output and latency

Nine datasets cover **15 frames and 30,720 returned 32-bit complex words**, with **zero mismatches** against the supplied frozen expected words. Cases are original, zero, impulse, DC, alternating, low/full-range random, and two four-frame batches. Raw CSV indices, counts, every output word, summary entries and board-log results were independently crosschecked. The reported error word is zero, but the wrapper ties `error_flags` to zero; it is not independent coverage of internal overflow flags.

| Run | Input samples / output words | Fabric cycles | Time at nominal 150 MHz |
| --- | ---: | ---: | ---: |
| One frame, complete output | 2,048 / 2,048 | 25,390 | 169.267 us |
| First output | — | 23,343 | 155.620 us |
| Four frames, complete output | 8,192 / 8,192 | 101,545 | 676.967 us |

These times convert the supplied on-board cycle counters, not USB/JTAG host upload/poll/download latency. The additional-frame interval derived from the batches is 25,385 cycles, or 169.233 us; it is not an independently observed per-frame timestamp. [All cases](Board_Cases.csv) · [Raw board summary](supplied/03_board_test/fft_2048/summary.csv) · [Board log](supplied/04_logs/board_test.log).

An independent local Icarus regression used the supplied wrapper/RTL and current-commit coefficient files. All 30,720 words also matched with no stalls and with randomized input/output stalls; TLAST, output stability and absence of extra output were checked. This RTL simulation does not repeat the physical board test or timing implementation. Numerical agreement is limited to the tested corpus and frozen fixed-point arithmetic; it is not an assertion of exact agreement with an ideal unscaled FFT.

## Evidence and scope

All six supplied SHA-256 entries pass; the archive and routed-DCP ZIP integrity checks also pass. [Verified results](verified_results.json) and [complete file/hash manifest](evidence_manifest.json) record the audit. Original text reports, logs, source snapshot and test scripts are preserved byte-for-byte under `supplied/`. The original archive, bitstream and DCP remain local; their verified hashes are retained in the manifest and original `SHA256.txt`.

The original build script references external `bench_engine.v` and `kv260_bench_top.v`; those harness sources and explicit coefficient-file snapshots are absent from the delivery. Accordingly the supplied folder alone is not a self-contained board rebuild kit. A DCP inspection is not a rerun of Vivado or bitstream-to-netlist equivalence checking.

**This is valid supplied evidence for the final shared architecture's standalone fixed N=2048, full-spectrum FFT at nominal 150 MHz. It does not establish complete-MFCC N2048 board operation, runtime size switching, or every FFT size at 150 MHz.** The rejected 2026-11-23 dedicated-core result remains excluded from the catalog.
