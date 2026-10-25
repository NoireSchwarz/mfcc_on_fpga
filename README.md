# mfcc_on_fpga

## Recursive SkewDCT8 branch

The shared SkewDCT8 now uses a registered 8-to-4-to-2 factorization for the project's eight coefficient families. Ports and original parameters are retained; generic dense modes remain available. The recursive transform expresses 12 real products and 29 add/subtract operations, with multiplication, rounding and sparse post-adds separated by registers. This arithmetic count is not a measured DSP count.

See [implementation and validation notes](docs/SkewDCT8_Recursive.md) and the [updated architecture PDF](Architecture/SkewDCT8_Recursive/SkewDCT8_Recursive_Architecture.pdf). The original FFT, ordinary DCT8, MatrixDCT and IP sources are retained. This revision has passed RTL functional simulation; its Vivado utilization and implementation timing results are pending.

### DCT-Modul

Das Design des DCT-Moduls orientiert sich an den folgenden Publikationen [^1] [^2].

---

## Referenzen / References

[^1]: Markus Püschel. *Cooley-Tukey FFT Like Algorithms for the DCT*. Department of Electrical and Computer Engineering, Carnegie Mellon University. [📄 PDF](https://spiral.ece.cmu.edu/pub-smart/pubfile/paper_16.pdf)
[^2]: Markus Püschel and José M. F. Moura. *Algebraic Signal Processing Theory: Cooley-Tukey Type Algorithms for DCTs and DSTs*. [📄 PDF](https://spiral.ece.cmu.edu/pub-spiral/pubfile/asp-dct_150.pdf)


## Upload log

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
