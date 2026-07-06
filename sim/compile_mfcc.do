if {![file exists sim/modelsim_work]} {
    vlib sim/modelsim_work
}

vlog -sv -work sim/modelsim_work \
    +incdir+src/work \
    +incdir+src/work/FFT512 \
    +incdir+src/work/FFT512/radix2_4_core \
    +incdir+src/work/FFT512/radix_16_core \
    +incdir+src/work/FFT512/radix_16_256_core \
    +incdir+src/work/DCT40_64 \
    sim/mult_gen_1_model.sv \
    src/work/dB_LUT.sv \
    src/work/reshape_output.sv \
    src/work/prepare_input.sv \
    src/work/hamming.sv \
    src/work/power_spectrum.sv \
    src/work/filter_bank.sv \
    src/work/FFT512/WROM2048.sv \
    src/work/FFT512/radix2_4_core/complex_twiddle_mul.sv \
    src/work/FFT512/radix2_4_core/fft_merge_kernel.sv \
    src/work/FFT512/radix2_4_core/radix2_merge_stage.sv \
    src/work/FFT512/radix2_4_core/radix4_merge_stage.sv \
    src/work/FFT512/radix_16_core/mpuc541.sv \
    src/work/FFT512/radix_16_core/mpuc1307.sv \
    src/work/FFT512/radix_16_core/mpuc707.sv \
    src/work/FFT512/radix_16_core/mpuc924_383.sv \
    src/work/FFT512/radix_16_core/fft16.sv \
    src/work/FFT512/radix_16_256_core/bufram256c.sv \
    src/work/FFT512/radix_16_256_core/cnorm.sv \
    src/work/FFT512/radix_16_256_core/ram256.sv \
    src/work/FFT512/radix_16_256_core/ram2x256.sv \
    src/work/FFT512/radix_16_256_core/rotator256_v.sv \
    src/work/FFT512/radix_16_256_core/fft256_config.sv \
    src/work/FFT512/radix_16_256_core/fft256.sv \
    src/work/FFT512/fft_16_64.sv \
    src/work/FFT512/fft256_1024.sv \
    src/work/FFT512/fft2x.sv \
    src/work/FFT512/fft512.sv \
    src/work/DCT40_64/skew_paraller_bufram64.sv \
    src/work/DCT40_64/skewdct_8.sv \
    src/work/DCT40_64/skewdct8_tdm.sv \
    src/work/DCT40_64/norm.sv \
    src/work/DCT40_64/DCT/signed_mult.sv \
    src/work/DCT40_64/DCT/butterfly.sv \
    src/work/DCT40_64/DCT/dct8.sv \
    src/work/DCT40_64/dct8_tdm_bank.sv \
    src/work/DCT40_64/c64_8_postadd_serial.sv \
    src/work/DCT40_64/dct64_serial.sv \
    src/work/mfcc.sv \
    sim/mfcc_trumpet_tb.sv
