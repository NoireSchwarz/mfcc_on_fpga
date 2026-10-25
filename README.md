# mfcc_on_fpga
### DCT-Modul

Das Design des DCT-Moduls orientiert sich an den folgenden Publikationen [^1] [^2].

---

## Referenzen / References

[^1]: Markus Püschel. *Cooley-Tukey FFT Like Algorithms for the DCT*. Department of Electrical and Computer Engineering, Carnegie Mellon University. [📄 PDF](https://spiral.ece.cmu.edu/pub-smart/pubfile/paper_16.pdf)
[^2]: Markus Püschel and José M. F. Moura. *Algebraic Signal Processing Theory: Cooley-Tukey Type Algorithms for DCTs and DSTs*. [📄 PDF](https://spiral.ece.cmu.edu/pub-spiral/pubfile/asp-dct_150.pdf)


## Upload log

### 2026-10-25 — High-frequency optimization

- Optimized the critical FFT and DCT datapaths by registering multiplication, addition/subtraction, reduction, and rounding stages to shorten combinational paths.
- Reorganized FFT intermediate storage and read/write scheduling around synchronous dual-port BRAM, reducing large register arrays and wide selection logic.
- Refined fixed-point widths, scaling, and rounding to improve numerical precision while retaining 64-dimensional MFCC output.
- Completed RTL functional simulations for FFT lengths 16/32/64/128/256/512/1024/2048, DCT, and the complete MFCC pipeline. Coefficient comparisons with the corresponding frozen references found no differences.
- Moved architecture figures to the root `Architecture/` directory and retained the original `src/ip/` folder. Uploaded the original packaged project; supplementary simulation tools and reports remain local.
