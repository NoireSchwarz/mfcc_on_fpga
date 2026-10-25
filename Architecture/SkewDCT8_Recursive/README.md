# Recursive SkewDCT8 architecture

[Download the five-page PDF](SkewDCT8_Recursive_Architecture.pdf). Each page is also provided as PNG, SVG and a separate PDF. Black solid lines carry data; blue dashed lines carry control. Equal named connectors denote the same net and replace long cross-page or cross-row routes.

| Page | Contents | Preview |
| --- | --- | --- |
| R01 | Thirteen-stage recursive core, data registers and valid/tag/family pipeline | [PNG](R01.png) / [SVG](R01.svg) |
| R02 | Explicit 8-to-4-to-2 recursive connections and input pair permutation | [PNG](R02.png) / [SVG](R02.svg) |
| R03 | Registered butterfly, multiplication, rounding and matching sum delays | [PNG](R03.png) / [SVG](R03.svg) |
| R04 | Complete DCT64 data flow, connected handshake ports and sticky overflow status | [PNG](R04.png) / [SVG](R04.svg) |
| R05 | Group issue, direct three-bit family input, tagged result writes and serializer | [PNG](R05.png) / [SVG](R05.svg) |

Register boxes show D/Q, the clock triangle and enable. Reset is shown where the RTL resets state; invalid payload registers have no reset. The result bank on R05 is the existing register bank with indexed access, not a new BRAM. R02 describes the mathematical grouping; R01 and R03 show the physical register boundaries.

In recursive mode, c_in is now a three-bit BLOCK ID. R01 and R05 show this direct connection; the old matrix coefficient ROM, 1,280-bit coefficient bus and signature decoder are removed. The thirteen-stage arithmetic and valid/tag timing are unchanged.

R05 groups the existing m_valid, m_data and m_index assignments in a left-aligned output-mapping box connected to their ports, the result bank and the controller. This is combinational grouping for readability and introduces no new RTL module or register stage. The m_ready input is shown connected to the controller.

R04 connects s_valid/s_ready to the input control and m_valid/m_ready to the output control. The existing ovf_skew and ovf_dct registers are grouped as a two-bit register symbol, with their sticky OR updates, clock, per-bit enable and synchronous clearing on rst or IDLE. ovf_en[1:0] is diagram notation for the separate existing skew_norm_valid and dct_norm_valid conditions. Matching labels carry normalization overflow flags and the status feedback without long crossing wires. These symbols describe existing dct64_serial logic; no new RTL is added.

The corresponding existing figures in `../SKEW_DCT64/` are updated: `SkewDCT8_Pipelined_Architecture.png` = R01, `D01.png` = R04 and `D02.png` = R05. The ordinary DCT8 core figures remain valid and unchanged.

For arithmetic, interface restrictions, simulation results and unmeasured hardware results, see [the implementation notes](../../docs/SkewDCT8_Recursive.md).
