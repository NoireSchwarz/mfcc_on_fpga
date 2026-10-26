# mfcc_on_fpga

## Recursive SkewDCT8 branch

The shared SkewDCT8 now uses a registered 8-to-4-to-2 factorization for the project's eight coefficient families. Recursive mode receives a three-bit family ID directly; original parameter declarations and generic dense modes remain available. The recursive transform expresses 12 real products and 29 add/subtract operations, with multiplication, rounding and sparse post-adds separated by registers. This arithmetic count is not a measured DSP count.

The current RTL also pipelines C64 output processing into registered selection, compensation-product and post-add/output stages. It preserves output coefficients and adds three no-stall clocks. [C64 implementation and validation](docs/C64_Output_Pipeline.md) records the change.

Latest supplied measurements, tested commit **b0db7a0**: N=1024, STRIDE=512, OUT_WIDTH=64, **150 MHz default OOC post-route** on K26 / Vivado 2026.1:

| Resource scope | LUT | FF | BRAM tiles | DSP |
| --- | ---: | ---: | ---: | ---: |
| Complete MFCC | **35,777** | **53,107** | **6.5** | **59** |
| DCT64 hierarchy, included above | 6,041 | 12,125 | 0 | 41 |
| C64 output processing, included above | 1,107 | 1,706 | 0 | 1 |

**150 MHz passes: WNS=+0.258 ns, WHS=+0.010 ns, zero setup/hold failures**, without Explore or implementation retries. Against the pre-C64 recursive implementation at the same 150 MHz constraint, whole-MFCC resources increase by **120 LUT and 201 FF**; DSP and BRAM are unchanged. The four-frame RTL test takes 39,508 cycles, equivalent to 263.387 us at 150 MHz; this is a cycle conversion, not board latency.

**200 MHz has not been tested.** The current worst paths are filter-bank acknowledgement/frame-clear fanout and input-selection/Hamming multiplication. Freezing the present route gives an estimated -1.409 ns worst slack at 200 MHz; further optimization and a new implementation are required to assess closure. See the [verified reports, matched resource comparison and 200 MHz assessment](docs/benchmarks/c64_pipeline_N1024_150MHz_20261026/README.md).

### Consolidated benchmarks

The MatrixDCT reference has subsequently been replaced with register/LUT storage. Its current resource and timing fields are **pending reimplementation**; previous BRAM numbers remain historical evidence. The replacement preserves coefficients and takes 43,622 cycles for the N1024 four-frame test. [Implementation and regression results](docs/MatrixDCT_Register_Storage.md).

All six supplied benchmark packages are classified in the [benchmark catalog](docs/benchmarks/README.md): [complete MFCC](docs/benchmarks/full_mfcc/README.md), [FFT/XFFT](docs/benchmarks/fft/README.md), [DCT comparison](docs/benchmarks/dct/README.md) and [memory optimization](docs/benchmarks/memory/README.md).

The [13-sheet Excel workbook](docs/benchmarks/MFCC_Benchmark_Summary.xlsx) and [consolidated JSON](docs/benchmarks/combined_data.json) keep the latest valid metric for each test/configuration. Architecture and pipeline generations are not separate primary result rows. LUT, FF, BRAM and DSP appear first; per-metric source columns retain provenance. Earlier reports remain available as evidence without repeating superseded values in the main tables.

See the [implementation notes](docs/SkewDCT8_Recursive.md) and [architecture PDF](Architecture/SkewDCT8_Recursive/SkewDCT8_Recursive_Architecture.pdf) for the current datapath.

### DCT-Modul

Das Design des DCT-Moduls orientiert sich an den folgenden Publikationen [^1] [^2].

---

## Referenzen / References

