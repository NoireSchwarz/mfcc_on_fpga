# Exact 150 MHz USB/JTAG deployment and full-data verification.
set bench [file normalize [file dirname [info script]]]
set evidence_root [file normalize [file join $bench ../..]]
set out [file join $bench rerun_output]
file mkdir $out
file mkdir [file join $evidence_root temp]
set ::env(TEMP) [file join $evidence_root temp]
set ::env(TMP) $::env(TEMP)
set name fft_2048
source -notrace [file join $bench cases.tcl]
set design_constraint_frequency_hz 150000000
set fabric_frequency_hz 150000000
set bitstream [file join $evidence_root 02_implementation kv260_fft2048_latest_exact150.bit]
if {![file exists $bitstream]} {error "Exact-150 bitstream missing: $bitstream"}
open_hw_manager
connect_hw_server -url localhost:45678
set cable [get_hw_targets -quiet *XFL1GVXDXK2FA]
if {[llength $cable]!=1} {error "Expected KV260 USB/JTAG cable not uniquely found: $cable"}
current_hw_target $cable
set_property PARAM.FREQUENCY 15000000 $cable
open_hw_target
set device [get_hw_devices -quiet xck26_0]
if {[llength $device]!=1} {error "Expected xck26 not uniquely found"}
current_hw_device $device
set_property PROGRAM.FILE $bitstream $device
program_hw_devices $device
# A board booted without a PL image can keep the PS->PL boundary isolated.
# Execute the exported initialization's PL-only request after configuration.
close_hw_target
set power_result [exec C:/Windows/System32/cmd.exe /d /c F:/2026.1/Vivado/bin/xsdb.bat [file join $evidence_root 01_source enable_pl1_exact150.tcl] [file join $out clock_after_program.txt] 2>@1]
puts $power_result
if {[string first "fabric_Hz=150000000" $power_result]<0} {error "Exact-150 PL clock verification failed"}
open_hw_target
set device [get_hw_devices -quiet xck26_0]
current_hw_device $device
set_property PARAM.FREQUENCY 1000000 $cable
refresh_hw_device $device
set axi [get_hw_axis -quiet -of_objects $device]
if {[llength $axi]!=1} {error "Expected one JTAG AXI master, found $axi"}
set axi [lindex $axi 0]
reset_hw_axi $axi
set reverse_write 1
set reverse_read 1
proc write_words {address words} {
    global axi reverse_write
    if {$reverse_write} {set words [lreverse $words]}
    create_hw_axi_txn -quiet -force bench_write $axi -type WRITE -address [format %08x $address] \
        -len [llength $words] -size 32 -data [join $words _]
    run_hw_axi -quiet [get_hw_axi_txns bench_write]
}
proc read_words {address count} {
    global axi reverse_read
    create_hw_axi_txn -quiet -force bench_read $axi -type READ -address [format %08x $address] -len $count -size 32
    run_hw_axi -quiet [get_hw_axi_txns bench_read]
    set data [string tolower [get_property DATA [get_hw_axi_txns bench_read]]]
    regsub -all {[_[:space:]]} $data {} data
    while {[string length $data]<8*$count} {set data "0$data"}
    if {[string length $data]!=8*$count} {error "Unexpected AXI data length: [string length $data]"}
    set words [regexp -all -inline {.{8}} $data]
    if {$reverse_read} {return [lreverse $words]} else {return $words}
}
proc read_word {address} {return [lindex [read_words $address 1] 0]}
# Calibrate the burst order using two unique scratch words and single reads.
# This avoids relying on historic Vivado versions' differing display order.
write_words 256 {12345678 9abcdef0}
set first [read_word 256]
set second [read_word 260]
if {$first eq "9abcdef0" && $second eq "12345678"} {
    set reverse_write 0;write_words 256 {12345678 9abcdef0}
    set first [read_word 256];set second [read_word 260]
}
if {$first ne "12345678" || $second ne "9abcdef0"} {error "JTAG AXI scratch read/write failed: $first $second"}
set burst [read_words 256 2]
if {$burst eq {9abcdef0 12345678}} {set reverse_read 0;set burst [read_words 256 2]}
if {$burst ne {12345678 9abcdef0}} {error "JTAG AXI burst read calibration failed: $burst"}
set status [read_word 0]
if {$status ni {52454144 444f4e45}} {error "Engine boot signature not ready: $status"}
set summary [open [file join $out summary.csv] w]
puts $summary "case,input_samples,output_words,cycles,first_output_cycle,frequency_hz,design_constraint_frequency_hz,errors,mismatches,upload_ms,compute_poll_ms,download_ms"
foreach dataset $datasets {
    set label [dict get $dataset label]
    set samples [dict get $dataset samples]
    set count [dict get $dataset outputs]
    set input_words [dict get $dataset input_words]
    set expected [dict get $dataset expected]
    set start [clock milliseconds]
    write_words 4 {00000000}
    for {set i 0} {$i<[llength $input_words]} {incr i 256} {
        set block [lrange $input_words $i [expr {$i+255}]]
        write_words [expr {1024+4*$i}] $block
        set checked [read_words [expr {1024+4*$i}] [llength $block]]
        if {$checked ne $block} {error "Input RAM readback mismatch in $label at word $i"}
    }
    write_words 8 [list [format %08x $samples] [format %08x $count]]
    set upload_ms [expr {[clock milliseconds]-$start}]
    set start [clock milliseconds]
    write_words 4 {26000001}
    set deadline [expr {[clock milliseconds]+30000}]
    while {1} {
        set command [read_word 4]
        set status [read_word 0]
        if {$command eq "00000000" && $status eq "444f4e45"} {break}
        if {$status eq "54494d45"} {error "Engine hardware timeout: $label"}
        if {[clock milliseconds]>$deadline} {error "Host poll timeout: $label, status=$status"}
        after 1
    }
    set compute_ms [expr {[clock milliseconds]-$start}]
    set registers [read_words 16 6]
    scan [lindex $registers 0] %x cycles
    scan [lindex $registers 1] %x first_cycle
    scan [lindex $registers 2] %x accepted
    scan [lindex $registers 3] %x produced
    set errors [lindex $registers 4]
    scan $errors %x actual_errors
    if {$actual_errors!=[dict get $dataset expected_errors]} {error "Unexpected core error flags in $label: $errors"}
    if {$accepted!=$samples || $produced!=$count} {error "Board count mismatch: $label accepted=$accepted produced=$produced"}
    set raw [open [file join $out ${label}_raw.csv] w]
    puts $raw "index,hex_word"
    set mismatches 0
    set start [clock milliseconds]
    for {set i 0} {$i<$count} {incr i 256} {
        set size [expr {min(256,$count-$i)}]
        set block [read_words [expr {4*($output_base+$i)}] $size]
        for {set j 0} {$j<$size} {incr j} {
            set value [lindex $block $j]
            set index [expr {$i+$j}]
            puts $raw "$index,$value"
            if {$value ne [lindex $expected $index]} {incr mismatches}
        }
    }
    close $raw
    set download_ms [expr {[clock milliseconds]-$start}]
    puts $summary "$label,$samples,$count,$cycles,$first_cycle,$fabric_frequency_hz,$design_constraint_frequency_hz,$errors,$mismatches,$upload_ms,$compute_ms,$download_ms"
    flush $summary
    puts "BOARD $name $label: inputs=$accepted outputs=$produced cycles=$cycles mismatches=$mismatches errors=$errors"
    if {$mismatches!=0} {error "Full output comparison failed for $name $label: $mismatches words"}
}
close $summary
close_hw_target
close_hw_manager
set f [open [file join $out complete.txt] w]
puts $f "All datasets deployed via USB/JTAG and all output words matched expected numerical simulation."
close $f
puts "EXACT150_BOARD_TEST_COMPLETE output=$out"
