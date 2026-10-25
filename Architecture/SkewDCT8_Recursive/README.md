# Recursive SkewDCT8 architecture

[Download the five-page PDF](SkewDCT8_Recursive_Architecture.pdf). Each page is also provided as PNG, SVG and a separate PDF. Black solid lines carry data; blue dashed lines carry control. Equal named connectors denote the same net and replace long cross-page or cross-row routes.

| Page | Contents | Preview |
| --- | --- | --- |
| R01 | Thirteen-stage recursive core, data registers and valid/tag/family pipeline | [PNG](R01.png) / [SVG](R01.svg) |
| R02 | Explicit 8-to-4-to-2 recursive connections and input pair permutation | [PNG](R02.png) / [SVG](R02.svg) |
| R03 | Registered butterfly, multiplication, rounding and matching sum delays | [PNG](R03.png) / [SVG](R03.svg) |
| R04 | Complete DCT64 data flow with the new shared Skew bank | [PNG](R04.png) / [SVG](R04.svg) |
| R05 | Group issue, coefficient family selection, tagged result writes and serializer | [PNG](R05.png) / [SVG](R05.svg) |

Register boxes show D/Q, the clock triangle and enable. Reset is shown where the RTL resets state; invalid payload registers have no reset. The result bank on R05 is the existing register bank with indexed access, not a new BRAM. R02 describes the mathematical grouping; R01 and R03 show the physical register boundaries.

The corresponding existing figures in `../SKEW_DCT64/` are updated: `SkewDCT8_Pipelined_Architecture.png` = R01, `D01.png` = R04 and `D02.png` = R05. The ordinary DCT8 core figures remain valid and unchanged.

For arithmetic, interface restrictions, simulation results and unmeasured hardware results, see [the implementation notes](../../docs/SkewDCT8_Recursive.md).