[^1]: Markus Püschel. *Cooley-Tukey FFT Like Algorithms for the DCT*. Department of Electrical and Computer Engineering, Carnegie Mellon University. [📄 PDF](https://spiral.ece.cmu.edu/pub-smart/pubfile/paper_16.pdf)
[^2]: Markus Püschel and José M. F. Moura. *Algebraic Signal Processing Theory: Cooley-Tukey Type Algorithms for DCTs and DSTs*. [📄 PDF](https://spiral.ece.cmu.edu/pub-spiral/pubfile/asp-dct_150.pdf)


## Upload log

### 2026-10-26 - Replace MatrixDCT BRAM storage with FF/LUT storage

- Captured the input frame in parallel FFs, used a LUT coefficient ROM and separate output-register words, and retained the public MatrixDCT interface and numerical parameters.
- Kept operand selection, multiplication and accumulation in separate register stages. Removed BRAM-only input loading and output-read preparation; standalone completion changes from 4,417 to 4,352 clocks.
- Passed six unit parameter cases against the original RTL and an independent integer model, plus twenty complete-MFCC configurations with zero coefficient differences. The N1024 unstalled four-frame batch changes from 43,687 to 43,622 clocks.
- Marked current MatrixDCT resource/timing values pending in the catalog; old BRAM measurements are not assigned to the new implementation. New synthesis, physical RAM mapping and timing remain to be measured.

### 2026-10-26 - Consolidate benchmark results by test project

- Classified all six supplied benchmark packages into complete-MFCC, FFT/XFFT, DCT and memory-optimization results, with a common index, 13-sheet workbook, CSV tables and JSON.
- Kept the latest valid metric for each test/configuration; architecture and pipeline generations no longer create repeated primary result rows. Different frequencies, point counts and comparison backends remain explicit.
- Retained per-metric evidence sources, original report bytes and archive hashes. Updated the SkewDCT/MatrixDCT comparison and N1024 runtime to the latest matching results.
- Preserved the explicit paired memory before/after experiment. The interrupted legacy 200 MHz attempt is not counted as a pass or fail; the latest 200 MHz value remains an estimate. No RTL or hardware test was changed.

### 2026-10-26 - Verify C64 pipeline at 150 MHz

- Imported the supplied b0db7a0 results; verified all 16 archive checksums, four core RTL snapshots and the RTL source-list hash.
- Recorded a default 150 MHz OOC post-route timing pass: WNS +0.258 ns, WHS +0.010 ns, no setup or hold failures. Complete MFCC uses 35,777 LUT, 53,107 FF, 6.5 BRAM tiles and 59 DSP.
- Added a matched 150 MHz before/after comparison, raw reports and independently checked numerical results. The four-frame regression takes 39,508 cycles and preserves the pre-C64 coefficient CSV.
- Classified the 20 reported worst setup paths and documented an explicitly estimated 200 MHz margin. No production RTL was changed or hardware run performed during this results import; 200 MHz remains untested.

### 2026-10-26 - Pipeline C64 output processing

- Registered indexed operand selection, sqrt(2) compensation and post-add/output in three stages, carrying index, validity and bypass controls with the data.
- Preserved the original truncating arithmetic and interface. Backpressure and ED hold the complete pipeline; completion follows acceptance of the final output.
- Passed ten C64 parameter configurations, complete-DCT64 checks, twenty MFCC configurations and two 459-frame audio regressions with zero coefficient differences. The N1024 unstalled four-frame batch changes from 39,505 to 39,508 cycles.
- Replaced the existing C64 and DCT64 overview figures and updated the combined architecture PDF. Follow-up Vivado measurements are recorded in the subsequent results import above.

### 2026-10-26 - Recursive SkewDCT measurements

- Imported the supplied N1024 benchmark package, verified all 35 packaged checksums and checked the included core sources against tested commit 8f1fd37.
- Added raw post-route reports, verified CSV/JSON results and a resource comparison. Complete-MFCC DSP use falls from 123 to 59; LUT and FF use rise to 35,601 and 52,870 at 50 MHz.
- Recorded 50/100 MHz timing passes and the 150 MHz setup failure. Classified the 20 reported worst setup paths as C64 selection/multiplication/post-add and MFCC writeback; the former dense 150 MHz signoff used an additional Explore step.
- Independently recomputed precision metrics from local coefficient CSVs whose hashes match the package. This update changes reports and documentation only.

### 2026-10-25 - Narrow SkewDCT8 family interface

- Reduced recursive-mode c_in from 64*COEF_W bits (1,280 bits in the production wrapper) to a three-bit BLOCK family ID.
- Removed the Skew matrix coefficient ROM, wide coefficient interconnect and signature decoder from the production path. Generic matrix modes retain their original interface widths.
- Kept the thirteen-stage arithmetic, precision, valid/tag protocol and enabled-edge latency unchanged. Verified exact outputs against the preceding recursive implementation, including complete-MFCC runs without the old matrix ROM file.
- Updated the core and TDM-bank diagrams and the combined PDF; aligned the output assignments and connected their ports in the bank figure. Physical routing and utilization savings still require Vivado measurement.
- Connected the DCT64 overview's input/output handshake and overflow-status ports, replacing detached labels with routed connections and the existing sticky status registers.


### 2026-10-25 - Recursive SkewDCT8 pipeline

- Replaced the active dense SkewDCT8 calculation with an 8-to-4-to-2 factorization and 13 enabled register stages, retaining an initiation interval of one enabled edge.
- Kept the existing core ports and original parameter list, preserving the six-stage generic dense modes and selecting the structured path in the existing TDM wrapper.
- Verified the core, TDM bank, DCT64, 20 complete-MFCC configurations and two 459-frame audio runs. Recursive arithmetic uses a different rounding order; observed full-audio differences from the dense baseline were at most four output integer units.
- Updated the SkewDCT8, TDM-bank and DCT64 diagrams and added a five-page PDF with PNG/SVG exports. Hardware resource and post-route timing measurements remain pending.


### 2026-10-25 — High-frequency optimization

- Optimized the critical FFT and DCT datapaths by registering multiplication, addition/subtraction, reduction, and rounding stages to shorten combinational paths.
- Reorganized FFT intermediate storage and read/write scheduling around synchronous dual-port BRAM, reducing large register arrays and wide selection logic.
- Refined fixed-point widths, scaling, and rounding to improve numerical precision while retaining 64-dimensional MFCC output.
- Completed RTL functional simulations for FFT lengths 16/32/64/128/256/512/1024/2048, DCT, and the complete MFCC pipeline. Coefficient comparisons with the corresponding frozen references found no differences.
