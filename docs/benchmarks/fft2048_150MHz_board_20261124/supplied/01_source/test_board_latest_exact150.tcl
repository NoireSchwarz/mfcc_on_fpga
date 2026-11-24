# Run the proven USB/JTAG harness against the latest generic FFT architecture.
# The legacy case file is reused only as a fixed input/expected-data corpus.
set latest_root D:/KV260_MFCC/33_fft2048_latest_9be89af_150mhz_20261124
set legacy_bench D:/KV260_MFCC/32_fft2048_150mhz_board_20261123/project/bench_kv260
set legacy_script [file join $legacy_bench test_board_150mhz.tcl]
set f [open $legacy_script r]
set script [read $f]
close $f

set script [string map [list \
    {set bench [file normalize [file dirname [info script]]]} [format {set bench %s} $legacy_bench] \
    {set evidence_root D:/KV260_MFCC/32_fft2048_150mhz_board_20261123} [format {set evidence_root %s} $latest_root] \
    {set out [file join $evidence_root board_results_exact150 fft_2048]} {set out [file join $evidence_root board_results_latest_exact150 fft_2048]} \
    {set bitstream [file join $evidence_root implementation_150mhz kv260_fft2048_exact150.bit]} {set bitstream [file join $evidence_root kv260_fft2048_latest_exact150.bit]} \
] $script]

eval $script
